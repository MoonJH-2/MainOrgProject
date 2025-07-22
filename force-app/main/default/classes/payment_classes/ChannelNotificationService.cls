/**
 * 간소화된 채널 알림 서비스 (표준 오브젝트만 사용)
 * Task 오브젝트를 활용한 알림 시스템
 */
public with sharing class ChannelNotificationService {
    
    /**
     * Task 기반 알림 처리
     */
    public static void processTaskNotification(Task notificationTask) {
        try {
            System.debug('📧 Task 알림 처리 시작: ' + notificationTask.Id);
            
            // 1. Salesforce 채널 알림 (우선순위)
            Boolean salesforceSuccess = sendSalesforceChannelNotification(notificationTask);
            
            // 2. Chatter 포스트 (기본)
            Boolean chatterSuccess = createChatterPost(notificationTask);
            
            System.debug('✅ 알림 처리 완료 - Salesforce: ' + salesforceSuccess + 
                        ', Chatter: ' + chatterSuccess);
            
        } catch(Exception e) {
            System.debug('❌ Task 알림 처리 오류: ' + e.getMessage());
        }
    }
    
    /**
     * Salesforce 채널 알림 발송 (Task 기반)
     */
    public static Boolean sendSalesforceChannelNotification(Task notificationTask) {
        try {
            if(notificationTask.WhatId == null) {
                System.debug('❌ Task에 관련 레코드가 없습니다');
                return false;
            }
            
            // Order 정보 조회
            List<Order> orders = [
                SELECT Id, OrderNumber, Name
                FROM Order 
                WHERE Id = :notificationTask.WhatId 
                LIMIT 1
            ];
            
            if(orders.isEmpty()) {
                System.debug('❌ 관련 Order를 찾을 수 없습니다: ' + notificationTask.WhatId);
                return false;
            }
            
            Order order = orders[0];
            
            // Salesforce 채널 찾기
            List<CollaborationGroup> channels = [
                SELECT Id, Name FROM CollaborationGroup 
                WHERE Name LIKE :('%' + order.OrderNumber + '%')
                LIMIT 1
            ];
            
            if(channels.isEmpty()) {
                System.debug('❌ Salesforce 채널을 찾을 수 없습니다: ' + order.OrderNumber);
                return false;
            }
            
            // 채널에 알림 메시지 발송
            String message = createChannelNotificationMessage(notificationTask, order);
            
            // SimpleSalesforceChannelService의 static 메서드 사용
            Boolean success = SimpleSalesforceChannelService.sendChannelMessage(channels[0].Id, message);
            
            if(success) {
                System.debug('✅ Salesforce 채널 알림 발송 완료: ' + channels[0].Name);
            }
            
            return success;
            
        } catch(Exception e) {
            System.debug('❌ Salesforce 채널 알림 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * 채널 알림 메시지 생성 (Task 기반)
     */
    private static String createChannelNotificationMessage(Task notificationTask, Order order) {
        String message = '📋 Task 알림\n\n';
        message += '📋 Order: ' + order.OrderNumber + '\n';
        message += '📝 제목: ' + notificationTask.Subject + '\n';
        message += '📅 기한: ' + (notificationTask.ActivityDate != null ? notificationTask.ActivityDate.format() : 'N/A') + '\n';
        message += '⚠️ 우선순위: ' + notificationTask.Priority + '\n';
        message += '📄 설명: ' + (notificationTask.Description != null ? notificationTask.Description : '') + '\n\n';
        
        if(notificationTask.Subject?.contains('연체')) {
            message += '🚨 연체 알림! 즉시 확인이 필요합니다.\n';
        } else if(notificationTask.Subject?.contains('알림')) {
            message += '⏰ 중요한 알림이 있습니다.\n';
        }
        
        message += '\n🔗 Order 확인: ' + System.URL.getOrgDomainUrl().toExternalForm() + 
                  '/lightning/r/Order/' + order.Id + '/view\n';
        message += '🔗 Task 확인: ' + System.URL.getOrgDomainUrl().toExternalForm() + 
                  '/lightning/r/Task/' + notificationTask.Id + '/view\n';
        message += '🕒 ' + System.now().format('yyyy-MM-dd HH:mm:ss') + '\n\n';
        message += '#TaskAlert #긴급확인필요';
        
        return message;
    }
    
    /**
     * Chatter 포스트 생성 (Task 기반)
     */
    public static Boolean createChatterPost(Task notificationTask) {
        try {
            if(notificationTask.WhatId == null) {
                System.debug('❌ Task에 관련 레코드가 없습니다');
                return false;
            }
            
            FeedItem post = new FeedItem();
            post.ParentId = notificationTask.WhatId; // Order에 포스트
            post.Body = '📋 Task 알림: ' + notificationTask.Subject + 
                       ' (기한: ' + (notificationTask.ActivityDate != null ? 
                       notificationTask.ActivityDate.format() : 'N/A') + ')';
            post.Type = 'TextPost';
            
            insert post;
            
            System.debug('✅ Chatter 포스트 생성 완료');
            return true;
            
        } catch(Exception e) {
            System.debug('❌ Chatter 포스트 오류: ' + e.getMessage());
            return false;
        }
    }
}
