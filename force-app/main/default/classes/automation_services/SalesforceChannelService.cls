/**
 * @description Salesforce Channels 간소화 버전
 * @author JH Moon
 * @created 2025-07-22
 */
public with sharing class SalesforceChannelService {
    
    /**
     * Order용 Chatter Group 채널 생성
     */
    public static Boolean createOrderChannel(Order orderInfo) {
        try {
            System.debug('📢 Order Channel 생성 시작: ' + orderInfo.OrderNumber);
            
            // 1. Chatter Group 생성
            CollaborationGroup channelGroup = new CollaborationGroup();
            channelGroup.Name = 'Order-' + orderInfo.OrderNumber;
            channelGroup.Description = 'Order ' + orderInfo.OrderNumber + ' 전용 채널';
            channelGroup.CollaborationType = 'Private';
            channelGroup.IsArchived = false;
            channelGroup.CanHaveGuests = false;
            
            insert channelGroup;
            
            // 2. 멤버 추가
            addGroupMembers(channelGroup.Id, orderInfo);
            
            // 3. 환영 메시지
            postWelcomeMessage(channelGroup.Id, orderInfo);
            
            System.debug('✅ Order Channel 생성 완료: ' + channelGroup.Id);
            return true;
            
        } catch (Exception e) {
            System.debug('❌ Order Channel 생성 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * 그룹 멤버 추가
     */
    private static void addGroupMembers(String groupId, Order orderInfo) {
        try {
            List<CollaborationGroupMember> members = new List<CollaborationGroupMember>();
            
            // Order Owner 추가
            CollaborationGroupMember ownerMember = new CollaborationGroupMember();
            ownerMember.CollaborationGroupId = groupId;
            ownerMember.MemberId = orderInfo.OwnerId;
            ownerMember.CollaborationRole = 'Admin';
            members.add(ownerMember);
            
            // Account Owner 추가 (다른 경우)
            if (orderInfo.Account.OwnerId != orderInfo.OwnerId) {
                CollaborationGroupMember accountMember = new CollaborationGroupMember();
                accountMember.CollaborationGroupId = groupId;
                accountMember.MemberId = orderInfo.Account.OwnerId;
                accountMember.CollaborationRole = 'Standard';
                members.add(accountMember);
            }
            
            insert members;
            System.debug('✅ 그룹 멤버 추가 완료: ' + members.size() + '명');
            
        } catch (Exception e) {
            System.debug('❌ 그룹 멤버 추가 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 환영 메시지 포스트
     */
    private static void postWelcomeMessage(String groupId, Order orderInfo) {
        try {
            String message = '🎉 Order ' + orderInfo.OrderNumber + ' 채널에 오신 것을 환영합니다!\n\n';
            message += '📋 주문 정보:\n';
            message += '• 고객: ' + orderInfo.Account.Name + '\n';
            message += '• 총액: ₩' + orderInfo.TotalAmount.format() + '\n';
            message += '• 상태: ' + orderInfo.Status + '\n';
            message += '• 담당자: ' + orderInfo.Owner.Name + '\n\n';
            message += '💬 이 채널에서 주문 관련 모든 소통을 진행하세요!';
            
            FeedItem post = new FeedItem();
            post.ParentId = groupId;
            post.Body = message;
            post.Type = 'TextPost';
            
            insert post;
            
            System.debug('✅ 환영 메시지 포스트 완료');
            
        } catch (Exception e) {
            System.debug('❌ 환영 메시지 포스트 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 채널에 메시지 발송
     */
    public static Boolean sendChannelMessage(String channelId, String message) {
        try {
            FeedItem post = new FeedItem();
            post.ParentId = channelId;
            post.Body = message;
            post.Type = 'TextPost';
            
            insert post;
            return true;
            
        } catch (Exception e) {
            System.debug('❌ 채널 메시지 발송 오류: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Order Product 자동화 알림
     */
    public static void notifyOrderProductAutomation(List<Order> orders) {
        try {
            for (Order order : orders) {
                List<CollaborationGroup> groups = [
                    SELECT Id 
                    FROM CollaborationGroup 
                    WHERE Name = :('Order-' + order.OrderNumber)
                    LIMIT 1
                ];
                
                if (!groups.isEmpty()) {
                    String message = '🤖 Order Product 자동화 완료!\n\n';
                    message += '• Order: ' + order.OrderNumber + '\n';
                    message += '• OrderProduct 생성 완료\n';
                    message += '• PDF 문서 생성 완료\n';
                    message += '• 채널 활성화 완료\n\n';
                    message += '📎 관련 문서를 확인해주세요.';
                    
                    sendChannelMessage(groups[0].Id, message);
                }
            }
        } catch (Exception e) {
            System.debug('❌ Order Product 자동화 알림 오류: ' + e.getMessage());
        }
    }
}
