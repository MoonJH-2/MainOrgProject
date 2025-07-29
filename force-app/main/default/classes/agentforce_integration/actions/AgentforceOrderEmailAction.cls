/**
 * @description Agentforce Order Email Draft Action
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceOrderEmailAction {
    
    /**
     * Order 관련 이메일 초안 생성
     */
    @InvocableMethod(label='Draft Order Email' description='Order 상태에 따른 이메일 초안을 생성합니다')
    public static List<EmailDraftResult> draftOrderEmail(List<OrderEmailRequest> requests) {
        List<EmailDraftResult> results = new List<EmailDraftResult>();
        
        for(OrderEmailRequest request : requests) {
            EmailDraftResult result = new EmailDraftResult();
            
            try {
                // Order 정보 조회 - OrderNumber 또는 Order ID로 검색
                List<Order> orders = new List<Order>();
                
                // 먼저 Order ID로 시도
                if(request.orderId.length() >= 15) {
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, EffectiveDate, Status,
                               Account.Name, Account.Id, Owner.Name, Owner.Email, Owner.Phone
                        FROM Order 
                        WHERE Id = :request.orderId 
                        LIMIT 1
                    ];
                }
                
                // Order ID로 찾지 못했으면 OrderNumber로 검색
                if(orders.isEmpty()) {
                    orders = [
                        SELECT Id, OrderNumber, TotalAmount, EffectiveDate, Status,
                               Account.Name, Account.Id, Owner.Name, Owner.Email, Owner.Phone
                        FROM Order 
                        WHERE OrderNumber = :request.orderId 
                        LIMIT 1
                    ];
                }
                
                if(orders.isEmpty()) {
                    result.success = false;
                    result.errorMessage = 'Order를 찾을 수 없습니다.';
                    results.add(result);
                    continue;
                }
                
                Order orderRecord = orders[0];
                
                // 이메일 템플릿 생성
                String emailSubject = generateOrderEmailSubject(orderRecord, request.emailType);
                String emailBody = generateOrderEmailBody(orderRecord, request.emailType);
                
                result.emailSubject = emailSubject;
                result.emailBody = emailBody;
                result.recipientEmail = getOrderRecipientEmail(orderRecord);
                result.emailType = request.emailType;
                result.orderNumber = orderRecord.OrderNumber;
                result.success = true;
                
            } catch(Exception e) {
                result.success = false;
                result.errorMessage = 'Order 이메일 생성 중 오류: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Helper Methods
    private static String generateOrderEmailSubject(Order orderRecord, String emailType) {
        String subject = '';
        
        switch on emailType {
            when 'Order_Confirmation' {
                subject = '[주문 확인] Order ' + orderRecord.OrderNumber + ' - ' + orderRecord.Account.Name;
            }
            when 'Order_Activation' {
                subject = '[서비스 활성화] Order ' + orderRecord.OrderNumber + ' 서비스가 시작되었습니다';
            }
            when 'Order_Status_Update' {
                subject = '[진행 상황] Order ' + orderRecord.OrderNumber + ' 상태 업데이트';
            }
            when 'Order_Completion' {
                subject = '[완료 알림] Order ' + orderRecord.OrderNumber + ' 서비스 완료';
            }
            when else {
                subject = '[알림] Order ' + orderRecord.OrderNumber + ' 관련 안내';
            }
        }
        
        return subject;
    }
    
    private static String generateOrderEmailBody(Order orderRecord, String emailType) {
        String body = '';
        
        body += '안녕하세요, ' + orderRecord.Account.Name + ' 담당자님\n\n';
        body += '담당 영업사원 ' + orderRecord.Owner.Name + '입니다.\n\n';
        
        switch on emailType {
            when 'Order_Confirmation' {
                body += '📋 주문이 정상적으로 접수되었습니다.\n\n';
                body += '주문 정보:\n';
                body += '• 주문번호: ' + orderRecord.OrderNumber + '\n';
                body += '• 주문금액: ₩' + String.valueOf(orderRecord.TotalAmount) + '\n';
                body += '• 시작일: ' + orderRecord.EffectiveDate.format() + '\n\n';
                body += '추가 문의사항이 있으시면 언제든 연락주세요.\n';
            }
            when 'Order_Activation' {
                body += '🚀 서비스가 정상적으로 활성화되었습니다.\n\n';
                body += '이제 주문하신 서비스를 이용하실 수 있습니다.\n';
                body += '서비스 이용 중 문의사항이 있으시면 담당자에게 연락주세요.\n';
            }
            when 'Order_Status_Update' {
                body += '📊 주문 진행 상황을 안내드립니다.\n\n';
                body += '현재 상태: ' + orderRecord.Status + '\n';
                body += '다음 단계 진행 시 별도 안내드리겠습니다.\n';
            }
            when 'Order_Completion' {
                body += '🎉 주문이 성공적으로 완료되었습니다.\n\n';
                body += '서비스 이용해 주셔서 감사합니다.\n';
                body += '추가 서비스나 연장이 필요하시면 언제든 문의주세요.\n';
            }
        }
        
        body += '\n감사합니다.\n';
        body += orderRecord.Owner.Name + '\n';
        body += '전화: ' + orderRecord.Owner.Phone + '\n';
        body += '이메일: ' + orderRecord.Owner.Email;
        
        return body;
    }
    
    private static String getOrderRecipientEmail(Order orderRecord) {
        // 실제 구현에서는 Contact 또는 Account에서 이메일 조회
        return 'customer@example.com'; // placeholder
    }
    
    // Input/Output Classes
    public class OrderEmailRequest {
        @InvocableVariable(required=true)
        public String orderId;
        @InvocableVariable(required=true)
        public String emailType; // Order_Confirmation, Order_Activation, Order_Status_Update, Order_Completion
    }
    
    public class EmailDraftResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String errorMessage;
        @InvocableVariable
        public String emailSubject;
        @InvocableVariable
        public String emailBody;
        @InvocableVariable
        public String recipientEmail;
        @InvocableVariable
        public String emailType;
        @InvocableVariable
        public String orderNumber;
    }
}
