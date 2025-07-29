/**
 * Logic 2 원클릭 갱신 기능 실제 테스트
 * 목적: 5초 갱신 프로세스가 정상 작동하는지 실시간 검증
 */

// 1단계: Logic 2 테스트 자산 조회
List<Asset> renewableAssets = [
    SELECT Id, Name, AccountId, Account.Name, UsageEndDate, Price, Quantity, 
           Status, 우선순위점수__c, 계약상태__c
    FROM Asset 
    WHERE Name LIKE 'Logic2테스트자산%' 
    AND 계약상태__c = 'Active'
    ORDER BY 우선순위점수__c DESC
];

System.debug('=== Logic 2 원클릭 갱신 테스트 시작 ===');
System.debug('갱신 대상 자산 수: ' + renewableAssets.size());

if(renewableAssets.isEmpty()) {
    System.debug('테스트 자산이 없습니다. logic2_test_data_setup.apex를 먼저 실행하세요.');
} else {
    
    // 2단계: 각 자산별 원클릭 갱신 프로세스 테스트
    DateTime startTime = DateTime.now();
    
    for(Asset asset : renewableAssets) {
        System.debug('--- 자산 갱신 테스트: ' + asset.Name + ' ---');
        
        try {
            // OneClickRenewalService 호출 (5초 프로세스)
            OneClickRenewalService.RenewalResult result = 
                OneClickRenewalService.startRenewalProcess(asset.Id);
            
            if(result.success) {
                System.debug('✅ 갱신 성공!');
                System.debug('  → 생성된 Opportunity ID: ' + result.opportunityId);
                System.debug('  → 생성된 Task ID: ' + result.taskId);
                System.debug('  → 메시지: ' + result.message);
                
                // 생성된 Opportunity 검증
                Opportunity createdOpp = [
                    SELECT Id, Name, Amount, CloseDate, StageName, AccountId
                    FROM Opportunity 
                    WHERE Id = :result.opportunityId
                ];
                System.debug('  → Opportunity 상세: ' + createdOpp.Name + 
                           ', 금액: ' + createdOpp.Amount +
                           ', 종료일: ' + createdOpp.CloseDate);
                
                // 생성된 Task 검증
                Task createdTask = [
                    SELECT Id, Subject, Status, Priority, WhoId, WhatId
                    FROM Task 
                    WHERE Id = :result.taskId
                ];
                System.debug('  → Task 상세: ' + createdTask.Subject + 
                           ', 상태: ' + createdTask.Status +
                           ', 우선순위: ' + createdTask.Priority);
                           
            } else {
                System.debug('❌ 갱신 실패: ' + result.message);
            }
            
        } catch(Exception e) {
            System.debug('❌ 예외 발생: ' + e.getMessage());
        }
        
        System.debug(''); // 구분선
    }
    
    // 3단계: 처리 시간 측정
    DateTime endTime = DateTime.now();
    Long processingTime = endTime.getTime() - startTime.getTime();
    
    System.debug('=== Logic 2 테스트 결과 요약 ===');
    System.debug('처리된 자산 수: ' + renewableAssets.size());
    System.debug('총 처리 시간: ' + processingTime + 'ms');
    System.debug('자산당 평균 시간: ' + (processingTime / renewableAssets.size()) + 'ms');
    
    if(processingTime < 5000 * renewableAssets.size()) {
        System.debug('✅ 성능 목표 달성! (자산당 5초 이내)');
    } else {
        System.debug('⚠️ 성능 최적화 필요 (자산당 5초 초과)');
    }
}

System.debug('=== Logic 2 원클릭 갱신 테스트 완료 ===');
