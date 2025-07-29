/**
 * @description 다중 채널 납부 알림 서비스
 * @author JH Moon
 * @date 2025-07-15
 */
public with sharing class PaymentNotificationService {
    
    /**
     * Salesforce 내부 알림 발송
     */
    public static Boolean sendSalesforceNotification(Payment_Notification__c notification) {
        try {
            // 1. Chatter 포스트 생성
            createChatterPost(notification);
            
            // 2. Custom Notification 발송 (Bell 아이콘 알림)
            sendCustomNotification(notification);
            
            // 3. Task 생성 (고객 팔로업용)
            createNotificationTask(notification);
            
            return true;
            
        } catch (Exception e) {
            System.debug('Salesforce 알림 발송 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * 이메일 알림 발송 (고객과 관리자 모두)
     */
    public static Boolean sendEmailNotification(Payment_Notification__c notification) {
        try {
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            // 1. 고객 이메일
            String customerEmail = getCustomerEmail(notification);
            if (String.isNotBlank(customerEmail)) {
                Messaging.SingleEmailMessage customerEmailMessage = createPaymentEmail(notification, customerEmail, 'Customer');
                emails.add(customerEmailMessage);
            }
            
            // 2. 관리자 이메일들
            List<String> adminEmails = getAdminEmails(notification);
            for (String adminEmail : adminEmails) {
                Messaging.SingleEmailMessage adminEmailMessage = createPaymentEmail(notification, adminEmail, 'Admin');
                emails.add(adminEmailMessage);
            }
            
            if (emails.isEmpty()) {
                System.debug('발송할 이메일 주소가 없습니다.');
                return false;
            }
            
            // 이메일 발송
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
            
            Integer successCount = 0;
            for (Messaging.SendEmailResult result : results) {
                if (result.isSuccess()) {
                    successCount++;
                } else {
                    System.debug('이메일 발송 실패: ' + result.getErrors()[0].getMessage());
                }
            }
            
            System.debug('이메일 발송 완료 - 성공: ' + successCount + '/' + emails.size());
            return successCount > 0;
            
        } catch (Exception e) {
            System.debug('이메일 알림 발송 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Salesforce Channel 알림 발송 (현재 비활성화 - 커스텀 필드 생성 후 활성화)
     */
    public static Boolean sendSalesforceChannelNotification(Payment_Notification__c notification) {
        // TODO: Order 객체에 Salesforce_Channel_ID__c 등 커스텀 필드 생성 후 활성화
        System.debug('⚠️ SalesforceChannel 기능은 커스텀 필드 생성 후 활성화 예정');
        return false;
        
        /*
        try {
            // Order에 연결된 Salesforce Channel이 있는지 확인
            List<Order> orders = [
                SELECT Id, Salesforce_Channel_ID__c, Salesforce_Channel_Name__c, Channel_Status__c
                FROM Order 
                WHERE Id = :notification.PaymentStatus__r.Order__c
                AND Salesforce_Channel_ID__c != null
                AND Channel_Status__c = 'Active'
                LIMIT 1
            ];
            
            if (orders.isEmpty()) {
                System.debug('❌ 활성화된 Salesforce Channel이 없습니다: Order ' + notification.PaymentStatus__r.Order__c);
                return false;
            }
            
            Order orderWithChannel = orders[0];
            
            // 채널에 납부 알림 메시지 발송
            String channelMessage = createChannelNotificationMessage(notification);
            Boolean success = SalesforceChannelService.sendChannelMessage(
                orderWithChannel.Salesforce_Channel_ID__c, 
                channelMessage
            );
            
            if (success) {
                System.debug('✅ Salesforce Channel 알림 발송 완료: ' + orderWithChannel.Salesforce_Channel_Name__c);
                return true;
            } else {
                System.debug('❌ Salesforce Channel 메시지 발송 실패');
                return false;
            }
            
        } catch (Exception e) {
            System.debug('❌ Salesforce Channel 알림 발송 오류: ' + e.getMessage());
            return false;
        }
        */
    }
    
    /**
     * 채널용 알림 메시지 생성 (현재 비활성화)
     */
    private static String createChannelNotificationMessage(Payment_Notification__c notification) {
        // TODO: Salesforce Channel 기능 활성화 시 사용
        return 'Channel message placeholder';
        /*
        String message = '';
        
        if (notification.NotificationType__c == '예정 알림') {
            message = '🔔 **납부 예정 알림**\n\n';
            message += '고객님의 납부 예정일이 3일 후입니다.\n\n';
        } else {
            message = '🚨 **납부 연체 알림**\n\n';
            message += '고객님의 납부가 연체되었습니다.\n\n';
        }
        
        message += '📋 **납부 정보**\n';
        message += '• **고객**: ' + notification.PaymentStatus__r.Order__r.Account.Name + '\n';
        message += '• **주문번호**: ' + notification.PaymentStatus__r.Order__r.OrderNumber + '\n';
        message += '• **납부 회차**: ' + notification.PaymentStatus__r.Installment_Number__c + '차\n';
        message += '• **납부 금액**: ₩' + notification.PaymentStatus__r.Amount__c.format() + '\n';
        message += '• **납부 예정일**: ' + notification.PaymentStatus__r.DueDate__c.format() + '\n';
        
        if (notification.NotificationType__c == '연체 알림') {
            Integer overdueDays = Date.today().daysBetween(notification.PaymentStatus__r.DueDate__c);
            message += '• **연체 기간**: ' + overdueDays + '일\n';
        }
        
        message += '\n💡 **다음 단계**\n';
        if (notification.NotificationType__c == '예정 알림') {
            message += '• 고객에게 납부 예정일 사전 안내\n';
            message += '• 납부 방법 및 계좌 정보 확인\n';
            message += '• 필요시 납부 일정 조정 상담\n';
        } else {
            message += '• 고객에게 즉시 연체 안내 연락\n';
            message += '• 납부 독촉 및 연체료 안내\n';
            message += '• 납부 계획 수립 지원\n';
        }
        
        message += '\n📞 담당자는 고객과의 소통 결과를 이 채널에 공유해주세요.';
        
        return message;
        */
    }
    
    /**
     * 슬랙 알림 발송
     */
    public static Boolean sendSlackNotification(Payment_Notification__c notification) {
        try {
            // 슬랙 웹훅 URL (Custom Setting에서 관리)
            String webhookUrl = getSlackWebhookUrl();
            if (String.isBlank(webhookUrl)) {
                System.debug('슬랙 웹훅 URL이 설정되지 않았습니다.');
                return false;
            }
            
            // 슬랙 메시지 생성
            String slackMessage = createSlackMessage(notification);
            
            // HTTP 요청으로 슬랙 발송
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(webhookUrl);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(slackMessage);
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                System.debug('슬랙 알림 발송 성공');
                return true;
            } else {
                System.debug('슬랙 알림 발송 실패: ' + response.getBody());
                return false;
            }
            
        } catch (Exception e) {
            System.debug('슬랙 알림 발송 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Chatter 포스트 생성
     */
    private static void createChatterPost(Payment_Notification__c notification) {
        try {
            FeedItem post = new FeedItem();
            // Order에 직접 포스팅
            post.ParentId = notification.PaymentStatus__r.Order__c;
            post.Type = 'TextPost';
            
            String message = '';
            if (notification.NotificationType__c == '예정 알림') {
                message = '🔔 [납부 예정 알림] ' + 
                         notification.PaymentStatus__r.Order__r.Account.Name + ' 고객님의 ' +
                         notification.PaymentStatus__r.Installment_Number__c + '차 납부 예정일이 3일 후입니다.\n' +
                         '납부금액: ₩' + notification.PaymentStatus__r.Amount__c.format() + '\n' +
                         '납부예정일: ' + notification.PaymentStatus__r.DueDate__c.format();
            } else if (notification.NotificationType__c == '연체 알림') {
                Integer overdueDays = Date.today().daysBetween(notification.PaymentStatus__r.DueDate__c);
                message = '🚨 [연체 알림] ' + 
                         notification.PaymentStatus__r.Order__r.Account.Name + ' 고객님의 ' +
                         notification.PaymentStatus__r.Installment_Number__c + '차 납부가 연체되었습니다.\n' +
                         '납부금액: ₩' + notification.PaymentStatus__r.Amount__c.format() + '\n' +
                         '납부예정일: ' + notification.PaymentStatus__r.DueDate__c.format() + '\n' +
                         '연체기간: ' + overdueDays + '일';
            }
            
            post.Body = message;
            insert post;
            System.debug('Chatter 포스트 생성 완료: ' + notification.PaymentStatus__r.Order__r.OrderNumber);
            
        } catch (Exception e) {
            System.debug('Chatter 포스트 생성 오류: ' + e.getMessage());
            // 오류가 발생해도 전체 프로세스는 계속 진행
        }
    }
    
    /**
     * Custom Notification 발송 (고객과 관리자 모두)
     */
    private static void sendCustomNotification(Payment_Notification__c notification) {
        try {
            // Custom Notification 타입 조회 또는 생성
            List<CustomNotificationType> notificationTypes = [
                SELECT Id FROM CustomNotificationType 
                WHERE DeveloperName = 'Payment_Notification' 
                LIMIT 1
            ];
            
            Id notificationTypeId;
            if (notificationTypes.isEmpty()) {
                // Custom Notification Type이 없으면 생성 시도
                notificationTypeId = createCustomNotificationType();
                if (notificationTypeId == null) {
                    System.debug('CustomNotificationType 생성/조회 실패. Bell 알림을 생략합니다.');
                    return;
                }
            } else {
                notificationTypeId = notificationTypes[0].Id;
            }
            
            // 알림 제목과 내용
            String title = notification.NotificationType__c == '예정 알림' ? 
                          '💰 납부 예정 알림' : '🚨 납부 연체 알림';
            
            String body = notification.PaymentStatus__r.Order__r.Account.Name + ' - ' +
                         notification.PaymentStatus__r.Installment_Number__c + '차 ₩' +
                         notification.PaymentStatus__r.Amount__c.format();
            
            // 수신자 ID 수집 (고객 담당자 + 관리자들)
            Set<String> recipientIds = getNotificationRecipients(notification);
            
            if (!recipientIds.isEmpty()) {
                Messaging.CustomNotification customNotification = new Messaging.CustomNotification();
                customNotification.setTitle(title);
                customNotification.setBody(body);
                customNotification.setTargetId(notification.PaymentStatus__r.Order__c);
                customNotification.setNotificationTypeId(notificationTypeId);
                customNotification.send(recipientIds);
                
                System.debug('Custom Notification 발송 완료: ' + title + ' (수신자: ' + recipientIds.size() + '명)');
            }
            
        } catch (Exception e) {
            System.debug('Custom Notification 발송 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 알림용 Task 생성
     */
    private static void createNotificationTask(Payment_Notification__c notification) {
        Task notificationTask = new Task();
        notificationTask.WhatId = notification.PaymentStatus__r.Order__c; // Order에 연결
        notificationTask.Subject = notification.NotificationType__c + ' - ' + 
                                  notification.PaymentStatus__r.Order__r.Account.Name + ' ' +
                                  notification.PaymentStatus__r.Installment_Number__c + '차';
        
        String description = '';
        if (notification.NotificationType__c == '예정 알림') {
            description = '고객님의 납부 예정일이 3일 후입니다. 사전 안내를 진행해주세요.\n\n';
            description += '주문번호: ' + notification.PaymentStatus__r.Order__r.OrderNumber + '\n';
            description += '납부 회차: ' + notification.PaymentStatus__r.Installment_Number__c + '차\n';
            description += '납부 금액: ₩' + String.valueOf(notification.PaymentStatus__r.Amount__c.format()) + '\n';
            description += '납부 예정일: ' + notification.PaymentStatus__r.DueDate__c.format();
        } else {
            description = '고객님의 납부가 연체되었습니다. 연체 관리를 진행해주세요.\n\n';
            description += '주문번호: ' + notification.PaymentStatus__r.Order__r.OrderNumber + '\n';
            description += '납부 회차: ' + notification.PaymentStatus__r.Installment_Number__c + '차\n';
            description += '납부 금액: ₩' + String.valueOf(notification.PaymentStatus__r.Amount__c.format()) + '\n';
            description += '연체일: ' + notification.PaymentStatus__r.DueDate__c.format() + '\n';
            description += '연체 기간: ' + (Date.today().daysBetween(notification.PaymentStatus__r.DueDate__c)) + '일';
        }
        
        notificationTask.Description = description;
        notificationTask.Priority = notification.NotificationType__c == '연체 알림' ? 'High' : 'Normal';
        notificationTask.Status = 'Not Started';
        notificationTask.ActivityDate = Date.today().addDays(
            notification.NotificationType__c == '연체 알림' ? 1 : 3
        );
        
        // PaymentStatus 정보를 Task에 연결 (커스텀 필드가 있다면)
        // notificationTask.PaymentStatus__c = notification.PaymentStatus__c;
        
        insert notificationTask;
    }
    
    /**
     * 고객 이메일 주소 조회
     */
    private static String getCustomerEmail(Payment_Notification__c notification) {
        // 설정된 수신자 이메일이 있으면 우선 사용 (null 체크 강화)
        try {
            if (notification.get('RecipientEmail__c') != null && 
                String.isNotBlank(String.valueOf(notification.get('RecipientEmail__c')))) {
                return String.valueOf(notification.get('RecipientEmail__c'));
            }
        } catch (Exception e) {
            System.debug('RecipientEmail__c 필드 접근 오류 (필드가 쿼리되지 않았을 수 있음): ' + e.getMessage());
        }
        
        // Account의 Contact 이메일 조회
        try {
            List<Contact> contacts = [
                SELECT Email 
                FROM Contact 
                WHERE AccountId = :notification.PaymentStatus__r.Order__r.Account.Id 
                AND Email != null 
                ORDER BY CreatedDate ASC 
                LIMIT 1
            ];
            
            if (!contacts.isEmpty() && String.isNotBlank(contacts[0].Email)) {
                return contacts[0].Email;
            }
        } catch (Exception e) {
            System.debug('고객 이메일 조회 오류: ' + e.getMessage());
        }
        
        return null;
    }
    
    /**
     * 이메일 메시지 생성 (고객/관리자별 구분)
     */
    private static Messaging.SingleEmailMessage createPaymentEmail(
        Payment_Notification__c notification, 
        String recipientEmail,
        String recipientType
    ) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{ recipientEmail });
        
        // 이메일 제목
        String subject = '';
        if (notification.NotificationType__c == '예정 알림') {
            subject = '[납부 예정] ' + notification.PaymentStatus__r.Installment_Number__c + 
                     '차 납부 예정일 안내';
        } else {
            subject = '[납부 연체] ' + notification.PaymentStatus__r.Installment_Number__c + 
                     '차 납부 연체 안내';
        }
        
        if (recipientType == 'Admin') {
            subject = '[관리자] ' + subject;
        }
        
        email.setSubject(subject);
        
        // 이메일 본문
        String body = createEmailBody(notification, recipientType);
        email.setPlainTextBody(body);
        
        // PDF 첨부파일 추가
        List<Messaging.EmailFileAttachment> attachments = getPDFAttachments(notification);
        if (!attachments.isEmpty()) {
            email.setFileAttachments(attachments);
        }
        
        return email;
    }
    
    /**
     * 이메일 본문 생성 (고객/관리자별 구분)
     */
    private static String createEmailBody(Payment_Notification__c notification, String recipientType) {
        String body = '';
        
        if (recipientType == 'Admin') {
            // 관리자용 이메일
            body = '납부 알림 시스템에서 자동 발송된 관리자 알림입니다.\n\n';
            body += '🏢 고객정보\n';
            body += '• 고객명: ' + notification.PaymentStatus__r.Order__r.Account.Name + '\n';
            body += '• 주문번호: ' + notification.PaymentStatus__r.Order__r.OrderNumber + '\n\n';
            body += '💰 납부정보\n';
            body += '• 납부 회차: ' + notification.PaymentStatus__r.Installment_Number__c + '차\n';
            body += '• 납부 금액: ₩' + notification.PaymentStatus__r.Amount__c.format() + '\n';
            body += '• 납부 예정일: ' + notification.PaymentStatus__r.DueDate__c.format() + '\n';
            
            if (notification.NotificationType__c == '연체 알림') {
                Integer overdueDays = Date.today().daysBetween(notification.PaymentStatus__r.DueDate__c);
                body += '• 연체 기간: ' + overdueDays + '일\n';
                body += '\n⚠️ 연체 관리가 필요합니다. 고객에게 연락하여 납부를 안내해주세요.\n';
            } else {
                body += '\n📅 3일 후 납부 예정입니다. 고객 사전 안내를 진행해주세요.\n';
            }
            
            body += '\nSalesforce에서 상세정보를 확인하실 수 있습니다.';
            
        } else {
            // 고객용 이메일
            body = '안녕하세요, ' + notification.PaymentStatus__r.Order__r.Account.Name + ' 고객님.\n\n';
            
            if (notification.NotificationType__c == '예정 알림') {
                body += '다가오는 납부 예정일을 안내드립니다.\n\n';
                body += '📋 납부 정보\n';
                body += '• 주문번호: ' + notification.PaymentStatus__r.Order__r.OrderNumber + '\n';
                body += '• 납부 회차: ' + notification.PaymentStatus__r.Installment_Number__c + '차\n';
                body += '• 납부 금액: ₩' + notification.PaymentStatus__r.Amount__c.format() + '\n';
                body += '• 납부 예정일: ' + notification.PaymentStatus__r.DueDate__c.format() + '\n\n';
                body += '원활한 서비스 이용을 위해 납부 예정일에 맞춰 납부해주시기 바랍니다.\n\n';
            } else {
                body += '납부 연체가 발생하여 안내드립니다.\n\n';
                body += '📋 연체 정보\n';
                body += '• 주문번호: ' + notification.PaymentStatus__r.Order__r.OrderNumber + '\n';
                body += '• 납부 회차: ' + notification.PaymentStatus__r.Installment_Number__c + '차\n';
                body += '• 납부 금액: ₩' + notification.PaymentStatus__r.Amount__c.format() + '\n';
                body += '• 납부 예정일: ' + notification.PaymentStatus__r.DueDate__c.format() + ' (연체)\n\n';
                body += '빠른 시일 내에 납부해주시기 바랍니다.\n\n';
            }
            
            body += '📎 첨부된 PDF 파일에서 상세 내역을 확인하실 수 있습니다.\n\n';
            body += '문의사항이 있으시면 고객센터(1588-0000)로 연락주세요.\n\n';
            body += '감사합니다.';
        }
        
        return body;
    }
    
    /**
     * 슬랙 메시지 생성
     */
    private static String createSlackMessage(Payment_Notification__c notification) {
        Map<String, Object> slackPayload = new Map<String, Object>();
        
        String text = '';
        String color = '';
        
        if (notification.NotificationType__c == '예정 알림') {
            text = ':bell: 납부 예정 알림';
            color = '#36a64f'; // 녹색
        } else {
            text = ':warning: 납부 연체 알림';
            color = '#ff0000'; // 빨간색
        }
        
        Map<String, Object> attachment = new Map<String, Object>();
        attachment.put('color', color);
        attachment.put('title', notification.PaymentStatus__r.Order__r.Account.Name + ' - ' + 
                              notification.PaymentStatus__r.Installment_Number__c + '차');
        attachment.put('text', '납부금액: ₩' + notification.PaymentStatus__r.Amount__c.format() + '\n' +
                              '예정일: ' + notification.PaymentStatus__r.DueDate__c.format());
        
        slackPayload.put('text', text);
        slackPayload.put('attachments', new List<Object>{ attachment });
        
        return JSON.serialize(slackPayload);
    }
    
    /**
     * 슬랙 웹훅 URL 조회 (Custom Setting에서 관리)
     */
    private static String getSlackWebhookUrl() {
        // Custom Setting에서 슬랙 웹훅 URL 조회
        // 실제 구현 시 Custom Setting 생성 필요
        return 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK';
    }
    
    /**
     * 관리자 이메일 주소 목록 조회
     */
    private static List<String> getAdminEmails(Payment_Notification__c notification) {
        List<String> adminEmails = new List<String>();
        
        try {
            // 1. Order Owner의 이메일
            List<Order> orders = [
                SELECT OwnerId, Owner.Email 
                FROM Order 
                WHERE Id = :notification.PaymentStatus__r.Order__c 
                AND Owner.Email != null
                LIMIT 1
            ];
            
            if (!orders.isEmpty() && String.isNotBlank(orders[0].Owner.Email)) {
                adminEmails.add(orders[0].Owner.Email);
            }
            
            // 2. 시스템 관리자들 (Profile 기반)
            List<User> adminUsers = [
                SELECT Email 
                FROM User 
                WHERE Profile.Name IN ('시스템 관리자', 'System Administrator') 
                AND IsActive = true 
                AND Email != null
                LIMIT 5
            ];
            
            for (User admin : adminUsers) {
                if (!adminEmails.contains(admin.Email)) {
                    adminEmails.add(admin.Email);
                }
            }
            
            // 3. 고정 관리자 이메일 (설정에서 관리)
            String fixedAdminEmail = 'eetd0000@gmail.com';
            if (!adminEmails.contains(fixedAdminEmail)) {
                adminEmails.add(fixedAdminEmail);
            }
            
        } catch (Exception e) {
            System.debug('관리자 이메일 조회 오류: ' + e.getMessage());
        }
        
        return adminEmails;
    }
    
    /**
     * Custom Notification 수신자 조회
     */
    private static Set<String> getNotificationRecipients(Payment_Notification__c notification) {
        Set<String> recipientIds = new Set<String>();
        
        try {
            // 1. 현재 사용자
            recipientIds.add(UserInfo.getUserId());
            
            // 2. Order Owner
            List<Order> orders = [
                SELECT OwnerId 
                FROM Order 
                WHERE Id = :notification.PaymentStatus__r.Order__c
                LIMIT 1
            ];
            
            if (!orders.isEmpty()) {
                recipientIds.add(orders[0].OwnerId);
            }
            
            // 3. 시스템 관리자들
            List<User> adminUsers = [
                SELECT Id 
                FROM User 
                WHERE Profile.Name IN ('시스템 관리자', 'System Administrator') 
                AND IsActive = true
                LIMIT 5
            ];
            
            for (User admin : adminUsers) {
                recipientIds.add(admin.Id);
            }
            
        } catch (Exception e) {
            System.debug('Notification 수신자 조회 오류: ' + e.getMessage());
        }
        
        return recipientIds;
    }
    
    /**
     * Custom Notification Type 생성
     */
    private static Id createCustomNotificationType() {
        try {
            // Custom Notification Type은 Setup에서 수동 생성 필요
            // 여기서는 조회만 재시도
            List<CustomNotificationType> types = [
                SELECT Id FROM CustomNotificationType 
                WHERE DeveloperName = 'Payment_Notification'
                LIMIT 1
            ];
            
            return types.isEmpty() ? null : types[0].Id;
            
        } catch (Exception e) {
            System.debug('CustomNotificationType 조회 오류: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * PDF 첨부파일 조회 (Notes & Attachments에서 최신 납부일정서 파일)
     */
    private static List<Messaging.EmailFileAttachment> getPDFAttachments(Payment_Notification__c notification) {
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        
        try {
            // 1차: 납부일정서 우선 검색
            List<ContentDocumentLink> paymentScheduleDocs = [
                SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension,
                       ContentDocument.CreatedDate
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :notification.PaymentStatus__r.Order__c
                AND ContentDocument.FileExtension = 'pdf'
                AND (ContentDocument.Title LIKE '%납부일정서%' 
                     OR ContentDocument.Title LIKE '%payment%schedule%'
                     OR ContentDocument.Title LIKE '%일정%')
                ORDER BY ContentDocument.CreatedDate DESC
                LIMIT 1
            ];
            
            ContentDocumentLink selectedPDF = null;
            
            if (!paymentScheduleDocs.isEmpty()) {
                selectedPDF = paymentScheduleDocs[0];
                System.debug('📎 납부일정서 PDF 발견: ' + selectedPDF.ContentDocument.Title + '.pdf');
            } else {
                // 2차: 일반 PDF 파일 검색
                List<ContentDocumentLink> generalPDFs = [
                    SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension,
                           ContentDocument.CreatedDate
                    FROM ContentDocumentLink 
                    WHERE LinkedEntityId = :notification.PaymentStatus__r.Order__c
                    AND ContentDocument.FileExtension = 'pdf'
                    ORDER BY ContentDocument.CreatedDate DESC
                    LIMIT 1
                ];
                
                if (!generalPDFs.isEmpty()) {
                    selectedPDF = generalPDFs[0];
                    System.debug('📎 일반 PDF 발견: ' + selectedPDF.ContentDocument.Title + '.pdf');
                }
            }
            
            if (selectedPDF != null) {
                // ContentVersion 조회
                List<ContentVersion> contentVersions = [
                    SELECT Title, VersionData, ContentSize, Description
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :selectedPDF.ContentDocument.Id
                    AND IsLatest = true
                    LIMIT 1
                ];
                
                if (!contentVersions.isEmpty()) {
                    ContentVersion cv = contentVersions[0];
                    
                    // 파일 데이터가 있는지 확인
                    if (cv.VersionData != null && cv.VersionData.size() > 0) {
                        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                        attachment.setFileName(cv.Title + '.pdf');
                        attachment.setBody(cv.VersionData);
                        attachment.setContentType('application/pdf');
                        attachments.add(attachment);
                        
                        System.debug('✅ PDF 첨부파일 추가 성공: ' + cv.Title + '.pdf');
                        System.debug('   파일 크기: ' + (cv.ContentSize / 1024) + 'KB');
                        System.debug('   설명: ' + cv.Description);
                    } else {
                        System.debug('⚠️ PDF 파일 데이터가 비어있습니다: ' + cv.Title);
                        
                        // 데이터가 없는 경우 새로운 납부일정서 PDF 생성
                        ContentVersion newPDF = createPaymentSchedulePDF(notification);
                        if (newPDF != null) {
                            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                            attachment.setFileName(newPDF.Title + '.pdf');
                            attachment.setBody(newPDF.VersionData);
                            attachment.setContentType('application/pdf');
                            attachments.add(attachment);
                            
                            System.debug('✅ 새 납부일정서 PDF 첨부: ' + newPDF.Title + '.pdf');
                        }
                    }
                }
            } else {
                System.debug('📄 Order에 연결된 PDF 파일이 없습니다. 새 납부일정서를 생성합니다.');
                
                // PDF 파일이 없는 경우 새로운 납부일정서 PDF 생성
                ContentVersion newPDF = createPaymentSchedulePDF(notification);
                if (newPDF != null) {
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName(newPDF.Title + '.pdf');
                    attachment.setBody(newPDF.VersionData);
                    attachment.setContentType('application/pdf');
                    attachments.add(attachment);
                    
                    System.debug('✅ 새 납부일정서 PDF 생성 및 첨부: ' + newPDF.Title + '.pdf');
                }
            }
            
        } catch (Exception e) {
            System.debug('❌ PDF 첨부파일 조회 오류: ' + e.getMessage());
        }
        
        return attachments;
    }
    
    /**
     * 납부일정서 PDF 생성
     */
    private static ContentVersion createPaymentSchedulePDF(Payment_Notification__c notification) {
        try {
            // PaymentStatus 목록 조회
            List<PaymentStatus__c> paymentList = [
                SELECT Installment_Number__c, Amount__c, DueDate__c, Status__c
                FROM PaymentStatus__c 
                WHERE Order__c = :notification.PaymentStatus__r.Order__c
                ORDER BY Installment_Number__c ASC
            ];
            
            // PDF 내용 생성
            String pdfContent = '%PDF-1.4\n';
            pdfContent += '1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n\n';
            pdfContent += '2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n\n';
            pdfContent += '3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n>>\nendobj\n\n';
            
            String contentStream = 'BT\n/F1 14 Tf\n100 720 Td\n';
            contentStream += '(납부일정서 - Order: ' + notification.PaymentStatus__r.Order__r.OrderNumber + ') Tj\n';
            contentStream += '0 -25 Td\n(고객명: ' + notification.PaymentStatus__r.Order__r.Account.Name + ') Tj\n';
            contentStream += '0 -20 Td\n(생성일: ' + Date.today().format() + ') Tj\n';
            contentStream += '0 -30 Td\n';
            
            // 납부 일정 목록 추가
            Integer yPosition = -20;
            for (PaymentStatus__c payment : paymentList) {
                String statusText = payment.Status__c == '완납' ? '완납' : '예정';
                String paymentLine = '(' + payment.Installment_Number__c + '차: ₩' + 
                                   payment.Amount__c.format() + ' - ' + 
                                   payment.DueDate__c.format() + ' ' + statusText + ') Tj\n';
                contentStream += '0 ' + yPosition + ' Td\n' + paymentLine;
            }
            
            contentStream += 'ET\n';
            
            Integer contentLength = contentStream.length();
            pdfContent += '4 0 obj\n<<\n/Length ' + contentLength + '\n>>\nstream\n';
            pdfContent += contentStream;
            pdfContent += 'endstream\nendobj\n\n';
            pdfContent += 'xref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n';
            pdfContent += '0000000115 00000 n \n0000000204 00000 n \ntrailer\n<<\n/Size 5\n/Root 1 0 R\n>>\n';
            pdfContent += 'startxref\n' + (300 + contentLength) + '\n%%EOF';
            
            // ContentVersion 생성 및 반환 (저장하지 않고 메모리에서만 사용)
            ContentVersion cv = new ContentVersion();
            cv.Title = '납부일정서_' + notification.PaymentStatus__r.Order__r.OrderNumber + '_' + DateTime.now().format('yyyyMMdd_HHmm');
            cv.VersionData = Blob.valueOf(pdfContent);
            
            return cv;
            
        } catch (Exception e) {
            System.debug('❌ 납부일정서 PDF 생성 오류: ' + e.getMessage());
            return null;
        }
    }
}
