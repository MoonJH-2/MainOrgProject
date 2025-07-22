/**
 * PaymentStatus 완납 시뮬레이션 테스트
 * 실제 PaymentStatus를 완납으로 변경하여 Asset 자동 생성 테스트
 */

System.debug('=== PaymentStatus 완납 시뮬레이션 테스트 ===');

// 1. 모든 Asset의 SerialNumber 가져오기
Set<String> existingAssetSerialNumbers = new Set<String>();
for (Asset ast : [SELECT SerialNumber FROM Asset WHERE SerialNumber != null]) {
    existingAssetSerialNumbers.add(ast.SerialNumber);
}

// 2. Asset이 없는 Order 찾기
List<Order> candidateOrders = [
    SELECT Id, OrderNumber, AccountId, Account.Name, Account.Key_Account__c,
           Account.CustomerPriority__c, TotalAmount
    FROM Order 
    WHERE AccountId != null
    LIMIT 10
];

List<Order> ordersWithoutAssets = new List<Order>();
for (Order ord : candidateOrders) {
    if (!existingAssetSerialNumbers.contains(ord.OrderNumber)) {
        ordersWithoutAssets.add(ord);
    }
}

System.debug('Asset이 없는 Order 개수: ' + ordersWithoutAssets.size());

Order targetOrder = null;
List<PaymentStatus__c> targetPayments = null;

// 미완납 PaymentStatus가 있는 Order 찾기
for (Order ord : ordersWithoutAssets) {
    List<PaymentStatus__c> payments = [
        SELECT Id, InstallmentNumber__c, Amount__c, Status__c, DueDate__c
        FROM PaymentStatus__c 
        WHERE Order__c = :ord.Id
        AND Status__c != '완납'
        ORDER BY InstallmentNumber__c
    ];
    
    if (!payments.isEmpty()) {
        targetOrder = ord;
        targetPayments = payments;
        System.debug('테스트 대상 Order 선정: ' + ord.OrderNumber + ' (' + ord.Account.Name + ')');
        System.debug('미완납 PaymentStatus: ' + payments.size() + '개');
        break;
    }
}

if (targetOrder == null) {
    System.debug('❌ 테스트할 수 있는 미완납 Order가 없습니다.');
    
    // 새로운 PaymentStatus 생성 옵션 제시
    if (!candidateOrders.isEmpty()) {
        Order sampleOrder = candidateOrders[0];
        System.debug('\n=== 테스트용 PaymentStatus 생성 가이드 ===');
        System.debug('Order ID: ' + sampleOrder.Id);
        System.debug('Order Number: ' + sampleOrder.OrderNumber);
        System.debug('Account: ' + sampleOrder.Account.Name);
        System.debug('\n다음 코드로 PaymentStatus를 생성하고 다시 테스트하세요:');
        System.debug('PaymentStatus__c ps = new PaymentStatus__c();');
        System.debug('ps.Order__c = \'' + sampleOrder.Id + '\';');
        System.debug('ps.InstallmentNumber__c = 1;');
        System.debug('ps.Amount__c = ' + (sampleOrder.TotalAmount != null ? sampleOrder.TotalAmount : 1000000) + ';');
        System.debug('ps.Status__c = \'미납\';');
        System.debug('ps.DueDate__c = Date.today().addDays(30);');
        System.debug('insert ps;');
    }
} else {
    System.debug('\n=== 선정된 Order 정보 ===');
    System.debug('Order: ' + targetOrder.OrderNumber);
    System.debug('고객: ' + targetOrder.Account.Name);
    System.debug('Key Account: ' + (targetOrder.Account.Key_Account__c ? 'Yes' : 'No'));
    System.debug('우선순위: ' + (targetOrder.Account.CustomerPriority__c ?? '일반'));
    System.debug('Order 금액: ' + (targetOrder.TotalAmount != null ? targetOrder.TotalAmount.format() : '0') + '원');
    
    // 현재 PaymentStatus 현황
    List<PaymentStatus__c> allPayments = [
        SELECT Id, InstallmentNumber__c, Amount__c, Status__c, DueDate__c
        FROM PaymentStatus__c 
        WHERE Order__c = :targetOrder.Id
        ORDER BY InstallmentNumber__c
    ];
    
    System.debug('\n=== 현재 PaymentStatus 현황 ===');
    for (PaymentStatus__c ps : allPayments) {
        System.debug(ps.InstallmentNumber__c + '차: ' + 
                    (ps.Amount__c != null ? ps.Amount__c.format() : '0') + '원 - ' + ps.Status__c);
    }
    
    // 완납 상태 확인
    // Note: AccountBasedAssetService는 OrderAssetCreationService를 내부적으로 사용하므로 직접 호출
    List<PaymentStatus__c> allPaymentsForCheck = [
        SELECT Status__c 
        FROM PaymentStatus__c 
        WHERE Order__c = :targetOrder.Id
    ];
    
    Boolean isCurrentlyFullyPaid = true;
    for (PaymentStatus__c ps : allPaymentsForCheck) {
        if (ps.Status__c != '완납') {
            isCurrentlyFullyPaid = false;
            break;
        }
    }
    System.debug('현재 완납 상태: ' + isCurrentlyFullyPaid);
    
    if (!isCurrentlyFullyPaid) {
        System.debug('\n=== PaymentStatus 완납 처리 시작 ===');
        
        try {
            // 모든 PaymentStatus를 완납으로 변경
            List<PaymentStatus__c> toUpdate = new List<PaymentStatus__c>();
            
            for (PaymentStatus__c ps : allPayments) {
                if (ps.Status__c != '완납') {
                    ps.Status__c = '완납';
                    // ps.PaidDate__c = Date.today(); // 필드 존재 시 활성화
                    toUpdate.add(ps);
                }
            }
            
            if (!toUpdate.isEmpty()) {
                System.debug('완납으로 변경할 PaymentStatus: ' + toUpdate.size() + '개');
                
                // PaymentStatus 업데이트 (트리거 실행됨)
                update toUpdate;
                
                System.debug('✅ PaymentStatus 완납 처리 완료!');
                System.debug('PaymentStatusAssetTrigger가 실행되어 Asset 자동 생성이 시작됩니다...');
                
                // 잠시 후 결과 확인
                System.debug('\n=== Asset 생성 결과 확인 ===');
                
                // 완납 상태 재확인
                List<PaymentStatus__c> updatedPayments = [
                    SELECT Status__c 
                    FROM PaymentStatus__c 
                    WHERE Order__c = :targetOrder.Id
                ];
                
                Boolean newIsFullyPaid = true;
                for (PaymentStatus__c ps : updatedPayments) {
                    if (ps.Status__c != '완납') {
                        newIsFullyPaid = false;
                        break;
                    }
                }
                System.debug('업데이트 후 완납 상태: ' + newIsFullyPaid);
                
                // 생성된 Asset 확인
                List<Asset> newAssets = [
                    SELECT Id, Name, SerialNumber, AccountId, Account.Name,
                           Status, Price, PurchaseDate, InstallDate, 
                           LifecycleStartDate, LifecycleEndDate, CreatedDate
                    FROM Asset 
                    WHERE SerialNumber = :targetOrder.OrderNumber
                    ORDER BY CreatedDate DESC
                ];
                
                if (!newAssets.isEmpty()) {
                    Asset createdAsset = newAssets[0];
                    System.debug('🎉 Asset 자동 생성 성공!');
                    System.debug('- Asset ID: ' + createdAsset.Id);
                    System.debug('- Asset Name: ' + createdAsset.Name);
                    System.debug('- Account: ' + createdAsset.Account.Name);
                    System.debug('- Status: ' + createdAsset.Status);
                    System.debug('- Price: ' + (createdAsset.Price != null ? createdAsset.Price.format() : '0') + '원');
                    System.debug('- Purchase Date: ' + (createdAsset.PurchaseDate != null ? createdAsset.PurchaseDate.format() : '없음'));
                    System.debug('- Lifecycle Start: ' + (createdAsset.LifecycleStartDate != null ? createdAsset.LifecycleStartDate.format() : '없음'));
                    System.debug('- Lifecycle End: ' + (createdAsset.LifecycleEndDate != null ? createdAsset.LifecycleEndDate.format() : '없음'));
                    System.debug('- Created: ' + createdAsset.CreatedDate.format());
                    
                    // 생성된 Task 확인
                    List<Task> createdTasks = [
                        SELECT Id, Subject, Priority, Status, ActivityDate, 
                               Owner.Name, Description
                        FROM Task 
                        WHERE WhatId = :createdAsset.Id
                        ORDER BY CreatedDate DESC
                    ];
                    
                    if (!createdTasks.isEmpty()) {
                        System.debug('\n--- 자동 생성된 후속 Task ---');
                        for (Task t : createdTasks) {
                            System.debug('📋 ' + t.Subject);
                            System.debug('   담당자: ' + t.Owner.Name);
                            System.debug('   우선순위: ' + t.Priority);
                            System.debug('   예정일: ' + (t.ActivityDate != null ? t.ActivityDate.format() : '미정'));
                            
                            // Description 미리보기
                            if (String.isNotBlank(t.Description)) {
                                String descPreview = t.Description.length() > 200 ? 
                                    t.Description.substring(0, 200) + '...' : t.Description;
                                System.debug('   내용: ' + descPreview.replace('\n', ' '));
                            }
                            System.debug('');
                        }
                    } else {
                        System.debug('생성된 후속 Task가 없습니다.');
                    }
                    
                } else {
                    System.debug('⚠️ Asset이 생성되지 않았습니다. 로그를 확인해주세요.');
                }
                
            } else {
                System.debug('이미 모든 PaymentStatus가 완납 상태입니다.');
            }
            
        } catch (Exception e) {
            System.debug('❌ PaymentStatus 완납 처리 오류: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
        
    } else {
        System.debug('⚠️ 이미 완납된 Order입니다.');
    }
}

System.debug('\n=== PaymentStatus 완납 시뮬레이션 테스트 완료 ===');

// 시스템 동작 요약
System.debug('\n=== 자동화 시스템 동작 요약 ===');
System.debug('1. PaymentStatus.Status__c → "완납" 변경');
System.debug('2. PaymentStatusAssetTrigger.trigger 실행');
System.debug('3. PaymentStatusAssetTriggerHandler.handleAfterUpdate() 호출');
System.debug('4. PaymentStatus 완납 확인');
System.debug('5. AccountBasedAssetService.createAssetWithAccountAnalysis() Asset 생성');
System.debug('6. Account 정보 기반 Lifecycle, 우선순위, 후속 액션 설정');
System.debug('7. Account Manager, Key Account, 고우선순위별 맞춤 Task 자동 생성');
