/**
 * Logic 2 벌크 원클릭 갱신 테스트
 * 목적: 여러 자산을 한 번에 갱신하는 벌크 프로세스 검증
 */

// 1단계: 벌크 갱신 대상 자산 조회
List<Asset> bulkRenewalAssets = [
    SELECT Id, Name, AccountId, Account.Name, UsageEndDate, Price, Quantity, 
           Status, 우선순위점수__c, 계약상태__c
    FROM Asset 
    WHERE Name LIKE 'Logic2테스트자산%' 
    AND 계약상태__c = 'Active'
    AND UsageEndDate <= :Date.today().addDays(60) // 60일 이내 만료 자산
    ORDER BY UsageEndDate ASC
];

System.debug('=== Logic 2 벌크 원클릭 갱신 테스트 시작 ===');
System.debug('벌크 갱신 대상 자산 수: ' + bulkRenewalAssets.size());

if(bulkRenewalAssets.size() < 2) {
    System.debug('벌크 테스트를 위한 충분한 자산이 없습니다. 최소 2개 필요.');
} else {
    
    // 2단계: Asset ID 목록 생성
    List<Id> assetIds = new List<Id>();
    for(Asset asset : bulkRenewalAssets) {
        assetIds.add(asset.Id);
    }
    
    System.debug('벌크 처리 자산 ID 목록: ' + assetIds);
    
    // 3단계: 벌크 갱신 프로세스 실행
    DateTime startTime = DateTime.now();
    
    try {
        // OneClickRenewalService의 벌크 처리 메소드 호출
        List<OneClickRenewalService.RenewalResult> bulkResults = 
            OneClickRenewalService.processBulkRenewal(assetIds);
        
        DateTime endTime = DateTime.now();
        Long totalProcessingTime = endTime.getTime() - startTime.getTime();
        
        System.debug('=== 벌크 갱신 결과 분석 ===');
        System.debug('총 처리 시간: ' + totalProcessingTime + 'ms');
        System.debug('자산당 평균 시간: ' + (totalProcessingTime / bulkResults.size()) + 'ms');
        
        // 4단계: 개별 결과 검토
        Integer successCount = 0;
        Integer failureCount = 0;
        
        for(Integer i = 0; i < bulkResults.size(); i++) {
            OneClickRenewalService.RenewalResult result = bulkResults[i];
            Asset asset = bulkRenewalAssets[i];
            
            System.debug('--- 자산 ' + (i+1) + ': ' + asset.Name + ' ---');
            
            if(result.success) {
                successCount++;
                System.debug('✅ 갱신 성공');
                System.debug('  → Opportunity ID: ' + result.opportunityId);
                System.debug('  → Task ID: ' + result.taskId);
                System.debug('  → 메시지: ' + result.message);
            } else {
                failureCount++;
                System.debug('❌ 갱신 실패: ' + result.message);
            }
        }
        
        // 5단계: 성과 통계
        System.debug('=== 벌크 갱신 성과 통계 ===');
        System.debug('성공: ' + successCount + '건');
        System.debug('실패: ' + failureCount + '건');
        System.debug('성공률: ' + (successCount * 100 / bulkResults.size()) + '%');
        
        // 6단계: 성능 평가
        if(totalProcessingTime < 5000 * bulkResults.size()) {
            System.debug('✅ 벌크 성능 목표 달성! (자산당 5초 이내)');
        } else {
            System.debug('⚠️ 벌크 성능 최적화 필요');
        }
        
        // 7단계: 생성된 레코드 검증
        System.debug('=== 생성된 레코드 검증 ===');
        
        List<Opportunity> createdOpportunities = [
            SELECT Id, Name, Amount, StageName, AccountId, Asset__c
            FROM Opportunity 
            WHERE Asset__c IN :assetIds 
            AND CreatedDate = TODAY
        ];
        System.debug('생성된 Opportunity 수: ' + createdOpportunities.size());
        
        List<Task> createdTasks = [
            SELECT Id, Subject, Status, Priority, WhatId
            FROM Task 
            WHERE WhatId IN :assetIds 
            AND CreatedDate = TODAY
        ];
        System.debug('생성된 Task 수: ' + createdTasks.size());
        
        if(createdOpportunities.size() == successCount && createdTasks.size() == successCount) {
            System.debug('✅ 레코드 생성 일치성 확인됨');
        } else {
            System.debug('⚠️ 레코드 생성 불일치 발견');
        }
        
    } catch(Exception e) {
        System.debug('❌ 벌크 갱신 예외 발생: ' + e.getMessage());
        System.debug('스택 트레이스: ' + e.getStackTraceString());
    }
}

System.debug('=== Logic 2 벌크 원클릭 갱신 테스트 완료 ===');
