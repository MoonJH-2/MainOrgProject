/**
 * @description Agentforce와 Slack 통합을 위한 서비스 (Phase 2)
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceSlackIntegrationService {
    
    /**
     * Order 활성화 시 자동으로 Slack 채널 생성 및 팀 초대
     */
    @InvocableMethod(label='Create Order Slack Channel' description='Order별 Slack 채널 자동 생성 및 초기화')
    public static List<SlackChannelResult> createOrderSlackChannel(List<SlackChannelRequest> requests) {
        List<SlackChannelResult> results = new List<SlackChannelResult>();
        
        for (SlackChannelRequest request : requests) {
            try {
                SlackChannelResult result = processSlackChannelCreation(request);
                results.add(result);
            } catch (Exception e) {
                SlackChannelResult errorResult = new SlackChannelResult();
                errorResult.success = false;
                errorResult.errorMessage = e.getMessage();
                results.add(errorResult);
            }
        }
        
        return results;
    }
    
    private static SlackChannelResult processSlackChannelCreation(SlackChannelRequest request) {
        SlackChannelResult result = new SlackChannelResult();
        
        // 1. Order 정보 조회
        Order orderInfo = getOrderInfo(request.orderId);
        
        // 2. 채널명 생성
        String channelName = generateChannelName(orderInfo);
        
        // 3. 기존 Salesforce 채널 시스템 활용 (SalesforceChannelService 연동)
        String channelId = createSalesforceChannel(orderInfo, channelName);
        
        // 4. 초기 메시지 및 캔버스 생성
        if (String.isNotBlank(channelId)) {
            createInitialChannelContent(orderInfo, channelId);
            result.success = true;
            result.channelId = channelId;
            result.channelName = channelName;
            result.orderNumber = orderInfo.OrderNumber;
        }
        
        return result;
    }
    
    /**
     * 결제 완료/연체 시 Slack 알림 발송
     */
    @InvocableMethod(label='Send Payment Notification' description='결제 상태 변경 시 Slack 알림')
    public static List<PaymentNotificationResult> sendPaymentNotification(List<PaymentNotificationRequest> requests) {
        List<PaymentNotificationResult> results = new List<PaymentNotificationResult>();
        
        for (PaymentNotificationRequest request : requests) {
            try {
                PaymentNotificationResult result = processPaymentNotification(request);
                results.add(result);
            } catch (Exception e) {
                PaymentNotificationResult errorResult = new PaymentNotificationResult();
                errorResult.success = false;
                errorResult.errorMessage = e.getMessage();
                results.add(errorResult);
            }
        }
        
        return results;
    }
    
    private static PaymentNotificationResult processPaymentNotification(PaymentNotificationRequest request) {
        PaymentNotificationResult result = new PaymentNotificationResult();
        
        // 1. PaymentStatus 정보 조회
        PaymentStatus__c payment = getPaymentInfo(request.paymentId);
        
        // 2. 관련 Order 정보 조회
        Order orderInfo = [SELECT Id, OrderNumber, AccountId, Account.Name FROM Order WHERE Id = :payment.Order__c LIMIT 1];
        
        // 3. 해당 Order의 Slack 채널 찾기
        String channelId = findOrderChannel(orderInfo.OrderNumber);
        
        // 4. 결제 상태에 따른 메시지 생성 및 발송
        if (String.isNotBlank(channelId)) {
            String message = generatePaymentMessage(payment, orderInfo, request.notificationType);
            Boolean sent = sendChannelMessage(channelId, message);
            
            result.success = sent;
            result.channelId = channelId;
            result.message = message;
        }
        
        return result;
    }
    
    /**
     * 영업 활동 후 팀 알림
     */
    @AuraEnabled
    public static SlackNotificationResult notifyTeamActivity(String orderId, String activityType, String message) {
        try {
            SlackNotificationResult result = new SlackNotificationResult();
            
            // Order 정보 조회
            Order orderInfo = [SELECT Id, OrderNumber, Account.Name FROM Order WHERE Id = :orderId LIMIT 1];
            
            // 채널 찾기
            String channelId = findOrderChannel(orderInfo.OrderNumber);
            
            if (String.isNotBlank(channelId)) {
                String formattedMessage = formatActivityMessage(orderInfo, activityType, message);
                Boolean sent = sendChannelMessage(channelId, formattedMessage);
                
                result.success = sent;
                result.channelId = channelId;
                result.message = formattedMessage;
            } else {
                result.success = false;
                result.errorMessage = '해당 Order의 Slack 채널을 찾을 수 없습니다.';
            }
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('팀 알림 발송 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    // Private Helper Methods
    
    private static Order getOrderInfo(String orderId) {
        return [
            SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate, EndDate,
                   AccountId, Account.Name, Contact.Name, Contact.Email,
                   OwnerId, Owner.Name, Payment_Method__c
            FROM Order 
            WHERE Id = :orderId 
            LIMIT 1
        ];
    }
    
    private static String generateChannelName(Order orderInfo) {
        // "Order-00000167-효원" 형태로 생성
        String accountName = orderInfo.Account.Name.replaceAll('[^a-zA-Z0-9가-힣]', '');
        return 'Order-' + orderInfo.OrderNumber + '-' + accountName;
    }
    
    private static String createSalesforceChannel(Order orderInfo, String channelName) {
        try {
            // 기존 SalesforceChannelService 활용
            // CollaborationGroup 생성
            CollaborationGroup channel = new CollaborationGroup();
            channel.Name = channelName;
            channel.CollaborationType = 'Private';
            channel.Description = String.format(
                'Order {0} ({1}) 진행관리 채널\n생성일: {2}\n담당자: {3}',
                new List<Object>{
                    orderInfo.OrderNumber,
                    orderInfo.Account.Name,
                    Date.today().format(),
                    orderInfo.Owner.Name
                }
            );
            
            insert channel;
            
            // Order Owner를 Admin으로 추가
            CollaborationGroupMember ownerMember = new CollaborationGroupMember();
            ownerMember.CollaborationGroupId = channel.Id;
            ownerMember.MemberId = orderInfo.OwnerId;
            ownerMember.CollaborationRole = 'Admin';
            
            insert ownerMember;
            
            return channel.Id;
            
        } catch (Exception e) {
            System.debug('Slack 채널 생성 오류: ' + e.getMessage());
            return null;
        }
    }
    
    private static void createInitialChannelContent(Order orderInfo, String channelId) {
        try {
            // 환영 메시지 생성
            String welcomeMessage = String.format(
                '🎉 **Order {0} 활성화 완료!**\n\n' +
                '📋 **주문 정보**\n' +
                '• 고객: {1}\n' +
                '• 담당자: {2}\n' +
                '• 영업담당: {3}\n\n' +
                '💰 **결제 정보**\n' +
                '• 총 금액: {4}\n' +
                '• 결제 방식: {5}\n' +
                '• 시작일: {6}\n\n' +
                '📅 **다음 액션**\n' +
                '• [ ] 고객 온보딩 미팅 일정 조율\n' +
                '• [ ] 첫 번째 납부 안내 이메일 발송\n' +
                '• [ ] Asset 준비 상태 확인\n\n' +
                '🔔 **자동 알림이 설정되었습니다**',
                new List<Object>{
                    orderInfo.OrderNumber,
                    orderInfo.Account.Name,
                    orderInfo.Contact.Name,
                    orderInfo.Owner.Name,
                    String.valueOf(orderInfo.TotalAmount),
                    orderInfo.Payment_Method__c,
                    orderInfo.EffectiveDate?.format()
                }
            );
            
            // FeedItem으로 메시지 게시
            FeedItem welcomePost = new FeedItem();
            welcomePost.ParentId = channelId;
            welcomePost.Body = welcomeMessage;
            welcomePost.Type = 'TextPost';
            
            insert welcomePost;
            
        } catch (Exception e) {
            System.debug('초기 채널 콘텐츠 생성 오류: ' + e.getMessage());
        }
    }
    
    private static PaymentStatus__c getPaymentInfo(String paymentId) {
        return [
            SELECT Id, Order__c, Amount__c, Due_Date__c, Status__c, Payment_Number__c
            FROM PaymentStatus__c 
            WHERE Id = :paymentId 
            LIMIT 1
        ];
    }
    
    private static String findOrderChannel(String orderNumber) {
        try {
            List<CollaborationGroup> channels = [
                SELECT Id 
                FROM CollaborationGroup 
                WHERE Name LIKE :('Order-' + orderNumber + '%')
                LIMIT 1
            ];
            
            return channels.isEmpty() ? null : channels[0].Id;
            
        } catch (Exception e) {
            System.debug('Order 채널 찾기 오류: ' + e.getMessage());
            return null;
        }
    }
    
    private static String generatePaymentMessage(PaymentStatus__c payment, Order orderInfo, String notificationType) {
        switch on notificationType {
            when 'PAYMENT_COMPLETED' {
                return String.format(
                    '✅ **{0}차 결제 완료!**\n' +
                    '💰 금액: {1}\n' +
                    '📅 완료일: {2}\n' +
                    '📊 Order {3} 진행률 업데이트됨',
                    new List<Object>{
                        payment.Payment_Number__c,
                        String.valueOf(payment.Amount__c),
                        payment.Due_Date__c?.format(),
                        orderInfo.OrderNumber
                    }
                );
            }
            when 'PAYMENT_OVERDUE' {
                return String.format(
                    '⚠️ **연체 알림: Order {0}**\n' +
                    '📅 예정일: {1}\n' +
                    '💰 금액: {2}\n' +
                    '🔔 {3}차 결제 연체\n' +
                    '👤 담당자: @{4} 즉시 연락 필요',
                    new List<Object>{
                        orderInfo.OrderNumber,
                        payment.Due_Date__c?.format(),
                        String.valueOf(payment.Amount__c),
                        payment.Payment_Number__c,
                        orderInfo.Account.Name
                    }
                );
            }
            when 'PAYMENT_REMINDER' {
                return String.format(
                    '📅 **납부 예정 알림: Order {0}**\n' +
                    '💰 금액: {1}\n' +
                    '📅 예정일: {2} (3일 후)\n' +
                    '👤 담당자: 고객 안내 필요',
                    new List<Object>{
                        orderInfo.OrderNumber,
                        String.valueOf(payment.Amount__c),
                        payment.Due_Date__c?.format()
                    }
                );
            }
            when else {
                return '📋 결제 상태가 업데이트되었습니다.';
            }
        }
    }    private static Boolean sendChannelMessage(String channelId, String message) {
        try {
            FeedItem post = new FeedItem();
            post.ParentId = channelId;
            post.Body = message;
            post.Type = 'TextPost';
            
            insert post;
            return true;
            
        } catch (Exception e) {
            System.debug('Slack 메시지 발송 오류: ' + e.getMessage());
            return false;
        }
    }
    
    private static String formatActivityMessage(Order orderInfo, String activityType, String message) {
        String icon = getActivityIcon(activityType);
        return String.format(
            '{0} **{1}**\n' +
            '📋 Order: {2} ({3})\n' +
            '💬 {4}\n' +
            '👤 작성자: {5}',
            new List<Object>{
                icon,
                activityType,
                orderInfo.OrderNumber,
                orderInfo.Account.Name,
                message,
                UserInfo.getName()
            }
        );
    }
    
    private static String getActivityIcon(String activityType) {
        switch on activityType {
            when 'MEETING' { return '🤝'; }
            when 'CALL' { return '📞'; }
            when 'EMAIL' { return '📧'; }
            when 'TASK' { return '✅'; }
            when 'PROPOSAL' { return '📋'; }
            when else { return '📝'; }
        }
    }
    
    // Wrapper Classes
    
    public class SlackChannelRequest {
        @InvocableVariable(label='Order ID' required=true)
        public String orderId;
        
        @InvocableVariable(label='Include Team Members')
        public Boolean includeTeamMembers;
    }
    
    public class SlackChannelResult {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String channelId;
        
        @InvocableVariable
        public String channelName;
        
        @InvocableVariable
        public String orderNumber;
        
        @InvocableVariable
        public String errorMessage;
        
        public SlackChannelResult() {
            this.success = false;
            this.includeTeamMembers = true;
        }
    }
    
    public class PaymentNotificationRequest {
        @InvocableVariable(label='Payment ID' required=true)
        public String paymentId;
        
        @InvocableVariable(label='Notification Type' required=true)
        public String notificationType; // PAYMENT_COMPLETED, PAYMENT_OVERDUE, PAYMENT_REMINDER
    }
    
    public class PaymentNotificationResult {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String channelId;
        
        @InvocableVariable
        public String message;
        
        @InvocableVariable
        public String errorMessage;
        
        public PaymentNotificationResult() {
            this.success = false;
        }
    }
    
    public class SlackNotificationResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String channelId { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        
        public SlackNotificationResult() {
            this.success = false;
        }
    }
}
