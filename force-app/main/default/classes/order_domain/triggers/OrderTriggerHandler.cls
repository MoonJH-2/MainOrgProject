/**
 * @description       : 
 * @author            : JH Moon
 * @last modified on  : 07-12-2025
 * @last modified by  : Hyowon Hong
**/
public with sharing class OrderTriggerHandler extends TriggerHandler {
    /** 
     * 현재 핸들러 이름 반환 
     * isFirstRun() 및 바이패스 기능(bypass, clearBypass)이 각 핸들러를 고유하게 식별하기 위해 필요
    **/
    protected override String getHandlerName() {
        return 'OrderTriggerHandler';
    }

    protected override void beforeInsert(List<SObject> news) {
        System.debug('Order Trigger Before Insert Start');
        
        List<Order> newOrders = (List<Order>) news;

        Set<Id> accountId = new Set<Id>();
        for (Order ord : newOrders) {
            if(ord.AccountId != null){
                accountId.add(ord.AccountId);
            }
        }
        
        if(!accountId.isEmpty()){
            // Map<Id, Account> convertAccMap = new Map<Id,Account>();
            Id activeRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ActiveCustomer').getRecordTypeId();

            Map<Id, Account> accMap = new Map<Id, Account>();
            List<Account> accList = [
                SELECT  Id
                        , BusinessNumberVerified__c
                        , RecordTypeId
                FROM Account
                WHERE Id IN :accountId
            ];

            for(Account acc : accList) {
                accMap.put(acc.Id, acc);
            }

            List<Account> updateAccRecordType = new List<Account>();
            for(Order ord : newOrders) {
                if(ord.AccountId != null){
                    Account relatedAcc = accMap.get(ord.AccountId);
                    if(relatedAcc != null) {
                        if(relatedAcc != null && !relatedAcc.BusinessNumberVerified__c) {
                            ord.addError('사업자 번호가 검증되지 않았습니다. 주문을 생성할 수 없습니다.');
                        } else if (relatedAcc.RecordTypeId != activeRecordType){
                            relatedAcc.RecordTypeId = activeRecordType;
                            updateAccRecordType.add(relatedAcc);
                        }
                    }
                }
            }

            if(!updateAccRecordType.isEmpty()){
                update updateAccRecordType;
            }
        }

        System.debug('Order Trigger Before Insert Finish');
    }
    
    // after insert 로직
    protected override void afterInsert(List<SObject> news, Map<Id, SObject> newMap) {
        Set<Id> orderIdsToProcess = new Set<Id>();
        List<Id> orderIdsForProductRegistration = new List<Id>();
        List<Order> newOrders = (List<Order>)news;
        
        // 🚀 모든 새 Order에 대해 Salesforce 채널 자동 생성
        List<Id> allNewOrderIds = new List<Id>();
        
        for (Order ord : newOrders) {
            // 모든 Order ID 수집 (채널 생성용)
            allNewOrderIds.add(ord.Id);
            
            // 납부 방식이 지정된 경우에만 처리 대상에 추가
            if (String.isNotBlank(ord.Payment_Method__c)) {
                orderIdsToProcess.add(ord.Id);
            }
            
            // Opportunity Product 자동 등록 대상 (Opportunity가 연결되어 있는 경우)
            if (ord.OpportunityId != null) {
                orderIdsForProductRegistration.add(ord.Id);
            }
        }
        
        // 🎯 모든 새 Order에 대해 Salesforce 채널 생성 (최우선 실행)
        if (!allNewOrderIds.isEmpty()) {
            try {
                System.debug('🚀 모든 새 Order에 대해 Salesforce 채널 자동 생성: ' + allNewOrderIds.size() + '개');
                
                for(Id orderId : allNewOrderIds) {
                    try {
                        String channelId = SimpleSalesforceChannelService.createOrderChannel(orderId);
                        
                        if(channelId != null) {
                            System.debug('✅ Order ' + orderId + ' Salesforce 채널 자동 생성 완료: ' + channelId);
                            
                            // Order Owner를 채널에 자동 추가 및 환영 메시지
                            List<Order> orderForOwner = [SELECT OwnerId, OrderNumber FROM Order WHERE Id = :orderId LIMIT 1];
                            if(!orderForOwner.isEmpty()) {
                                SimpleSalesforceChannelService.addUserToChannel(channelId, orderForOwner[0].OwnerId);
                                SimpleSalesforceChannelService.postWelcomeMessage(channelId, orderId, orderForOwner[0].OrderNumber);
                            }
                        }
                    } catch(Exception channelError) {
                        System.debug('❌ Order ' + orderId + ' 채널 생성 오류: ' + channelError.getMessage());
                    }
                }
                
            } catch (Exception e) {
                System.debug('❌ Salesforce 채널 자동 생성 실패: ' + e.getMessage());
            }
        }
        
        // 서비스 호출
        if (!orderIdsToProcess.isEmpty()) {
            PaymentScheduleService.createSchedules(orderIdsToProcess);
        }
        
        // Opportunity Product 자동 등록
        if (!orderIdsForProductRegistration.isEmpty()) {
            try {
                OrderProductAutoRegistrationService.batchRegisterOpportunityProducts(orderIdsForProductRegistration);
                System.debug('Opportunity Product 자동 등록 완료: ' + orderIdsForProductRegistration.size() + '개 Order');
            } catch (Exception e) {
                System.debug('Opportunity Product 자동 등록 실패: ' + e.getMessage());
            }
        }
        
        // Sales 앱 Order 생성 알림 발송
        try {
            // Order ID Set 생성
            Set<Id> orderIds = new Set<Id>();
            for (Order ord : newOrders) {
                orderIds.add(ord.Id);
            }
            
            // Account 정보 포함해서 조회
            List<Order> ordersWithAccount = [
                SELECT Id, OrderNumber, TotalAmount, Account.Name
                FROM Order 
                WHERE Id IN :orderIds
            ];
            
            if (!ordersWithAccount.isEmpty()) {
                System.debug('🎉 Order 생성 알림 발송 중: ' + ordersWithAccount.size() + '개');
                OrderNotificationService.notifyOrderCreated(ordersWithAccount);
                System.debug('✅ Order 생성 알림 발송 완료');
            }
        } catch (Exception e) {
            System.debug('❌ Order 생성 알림 실패: ' + e.getMessage());
            System.debug('❌ 스택 트레이스: ' + e.getStackTraceString());
        }
    }

    // after update 로직
    protected override void afterUpdate(List<SObject> news, List<SObject> olds, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        Set<Id> orderIdsToProcess = new Set<Id>();
        List<Id> orderIdsForActivation = new List<Id>();
        Set<Id> orderIdsForAutomation = new Set<Id>();
        List<Id> orderIdsForChannelCreation = new List<Id>(); // 🆕 채널 생성 대상
        Map<Id, Order> oldOrderMap = (Map<Id, Order>)oldMap;

        for (Order newOrd : (List<Order>)news) {
            Order oldOrd = oldOrderMap.get(newOrd.Id);

            // 납부 방식 또는 총액이 변경된 경우 처리 대상에 추가
            if (newOrd.Payment_Method__c != oldOrd.Payment_Method__c || newOrd.TotalAmount != oldOrd.TotalAmount) {
                orderIdsToProcess.add(newOrd.Id);
            }
            
            // Order Products가 추가되어 TotalAmount가 0에서 양수로 변경되고 
            // Status가 여전히 Draft인 경우 활성화 대상
            if (oldOrd.TotalAmount == 0 && newOrd.TotalAmount > 0 && newOrd.Status == 'Draft') {
                orderIdsForActivation.add(newOrd.Id);
            }
            
            // Order Product 자동화 처리 대상
            // 1. Order Products가 새로 등록된 경우 (TotalAmount 0 → 양수)
            // 2. Status가 Draft → Activated로 변경된 경우
            if ((oldOrd.TotalAmount == 0 && newOrd.TotalAmount > 0) || 
                (oldOrd.Status != 'Activated' && newOrd.Status == 'Activated')) {
                orderIdsForAutomation.add(newOrd.Id);
            }
            
            // 🆕 Slack Channel ID가 지연되어 업데이트된 경우 Salesforce 채널 생성
            // Slack 필드가 새로 입력되었고 Notification Status가 "Not Created"인 경우
            if (String.isBlank(oldOrd.Slack_Channel_ID__c) && 
                String.isNotBlank(newOrd.Slack_Channel_ID__c) &&
                (newOrd.Slack_Notification_Status__c == 'Not Created' || String.isBlank(newOrd.Slack_Notification_Status__c))) {
                orderIdsForChannelCreation.add(newOrd.Id);
                System.debug('🎯 Slack Channel ID 지연 업데이트 감지 - Order: ' + newOrd.OrderNumber);
            }
            
            // 🔧 Slack Channel 활성화 조건 확인 및 자동 수정
            // Slack Channel ID는 있지만 Notification Status가 "Not Created"인 경우
            if (String.isNotBlank(newOrd.Slack_Channel_ID__c) && 
                newOrd.Slack_Notification_Status__c == 'Not Created') {
                
                // Notification Status를 "Created"로 업데이트하여 Slack Channel 활성화
                Order orderToActivate = new Order();
                orderToActivate.Id = newOrd.Id;
                orderToActivate.Slack_Notification_Status__c = 'Created';
                
                // Webhook URL이 비어있다면 기본값 설정
                if (String.isBlank(newOrd.Slack_Webhook_URL__c)) {
                    orderToActivate.Slack_Webhook_URL__c = 'https://hooks.slack.com/services/default';
                }
                
                try {
                    update orderToActivate;
                    System.debug('✅ Order ' + newOrd.OrderNumber + ' Slack Channel 자동 활성화 완료');
                } catch (Exception activationError) {
                    System.debug('❌ Slack Channel 활성화 오류: ' + activationError.getMessage());
                }
            }
        }

        // 서비스 호출
        if (!orderIdsToProcess.isEmpty()) {
            PaymentScheduleService.createSchedules(orderIdsToProcess);
        }
        
        // Order 자동 활성화
        if (!orderIdsForActivation.isEmpty()) {
            try {
                List<Order> ordersToActivate = new List<Order>();
                for (Id orderId : orderIdsForActivation) {
                    // Order Products가 실제로 존재하는지 확인
                    List<OrderItem> orderProducts = [
                        SELECT Id FROM OrderItem WHERE OrderId = :orderId LIMIT 1
                    ];
                    
                    if (!orderProducts.isEmpty()) {
                        Order orderToUpdate = new Order();
                        orderToUpdate.Id = orderId;
                        orderToUpdate.Status = 'Activated';
                        ordersToActivate.add(orderToUpdate);
                    }
                }
                
                if (!ordersToActivate.isEmpty()) {
                    update ordersToActivate;
                    System.debug('Order 자동 활성화 완료: ' + ordersToActivate.size() + '개');
                }
                
            } catch (Exception e) {
                System.debug('Order 자동 활성화 실패: ' + e.getMessage());
            }
        }
        
        // Order Product 자동화 처리 (PDF 생성 + Salesforce 채널 생성)
        if (!orderIdsForAutomation.isEmpty()) {
            try {
                System.debug('🤖 Order Product 자동화 트리거: ' + orderIdsForAutomation.size() + '개 Order');
                OrderProductAutomationService.processOrderProductAutomation(orderIdsForAutomation);
                
                // Salesforce 채널 생성
                for(String orderId : orderIdsForAutomation) {
                    try {
                        String channelId = SimpleSalesforceChannelService.createOrderChannel(orderId);
                        
                        if(channelId != null) {
                            System.debug('✅ Salesforce 채널 생성 완료: ' + channelId);
                        }
                    } catch(Exception channelError) {
                        System.debug('❌ Salesforce 채널 생성 오류: ' + channelError.getMessage());
                    }
                }
                
            } catch (Exception e) {
                System.debug('❌ Order Product 자동화 실패: ' + e.getMessage());
            }
        }
        
        // 🆕 Slack Channel ID 지연 업데이트로 인한 Salesforce 채널 생성
        if (!orderIdsForChannelCreation.isEmpty()) {
            try {
                System.debug('🚀 Slack 지연 업데이트 감지 - Salesforce 채널 생성: ' + orderIdsForChannelCreation.size() + '개');
                
                for(Id orderId : orderIdsForChannelCreation) {
                    try {
                        // 기존 채널 존재 여부 확인
                        List<Order> orderInfo = [SELECT OrderNumber FROM Order WHERE Id = :orderId LIMIT 1];
                        if(!orderInfo.isEmpty()) {
                            String orderNumber = orderInfo[0].OrderNumber;
                            
                            List<CollaborationGroup> existingChannels = [
                                SELECT Id FROM CollaborationGroup 
                                WHERE Name LIKE :('%' + orderNumber + '%')
                                LIMIT 1
                            ];
                            
                            if(existingChannels.isEmpty()) {
                                String channelId = SimpleSalesforceChannelService.createOrderChannel(orderId);
                                
                                if(channelId != null) {
                                    System.debug('✅ 지연 업데이트 Salesforce 채널 생성 완료 - Order: ' + orderNumber + ', Channel: ' + channelId);
                                    
                                    // Order Owner를 채널에 자동 추가
                                    List<Order> orderForOwner = [SELECT OwnerId FROM Order WHERE Id = :orderId LIMIT 1];
                                    if(!orderForOwner.isEmpty()) {
                                        SimpleSalesforceChannelService.addUserToChannel(channelId, orderForOwner[0].OwnerId);
                                        System.debug('✅ Order Owner 채널 추가 완료');
                                    }
                                    
                                    // 환영 메시지 게시 (orderNumber 파라미터 추가)
                                    SimpleSalesforceChannelService.postWelcomeMessage(channelId, orderId, orderNumber);
                                }
                            } else {
                                System.debug('ℹ️ Salesforce 채널이 이미 존재함 - Order: ' + orderNumber);
                            }
                        }
                    } catch(Exception channelError) {
                        System.debug('❌ 지연 업데이트 채널 생성 오류: ' + channelError.getMessage());
                    }
                }
                
            } catch (Exception e) {
                System.debug('❌ 지연 업데이트 Salesforce 채널 생성 실패: ' + e.getMessage());
            }
        }
    }

}