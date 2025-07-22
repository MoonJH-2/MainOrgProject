/**
 * @description Order 완납 시 Asset 자동 생성 서비스
 * @author JH Moon
 * @created 2025-07-22
 */
public with sharing class OrderAssetCreationService {
    
    /**
     * Order 완납 시 Asset 생성 (메인 메서드)
     */
    public static List<Asset> createAssetsForCompletedOrders(List<Id> orderIds) {
        List<Asset> createdAssets = new List<Asset>();
        
        try {
            // 1. Order 정보 조회 (Payment Schedule 포함)
            List<Order> ordersWithDetails = getOrdersWithPaymentDetails(orderIds);
            
            for (Order order : ordersWithDetails) {
                // 2. 완납 여부 확인
                if (isOrderFullyPaid(order)) {
                    // 3. 기존 Asset 존재 여부 확인
                    if (!hasExistingAsset(order.Id)) {
                        // 4. Asset 생성
                        Asset newAsset = createAssetFromOrder(order);
                        if (newAsset != null) {
                            createdAssets.add(newAsset);
                        }
                    } else {
                        System.debug('ℹ️ Order ' + order.OrderNumber + '에 대한 Asset이 이미 존재합니다.');
                    }
                }
            }
            
            // 5. Asset 일괄 생성
            if (!createdAssets.isEmpty()) {
                insert createdAssets;
                System.debug('✅ Asset 생성 완료: ' + createdAssets.size() + '개');
                
                // 6. Asset 생성 후 후속 작업
                processPostAssetCreation(createdAssets);
            }
            
        } catch (Exception e) {
            System.debug('❌ Asset 생성 중 오류: ' + e.getMessage());
            System.debug('스택 트레이스: ' + e.getStackTraceString());
        }
        
        return createdAssets;
    }
    
    /**
     * Order 상세 정보 조회 (Payment Schedule 포함)
     */
    private static List<Order> getOrdersWithPaymentDetails(List<Id> orderIds) {
        return [
            SELECT Id, OrderNumber, AccountId, Contact__c, OwnerId, Owner.Name,
                   ActivatedDate, OrderStartDate, OrderEndDate, TotalAmount, Status,
                   Payment_Method__c, Account.Name,
                   (SELECT Id, Payment_Status__c, Amount__c, Due_Date__c 
                    FROM Payment_Schedules__r),
                   (SELECT Id, Product2Id, Product2.Name, Quantity, UnitPrice, TotalPrice
                    FROM OrderItems)
            FROM Order 
            WHERE Id IN :orderIds
        ];
    }
    
    /**
     * Order 완납 여부 확인
     */
    private static Boolean isOrderFullyPaid(Order order) {
        if (order.Payment_Schedules__r.isEmpty()) {
            return false;
        }
        
        Integer totalSchedules = order.Payment_Schedules__r.size();
        Integer completedSchedules = 0;
        
        for (Payment_Schedule__c schedule : order.Payment_Schedules__r) {
            if (schedule.Payment_Status__c == '완납') {
                completedSchedules++;
            }
        }
        
        Boolean isFullyPaid = (completedSchedules == totalSchedules);
        System.debug('Order ' + order.OrderNumber + ' 완납 상태: ' + completedSchedules + '/' + totalSchedules + ' = ' + isFullyPaid);
        
        return isFullyPaid;
    }
    
    /**
     * 기존 Asset 존재 여부 확인 (SerialNumber 기반)
     */
    private static Boolean hasExistingAsset(Id orderId) {
        // Order Number로 기존 Asset 확인
        List<Order> orders = [SELECT OrderNumber FROM Order WHERE Id = :orderId LIMIT 1];
        if (orders.isEmpty()) {
            return false;
        }
        
        List<Asset> existingAssets = [
            SELECT Id FROM Asset 
            WHERE SerialNumber = :orders[0].OrderNumber
            LIMIT 1
        ];
        
        return !existingAssets.isEmpty();
    }
    
    /**
     * Order로부터 Asset 생성
     */
    private static Asset createAssetFromOrder(Order order) {
        try {
            Asset newAsset = new Asset();
            
            // 기본 정보
            newAsset.Name = 'Order ' + order.OrderNumber + ' Asset';
            newAsset.AccountId = order.AccountId;
            newAsset.ContactId = order.Contact__c;
            
            // Order 연결 (커스텀 필드 Order__c가 없는 경우 대안)
            newAsset.SerialNumber = order.OrderNumber; // Order Number로 연결
            
            // 날짜 정보
            newAsset.PurchaseDate = order.ActivatedDate != null ? order.ActivatedDate.date() : Date.today();
            newAsset.InstallDate = order.OrderStartDate;
            newAsset.UsageEndDate = order.OrderEndDate;
            
            // 가격 정보
            newAsset.Price = order.TotalAmount;
            
            // 상태 정보
            newAsset.Status = 'Purchased';
            
            // 제품 정보 (OrderItem에서 첫 번째 제품 사용)
            if (!order.OrderItems.isEmpty()) {
                OrderItem firstItem = order.OrderItems[0];
                newAsset.Product2Id = firstItem.Product2Id;
                newAsset.Quantity = Integer.valueOf(firstItem.Quantity);
                
                // Asset Name에 제품명 포함
                if (firstItem.Product2 != null) {
                    newAsset.Name = order.Account.Name + ' - ' + firstItem.Product2.Name;
                }
            }
            
            // 설명 추가 (Order ID도 포함하여 역추적 가능)
            newAsset.Description = 'Order ' + order.OrderNumber + ' 완납으로 생성된 고객 자산\n' +
                                 'Order ID: ' + order.Id + '\n' +
                                 '납부 방식: ' + order.Payment_Method__c + '\n' +
                                 '완납일: ' + Date.today().format() + '\n' +
                                 '담당자: ' + order.Owner.Name;
            
            System.debug('✅ Asset 생성 준비 완료: ' + newAsset.Name);
            return newAsset;
            
        } catch (Exception e) {
            System.debug('❌ Asset 생성 중 오류: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Asset 생성 후 후속 작업
     */
    private static void processPostAssetCreation(List<Asset> createdAssets) {
        try {
            // 1. 영업사원에게 Asset 생성 알림 Task 생성
            List<Task> notificationTasks = new List<Task>();
            
            for (Asset asset : createdAssets) {
                Task assetNotificationTask = new Task();
                assetNotificationTask.Subject = '고객 Asset 생성 완료 - ' + asset.Name;
                assetNotificationTask.Description = '완납 완료로 인한 고객 Asset이 생성되었습니다.\n\n' +
                                                  '📋 Asset: ' + asset.Name + '\n' +
                                                  '💰 가격: ₩' + String.valueOf(asset.Price) + '\n' +
                                                  '📅 구매일: ' + asset.PurchaseDate + '\n' +
                                                  '📅 종료일: ' + asset.UsageEndDate + '\n\n' +
                                                  '💡 갱신 영업 기회를 검토하세요!';
                assetNotificationTask.ActivityDate = Date.today().addDays(7); // 1주일 후
                assetNotificationTask.Priority = 'Normal';
                assetNotificationTask.Status = 'Not Started';
                assetNotificationTask.WhatId = asset.Id; // Asset 연결
                
                // Asset의 Account Owner에게 할당
                List<Account> accounts = [SELECT OwnerId FROM Account WHERE Id = :asset.AccountId LIMIT 1];
                if (!accounts.isEmpty()) {
                    assetNotificationTask.OwnerId = accounts[0].OwnerId;
                }
                
                notificationTasks.add(assetNotificationTask);
            }
            
            if (!notificationTasks.isEmpty()) {
                insert notificationTasks;
                System.debug('✅ Asset 생성 알림 Task 생성 완료: ' + notificationTasks.size() + '개');
            }
            
            // 2. Salesforce 채널에 Asset 생성 알림
            notifyAssetCreationToChannels(createdAssets);
            
            // 3. 갱신 알림 스케줄링 (6개월 전)
            scheduleRenewalReminders(createdAssets);
            
        } catch (Exception e) {
            System.debug('❌ Asset 후속 작업 중 오류: ' + e.getMessage());
        }
    }
    
    /**
     * Salesforce 채널에 Asset 생성 알림
     */
    private static void notifyAssetCreationToChannels(List<Asset> createdAssets) {
        try {
            for (Asset asset : createdAssets) {
                // Order에 연결된 Salesforce 채널 찾기
                List<Order> orders = [SELECT OrderNumber FROM Order WHERE Id = :asset.Order__c LIMIT 1];
                if (!orders.isEmpty()) {
                    String orderNumber = orders[0].OrderNumber;
                    
                    List<CollaborationGroup> channels = [
                        SELECT Id FROM CollaborationGroup 
                        WHERE Name LIKE :('%' + orderNumber + '%')
                        LIMIT 1
                    ];
                    
                    if (!channels.isEmpty()) {
                        String message = '🎉 고객 Asset 생성 완료!\n\n' +
                                       '📋 Asset: ' + asset.Name + '\n' +
                                       '💰 가격: ₩' + String.valueOf(asset.Price) + '\n' +
                                       '📅 구매일: ' + asset.PurchaseDate + '\n' +
                                       '📅 사용 종료일: ' + asset.UsageEndDate + '\n\n' +
                                       '✅ 완납이 완료되어 고객 자산으로 등록되었습니다.\n' +
                                       '💡 갱신 영업 기회를 놓치지 마세요!\n\n' +
                                       '#AssetManagement #고객관리 #갱신영업';
                        
                        SimpleSalesforceChannelService.sendChannelMessage(channels[0].Id, message);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('❌ 채널 알림 중 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 갱신 알림 스케줄링
     */
    private static void scheduleRenewalReminders(List<Asset> createdAssets) {
        try {
            List<Task> renewalTasks = new List<Task>();
            
            for (Asset asset : createdAssets) {
                if (asset.UsageEndDate != null) {
                    // 종료일 6개월 전에 갱신 알림 Task 생성
                    Date reminderDate = asset.UsageEndDate.addMonths(-6);
                    
                    if (reminderDate > Date.today()) {
                        Task renewalTask = new Task();
                        renewalTask.Subject = '갱신 영업 기회 - ' + asset.Name;
                        renewalTask.Description = '고객 Asset 갱신 시점이 다가오고 있습니다.\n\n' +
                                                '📋 Asset: ' + asset.Name + '\n' +
                                                '📅 종료일: ' + asset.UsageEndDate + '\n' +
                                                '💰 기존 가격: ₩' + String.valueOf(asset.Price) + '\n\n' +
                                                '💡 갱신 제안을 준비하세요!';
                        renewalTask.ActivityDate = reminderDate;
                        renewalTask.Priority = 'High';
                        renewalTask.Status = 'Not Started';
                        renewalTask.WhatId = asset.Id;
                        
                        // Asset의 Account Owner에게 할당
                        List<Account> accounts = [SELECT OwnerId FROM Account WHERE Id = :asset.AccountId LIMIT 1];
                        if (!accounts.isEmpty()) {
                            renewalTask.OwnerId = accounts[0].OwnerId;
                        }
                        
                        renewalTasks.add(renewalTask);
                    }
                }
            }
            
            if (!renewalTasks.isEmpty()) {
                insert renewalTasks;
                System.debug('✅ 갱신 알림 Task 스케줄링 완료: ' + renewalTasks.size() + '개');
            }
            
        } catch (Exception e) {
            System.debug('❌ 갱신 알림 스케줄링 중 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 특정 Order의 Asset 생성 (단일)
     */
    public static Asset createAssetForOrder(Id orderId) {
        List<Asset> assets = createAssetsForCompletedOrders(new List<Id>{orderId});
        return assets.isEmpty() ? null : assets[0];
    }
}
