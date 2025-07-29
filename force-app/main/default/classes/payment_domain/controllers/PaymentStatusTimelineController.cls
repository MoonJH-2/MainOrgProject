/**
 * @description       : 
 * @author            : JH Moon
 * @last modified on  : 07-14-2025
 * @last modified by  : JH Moon
**/
public with sharing class PaymentStatusTimelineController {
    
    @AuraEnabled(cacheable=true)
    public static PaymentTimelineWrapper getPaymentTimeline(Id orderId) {
        try {
            // Order 정보 조회
            Order orderInfo = [
                SELECT Id, OrderNumber, TotalAmount, EffectiveDate, Payment_Method__c, Account.Name
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            // PaymentStatus 목록 조회
            List<PaymentStatus__c> paymentStatuses = [
                SELECT Id, Order__c, Amount__c, DueDate__c, Installment_Number__c, Status__c, PaidDate__c
                FROM PaymentStatus__c 
                WHERE Order__c = :orderId 
                ORDER BY Installment_Number__c ASC
            ];
            
            // 진행률 계산
            Integer totalInstallments = paymentStatuses.size();
            Integer completedInstallments = 0;
            Integer overdueInstallments = 0;
            Date today = Date.today();
            
            for (PaymentStatus__c ps : paymentStatuses) {
                if (ps.Status__c == '완납') {
                    completedInstallments++;
                } else if (ps.DueDate__c != null && ps.DueDate__c < today) {
                    overdueInstallments++;
                }
            }
            
            Decimal progressPercentage = totalInstallments > 0 ? 
                (Decimal.valueOf(completedInstallments) / totalInstallments * 100).setScale(1) : 0;
            
            PaymentTimelineWrapper wrapper = new PaymentTimelineWrapper();
            wrapper.orderInfo = orderInfo;
            wrapper.paymentStatuses = paymentStatuses;
            wrapper.totalInstallments = totalInstallments;
            wrapper.completedInstallments = completedInstallments;
            wrapper.overdueInstallments = overdueInstallments;
            wrapper.progressPercentage = progressPercentage;
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('납부 일정을 가져오는 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String updatePaymentStatus(Id paymentStatusId, String newStatus) {
        try {
            PaymentStatus__c ps = new PaymentStatus__c(
                Id = paymentStatusId,
                Status__c = newStatus
            );
            
            // 완납 처리 시 납부일자 설정, 미납 처리 시 납부일자 제거
            if (newStatus == '완납') {
                ps.PaidDate__c = Date.today();
            } else {
                ps.PaidDate__c = null;
            }
            
            update ps;
            
            // 트리거에서 Task 생성을 처리하므로 여기서는 제거
            // checkOverdueAndCreateTasks(new List<Id>{paymentStatusId});
            
            return 'SUCCESS';
        } catch (Exception e) {
            throw new AuraHandledException('납부 상태 업데이트 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String updateMultiplePaymentStatus(List<Id> paymentStatusIds, String newStatus) {
        try {
            List<PaymentStatus__c> paymentStatusesToUpdate = new List<PaymentStatus__c>();
            
            for (Id psId : paymentStatusIds) {
                paymentStatusesToUpdate.add(new PaymentStatus__c(
                    Id = psId,
                    Status__c = newStatus
                ));
            }
            
            if (!paymentStatusesToUpdate.isEmpty()) {
                update paymentStatusesToUpdate;
            }
            
            return 'SUCCESS';
        } catch (Exception e) {
            throw new AuraHandledException('납부 상태 일괄 업데이트 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String generatePaymentSchedulePDF(Id orderId) {
        try {
            // Order 정보 조회 (OrderItem 포함)
            Order orderInfo = [
                SELECT Id, OrderNumber, Account.Name, AccountId, TotalAmount,
                       (SELECT Id, Product2Id, Product2.Name, Quantity, UnitPrice, TotalPrice 
                        FROM OrderItems)
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            // 1. 납부확인서 PDF 생성
            PageReference paymentPdfPage = Page.PaymentSchedule_PDF;
            paymentPdfPage.getParameters().put('orderId', orderId);
            Blob paymentPdfBlob = paymentPdfPage.getContentAsPDF();
            
            // 납부확인서 첨부파일 생성
            ContentVersion paymentPdf = new ContentVersion();
            paymentPdf.Title = '납부확인서_' + orderInfo.OrderNumber + '_' + String.valueOf(System.now()).replace(' ', '_').replace(':', '');
            paymentPdf.PathOnClient = paymentPdf.Title + '.pdf';
            paymentPdf.VersionData = paymentPdfBlob;
            paymentPdf.FirstPublishLocationId = orderId;
            paymentPdf.ContentLocation = 'S';
            
            // 2. 세금계산서 PDF 생성
            ContentVersion taxInvoicePdf = generateTaxInvoicePDF(orderInfo);
            
            // 3. Asset 생성 및 Order 연결 (PDF 저장 전에 먼저 생성)
            Asset orderAsset = createAssetForOrder(orderInfo);
            
            // PDF 파일들 저장
            List<ContentVersion> pdfsToInsert = new List<ContentVersion>{paymentPdf, taxInvoicePdf};
            insert pdfsToInsert;
            
            // 4. Asset에 PDF 첨부 (저장된 PDF를 Asset에 연결)
            attachPDFsToAsset(orderAsset.Id, pdfsToInsert);
            
            // PDF 생성 관련 Task 생성
            createPDFGenerationTask(orderId, orderInfo.OrderNumber, paymentPdf.Title + ', ' + taxInvoicePdf.Title);
            
            // Asset 생성 관련 Task 생성
            createAssetCreationTask(orderId, orderInfo.OrderNumber, orderAsset.Id);
            
            return paymentPdf.Id;
        } catch (Exception e) {
            throw new AuraHandledException('PDF 생성 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * 세금계산서 PDF 생성 (한국 표준 양식)
     */
    private static ContentVersion generateTaxInvoicePDF(Order orderInfo) {
        try {
            // OrderItem 기반 세금 계산
            Decimal totalAmount = 0;
            Decimal vatAmount = 0;
            Decimal supplyAmount = 0;
            
            if (!orderInfo.OrderItems.isEmpty()) {
                for (OrderItem item : orderInfo.OrderItems) {
                    totalAmount += item.TotalPrice;
                }
                // 부가세 10% 계산
                supplyAmount = totalAmount / 1.1;
                vatAmount = totalAmount - supplyAmount;
            } else {
                // OrderItem이 없는 경우 Order.TotalAmount 사용
                totalAmount = orderInfo.TotalAmount != null ? orderInfo.TotalAmount : 0;
                supplyAmount = totalAmount / 1.1;
                vatAmount = totalAmount - supplyAmount;
            }
            
            // 한국 표준 세금계산서 Visualforce 페이지 사용
            PageReference taxInvoicePage = Page.TaxInvoice_PDF;
            taxInvoicePage.getParameters().put('orderId', orderInfo.Id);
            Blob taxInvoiceBlob = taxInvoicePage.getContentAsPDF();
            
            // ContentVersion 생성
            ContentVersion taxPdf = new ContentVersion();
            taxPdf.Title = '세금계산서_' + orderInfo.OrderNumber + '_' + String.valueOf(System.now()).replace(' ', '_').replace(':', '');
            taxPdf.PathOnClient = taxPdf.Title + '.pdf';
            taxPdf.VersionData = taxInvoiceBlob;
            taxPdf.FirstPublishLocationId = orderInfo.Id;
            taxPdf.ContentLocation = 'S';
            
            return taxPdf;
            
        } catch (Exception e) {
            System.debug('세금계산서 생성 오류: ' + e.getMessage());
            // 기본 세금계산서 반환 (fallback)
            ContentVersion defaultTaxPdf = new ContentVersion();
            defaultTaxPdf.Title = '세금계산서_' + orderInfo.OrderNumber + '_' + String.valueOf(System.now()).replace(' ', '_').replace(':', '');
            defaultTaxPdf.PathOnClient = defaultTaxPdf.Title + '.pdf';
            defaultTaxPdf.VersionData = Blob.valueOf('세금계산서 생성 중 오류가 발생했습니다. 고객센터로 문의하시기 바랍니다.');
            defaultTaxPdf.FirstPublishLocationId = orderInfo.Id;
            defaultTaxPdf.ContentLocation = 'S';
            return defaultTaxPdf;
        }
    }
    
    /**
     * 완납 처리 메서드 (테스트용)
     */
    @AuraEnabled
    public static String markAllPaymentsAsCompleted(Id orderId) {
        try {
            // 해당 Order의 모든 PaymentStatus를 완납으로 변경
            List<PaymentStatus__c> paymentStatuses = [
                SELECT Id, Status__c, Installment_Number__c
                FROM PaymentStatus__c
                WHERE Order__c = :orderId
                AND Status__c != '완납'
            ];
            
            if (paymentStatuses.isEmpty()) {
                return 'SUCCESS: 이미 모든 납부가 완료되었습니다.';
            }
            
            for (PaymentStatus__c payment : paymentStatuses) {
                payment.Status__c = '완납';
                payment.PaidDate__c = Date.today();
            }
            
            update paymentStatuses;
            
            // 완납 처리 Task 생성
            createCompletedPaymentTasks(paymentStatuses);
            
            return 'SUCCESS: ' + paymentStatuses.size() + '개의 납부 항목이 완납으로 처리되었습니다.';
            
        } catch (Exception e) {
            throw new AuraHandledException('완납 처리 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }

    /**
     * 완납 처리된 납부에 대한 Task 생성
     */
    private static void createCompletedPaymentTasks(List<PaymentStatus__c> completedPayments) {
        try {
            List<Task> tasksToCreate = new List<Task>();
            
            for (PaymentStatus__c payment : completedPayments) {
                Task newTask = new Task(
                    Subject = payment.Installment_Number__c + '회차 납부 완료',
                    Status = 'Completed',
                    Priority = 'Normal',
                    WhatId = payment.Id
                );
                tasksToCreate.add(newTask);
            }
            
            if (!tasksToCreate.isEmpty()) {
                insert tasksToCreate;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Task 생성 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String sendPaymentNotificationEmail(Id orderId, String emailAddress) {
        try {
            // Order 정보 조회
            Order orderInfo = [
                SELECT Id, OrderNumber, Account.Name, TotalAmount
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            // PaymentStatus 조회
            List<PaymentStatus__c> paymentStatuses = [
                SELECT Id, Amount__c, DueDate__c, Installment_Number__c, Status__c
                FROM PaymentStatus__c 
                WHERE Order__c = :orderId AND Status__c = '미납'
                ORDER BY Installment_Number__c ASC
            ];
            
            // 이메일 발송
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { emailAddress });
            email.setSubject('[' + orderInfo.OrderNumber + '] 납부 일정 안내');
            
            // HTML 이메일 본문 생성
            String emailBody = generateEmailBody(orderInfo, paymentStatuses);
            email.setHtmlBody(emailBody);
            
            // PDF 첨부
            try {
                PageReference pdfPage = Page.PaymentSchedule_PDF;
                pdfPage.getParameters().put('orderId', orderId);
                Blob pdfBlob = pdfPage.getContentAsPDF();
                
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('납부일정서.pdf');
                attachment.setBody(pdfBlob);
                attachment.setContentType('application/pdf');
                
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            } catch (Exception pdfEx) {
                System.debug('PDF 첨부 실패: ' + pdfEx.getMessage());
            }
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            return 'EMAIL_SENT_SUCCESS';
        } catch (Exception e) {
            throw new AuraHandledException('이메일 발송 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    private static String generateEmailBody(Order orderInfo, List<PaymentStatus__c> paymentStatuses) {
        String body = '<html><body>';
        body += '<h2>납부 일정 안내</h2>';
        body += '<p>안녕하세요, ' + orderInfo.Account.Name + ' 고객님</p>';
        body += '<p>주문번호 <strong>' + orderInfo.OrderNumber + '</strong>에 대한 납부 일정을 안내드립니다.</p>';
        
        if (!paymentStatuses.isEmpty()) {
            body += '<h3>미납 내역</h3>';
            body += '<table border="1" style="border-collapse: collapse; width: 100%;">';
            body += '<tr style="background-color: #f0f0f0;"><th>회차</th><th>납부 예정일</th><th>납부 금액</th></tr>';
            
            for (PaymentStatus__c ps : paymentStatuses) {
                body += '<tr>';
                body += '<td style="text-align: center;">' + ps.Installment_Number__c + '</td>';
                body += '<td style="text-align: center;">' + ps.DueDate__c + '</td>';
                body += '<td style="text-align: right;">' + String.valueOf(ps.Amount__c) + '원</td>';
                body += '</tr>';
            }
            
            body += '</table>';
        }
        
        body += '<p>자세한 내용은 첨부된 납부일정서를 확인해 주시기 바랍니다.</p>';
        body += '<p>감사합니다.</p>';
        body += '</body></html>';
        
        return body;
    }
    
    // 연체 체크 및 Task 생성 메서드
    @AuraEnabled
    public static void checkOverdueAndCreateTasks(List<Id> paymentStatusIds) {
        try {
            List<PaymentStatus__c> paymentStatuses = [
                SELECT Id, Order__c, Order__r.OrderNumber, Order__r.Account.Name, 
                       Amount__c, DueDate__c, Installment_Number__c, Status__c, PaidDate__c
                FROM PaymentStatus__c 
                WHERE Id IN :paymentStatusIds
            ];
            
            Date today = Date.today();
            List<Task> tasksToCreate = new List<Task>();
            Set<String> subjectsToCheck = new Set<String>();
            
            // 먼저 생성할 Task Subject들을 수집
            for (PaymentStatus__c ps : paymentStatuses) {
                // 연체 상황 체크
                if (ps.DueDate__c != null && ps.DueDate__c < today && ps.Status__c == '미납') {
                    subjectsToCheck.add('연체 알림 - ' + ps.Order__r.OrderNumber + ' ' + ps.Installment_Number__c + '차');
                }
                
                // 완납 처리 시 완료 Task 생성
                if (ps.Status__c == '완납' && ps.PaidDate__c == Date.today()) {
                    subjectsToCheck.add('납부 완료 - ' + ps.Order__r.OrderNumber + ' ' + ps.Installment_Number__c + '차');
                }
            }
            
            // 오늘 생성된 동일한 Subject의 Task가 있는지 확인
            Set<String> existingSubjects = new Set<String>();
            if (!subjectsToCheck.isEmpty()) {
                List<Task> existingTasks = [
                    SELECT Subject FROM Task 
                    WHERE Subject IN :subjectsToCheck 
                    AND CreatedDate = TODAY
                ];
                
                for (Task t : existingTasks) {
                    existingSubjects.add(t.Subject);
                }
            }
            
            // 중복되지 않은 Task만 생성
            for (PaymentStatus__c ps : paymentStatuses) {
                // 연체 상황 체크 (납부 기일이 지났는데 미납 상태)
                if (ps.DueDate__c != null && ps.DueDate__c < today && ps.Status__c == '미납') {
                    String overdueSubject = '연체 알림 - ' + ps.Order__r.OrderNumber + ' ' + ps.Installment_Number__c + '차';
                    
                    if (!existingSubjects.contains(overdueSubject)) {
                        Integer overdueDays = today.daysBetween(ps.DueDate__c);
                        
                        Task overdueTask = new Task();
                        overdueTask.Subject = overdueSubject;
                        overdueTask.Description = buildOverdueTaskDescription(ps, overdueDays);
                        overdueTask.WhatId = ps.Order__c; // Order와 연결
                        overdueTask.ActivityDate = Date.today();
                        overdueTask.Priority = 'High';
                        overdueTask.Status = 'Open';
                        overdueTask.Type = '연체 관리';
                        
                        tasksToCreate.add(overdueTask);
                        existingSubjects.add(overdueSubject); // 중복 방지용 추가
                    }
                }
                
                // 완납 처리 시 완료 Task 생성
                if (ps.Status__c == '완납' && ps.PaidDate__c == Date.today()) {
                    String completedSubject = '납부 완료 - ' + ps.Order__r.OrderNumber + ' ' + ps.Installment_Number__c + '차';
                    
                    if (!existingSubjects.contains(completedSubject)) {
                        Task completedTask = new Task();
                        completedTask.Subject = completedSubject;
                        completedTask.Description = buildCompletedTaskDescription(ps);
                        completedTask.WhatId = ps.Order__c; // Order와 연결
                        completedTask.ActivityDate = Date.today();
                        completedTask.Priority = 'Normal';
                        completedTask.Status = 'Completed';
                        completedTask.Type = '납부 관리';
                        
                        tasksToCreate.add(completedTask);
                        existingSubjects.add(completedSubject); // 중복 방지용 추가
                    }
                }
            }
            
            if (!tasksToCreate.isEmpty()) {
                insert tasksToCreate;
            }
            
        } catch (Exception e) {
            System.debug('Task 생성 중 오류: ' + e.getMessage());
        }
    }
    
    // PDF 생성 Task 생성 메서드
    private static void createPDFGenerationTask(Id orderId, String orderNumber, String pdfFileName) {
        try {
            Task pdfTask = new Task();
            pdfTask.Subject = 'PDF 생성 완료 - ' + orderNumber + ' 납부확인서';
            pdfTask.Description = buildPDFTaskDescription(orderNumber, pdfFileName);
            pdfTask.WhatId = orderId; // Order와 연결
            pdfTask.ActivityDate = Date.today();
            pdfTask.Priority = 'Normal';
            pdfTask.Status = 'Completed';
            pdfTask.Type = '문서 관리';
            
            insert pdfTask;
            
        } catch (Exception e) {
            System.debug('PDF Task 생성 중 오류: ' + e.getMessage());
        }
    }
    
    // 연체 Task 설명 생성
    private static String buildOverdueTaskDescription(PaymentStatus__c ps, Integer overdueDays) {
        String description = '🚨 연체 알림\n\n';
        description += '📋 주문 정보:\n';
        description += '• 주문번호: ' + ps.Order__r.OrderNumber + '\n';
        description += '• 고객명: ' + ps.Order__r.Account.Name + '\n';
        description += '• 납부 회차: ' + ps.Installment_Number__c + '차\n\n';
        
        description += '💰 연체 내역:\n';
        description += '• 납부 예정일: ' + ps.DueDate__c.format() + '\n';
        description += '• 납부 금액: ' + String.valueOf(ps.Amount__c.format()) + '원\n';
        description += '• 연체 일수: ' + overdueDays + '일\n';
        description += '• 현재 상태: ' + ps.Status__c + '\n\n';
        
        description += '📞 필요 조치:\n';
        description += '• 고객 연락 및 납부 독촉\n';
        description += '• 연체료 산정 검토\n';
        description += '• 납부 계획 재협의 필요 시 협의\n\n';
        
        description += '⏰ 생성일시: ' + System.now().format('yyyy-MM-dd HH:mm:ss');
        
        return description;
    }
    
    // 완납 Task 설명 생성
    private static String buildCompletedTaskDescription(PaymentStatus__c ps) {
        String description = '✅ 납부 완료\n\n';
        description += '📋 주문 정보:\n';
        description += '• 주문번호: ' + ps.Order__r.OrderNumber + '\n';
        description += '• 고객명: ' + ps.Order__r.Account.Name + '\n';
        description += '• 납부 회차: ' + ps.Installment_Number__c + '차\n\n';
        
        description += '💰 납부 내역:\n';
        description += '• 납부 예정일: ' + ps.DueDate__c.format() + '\n';
        description += '• 납부 완료일: ' + ps.PaidDate__c.format() + '\n';
        description += '• 납부 금액: ' + String.valueOf(ps.Amount__c.format()) + '원\n';
        description += '• 현재 상태: ' + ps.Status__c + '\n\n';
        
        description += '⏰ 완료일시: ' + System.now().format('yyyy-MM-dd HH:mm:ss');
        
        return description;
    }
    
    // PDF 생성 Task 설명 생성
    private static String buildPDFTaskDescription(String orderNumber, String pdfFileName) {
        String description = '📄 납부확인서 PDF 생성 완료\n\n';
        description += '📋 생성 정보:\n';
        description += '• 주문번호: ' + orderNumber + '\n';
        description += '• 파일명: ' + pdfFileName + '\n';
        description += '• 생성일시: ' + System.now().format('yyyy-MM-dd HH:mm:ss') + '\n\n';
        
        description += '📁 파일 위치:\n';
        description += '• Notes & Attachments 섹션에서 확인 가능\n';
        description += '• 고객 발송용으로 활용 가능\n\n';
        
        description += '📞 후속 조치:\n';
        description += '• 필요 시 고객에게 이메일 발송\n';
        description += '• 납부 일정 안내 및 확인\n';
        
        return description;
    }
    
    // 스케줄러용 연체 체크 메서드 (일일 배치 실행용)
    @AuraEnabled
    public static void checkAllOverduePayments() {
        try {
            Date today = Date.today();
            
            // 연체된 모든 PaymentStatus 조회
            List<PaymentStatus__c> overduePayments = [
                SELECT Id, Order__c, Order__r.OrderNumber, Order__r.Account.Name,
                       Amount__c, DueDate__c, Installment_Number__c, Status__c
                FROM PaymentStatus__c 
                WHERE DueDate__c < :today 
                AND Status__c = '미납'
                ORDER BY DueDate__c ASC
                LIMIT 200
            ];
            
            if (!overduePayments.isEmpty()) {
                // 오늘 생성된 연체 알림 Task 조회 (중복 방지)
                Set<String> existingTaskSubjects = new Set<String>();
                List<Task> todayTasks = [
                    SELECT Subject FROM Task 
                    WHERE Subject LIKE '%연체 알림%' 
                    AND CreatedDate = TODAY
                ];
                
                for (Task t : todayTasks) {
                    existingTaskSubjects.add(t.Subject);
                }
                
                // 중복되지 않은 PaymentStatus만 처리
                List<Id> overdueIds = new List<Id>();
                for (PaymentStatus__c ps : overduePayments) {
                    String expectedSubject = '연체 알림 - ' + ps.Order__r.OrderNumber + ' ' + ps.Installment_Number__c + '차';
                    if (!existingTaskSubjects.contains(expectedSubject)) {
                        overdueIds.add(ps.Id);
                    }
                }
                
                if (!overdueIds.isEmpty()) {
                    checkOverdueAndCreateTasks(overdueIds);
                }
            }
            
        } catch (Exception e) {
            System.debug('일괄 연체 체크 중 오류: ' + e.getMessage());
        }
    }
    
    // Wrapper 클래스
    public class PaymentTimelineWrapper {
        @AuraEnabled public Order orderInfo { get; set; }
        @AuraEnabled public List<PaymentStatus__c> paymentStatuses { get; set; }
        @AuraEnabled public Integer totalInstallments { get; set; }
        @AuraEnabled public Integer completedInstallments { get; set; }
        @AuraEnabled public Integer overdueInstallments { get; set; }
        @AuraEnabled public Decimal progressPercentage { get; set; }
    }
    
    // Helper method: Asset 생성 및 Order 연결
    private static Asset createAssetForOrder(Order orderInfo) {
        try {
            // 기존 Asset 존재 여부 확인
            List<Asset> existingAssets = [
                SELECT Id, Name 
                FROM Asset 
                WHERE Order__c = :orderInfo.Id 
                LIMIT 1
            ];
            
            if (!existingAssets.isEmpty()) {
                return existingAssets[0];
            }
            
            // 새 Asset 생성
            Asset orderAsset = new Asset();
            orderAsset.Name = 'Order ' + orderInfo.OrderNumber + ' Documents';
            orderAsset.AccountId = orderInfo.AccountId;
            orderAsset.Order__c = orderInfo.Id;
            orderAsset.Status = 'Installed';
            orderAsset.Description = 'Order ' + orderInfo.OrderNumber + '의 생성된 문서들 (납부확인서, 세금계산서)';
            orderAsset.SerialNumber = 'DOC-' + orderInfo.OrderNumber + '-' + String.valueOf(System.now().getTime());
            
            insert orderAsset;
            return orderAsset;
            
        } catch (Exception e) {
            System.debug('Asset 생성 오류: ' + e.getMessage());
            throw new AuraHandledException('Asset 생성 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    // Helper method: Asset에 PDF 첨부
    private static void attachPDFsToAsset(Id assetId, List<ContentVersion> pdfFiles) {
        try {
            // ContentVersion에서 ContentDocumentId 조회
            List<ContentVersion> insertedPdfs = [
                SELECT Id, ContentDocumentId, Title
                FROM ContentVersion 
                WHERE Id IN :pdfFiles
            ];
            
            // Asset에 ContentDocument 연결
            List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
            
            for (ContentVersion pdf : insertedPdfs) {
                ContentDocumentLink link = new ContentDocumentLink();
                link.LinkedEntityId = assetId;
                link.ContentDocumentId = pdf.ContentDocumentId;
                link.ShareType = 'V';
                link.Visibility = 'AllUsers';
                linksToInsert.add(link);
            }
            
            if (!linksToInsert.isEmpty()) {
                insert linksToInsert;
                System.debug('PDF 파일들이 Asset에 성공적으로 첨부되었습니다. Asset ID: ' + assetId);
            }
            
        } catch (Exception e) {
            System.debug('PDF Asset 첨부 오류: ' + e.getMessage());
            throw new AuraHandledException('PDF를 Asset에 첨부하는 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    // Helper method: Asset 관련 Task 생성
    private static void createAssetCreationTask(Id orderId, String orderNumber, Id assetId) {
        try {
            Task assetTask = new Task();
            assetTask.Subject = 'Asset 생성 완료 - ' + orderNumber + ' 문서 관리';
            assetTask.Description = buildAssetTaskDescription(orderNumber, assetId);
            assetTask.WhatId = orderId;
            assetTask.ActivityDate = Date.today();
            assetTask.Priority = 'Normal';
            assetTask.Status = 'Completed';
            assetTask.Type = 'Asset 관리';
            
            insert assetTask;
            
        } catch (Exception e) {
            System.debug('Asset Task 생성 중 오류: ' + e.getMessage());
        }
    }
    
    // Asset Task 설명 생성
    private static String buildAssetTaskDescription(String orderNumber, Id assetId) {
        String description = '📦 Asset 생성 및 문서 연결 완료\n\n';
        description += '📋 Asset 정보:\n';
        description += '• 주문번호: ' + orderNumber + '\n';
        description += '• Asset ID: ' + assetId + '\n';
        description += '• 생성일시: ' + System.now().format('yyyy-MM-dd HH:mm:ss') + '\n\n';
        
        description += '📄 첨부된 문서:\n';
        description += '• 납부확인서 PDF\n';
        description += '• 세금계산서 PDF\n\n';
        
        description += '📁 문서 관리:\n';
        description += '• Asset의 Notes & Attachments에서 확인 가능\n';
        description += '• Order와 Asset이 연결되어 통합 관리 가능\n';
        description += '• 추가 문서 업로드 시 동일 Asset 활용\n\n';
        
        description += '🔗 관련 객체:\n';
        description += '• Order → Asset → ContentDocument 구조로 연결\n';
        description += '• 고객별 문서 이력 추적 가능\n';
        
        return description;
    }

    /**
     * @description Asset과 연결된 Payment History 조회
     * @param assetId Asset ID
     * @return List<PaymentStatus__c> Payment 히스토리 목록
     */
    @AuraEnabled(cacheable=true)
    public static List<PaymentStatus__c> getPaymentHistory(Id assetId) {
        try {
            // Asset에서 Order 조회
            Asset assetInfo = [
                SELECT Id, Order__c
                FROM Asset 
                WHERE Id = :assetId 
                LIMIT 1
            ];
            
            if (assetInfo.Order__c == null) {
                return new List<PaymentStatus__c>();
            }
            
            // Order와 연결된 PaymentStatus 목록 조회
            return [
                SELECT Id, Order__c, Amount__c, DueDate__c, Installment_Number__c, 
                       Status__c, PaidDate__c, CreatedDate, LastModifiedDate
                FROM PaymentStatus__c 
                WHERE Order__c = :assetInfo.Order__c 
                ORDER BY Installment_Number__c ASC
            ];
            
        } catch (Exception e) {
            System.debug('PaymentStatusTimelineController.getPaymentHistory Error: ' + e.getMessage());
            throw new AuraHandledException('Payment 히스토리를 가져오는 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
}
