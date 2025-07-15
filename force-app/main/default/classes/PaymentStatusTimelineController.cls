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
                SELECT Id, Order__c, Amount__c, DueDate__c, InstallmentNumber__c, Status__c, PaidDate__c
                FROM PaymentStatus__c 
                WHERE Order__c = :orderId 
                ORDER BY InstallmentNumber__c ASC
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
            // PDF 페이지 URL 생성
            PageReference pdfPage = Page.PaymentSchedule_PDF;
            pdfPage.getParameters().put('orderId', orderId);
            
            // PDF 생성 및 첨부파일로 저장 (선택사항)
            Blob pdfBlob = pdfPage.getContentAsPDF();
            
            // 첨부파일 생성
            Attachment attachment = new Attachment();
            attachment.Name = '납부일정서_' + String.valueOf(Date.today()) + '.pdf';
            attachment.Body = pdfBlob;
            attachment.ParentId = orderId;
            attachment.ContentType = 'application/pdf';
            
            insert attachment;
            
            return attachment.Id;
        } catch (Exception e) {
            throw new AuraHandledException('PDF 생성 중 오류가 발생했습니다: ' + e.getMessage());
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
                SELECT Id, Amount__c, DueDate__c, InstallmentNumber__c, Status__c
                FROM PaymentStatus__c 
                WHERE Order__c = :orderId AND Status__c = '미납'
                ORDER BY InstallmentNumber__c ASC
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
                body += '<td style="text-align: center;">' + ps.InstallmentNumber__c + '</td>';
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
    
    // Wrapper 클래스
    public class PaymentTimelineWrapper {
        @AuraEnabled public Order orderInfo { get; set; }
        @AuraEnabled public List<PaymentStatus__c> paymentStatuses { get; set; }
        @AuraEnabled public Integer totalInstallments { get; set; }
        @AuraEnabled public Integer completedInstallments { get; set; }
        @AuraEnabled public Integer overdueInstallments { get; set; }
        @AuraEnabled public Decimal progressPercentage { get; set; }
    }
}
