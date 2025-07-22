/**
 * @description Order 관련 Sales 앱 알림 서비스
 * AccountTriggerHandler.cls 패턴 참조하여 구현
 * @author JH Moon
 * @last modified on 07-21-2025
 * @last modified by JH Moon
 */
public with sharing class OrderNotificationService {
    
    /**
     * Order 생성 시 Sales 앱 알림 발송
     */
    public static void notifyOrderCreated(List<Order> orders) {
        try {
            if (orders == null || orders.isEmpty()) {
                System.debug('⚠️ notifyOrderCreated: 전달된 Order 목록이 비어있습니다.');
                return;
            }
            
            System.debug('🎉 Order 생성 알림 발송 시작: ' + orders.size() + '개');
            
            // CustomNotificationType 확인
            List<CustomNotificationType> salesNotificationTypes = [
                SELECT Id, DeveloperName
                FROM CustomNotificationType
                WHERE DeveloperName = 'Sales_Order_Notification'
                LIMIT 1
            ];
            
            if (salesNotificationTypes.isEmpty()) {
                System.debug('❌ Sales_Order_Notification CustomNotificationType이 설정되지 않았습니다.');
                System.debug('   Setup > Custom Notification Types에서 생성이 필요합니다.');
                return;
            }
            
            for (Order ord : orders) {
                if (ord.Account == null || String.isBlank(ord.Account.Name)) {
                    System.debug('⚠️ Order ' + ord.OrderNumber + ': Account 정보가 없어 알림을 건너뜁니다.');
                    continue;
                }
                
                String title = '🎉 새 주문 생성';
                String body = ord.Account.Name + ' - Order ' + ord.OrderNumber + 
                             ' (₩' + ord.TotalAmount.format() + ')';
                
                System.debug('📤 알림 발송: ' + title + ' - ' + body);
                sendSalesNotification(title, body, ord.Id, 'Order_Created');
            }
            
            System.debug('✅ Order 생성 알림 발송 완료');
            
        } catch (Exception e) {
            System.debug('❌ Order 생성 알림 오류: ' + e.getMessage());
            System.debug('❌ 스택 트레이스: ' + e.getStackTraceString());
        }
    }
    
    /**
     * 연체 상태 발생 시 Sales 앱 알림 발송
     */
    public static void notifyOverduePayments(List<PaymentStatus__c> overduePayments) {
        try {
            if (overduePayments.isEmpty()) return;
            
            System.debug('🚨 연체 알림 발송 시작: ' + overduePayments.size() + '개');
            
            for (PaymentStatus__c payment : overduePayments) {
                // 연체 일수 계산
                Integer overdueDays = Date.today().daysBetween(payment.DueDate__c);
                
                String title = '🚨 납부 연체 발생';
                String body = payment.Order__r.Account.Name + ' - ' + 
                             payment.InstallmentNumber__c + '차 납부 연체 (' + 
                             Math.abs(overdueDays) + '일)';
                
                sendSalesNotification(title, body, payment.Order__c, 'Payment_Overdue');
            }
            
            System.debug('✅ 연체 알림 발송 완료');
            
        } catch (Exception e) {
            System.debug('❌ 연체 알림 오류: ' + e.getMessage());
        }
    }
    
    /**
     * Slack 채널 생성 시 Sales 앱 알림 발송
     */
    public static void notifySlackChannelCreated(List<Order> orders) {
        try {
            List<Order> ordersWithSlack = new List<Order>();
            
            for (Order ord : orders) {
                if (String.isNotBlank(ord.Slack_Channel_Name__c) && 
                    ord.Slack_Notification_Status__c == 'Created') {
                    ordersWithSlack.add(ord);
                }
            }
            
            if (ordersWithSlack.isEmpty()) return;
            
            System.debug('📢 Slack 채널 생성 알림 발송 시작: ' + ordersWithSlack.size() + '개');
            
            for (Order ord : ordersWithSlack) {
                String title = '📢 Slack 채널 생성 완료';
                String body = 'Order ' + ord.OrderNumber + ' Salesforce 연동 채널 생성 (#' + 
                             ord.Slack_Channel_Name__c + ')';
                
                sendSalesNotification(title, body, ord.Id, 'Slack_Channel_Created');
            }
            
            System.debug('✅ Slack 채널 생성 알림 발송 완료');
            
        } catch (Exception e) {
            System.debug('❌ Slack 채널 생성 알림 오류: ' + e.getMessage());
        }
    }
    
    /**
     * PaymentStatus가 연체로 변경된 항목 필터링
     */
    public static List<PaymentStatus__c> getOverduePayments(List<PaymentStatus__c> newPayments, List<PaymentStatus__c> oldPayments) {
        List<PaymentStatus__c> overduePayments = new List<PaymentStatus__c>();
        Map<Id, PaymentStatus__c> oldPaymentMap = new Map<Id, PaymentStatus__c>();
        
        if (oldPayments != null) {
            for (PaymentStatus__c oldPayment : oldPayments) {
                oldPaymentMap.put(oldPayment.Id, oldPayment);
            }
        }
        
        for (PaymentStatus__c newPayment : newPayments) {
            PaymentStatus__c oldPayment = oldPaymentMap.get(newPayment.Id);
            
            // 상태가 미납에서 연체로 변경되었거나, 새로 연체가 된 경우
            if (newPayment.Status__c == '연체' && 
                (oldPayment == null || oldPayment.Status__c != '연체')) {
                overduePayments.add(newPayment);
            }
        }
        
        return overduePayments;
    }
    
    /**
     * 공통 Sales 앱 알림 발송 로직 (AccountTriggerHandler 패턴)
     */
    private static void sendSalesNotification(String title, String body, Id targetId, String notificationType) {
        try {
            System.debug('📡 sendSalesNotification 시작: ' + title);
            
            // CustomNotificationType 조회
            List<CustomNotificationType> salesNotificationTypes = [
                SELECT Id, DeveloperName
                FROM CustomNotificationType
                WHERE DeveloperName = 'Sales_Order_Notification'
                LIMIT 1
            ];
            
            if (salesNotificationTypes.isEmpty()) {
                System.debug('❌ Sales_Order_Notification CustomNotificationType이 설정되지 않았습니다.');
                System.debug('   Setup에서 생성이 필요합니다.');
                
                // 사용 가능한 다른 CustomNotificationType 찾기
                List<CustomNotificationType> alternativeTypes = [
                    SELECT Id, DeveloperName, MasterLabel
                    FROM CustomNotificationType
                    LIMIT 1
                ];
                
                if (!alternativeTypes.isEmpty()) {
                    System.debug('⚠️ 대안으로 ' + alternativeTypes[0].MasterLabel + ' 사용 시도');
                    CustomNotificationType altType = alternativeTypes[0];
                    
                    Set<String> recipients = getNotificationRecipients(targetId, notificationType);
                    if (!recipients.isEmpty()) {
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setTitle(title + ' (임시)');
                        notification.setBody(body);
                        notification.setNotificationTypeId(altType.Id);
                        notification.setTargetId(targetId);
                        notification.send(recipients);
                        
                        System.debug('✅ 대안 알림 발송 성공 (수신자: ' + recipients.size() + '명)');
                    }
                }
                return;
            }
            
            CustomNotificationType salesNotificationType = salesNotificationTypes[0];
            
            // 수신자 결정 (AccountTriggerHandler 패턴 참조)
            Set<String> recipients = getNotificationRecipients(targetId, notificationType);
            
            if (recipients.isEmpty()) {
                System.debug('⚠️ 알림 수신자가 없습니다.');
                return;
            }
            
            System.debug('👥 수신자 수: ' + recipients.size() + '명');
            
            // Messaging.CustomNotification 생성 및 발송
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(title);
            notification.setBody(body);
            notification.setNotificationTypeId(salesNotificationType.Id);
            notification.setTargetId(targetId);
            notification.send(recipients);
            
            System.debug('✅ Sales 앱 알림 발송: ' + title + ' (수신자: ' + recipients.size() + '명)');
            
        } catch (Exception e) {
            System.debug('❌ Sales 앱 알림 발송 오류: ' + e.getMessage());
            System.debug('❌ 스택 트레이스: ' + e.getStackTraceString());
            
            // 알림 발송 실패 시에도 로그는 남기되 전체 프로세스는 중단하지 않음
        }
    }
    
    /**
     * 알림 수신자 결정 (AccountTriggerHandler 패턴 참조)
     */
    private static Set<String> getNotificationRecipients(Id targetId, String notificationType) {
        Set<String> recipients = new Set<String>();
        
        try {
            // 현재 사용자 정보 조회 (AccountTriggerHandler 패턴)
            User currentUser = [
                SELECT Id, ManagerId, Manager.Email
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            // Order 정보 조회
            List<Order> orders = [
                SELECT Id, OwnerId, Owner.Email
                FROM Order 
                WHERE Id = :targetId
                LIMIT 1
            ];
            
            if (!orders.isEmpty()) {
                Order targetOrder = orders[0];
                
                // Order Owner 상세 정보 조회
                List<User> ownerUsers = [
                    SELECT Id, ManagerId
                    FROM User
                    WHERE Id = :targetOrder.OwnerId
                    LIMIT 1
                ];
                
                // 1. Order Owner
                recipients.add(targetOrder.OwnerId);
                
                // 2. Order Owner의 Manager (있는 경우)
                if (!ownerUsers.isEmpty() && ownerUsers[0].ManagerId != null) {
                    recipients.add(ownerUsers[0].ManagerId);
                }
                
                // 3. 현재 사용자의 Manager (AccountTriggerHandler 패턴)
                if (currentUser.ManagerId != null) {
                    recipients.add(currentUser.ManagerId);
                }
                
                // 4. 현재 사용자 (생성자)
                recipients.add(UserInfo.getUserId());
            }
            
            // 5. 알림 유형별 추가 수신자
            switch on notificationType {
                when 'Payment_Overdue' {
                    // 연체 알림의 경우 시스템 관리자도 포함
                    List<User> adminUsers = [
                        SELECT Id
                        FROM User 
                        WHERE Profile.Name IN ('시스템 관리자', 'System Administrator') 
                        AND IsActive = true
                        LIMIT 3
                    ];
                    
                    for (User admin : adminUsers) {
                        recipients.add(admin.Id);
                    }
                }
                when 'Slack_Channel_Created' {
                    // Slack 채널 생성 알림의 경우 팀원들도 포함 가능
                    // 필요시 추가 로직 구현
                }
            }
            
        } catch (Exception e) {
            System.debug('알림 수신자 조회 오류: ' + e.getMessage());
        }
        
        return recipients;
    }
    
    /**
     * Order의 연체 상태 확인 및 알림
     */
    public static void checkAndNotifyOverdueOrders(Set<Id> orderIds) {
        try {
            // 연체된 PaymentStatus 조회
            List<PaymentStatus__c> overduePayments = [
                SELECT Id, Order__c, Order__r.Account.Name, Order__r.OrderNumber,
                       InstallmentNumber__c, Amount__c, DueDate__c, Status__c
                FROM PaymentStatus__c 
                WHERE Order__c IN :orderIds
                AND Status__c = '연체'
                AND DueDate__c < TODAY
            ];
            
            if (!overduePayments.isEmpty()) {
                notifyOverduePayments(overduePayments);
            }
            
        } catch (Exception e) {
            System.debug('❌ 연체 Order 확인 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 이메일 알림도 함께 발송 (선택사항)
     */
    public static void sendEmailNotificationForOrder(Order orderInfo, String notificationType) {
        try {
            // AccountTriggerHandler의 이메일 발송 패턴 참조
            List<EmailTemplate> emailTemplates = [
                SELECT Id, DeveloperName, Subject, HtmlValue, Body
                FROM EmailTemplate
                WHERE DeveloperName = 'Order_Notification_Email_Alert'
                LIMIT 1
            ];
            
            if (emailTemplates.isEmpty()) {
                System.debug('⚠️ Order_Notification_Email_Alert 템플릿이 없습니다.');
                return;
            }
            
            EmailTemplate emailTemplate = emailTemplates[0];
            
            User currentUser = [
                SELECT Id, Email, Name, ManagerId, Manager.Email
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            // Manager에게 이메일 발송 (AccountTriggerHandler 패턴)
            if (currentUser.Manager != null && String.isNotBlank(currentUser.Manager.Email)) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{currentUser.Manager.Email});
                email.setTemplateId(emailTemplate.Id);
                email.setTargetObjectId(currentUser.ManagerId);
                email.setWhatId(orderInfo.Id);
                email.setSaveAsActivity(false);
                
                emails.add(email);
            }
            
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
                System.debug('✅ Order 관련 이메일 알림 발송 완료');
            }
            
        } catch (Exception e) {
            System.debug('❌ Order 이메일 알림 오류: ' + e.getMessage());
        }
    }
}
