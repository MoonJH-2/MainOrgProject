/**
 * Slack 채널에서 Salesforce 채널로 완전 전환 서비스
 * 목적: 기존 Slack 채널을 Salesforce 채널로 마이그레이션하고 데이터 동기화
 */
public class SlackToSalesforceChannelMigrationService {
    
    /**
     * 전체 마이그레이션 프로세스 실행
     */
    public static void executeFullMigration() {
        System.debug('=== 🚀 Slack → Salesforce 채널 완전 전환 시작 ===');
        
        try {
            // 1. Slack 채널이 있는 모든 Order 조회
            List<Order> ordersWithSlack = getOrdersWithSlackChannels();
            System.debug('Slack 채널이 있는 Order 수: ' + ordersWithSlack.size());
            
            // 2. 각 Order에 대해 Salesforce 채널 생성
            Integer successCount = 0;
            Integer failCount = 0;
            
            for(Order order : ordersWithSlack) {
                try {
                    boolean migrationSuccess = migrateOrderToSalesforceChannel(order);
                    if(migrationSuccess) {
                        successCount++;
                        System.debug('✅ Order ' + order.OrderNumber + ' 마이그레이션 성공');
                    } else {
                        failCount++;
                        System.debug('❌ Order ' + order.OrderNumber + ' 마이그레이션 실패');
                    }
                } catch(Exception e) {
                    failCount++;
                    System.debug('❌ Order ' + order.OrderNumber + ' 오류: ' + e.getMessage());
                }
            }
            
            // 3. 마이그레이션 결과 보고
            System.debug('=== 📊 마이그레이션 완료 결과 ===');
            System.debug('성공: ' + successCount + '건');
            System.debug('실패: ' + failCount + '건');
            System.debug('총 처리: ' + ordersWithSlack.size() + '건');
            
        } catch(Exception e) {
            System.debug('❌ 전체 마이그레이션 오류: ' + e.getMessage());
        }
    }
    
    /**
     * Slack 채널이 있는 Order들 조회
     */
    private static List<Order> getOrdersWithSlackChannels() {
        return [
            SELECT Id, Name, OrderNumber, Status, AccountId,
                   Slack_Channel_ID__c, Slack_Channel_Name__c, 
                   Slack_Webhook_URL__c, Slack_Notification_Status__c
            FROM Order 
            WHERE Slack_Channel_ID__c != null 
               OR Slack_Channel_Name__c != null
               OR Slack_Notification_Status__c = 'Channel Created'
            ORDER BY CreatedDate DESC
        ];
    }
    
    /**
     * 개별 Order의 Slack → Salesforce 채널 마이그레이션
     */
    private static Boolean migrateOrderToSalesforceChannel(Order order) {
        try {
            // 1. 기존 Salesforce 채널 확인
            List<CollaborationGroup> existingChannels = [
                SELECT Id, Name 
                FROM CollaborationGroup 
                WHERE Name LIKE :('%' + order.OrderNumber + '%')
                LIMIT 1
            ];
            
            String salesforceChannelId;
            
            if(existingChannels.isEmpty()) {
                // 2. 새 Salesforce 채널 생성 (SimpleSalesforceChannelService 사용)
                salesforceChannelId = SimpleSalesforceChannelService.createOrderChannel(order.Id);
                
                if(salesforceChannelId == null) {
                    return false;
                }
                
                // 3. 기본 멤버 추가 (Order Owner, Account 관련자들)
                addDefaultMembersToChannel(salesforceChannelId, order);
                
                // 4. 마이그레이션 환영 메시지
                postMigrationWelcomeMessage(salesforceChannelId, order);
                
            } else {
                salesforceChannelId = existingChannels[0].Id;
                System.debug('기존 Salesforce 채널 사용: ' + existingChannels[0].Name);
            }
            
            // 5. Order 레코드 업데이트 (Salesforce 채널 정보 추가)
            updateOrderWithSalesforceChannel(order, salesforceChannelId);
            
            // 6. Slack 채널 비활성화 처리
            deactivateSlackChannel(order);
            
            // 7. 마이그레이션 완료 알림
            notifyMigrationCompletion(order, salesforceChannelId);
            
            return true;
            
        } catch(Exception e) {
            System.debug('마이그레이션 오류 (Order: ' + order.OrderNumber + '): ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * 채널에 기본 멤버들 추가
     */
    private static void addDefaultMembersToChannel(String channelId, Order order) {
        try {
            // Order Owner 추가 (SimpleSalesforceChannelService 사용)
            if(order.OwnerId != null) {
                SimpleSalesforceChannelService.addUserToChannel(channelId, order.OwnerId);
            }
            
            // Account Owner만 추가 (단순화)
            Set<Id> accountUserIds = new Set<Id>();
            
            // Account Owner 추가
            List<Account> accounts = [SELECT OwnerId FROM Account WHERE Id = :order.AccountId LIMIT 1];
            if(!accounts.isEmpty()) {
                accountUserIds.add(accounts[0].OwnerId);
            }
            
            List<User> accountUsers = [SELECT Id FROM User WHERE Id IN :accountUserIds LIMIT 10];
            
            for(User user : accountUsers) {
                SimpleSalesforceChannelService.addUserToChannel(channelId, user.Id);
            }
            
        } catch(Exception e) {
            System.debug('멤버 추가 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 마이그레이션 환영 메시지 게시
     */
    private static void postMigrationWelcomeMessage(String channelId, Order order) {
        try {
            String message = '🎉 Slack 채널에서 Salesforce 채널로 성공적으로 마이그레이션되었습니다!\n\n';
            message += '📋 Order: ' + order.OrderNumber + '\n';
            message += '📅 마이그레이션 날짜: ' + System.now().format('yyyy-MM-dd HH:mm:ss') + '\n';
            message += '✨ 이제 Salesforce 내에서 모든 협업을 진행할 수 있습니다.\n\n';
            message += '💡 주요 기능:\n';
            message += '• 실시간 알림 및 멘션\n';
            message += '• 파일 공유 및 문서 협업\n';
            message += '• Order 진행 상황 자동 업데이트\n';
            message += '• 모바일 앱에서도 동일한 경험\n\n';
            message += '#마이그레이션완료 #SalesforceChannels';
            
            FeedItem welcomePost = new FeedItem(
                ParentId = channelId,
                Body = message,
                Type = 'TextPost'
            );
            insert welcomePost;
            
        } catch(Exception e) {
            System.debug('환영 메시지 오류: ' + e.getMessage());
        }
    }
    
    /**
     * Order 레코드에 Salesforce 채널 정보 업데이트
     */
    private static void updateOrderWithSalesforceChannel(Order order, String salesforceChannelId) {
        try {
            // 새로운 Salesforce 채널 필드들 (미래에 추가될 예정)
            Order updateOrder = new Order(Id = order.Id);
            
            // 기존 Slack 관련 필드들을 마이그레이션 상태로 변경
            updateOrder.Slack_Notification_Status__c = 'Migrated to Salesforce';
            
            // 마이그레이션 날짜 기록 (Description 필드 활용)
            String migrationNote = '마이그레이션 완료: ' + System.now().format('yyyy-MM-dd HH:mm:ss') + 
                                 ' | Salesforce Channel ID: ' + salesforceChannelId;
            updateOrder.Description = (order.Description != null ? order.Description + '\n' : '') + migrationNote;
            
            update updateOrder;
            
        } catch(Exception e) {
            System.debug('Order 업데이트 오류: ' + e.getMessage());
        }
    }
    
    /**
     * Slack 채널 비활성화 처리
     */
    private static void deactivateSlackChannel(Order order) {
        try {
            // Slack 채널 상태를 '비활성화'로 변경
            Order updateOrder = new Order(Id = order.Id);
            updateOrder.Slack_Notification_Status__c = 'Deactivated - Migrated';
            
            // Slack Webhook을 비활성화 (URL 앞에 DISABLED_ 접두사 추가)
            if(order.Slack_Webhook_URL__c != null && !order.Slack_Webhook_URL__c.startsWith('DISABLED_')) {
                updateOrder.Slack_Webhook_URL__c = 'DISABLED_' + order.Slack_Webhook_URL__c;
            }
            
            update updateOrder;
            
            System.debug('Slack 채널 비활성화 완료: ' + order.OrderNumber);
            
        } catch(Exception e) {
            System.debug('Slack 비활성화 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 마이그레이션 완료 알림
     */
    private static void notifyMigrationCompletion(Order order, String salesforceChannelId) {
        try {
            // 시스템 관리자에게 Chatter 알림
            String adminMessage = order.OrderNumber + '의 채널 마이그레이션이 완료되었습니다. ' +
                                'Salesforce Channel ID: ' + salesforceChannelId;
            
            // 현재 사용자에게 알림 (실제로는 시스템 관리자 ID 사용)
            FeedItem notification = new FeedItem(
                ParentId = UserInfo.getUserId(),
                Body = adminMessage,
                Type = 'TextPost'
            );
            insert notification;
            
        } catch(Exception e) {
            System.debug('완료 알림 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 특정 Order의 마이그레이션 상태 확인
     */
    public static void checkMigrationStatus(String orderNumber) {
        try {
            List<Order> orders = [
                SELECT Id, OrderNumber, Slack_Channel_ID__c, Slack_Notification_Status__c, Description
                FROM Order 
                WHERE OrderNumber = :orderNumber
                LIMIT 1
            ];
            
            if(orders.isEmpty()) {
                System.debug('❌ Order를 찾을 수 없습니다: ' + orderNumber);
                return;
            }
            
            Order order = orders[0];
            
            // Salesforce 채널 확인
            List<CollaborationGroup> salesforceChannels = [
                SELECT Id, Name, MemberCount
                FROM CollaborationGroup 
                WHERE Name LIKE :('%' + orderNumber + '%')
            ];
            
            System.debug('=== 📊 마이그레이션 상태: ' + orderNumber + ' ===');
            System.debug('Slack 상태: ' + order.Slack_Notification_Status__c);
            System.debug('Slack Channel ID: ' + order.Slack_Channel_ID__c);
            System.debug('Salesforce 채널 수: ' + salesforceChannels.size());
            
            if(!salesforceChannels.isEmpty()) {
                for(CollaborationGroup channel : salesforceChannels) {
                    System.debug('✅ Salesforce 채널: ' + channel.Name + ' (멤버: ' + channel.MemberCount + ')');
                }
            }
            
            // 마이그레이션 상태 판단
            if(order.Slack_Notification_Status__c?.contains('Migrated') && !salesforceChannels.isEmpty()) {
                System.debug('🎉 완전 마이그레이션 완료!');
            } else if(!salesforceChannels.isEmpty()) {
                System.debug('⚠️ 부분 마이그레이션 (Salesforce 채널 존재, Slack 상태 미변경)');
            } else {
                System.debug('❌ 마이그레이션 필요 (Salesforce 채널 없음)');
            }
            
        } catch(Exception e) {
            System.debug('❌ 상태 확인 오류: ' + e.getMessage());
        }
    }
}
