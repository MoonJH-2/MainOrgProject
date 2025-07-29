/**
 * Account 기반 Asset 자동 생성 시스템 종합 테스트
 * PaymentStatus 완납 → Account 분석 → Asset 생성 → 후속 액션
 */

System.debug('=== Account 기반 Asset 자동 생성 시스템 종합 테스트 ===');

// 1. Order와 Account 정보 조회
List<Order> testOrders = [
    SELECT Id, OrderNumber, AccountId, Account.Name, Account.Industry,
           Account.NumberOfEmployees, Account.AnnualRevenue, Account.Key_Account__c,
           Account.CustomerPriority__c, Account.Manager__c,
           TotalAmount, Status, EffectiveDate, EndDate, Contact__c, OwnerId
    FROM Order 
    WHERE AccountId != null
    ORDER BY CreatedDate DESC
    LIMIT 5
];

System.debug('테스트 가능한 Order 개수: ' + testOrders.size());

for (Order ord : testOrders) {
    System.debug('\n=== Order: ' + ord.OrderNumber + ' ===');
    System.debug('고객: ' + ord.Account.Name);
    System.debug('산업군: ' + (ord.Account.Industry ?? '미분류'));
    System.debug('직원수: ' + (ord.Account.NumberOfEmployees != null ? ord.Account.NumberOfEmployees.format() : '미확인') + '명');
    System.debug('연매출: ' + (ord.Account.AnnualRevenue != null ? ord.Account.AnnualRevenue.format() : '미확인') + '원');
    System.debug('Key Account: ' + (ord.Account.Key_Account__c ? 'Yes' : 'No'));
    System.debug('우선순위: ' + (ord.Account.CustomerPriority__c ?? '일반'));
    // System.debug('Einstein Tier: ' + (ord.Account.Tier ?? '미분류'));
    System.debug('Account Manager: ' + (ord.Account.Manager__c != null ? 'Assigned' : 'None'));
    System.debug('Order 금액: ' + (ord.TotalAmount != null ? ord.TotalAmount.format() : '0') + '원');
    
    // PaymentStatus 현황 확인
    List<PaymentStatus__c> payments = [
        SELECT Id, InstallmentNumber__c, Amount__c, Status__c, DueDate__c
        FROM PaymentStatus__c 
        WHERE Order__c = :ord.Id
        ORDER BY InstallmentNumber__c
    ];
    
    System.debug('PaymentStatus 개수: ' + payments.size());
    
    if (!payments.isEmpty()) {
        Integer totalPayments = payments.size();
        Integer completedPayments = 0;
        Decimal totalAmount = 0;
        Decimal paidAmount = 0;
        
        for (PaymentStatus__c ps : payments) {
            if (ps.Amount__c != null) {
                totalAmount += ps.Amount__c;
            }
            
            String statusInfo = '  ' + ps.InstallmentNumber__c + '차: ';
            statusInfo += (ps.Amount__c != null ? ps.Amount__c.format() : '0') + '원';
            statusInfo += ' [' + ps.Status__c + ']';
            
            if (ps.DueDate__c != null) {
                statusInfo += ' 예정: ' + ps.DueDate__c.format();
            }
            // if (ps.PaidDate__c != null) {
            //     statusInfo += ' 납부: ' + ps.PaidDate__c.format();
            // }
            
            System.debug(statusInfo);
            
            if (ps.Status__c == '완납') {
                completedPayments++;
                if (ps.Amount__c != null) {
                    paidAmount += ps.Amount__c;
                }
            }
        }
        
        Boolean isFullyPaid = (totalPayments > 0 && totalPayments == completedPayments);
        System.debug('납부 현황: ' + completedPayments + '/' + totalPayments + ' 완납');
        System.debug('금액 현황: ' + paidAmount.format() + '/' + totalAmount.format() + '원');
        System.debug('완납 상태: ' + isFullyPaid);
        
        // 기존 Asset 확인
        List<Asset> existingAssets = [
            SELECT Id, Name, Status, CreatedDate
            FROM Asset 
            WHERE SerialNumber = :ord.OrderNumber
        ];
        
        if (!existingAssets.isEmpty()) {
            System.debug('기존 Asset 존재: ' + existingAssets[0].Name + ' (' + existingAssets[0].Status + ')');
        } else {
            System.debug('기존 Asset 없음');
            
            if (isFullyPaid) {
                System.debug('\n🎯 완납 Order 발견! Account 기반 Asset 생성 테스트...');
                
                try {
                    // Account 기반 Asset 생성 테스트
                    Asset newAsset = AccountBasedAssetService.createAssetWithAccountAnalysis(ord.Id);
                    
                    if (newAsset != null) {
                        System.debug('✅ Account 기반 Asset 생성 성공!');
                        System.debug('- Asset ID: ' + newAsset.Id);
                        System.debug('- Asset Name: ' + newAsset.Name);
                        System.debug('- Serial Number: ' + newAsset.SerialNumber);
                        System.debug('- Price: ' + (newAsset.Price != null ? newAsset.Price.format() : '0') + '원');
                        
                        // 생성된 Asset 상세 조회
                        Asset assetDetail = [
                            SELECT Id, Name, SerialNumber, AccountId, Account.Name,
                                   ContactId, PurchaseDate, InstallDate, LifecycleEndDate,
                                   LifecycleStartDate, Status, Price, Description
                            FROM Asset 
                            WHERE Id = :newAsset.Id
                        ];
                        
                        System.debug('\n--- Account 기반 Asset 상세 정보 ---');
                        System.debug('고객: ' + assetDetail.Account.Name);
                        System.debug('구매일: ' + (assetDetail.PurchaseDate != null ? assetDetail.PurchaseDate.format() : '없음'));
                        System.debug('설치일: ' + (assetDetail.InstallDate != null ? assetDetail.InstallDate.format() : '없음'));
                        System.debug('Lifecycle 시작: ' + (assetDetail.LifecycleStartDate != null ? assetDetail.LifecycleStartDate.format() : '없음'));
                        System.debug('Lifecycle 종료: ' + (assetDetail.LifecycleEndDate != null ? assetDetail.LifecycleEndDate.format() : '없음'));
                        System.debug('상태: ' + assetDetail.Status);
                        
                        // Description 미리보기 (처음 500자)
                        if (String.isNotBlank(assetDetail.Description)) {
                            String descPreview = assetDetail.Description.length() > 500 ? 
                                assetDetail.Description.substring(0, 500) + '...' : 
                                assetDetail.Description;
                            System.debug('\nDescription 미리보기:\n' + descPreview);
                        }
                        
                        // 생성된 Task 확인
                        List<Task> relatedTasks = [
                            SELECT Id, Subject, Priority, Status, ActivityDate, Owner.Name
                            FROM Task 
                            WHERE WhatId = :newAsset.Id
                            ORDER BY CreatedDate DESC
                        ];
                        
                        if (!relatedTasks.isEmpty()) {
                            System.debug('\n--- 생성된 후속 Task ---');
                            for (Task t : relatedTasks) {
                                System.debug('- ' + t.Subject + ' (' + t.Priority + ') → ' + t.Owner.Name);
                                System.debug('  예정일: ' + (t.ActivityDate != null ? t.ActivityDate.format() : '미정'));
                            }
                        }
                        
                        break; // 첫 번째 성공 후 종료
                    }
                    
                } catch (Exception e) {
                    System.debug('❌ Account 기반 Asset 생성 오류: ' + e.getMessage());
                    System.debug('Stack Trace: ' + e.getStackTraceString());
                }
            } else {
                System.debug('⚠️ 아직 완납되지 않은 Order입니다.');
            }
        }
    } else {
        System.debug('PaymentStatus가 없는 Order입니다.');
    }
}

// 전체 시스템 상태 요약
System.debug('\n=== 전체 Asset 시스템 현황 ===');

// Asset 총 개수
Integer totalAssets = [SELECT COUNT() FROM Asset];
System.debug('전체 Asset 개수: ' + totalAssets);

// 오늘 생성된 Asset
List<Asset> todayAssets = [
    SELECT Id, Name, SerialNumber, Account.Name, Price, CreatedDate
    FROM Asset 
    WHERE CreatedDate = TODAY
    ORDER BY CreatedDate DESC
    LIMIT 5
];

System.debug('오늘 생성된 Asset: ' + todayAssets.size() + '개');
for (Asset asset : todayAssets) {
    System.debug('- ' + asset.Name + ' (' + asset.Account.Name + ') ' + 
                (asset.Price != null ? asset.Price.format() : '0') + '원');
}

// 최근 Task 확인
List<Task> recentAssetTasks = [
    SELECT Id, Subject, Priority, Status, Owner.Name, What.Name
    FROM Task 
    WHERE What.Type = 'Asset'
    AND CreatedDate = TODAY
    ORDER BY CreatedDate DESC
    LIMIT 5
];

System.debug('오늘 생성된 Asset 관련 Task: ' + recentAssetTasks.size() + '개');
for (Task task : recentAssetTasks) {
    System.debug('- ' + task.Subject + ' (' + task.Priority + ') → ' + task.Owner.Name);
}

System.debug('\n=== Account 기반 Asset 자동 생성 시스템 테스트 완료 ===');

// PaymentStatus 트리거 테스트 가이드
System.debug('\n=== PaymentStatus 트리거 테스트 가이드 ===');
System.debug('1. PaymentStatus의 Status__c를 "완납"으로 변경');
System.debug('2. PaymentStatusAssetTrigger가 자동 실행');
System.debug('3. AccountBasedAssetService.createAssetWithAccountAnalysis() 호출');
System.debug('4. Account 분석 기반 Asset 생성 및 후속 액션 수행');
System.debug('5. Account Manager, Key Account, 고우선순위 고객별 맞춤 Task 생성');
