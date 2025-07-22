/**
 * @description 완전 독립적인 Salesforce 채널 서비스 (배포 오류 없음)
 * @author JH Moon
 * @created 2025-07-22
 */
public with sharing class SimpleSalesforceChannelService {
    
    /**
     * Order ID로 채널 생성
     */
    public static String createOrderChannel(String orderId) {
        try {
            Order orderInfo = [SELECT Id, Name, OrderNumber, OwnerId, AccountId 
                              FROM Order WHERE Id = :orderId LIMIT 1];
            
            System.debug('📢 Order Channel 생성 시작: ' + orderInfo.OrderNumber);
            
            // 기존 채널 확인
            List<CollaborationGroup> existingGroups = [
                SELECT Id, Name FROM CollaborationGroup 
                WHERE Name = :('Order-' + orderInfo.OrderNumber) LIMIT 1
            ];
            
            if(!existingGroups.isEmpty()) {
                System.debug('✅ 기존 채널 사용: ' + existingGroups[0].Id);
                return existingGroups[0].Id;
            }
            
            // 새 Chatter Group 생성
            CollaborationGroup channelGroup = new CollaborationGroup();
            channelGroup.Name = 'Order-' + orderInfo.OrderNumber;
            channelGroup.Description = 'Order ' + orderInfo.OrderNumber + ' 전용 협업 채널\n' +
                                     '생성일: ' + System.now().format('yyyy-MM-dd HH:mm') + '\n' +
                                     'Account: ' + orderInfo.AccountId;
            channelGroup.CollaborationType = 'Private';
            channelGroup.IsArchived = false;
            channelGroup.CanHaveGuests = false;
            
            insert channelGroup;
            
            System.debug('✅ Order Channel 생성 완료: ' + channelGroup.Id);
            return channelGroup.Id;
            
        } catch (Exception e) {
            System.debug('❌ Order Channel 생성 오류: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * 채널에 사용자 추가
     */
    public static Boolean addUserToChannel(String channelId, String userId) {
        try {
            // 기존 멤버 확인
            List<CollaborationGroupMember> existingMembers = [
                SELECT Id FROM CollaborationGroupMember 
                WHERE CollaborationGroupId = :channelId AND MemberId = :userId
            ];
            
            if(!existingMembers.isEmpty()) {
                System.debug('이미 채널 멤버입니다: ' + userId);
                return true;
            }
            
            CollaborationGroupMember member = new CollaborationGroupMember();
            member.CollaborationGroupId = channelId;
            member.MemberId = userId;
            member.CollaborationRole = 'Standard';
            
            insert member;
            
            System.debug('✅ 채널 멤버 추가 완료: ' + userId);
            return true;
            
        } catch (Exception e) {
            System.debug('❌ 멤버 추가 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * 환영 메시지 게시
     */
    public static Boolean postWelcomeMessage(String channelId, String orderId, String orderNumber) {
        try {
            String welcomeMessage = '🎉 Order ' + orderNumber + ' 채널에 오신 것을 환영합니다!\n\n';
            welcomeMessage += '📋 이 채널에서 다음과 같은 활동을 할 수 있습니다:\n';
            welcomeMessage += '• 📞 Order 관련 실시간 소통\n';
            welcomeMessage += '• 📄 문서 및 파일 공유\n';
            welcomeMessage += '• 🔔 Payment 알림 및 업데이트\n';
            welcomeMessage += '• 👥 팀원들과의 협업\n\n';
            welcomeMessage += '💡 @멘션을 사용하여 특정 멤버에게 알림을 보낼 수 있습니다.\n';
            welcomeMessage += '🚀 Order URL: ' + System.URL.getOrgDomainUrl().toExternalForm() + 
                            '/lightning/r/Order/' + orderId + '/view\n\n';
            welcomeMessage += '#OrderChannel #팀워크 #협업';
            
            FeedItem welcomePost = new FeedItem();
            welcomePost.ParentId = channelId;
            welcomePost.Body = welcomeMessage;
            welcomePost.Type = 'TextPost';
            
            insert welcomePost;
            
            System.debug('✅ 환영 메시지 게시 완료');
            return true;
            
        } catch (Exception e) {
            System.debug('❌ 환영 메시지 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * 채널에 일반 메시지 게시
     */
    public static Boolean sendChannelMessage(String channelId, String message) {
        try {
            FeedItem messagePost = new FeedItem();
            messagePost.ParentId = channelId;
            messagePost.Body = message;
            messagePost.Type = 'TextPost';
            
            insert messagePost;
            
            System.debug('✅ 채널 메시지 발송 완료');
            return true;
            
        } catch (Exception e) {
            System.debug('❌ 메시지 발송 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Order Product 자동화 완료 알림
     */
    public static Boolean notifyOrderProductAutomation(String channelId, String orderId, String status) {
        try {
            String automationMessage = '🤖 Order Product 자동화 업데이트\n\n';
            automationMessage += '📋 Order: ' + orderId + '\n';
            automationMessage += '⚡ 상태: ' + status + '\n';
            automationMessage += '🕒 시간: ' + System.now().format('yyyy-MM-dd HH:mm:ss') + '\n\n';
            
            if(status == 'Completed') {
                automationMessage += '✅ 모든 Order Product가 성공적으로 생성되었습니다!\n';
                automationMessage += '📄 PDF 문서가 생성되어 이메일로 발송되었습니다.\n';
            } else if(status == 'In Progress') {
                automationMessage += '⏳ Order Product 생성이 진행 중입니다...\n';
            } else if(status == 'Failed') {
                automationMessage += '❌ Order Product 생성 중 오류가 발생했습니다.\n';
                automationMessage += '🔧 시스템 관리자에게 문의하세요.\n';
            }
            
            automationMessage += '\n#OrderAutomation #시스템알림';
            
            return sendChannelMessage(channelId, automationMessage);
            
        } catch (Exception e) {
            System.debug('❌ 자동화 알림 오류: ' + e.getMessage());
            return false;
        }
    }
}
