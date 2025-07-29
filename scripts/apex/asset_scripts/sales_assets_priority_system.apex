/**
 * 영업사원 중심 Assets 관리 시스템
 * 실제 구현 가능한 핵심 로직
 */

// ==========================================
// 1. 영업사원 우선순위 고객 자동 분석
// ==========================================

System.debug('=== 영업사원 중심 Assets 우선순위 분석 ===');

// 현재 사용자 (영업사원) ID 확인
Id currentUserId = UserInfo.getUserId();
System.debug('분석 대상 영업사원: ' + UserInfo.getName());

// 담당 Assets 조회 및 우선순위 계산
List<Asset> myAssets = [
    SELECT Id, Name, AccountId, Account.Name, Account.Phone, Account.Industry,
           Status, InstallDate, Price, SerialNumber, Product2.Name,
           Account.OwnerId, LastModifiedDate
    FROM Asset 
    WHERE Account.OwnerId = :currentUserId
    AND Status IN ('Installed', 'Registered', 'Shipped')
    ORDER BY LastModifiedDate DESC
];

System.debug('담당 Assets 총 ' + myAssets.size() + '개 발견');

// 우선순위 분석 맵
Map<Id, Decimal> priorityScores = new Map<Id, Decimal>();
Map<Id, String> actionRecommendations = new Map<Id, String>();

for (Asset asset : myAssets) {
    Decimal score = 0;
    String recommendation = '';
    
    // 1. 갱신 임박도 점수 (최대 40점)
    if (asset.InstallDate != null) {
        Integer daysFromInstall = asset.InstallDate.daysBetween(Date.today());
        System.debug('Asset ' + asset.Name + ' 사용 기간: ' + daysFromInstall + '일');
        
        if (daysFromInstall >= 300 && daysFromInstall <= 400) {
            score += 40;
            recommendation = '🔥 갱신 적기 - 즉시 연락 필요';
        } else if (daysFromInstall >= 250 && daysFromInstall < 300) {
            score += 30;
            recommendation = '⏰ 갱신 준비 - 2주 내 접촉';
        } else if (daysFromInstall >= 200 && daysFromInstall < 250) {
            score += 20;
            recommendation = '📅 갱신 예비 - 1개월 내 관계 강화';
        }
    } else {
        recommendation = '📋 정보 업데이트 필요';
    }
    
    // 2. 매출 규모 점수 (최대 30점)
    if (asset.Price != null) {
        if (asset.Price >= 10000000) {
            score += 30;
            System.debug('고액 Asset: ₩' + asset.Price.format());
        } else if (asset.Price >= 5000000) {
            score += 20;
        } else if (asset.Price >= 1000000) {
            score += 10;
        }
    }
    
    // 3. 고객 활동성 점수 (최대 30점)
    List<Task> recentTasks = [
        SELECT Id FROM Task 
        WHERE WhatId = :asset.AccountId 
        AND CreatedDate = LAST_N_DAYS:30
        LIMIT 10
    ];
    
    if (recentTasks.size() >= 5) {
        score += 30; // 활발한 소통
    } else if (recentTasks.size() >= 2) {
        score += 15; // 보통 소통
    } else {
        score += 0; // 소통 부족
        if (recommendation.length() < 20) {
            recommendation = '📞 관계 회복 필요 - 안부 연락';
        }
    }
    
    priorityScores.put(asset.Id, score);
    actionRecommendations.put(asset.Id, recommendation);
}

// 우선순위 TOP 5 출력
System.debug('');
System.debug('🎯 TODAY\'S TOP 5 우선순위 고객:');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

List<Asset> sortedAssets = new List<Asset>(myAssets);
// 점수 기준으로 정렬 (간단한 버블 정렬)
for (Integer i = 0; i < sortedAssets.size() - 1; i++) {
    for (Integer j = 0; j < sortedAssets.size() - 1 - i; j++) {
        Decimal score1 = priorityScores.get(sortedAssets[j].Id);
        Decimal score2 = priorityScores.get(sortedAssets[j + 1].Id);
        if (score1 < score2) {
            Asset temp = sortedAssets[j];
            sortedAssets[j] = sortedAssets[j + 1];
            sortedAssets[j + 1] = temp;
        }
    }
}

for (Integer i = 0; i < Math.min(5, sortedAssets.size()); i++) {
    Asset asset = sortedAssets[i];
    Decimal score = priorityScores.get(asset.Id);
    String action = actionRecommendations.get(asset.Id);
    
    System.debug((i + 1) + '위. ' + asset.Account.Name + ' (' + score.format() + '점)');
    System.debug('    Asset: ' + asset.Name);
    System.debug('    전화: ' + (asset.Account.Phone != null ? asset.Account.Phone : 'N/A'));
    System.debug('    가치: ₩' + (asset.Price != null ? asset.Price.format() : 'N/A'));
    System.debug('    액션: ' + action);
    System.debug('');
}

// ==========================================
// 2. 일일 매출 기회 자동 계산
// ==========================================

System.debug('📊 오늘의 매출 기회 분석:');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

Decimal todaysPotential = 0;
Integer highPriorityActions = 0;

for (Asset asset : sortedAssets) {
    Decimal score = priorityScores.get(asset.Id);
    
    if (score >= 70) { // 고우선순위
        highPriorityActions++;
        if (asset.Price != null) {
            // 갱신 확률 적용 (높은 우선순위일수록 높은 확률)
            Decimal renewalProbability = score > 80 ? 0.8 : 0.6;
            todaysPotential += asset.Price * renewalProbability;
        }
    }
}

System.debug('💰 오늘 예상 매출: ₩' + todaysPotential.format());
System.debug('🎯 고우선순위 액션: ' + highPriorityActions + '건');
System.debug('⏰ 예상 소요시간: ' + (highPriorityActions * 15) + '분');

// ==========================================
// 3. 자동 업무 생성 시뮬레이션
// ==========================================

System.debug('');
System.debug('🤖 자동 업무 생성 시뮬레이션:');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

Integer tasksCreated = 0;
Integer opportunitiesRecommended = 0;

for (Integer i = 0; i < Math.min(3, sortedAssets.size()); i++) {
    Asset asset = sortedAssets[i];
    Decimal score = priorityScores.get(asset.Id);
    
    if (score >= 60) {
        System.debug('✅ ' + asset.Account.Name + ' 대상 자동 생성:');
        
        // Task 생성 시뮬레이션
        System.debug('  📋 Task: "' + asset.Account.Name + ' 갱신 논의 통화"');
        System.debug('      - 우선순위: High');
        System.debug('      - 예정일: ' + Date.today().addDays(1).format());
        System.debug('      - 예상 매출: ₩' + (asset.Price != null ? asset.Price.format() : 'N/A'));
        tasksCreated++;
        
        // Opportunity 추천 시뮬레이션
        if (score >= 80) {
            System.debug('  🎯 Opportunity 추천: "' + asset.Account.Name + ' - ' + asset.Product2?.Name + ' 갱신"');
            System.debug('      - 확률: 80%');
            System.debug('      - 예상 Close: ' + Date.today().addDays(30).format());
            opportunitiesRecommended++;
        }
        
        System.debug('');
    }
}

System.debug('📋 생성 예정 Tasks: ' + tasksCreated + '건');
System.debug('🎯 추천 Opportunities: ' + opportunitiesRecommended + '건');

// ==========================================
// 4. 영업사원 성과 예측
// ==========================================

System.debug('');
System.debug('📈 이번 달 성과 예측:');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

// 이번 달 기존 성과 조회
List<Opportunity> thisMonthWins = [
    SELECT Id, Amount, CloseDate 
    FROM Opportunity 
    WHERE OwnerId = :currentUserId 
    AND StageName = 'Closed Won'
    AND CloseDate = THIS_MONTH
];

Decimal currentMonthRevenue = 0;
for (Opportunity opp : thisMonthWins) {
    currentMonthRevenue += opp.Amount != null ? opp.Amount : 0;
}

System.debug('💰 이번 달 기달성 매출: ₩' + currentMonthRevenue.format());
System.debug('🎯 Assets 기반 추가 예상: ₩' + todaysPotential.format());
System.debug('📊 월말 예상 총 매출: ₩' + (currentMonthRevenue + todaysPotential).format());

// 성과 등급 계산
String performanceGrade;
Decimal totalExpected = currentMonthRevenue + todaysPotential;

if (totalExpected >= 100000000) {
    performanceGrade = '👑 LEGEND (1억원 이상)';
} else if (totalExpected >= 50000000) {
    performanceGrade = '💎 DIAMOND (5천만원 이상)';
} else if (totalExpected >= 25000000) {
    performanceGrade = '🥇 GOLD (2천5백만원 이상)';
} else if (totalExpected >= 10000000) {
    performanceGrade = '🥈 SILVER (1천만원 이상)';
} else {
    performanceGrade = '🥉 BRONZE (1천만원 미만)';
}

System.debug('🏆 예상 성과 등급: ' + performanceGrade);

// ==========================================
// 5. 실행 계획 요약
// ==========================================

System.debug('');
System.debug('🎯 오늘의 실행 계획:');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

System.debug('⏰ 오전 (30분):');
System.debug('  1. TOP ' + Math.min(3, highPriorityActions) + ' 고객 우선 연락');
System.debug('  2. 갱신 관련 ' + tasksCreated + '건 Task 처리');
System.debug('  3. 예상 매출: ₩' + (todaysPotential * 0.3).format() + ' (30% 확률)');

System.debug('');
System.debug('🏃 오후 (60분):');
System.debug('  1. ' + opportunitiesRecommended + '건 Opportunity 생성/관리');
System.debug('  2. 관계 강화 활동 (만족도 높은 고객)');
System.debug('  3. 다음주 계획 수립');

System.debug('');
System.debug('🌙 마무리 (30분):');
System.debug('  1. Assets 정보 업데이트');
System.debug('  2. 내일 우선순위 고객 확인');
System.debug('  3. 성과 분석 및 개선점 파악');

System.debug('');
System.debug('✅ Assets 기반 스마트 영업 시스템 분석 완료!');
System.debug('💡 ' + UserInfo.getName() + '님의 오늘 예상 성과: ₩' + todaysPotential.format());
System.debug('🚀 효율적인 영업 활동으로 목표 달성하세요!');
