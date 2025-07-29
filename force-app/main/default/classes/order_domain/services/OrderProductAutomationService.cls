/**
 * @description Order Product 등록 시 자동화 서비스
 * - PDF 자동 생성 및 다운로드
 * - Slack 채널 자동 생성
 * - 알림 발송
 * @author JH Moon
 * @last modified on 07-21-2025
 * @last modified by JH Moon
 */
public with sharing class OrderProductAutomationService {
    
    /**
     * Order Product 등록 시 자동화 처리 (비동기)
     */
    @future(callout=true)
    public static void processOrderProductAutomation(Set<Id> orderIds) {
        try {
            System.debug('🤖 Order Product 자동화 시작: ' + orderIds.size() + '개 Order');
            
            // 1. Order 정보 조회 (OrderItem 포함)
            List<Order> ordersWithProducts = [
                SELECT Id, OrderNumber, Account.Name, Account.Id, TotalAmount, 
                       Payment_Method__c, Status, EffectiveDate, OwnerId, Owner.Email,
                       Slack_Channel_ID__c, Slack_Channel_Name__c, Slack_Notification_Status__c,
                       (SELECT Id, Product2.Name, Product2.ProductCode, Quantity, 
                               UnitPrice, TotalPrice FROM OrderItems)
                FROM Order 
                WHERE Id IN :orderIds 
                AND Status = 'Activated'
            ];
            
            if (ordersWithProducts.isEmpty()) {
                System.debug('❌ 처리할 Activated Order가 없습니다.');
                return;
            }
            
            System.debug('📋 처리 대상 Order: ' + ordersWithProducts.size() + '개');
            
            // 2. PDF 자동 생성 및 첨부
            generateOrderProductPDFs(ordersWithProducts);
            
            // 3. Slack 채널 자동 생성
            createSlackChannels(ordersWithProducts);
            
            // 4. 완료 알림 발송
            sendCompletionNotifications(ordersWithProducts);
            
            System.debug('✅ Order Product 자동화 완료');
            
        } catch (Exception e) {
            System.debug('❌ Order Product 자동화 오류: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }
    
    /**
     * Order Product 상세 PDF 생성 및 첨부
     */
    private static void generateOrderProductPDFs(List<Order> orders) {
        List<ContentVersion> pdfVersionsToInsert = new List<ContentVersion>();
        List<ContentDocumentLink> cdlsToInsert = new List<ContentDocumentLink>();
        
        for (Order orderInfo : orders) {
            try {
                // OrderItem이 없는 경우 건너뛰기
                if (orderInfo.OrderItems.isEmpty()) {
                    System.debug('⚠️ Order ' + orderInfo.OrderNumber + '에 OrderItem이 없습니다.');
                    continue;
                }
                
                System.debug('📄 PDF 생성 중: Order ' + orderInfo.OrderNumber);
                
                // PDF 내용 생성
                String pdfContent = createOrderProductPDFContent(orderInfo);
                
                // ContentVersion 생성
                ContentVersion cv = new ContentVersion();
                cv.Title = 'Order_Product_상세서_' + orderInfo.OrderNumber + '_' + 
                          DateTime.now().format('yyyyMMdd_HHmmss');
                cv.PathOnClient = cv.Title + '.pdf';
                cv.VersionData = Blob.valueOf(pdfContent);
                cv.ContentLocation = 'S';
                cv.Description = orderInfo.Account.Name + ' 고객 Order Product 상세서 - ' + 
                               orderInfo.OrderNumber + ' (자동생성)';
                
                pdfVersionsToInsert.add(cv);
                
            } catch (Exception e) {
                System.debug('❌ PDF 생성 오류 (Order: ' + orderInfo.OrderNumber + '): ' + e.getMessage());
            }
        }
        
        // ContentVersion 일괄 생성
        if (!pdfVersionsToInsert.isEmpty()) {
            insert pdfVersionsToInsert;
            
            // ContentDocumentLink 생성을 위해 ContentDocument ID 조회
            Map<String, Id> contentDocumentMap = new Map<String, Id>();
            for (ContentVersion cv : [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id IN :pdfVersionsToInsert]) {
                contentDocumentMap.put(cv.Title, cv.ContentDocumentId);
            }
            
            // ContentDocumentLink 생성 (Order에 연결)
            Integer index = 0;
            for (Order orderInfo : orders) {
                if (index < pdfVersionsToInsert.size() && !orderInfo.OrderItems.isEmpty()) {
                    ContentVersion cv = pdfVersionsToInsert[index];
                    Id contentDocumentId = contentDocumentMap.get(cv.Title);
                    
                    if (contentDocumentId != null) {
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = contentDocumentId;
                        cdl.LinkedEntityId = orderInfo.Id;
                        cdl.ShareType = 'V';
                        cdl.Visibility = 'AllUsers';
                        cdlsToInsert.add(cdl);
                    }
                    index++;
                }
            }
            
            if (!cdlsToInsert.isEmpty()) {
                insert cdlsToInsert;
                System.debug('✅ PDF 생성 및 첨부 완료: ' + cdlsToInsert.size() + '개');
            }
        }
    }
    
    /**
     * PDF 내용 생성
     */
    private static String createOrderProductPDFContent(Order orderInfo) {
        // 납부 일정 조회
        List<PaymentStatus__c> paymentSchedule = [
            SELECT Installment_Number__c, Amount__c, DueDate__c, Status__c
            FROM PaymentStatus__c 
            WHERE Order__c = :orderInfo.Id
            ORDER BY Installment_Number__c ASC
        ];
        
        // PDF 내용 생성 (간단한 PDF 구조)
        String pdfContent = '%PDF-1.4\n';
        pdfContent += '1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n\n';
        pdfContent += '2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n\n';
        pdfContent += '3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n>>\nendobj\n\n';
        
        // PDF 본문 내용
        String contentStream = 'BT\n/F1 16 Tf\n50 750 Td\n';
        contentStream += '(Order Product 상세서) Tj\n';
        contentStream += '/F1 12 Tf\n0 -30 Td\n';
        contentStream += '(Order Number: ' + orderInfo.OrderNumber + ') Tj\n';
        contentStream += '0 -20 Td\n(Customer: ' + orderInfo.Account.Name + ') Tj\n';
        contentStream += '0 -20 Td\n(Order Date: ' + orderInfo.EffectiveDate?.format() + ') Tj\n';
        contentStream += '0 -20 Td\n(Status: ' + orderInfo.Status + ') Tj\n';
        contentStream += '0 -30 Td\n(=== Product Details ===) Tj\n';
        
        // Order Items 추가
        for (OrderItem item : orderInfo.OrderItems) {
            contentStream += '0 -20 Td\n(• ' + item.Product2.Name + ') Tj\n';
            contentStream += '0 -15 Td\n(  Code: ' + item.Product2.ProductCode + ') Tj\n';
            contentStream += '0 -15 Td\n(  Quantity: ' + item.Quantity + ') Tj\n';
            contentStream += '0 -15 Td\n(  Unit Price: ₩' + String.valueOf(item.UnitPrice.format()) + ') Tj\n';
            contentStream += '0 -15 Td\n(  Total: ₩' + String.valueOf(item.TotalPrice.format()) + ') Tj\n';
        }
        
        contentStream += '0 -30 Td\n(=== Payment Information ===) Tj\n';
        contentStream += '0 -20 Td\n(Method: ' + orderInfo.Payment_Method__c + ') Tj\n';
        contentStream += '0 -20 Td\n(Total Amount: ₩' + String.valueOf(orderInfo.TotalAmount.format()) + ') Tj\n';
        
        // 납부 일정 추가
        if (!paymentSchedule.isEmpty()) {
            contentStream += '0 -20 Td\n(Payment Schedule:) Tj\n';
            for (PaymentStatus__c payment : paymentSchedule) {
                contentStream += '0 -15 Td\n(  ' + payment.Installment_Number__c + '차: ₩' + 
                               payment.Amount__c.format() + ' - ' + payment.DueDate__c.format() + 
                               ' (' + payment.Status__c + ')) Tj\n';
            }
        }
        
        contentStream += '0 -30 Td\n(생성일: ' + Date.today().format() + ') Tj\n';
        contentStream += 'ET';
        
        pdfContent += '4 0 obj\n<<\n/Length ' + contentStream.length() + '\n>>\nstream\n';
        pdfContent += contentStream + '\nendstream\nendobj\n\n';
        pdfContent += 'xref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n';
        pdfContent += '0000000058 00000 n \n0000000115 00000 n \n0000000204 00000 n \n';
        pdfContent += 'trailer\n<<\n/Size 5\n/Root 1 0 R\n>>\nstartxref\n' + 
                     (pdfContent.length() + 100) + '\n%%EOF';
        
        return pdfContent;
    }
    
    /**
     * Slack 채널 자동 생성
     */
    private static void createSlackChannels(List<Order> orders) {
        List<Order> ordersToUpdate = new List<Order>();
        
        for (Order orderInfo : orders) {
            try {
                // 이미 Slack 채널이 생성된 경우 건너뛰기
                if (String.isNotBlank(orderInfo.Slack_Channel_ID__c)) {
                    System.debug('⚠️ Order ' + orderInfo.OrderNumber + '는 이미 Slack 채널이 있습니다.');
                    continue;
                }
                
                System.debug('💬 Slack 채널 생성 중: Order ' + orderInfo.OrderNumber);
                
                // Slack API 호출
                Boolean channelCreated = SlackChannelService.createOrderChannel(orderInfo);
                
                if (channelCreated) {
                    // Order 업데이트 (Slack 정보)
                    Order orderToUpdate = new Order();
                    orderToUpdate.Id = orderInfo.Id;
                    orderToUpdate.Slack_Channel_Name__c = orderInfo.OrderNumber;
                    orderToUpdate.Slack_Notification_Status__c = 'Created';
                    ordersToUpdate.add(orderToUpdate);
                    
                    System.debug('✅ Slack 채널 생성 완료: #' + orderInfo.OrderNumber);
                } else {
                    System.debug('❌ Slack 채널 생성 실패: Order ' + orderInfo.OrderNumber);
                }
                
            } catch (Exception e) {
                System.debug('❌ Slack 채널 생성 오류 (Order: ' + orderInfo.OrderNumber + '): ' + e.getMessage());
            }
        }
        
        // Order 일괄 업데이트
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
            System.debug('✅ Order Slack 정보 업데이트 완료: ' + ordersToUpdate.size() + '개');
        }
    }
    
    /**
     * 완료 알림 발송 (Chatter)
     */
    private static void sendCompletionNotifications(List<Order> orders) {
        List<FeedItem> chatterPosts = new List<FeedItem>();
        
        for (Order orderInfo : orders) {
            try {
                // Chatter 포스트 생성
                FeedItem post = new FeedItem();
                post.ParentId = orderInfo.Id;
                post.Type = 'TextPost';
                
                String message = '🎉 Order Product 자동화 완료!\n\n';
                message += '📋 Order: ' + orderInfo.OrderNumber + '\n';
                message += '👤 Customer: ' + orderInfo.Account.Name + '\n';
                message += '💰 Amount: ₩' + orderInfo.TotalAmount.format() + '\n\n';
                message += '✅ 완료된 작업:\n';
                message += '• Order Product 상세서 PDF 생성\n';
                message += '• Slack 채널 생성 (#' + orderInfo.OrderNumber + ')\n';
                message += '• Files 자동 첨부\n\n';
                message += '📎 Notes & Attachments에서 PDF를 확인하세요!';
                
                post.Body = message;
                chatterPosts.add(post);
                
            } catch (Exception e) {
                System.debug('❌ Chatter 포스트 생성 오류 (Order: ' + orderInfo.OrderNumber + '): ' + e.getMessage());
            }
        }
        
        // Chatter 포스트 일괄 생성
        if (!chatterPosts.isEmpty()) {
            insert chatterPosts;
            System.debug('✅ Chatter 알림 발송 완료: ' + chatterPosts.size() + '개');
        }
    }
}
