// Order 00000158 Asset 생성 테스트 스크립트
// 완납 완료된 Order에 대해 Asset 자동 생성 실행

try {
    System.debug('=== Order 00000158 Asset 생성 테스트 시작 ===');
    
    // 1. Order 00000158 조회
    List<Order> orders = [
        SELECT Id, OrderNumber, AccountId, Account.Name, Contact__c, 
               TotalAmount, ActivatedDate, OrderStartDate, OrderEndDate,
               Payment_Method__c, OwnerId, Owner.Name, Status
        FROM Order 
        WHERE OrderNumber = '00000158'
        LIMIT 1
    ];
    
    if (orders.isEmpty()) {
        System.debug('❌ Order 00000158을 찾을 수 없습니다.');
        return;
    }
    
    Order order = orders[0];
    System.debug('📋 Order 정보:');
    System.debug('- Order Number: ' + order.OrderNumber);
    System.debug('- Account: ' + order.Account.Name);
    System.debug('- Total Amount: ₩' + order.TotalAmount);
    System.debug('- Owner: ' + order.Owner.Name);
    System.debug('- Status: ' + order.Status);
    
    // 2. Payment Schedule 상태 확인
    List<Payment_Schedule__c> schedules = [
        SELECT Id, Name, Payment_Status__c, Amount__c, Due_Date__c
        FROM Payment_Schedule__c 
        WHERE Order__c = :order.Id
        ORDER BY Due_Date__c
    ];
    
    System.debug('\n📅 Payment Schedule 현황:');
    Integer totalSchedules = schedules.size();
    Integer completedSchedules = 0;
    
    for (Payment_Schedule__c schedule : schedules) {
        System.debug('- ' + schedule.Name + ': ' + schedule.Payment_Status__c + ' (₩' + schedule.Amount__c + ')');
        if (schedule.Payment_Status__c == '완납') {
            completedSchedules++;
        }
    }
    
    System.debug('완납 진행률: ' + completedSchedules + '/' + totalSchedules + ' (' + 
                (totalSchedules > 0 ? (completedSchedules * 100 / totalSchedules) : 0) + '%)');
    
    // 3. 기존 Asset 확인
    List<Asset> existingAssets = [
        SELECT Id, Name, Status, PurchaseDate, UsageEndDate
        FROM Asset 
        WHERE AccountId = :order.AccountId 
        AND Name LIKE '%00000158%'
    ];
    
    System.debug('\n🏷️ 기존 Asset 확인:');
    if (existingAssets.isEmpty()) {
        System.debug('- 기존 Asset 없음');
    } else {
        for (Asset asset : existingAssets) {
            System.debug('- Asset: ' + asset.Name + ' (Status: ' + asset.Status + ')');
        }
    }
    
    // 4. Asset 생성 실행
    System.debug('\n🚀 Asset 생성 실행...');
    Asset createdAsset = OrderAssetCreationService.createAssetForOrder(order.Id);
    
    if (createdAsset != null) {
        System.debug('✅ Asset 생성 성공!');
        System.debug('📋 생성된 Asset 정보:');
        
        // 생성된 Asset 재조회 (ID 포함)
        List<Asset> newAssets = [
            SELECT Id, Name, AccountId, ContactId, Product2Id, Status,
                   PurchaseDate, InstallDate, UsageEndDate, Price, Quantity, Description
            FROM Asset 
            WHERE Id = :createdAsset.Id
        ];
        
        if (!newAssets.isEmpty()) {
            Asset asset = newAssets[0];
            System.debug('- Asset ID: ' + asset.Id);
            System.debug('- Asset Name: ' + asset.Name);
            System.debug('- Account ID: ' + asset.AccountId);
            System.debug('- Contact ID: ' + asset.ContactId);
            System.debug('- Product ID: ' + asset.Product2Id);
            System.debug('- Status: ' + asset.Status);
            System.debug('- Purchase Date: ' + asset.PurchaseDate);
            System.debug('- Install Date: ' + asset.InstallDate);
            System.debug('- Usage End Date: ' + asset.UsageEndDate);
            System.debug('- Price: ₩' + asset.Price);
            System.debug('- Quantity: ' + asset.Quantity);
            System.debug('- Description: ' + asset.Description);
        }
        
        // 5. 생성된 Task 확인
        System.debug('\n📋 생성된 Task 확인:');
        List<Task> relatedTasks = [
            SELECT Id, Subject, Description, ActivityDate, Priority, Status, OwnerId
            FROM Task 
            WHERE WhatId = :createdAsset.Id
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
        
        if (relatedTasks.isEmpty()) {
            System.debug('- 관련 Task 없음');
        } else {
            for (Task task : relatedTasks) {
                System.debug('- Task: ' + task.Subject + ' (Due: ' + task.ActivityDate + ', Priority: ' + task.Priority + ')');
            }
        }
        
        // 6. Salesforce 채널 알림 확인
        System.debug('\n💬 Salesforce 채널 알림 확인:');
        List<CollaborationGroup> channels = [
            SELECT Id, Name FROM CollaborationGroup 
            WHERE Name LIKE '%00000158%'
            LIMIT 1
        ];
        
        if (!channels.isEmpty()) {
            System.debug('- 채널 발견: ' + channels[0].Name);
            System.debug('- Asset 생성 알림이 채널에 게시되었습니다.');
        } else {
            System.debug('- 관련 채널 없음');
        }
        
    } else {
        System.debug('❌ Asset 생성 실패 또는 이미 존재함');
        
        // 실패 원인 분석
        if (completedSchedules < totalSchedules) {
            System.debug('💡 실패 원인: 아직 완납이 완료되지 않음 (' + completedSchedules + '/' + totalSchedules + ')');
        }
        
        if (!existingAssets.isEmpty()) {
            System.debug('💡 실패 원인: 이미 Asset이 존재함');
        }
    }
    
    System.debug('\n=== Order 00000158 Asset 생성 테스트 완료 ===');
    
} catch (Exception e) {
    System.debug('❌ Asset 생성 테스트 중 오류: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
}
