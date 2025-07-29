/**
 * @description Slack 채널 생성 및 관리 서비스
 * @author JH Moon
 * @last modified on 07-21-2025
 * @last modified by JH Moon
 */
public with sharing class SlackChannelService {
    
    // Slack API 설정 (실제 구현 시 Custom Setting에서 관리)
    private static final String SLACK_API_BASE_URL = 'https://slack.com/api/';
    private static final String CHANNEL_CREATE_ENDPOINT = 'conversations.create';
    private static final String MESSAGE_POST_ENDPOINT = 'chat.postMessage';
    
    /**
     * Order용 Slack 채널 생성
     */
    public static Boolean createOrderChannel(Order orderInfo) {
        try {
            System.debug('💬 Slack 채널 생성 시작: Order ' + orderInfo.OrderNumber);
            
            // 1. Slack Bot Token 조회
            String botToken = getSlackBotToken();
            if (String.isBlank(botToken)) {
                System.debug('❌ Slack Bot Token이 설정되지 않았습니다.');
                return false;
            }
            
            // 2. 채널 이름 생성 (Order Number 기반)
            String channelName = generateChannelName(orderInfo.OrderNumber);
            
            // 3. Slack API 호출 - 채널 생성
            String channelId = createSlackChannel(channelName, orderInfo, botToken);
            
            if (String.isNotBlank(channelId)) {
                // 4. Order에 Slack 정보 업데이트
                updateOrderSlackInfo(orderInfo.Id, channelId, channelName);
                
                // 5. 환영 메시지 발송
                sendWelcomeMessage(channelId, orderInfo, botToken);
                
                System.debug('✅ Slack 채널 생성 완료: #' + channelName + ' (ID: ' + channelId + ')');
                return true;
            } else {
                System.debug('❌ Slack 채널 생성 실패: Order ' + orderInfo.OrderNumber);
                return false;
            }
            
        } catch (Exception e) {
            System.debug('❌ Slack 채널 생성 오류: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            return false;
        }
    }
    
    /**
     * Slack API를 통한 채널 생성
     */
    private static String createSlackChannel(String channelName, Order orderInfo, String botToken) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(SLACK_API_BASE_URL + CHANNEL_CREATE_ENDPOINT);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + botToken);
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(10000); // 10초 타임아웃
            
            // 요청 페이로드 생성
            Map<String, Object> payload = new Map<String, Object>{
                'name' => channelName,
                'is_private' => false,
                'is_channel' => true
            };
            
            request.setBody(JSON.serialize(payload));
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                Boolean ok = (Boolean)responseBody.get('ok');
                
                if (ok) {
                    Map<String, Object> channel = (Map<String, Object>)responseBody.get('channel');
                    String channelId = (String)channel.get('id');
                    
                    System.debug('✅ Slack 채널 생성 API 성공: ' + channelId);
                    return channelId;
                } else {
                    String error = (String)responseBody.get('error');
                    System.debug('❌ Slack API 오류: ' + error);
                    
                    // 채널이 이미 존재하는 경우 기존 채널 ID 반환
                    if (error == 'name_taken') {
                        System.debug('⚠️ 채널이 이미 존재합니다. 기존 채널을 사용합니다.');
                        return getExistingChannelId(channelName, botToken);
                    }
                    return null;
                }
            } else {
                System.debug('❌ Slack API HTTP 오류: ' + response.getStatusCode() + ' - ' + response.getBody());
                return null;
            }
            
        } catch (Exception e) {
            System.debug('❌ Slack 채널 생성 API 호출 오류: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * 기존 채널 ID 조회 (채널명이 중복인 경우)
     */
    private static String getExistingChannelId(String channelName, String botToken) {
        try {
            // conversations.list API를 통해 기존 채널 조회
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(SLACK_API_BASE_URL + 'conversations.list?types=public_channel&limit=1000');
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + botToken);
            request.setTimeout(10000);
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                Boolean ok = (Boolean)responseBody.get('ok');
                
                if (ok) {
                    List<Object> channels = (List<Object>)responseBody.get('channels');
                    for (Object channelObj : channels) {
                        Map<String, Object> channel = (Map<String, Object>)channelObj;
                        if (channelName.equals((String)channel.get('name'))) {
                            return (String)channel.get('id');
                        }
                    }
                }
            }
            
            return null;
            
        } catch (Exception e) {
            System.debug('❌ 기존 채널 ID 조회 오류: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * 채널명 생성 (Order Number 기반)
     */
    private static String generateChannelName(String orderNumber) {
        // Slack 채널명 규칙: 소문자, 숫자, 하이픈, 언더스코어만 허용
        return orderNumber.toLowerCase().replaceAll('[^a-z0-9\\-_]', '');
    }
    
    /**
     * Order에 Slack 정보 업데이트
     */
    private static void updateOrderSlackInfo(Id orderId, String channelId, String channelName) {
        try {
            Order orderToUpdate = new Order();
            orderToUpdate.Id = orderId;
            orderToUpdate.Slack_Channel_ID__c = channelId;
            orderToUpdate.Slack_Channel_Name__c = channelName;
            orderToUpdate.Slack_Notification_Status__c = 'Created';
            
            update orderToUpdate;
            
            System.debug('✅ Order Slack 정보 업데이트 완료: ' + channelName);
            
        } catch (Exception e) {
            System.debug('❌ Order Slack 정보 업데이트 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 환영 메시지 발송
     */
    private static void sendWelcomeMessage(String channelId, Order orderInfo, String botToken) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(SLACK_API_BASE_URL + MESSAGE_POST_ENDPOINT);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + botToken);
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(10000);
            
            // 환영 메시지 생성
            String welcomeMessage = createWelcomeMessage(orderInfo);
            
            Map<String, Object> payload = new Map<String, Object>{
                'channel' => channelId,
                'text' => welcomeMessage,
                'username' => 'Salesforce Bot',
                'icon_emoji' => ':robot_face:'
            };
            
            request.setBody(JSON.serialize(payload));
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                Boolean ok = (Boolean)responseBody.get('ok');
                
                if (ok) {
                    System.debug('✅ 환영 메시지 발송 완료');
                } else {
                    System.debug('❌ 환영 메시지 발송 실패: ' + responseBody.get('error'));
                }
            } else {
                System.debug('❌ 환영 메시지 HTTP 오류: ' + response.getStatusCode());
            }
            
        } catch (Exception e) {
            System.debug('❌ 환영 메시지 발송 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 환영 메시지 내용 생성
     */
    private static String createWelcomeMessage(Order orderInfo) {
        String message = '🎉 *Order ' + orderInfo.OrderNumber + ' 채널이 생성되었습니다!*\n\n';
        message += '📋 *Order 정보*\n';
        message += '• Customer: ' + orderInfo.Account.Name + '\n';
        message += '• Amount: ₩' + orderInfo.TotalAmount.format() + '\n';
        message += '• Payment Method: ' + orderInfo.Payment_Method__c + '\n';
        message += '• Status: ' + orderInfo.Status + '\n\n';
        
        // Order Items 정보 추가
        if (!orderInfo.OrderItems.isEmpty()) {
            message += '🛒 *Products*\n';
            for (OrderItem item : orderInfo.OrderItems) {
                message += '• ' + item.Product2.Name + ' (Qty: ' + item.Quantity + ')\n';
            }
            message += '\n';
        }
        
        message += '📎 *관련 문서*\n';
        message += '• Order Product 상세서.pdf\n';
        message += '• 납부 일정서.pdf\n\n';
        message += '💬 이 채널에서 주문과 관련된 모든 커뮤니케이션을 진행하세요!\n';
        message += '문의사항이 있으시면 언제든 메시지를 남겨주세요. 📞';
        
        return message;
    }
    
    /**
     * Slack Bot Token 조회 (Custom Setting에서 관리)
     */
    private static String getSlackBotToken() {
        try {
            // 실제 구현 시 Custom Setting 또는 Custom Metadata에서 토큰 조회
            // 현재는 더미 토큰 반환 (테스트용)
            
            // Custom Setting 예시:
            // Slack_Settings__c settings = Slack_Settings__c.getInstance();
            // return settings.Bot_Token__c;
            
            // 테스트용 더미 토큰 (실제 구현 시 실제 토큰으로 교체 필요)
            System.debug('⚠️ 테스트 모드: 더미 Slack Bot Token 사용');
            return 'xoxb-test-token-for-development';
            
        } catch (Exception e) {
            System.debug('❌ Slack Bot Token 조회 오류: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * 채널에 메시지 발송 (공통 메서드)
     */
    public static Boolean sendChannelMessage(String channelId, String message) {
        try {
            String botToken = getSlackBotToken();
            if (String.isBlank(botToken)) {
                return false;
            }
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(SLACK_API_BASE_URL + MESSAGE_POST_ENDPOINT);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + botToken);
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(10000);
            
            Map<String, Object> payload = new Map<String, Object>{
                'channel' => channelId,
                'text' => message,
                'username' => 'Salesforce Bot',
                'icon_emoji' => ':robot_face:'
            };
            
            request.setBody(JSON.serialize(payload));
            
            HttpResponse response = http.send(request);
            return response.getStatusCode() == 200;
            
        } catch (Exception e) {
            System.debug('❌ Slack 메시지 발송 오류: ' + e.getMessage());
            return false;
        }
    }
}
