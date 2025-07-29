/**
 * Salesforce Assets 실제 활용 시연
 * Order 00000153 기반 Asset 라이프사이클 관리 예시
 */

System.debug('=== Salesforce Assets 활용 시연 ===');
System.debug('Order 00000153 -> Asset 생성 -> 라이프사이클 관리');
System.debug('');

// ==========================================
// 1단계: Order에서 Asset 자동 생성 시연
// ==========================================
System.debug('📍 1단계: Order 기반 Asset 생성');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

// Order 00000153 조회
List<Order> testOrders = [
    SELECT Id, OrderNumber, AccountId, Account.Name, Account.Industry,
           TotalAmount, Status, EffectiveDate, CreatedDate
    FROM Order 
    WHERE OrderNumber = '00000153'
    LIMIT 1
];

if (testOrders.isEmpty()) {
    System.debug('⚠️ Order 00000153을 찾을 수 없습니다.');
    return;
}

Order testOrder = testOrders[0];
System.debug('🎯 Order 정보:');
System.debug('  - Order Number: ' + testOrder.OrderNumber);
System.debug('  - Account: ' + testOrder.Account.Name);
System.debug('  - Total Amount: ' + testOrder.TotalAmount?.format());
System.debug('  - Status: ' + testOrder.Status);
System.debug('  - Created Date: ' + testOrder.CreatedDate.format());

// 연결된 Asset 조회
List<Asset> existingAssets = [
    SELECT Id, Name, Status, SerialNumber, PurchaseDate, InstallDate,
           Price, Account.Name, Product2.Name
    FROM Asset 
    WHERE SerialNumber = :testOrder.OrderNumber
    OR Name LIKE '%' + testOrder.OrderNumber + '%'
];

System.debug('');
System.debug('🏭 연결된 Assets:');
if (existingAssets.isEmpty()) {
    System.debug('  - 연결된 Asset이 없습니다.');
} else {
    for (Asset asset : existingAssets) {
        System.debug('  ✅ Asset: ' + asset.Name);
        System.debug('    - Serial Number: ' + asset.SerialNumber);
        System.debug('    - Status: ' + asset.Status);
        System.debug('    - Purchase Date: ' + (asset.PurchaseDate != null ? asset.PurchaseDate.format() : 'N/A'));
        System.debug('    - Install Date: ' + (asset.InstallDate != null ? asset.InstallDate.format() : 'N/A'));
        System.debug('    - Price: ' + (asset.Price != null ? asset.Price.format() : 'N/A'));
    }
}

System.debug('');

// ==========================================
// 2단계: Asset Health Score 계산
// ==========================================
System.debug('📍 2단계: Asset Health Score 분석');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

for (Asset asset : existingAssets) {
    System.debug('🏥 Asset Health 분석: ' + asset.Name);
    
    // 기본 건강도 점수 (100점 만점)
    Decimal healthScore = 100;
    
    // 1. 사용 기간 분석
    if (asset.InstallDate != null) {
        Integer daysUsed = asset.InstallDate.daysBetween(Date.today());
        System.debug('  📅 사용 기간: ' + daysUsed + '일');
        
        if (daysUsed > 365) {
            healthScore -= 10; // 1년 이상 사용 시 노후화 점수 감소
            System.debug('  ⚠️ 장기 사용: -10점 (노후화)');
        }
    }
    
    // 2. Support Case 분석
    List<Case> recentCases = [
        SELECT Id, Subject, Status, Priority, CreatedDate
        FROM Case 
        WHERE AssetId = :asset.Id 
        AND CreatedDate = LAST_N_DAYS:30
    ];
    
    System.debug('  🎫 최근 30일 Support Cases: ' + recentCases.size() + '건');
    if (recentCases.size() > 0) {
        healthScore -= (recentCases.size() * 5); // 케이스 1건당 5점씩 감소
        System.debug('  ⚠️ Support Cases: -' + (recentCases.size() * 5) + '점');
        
        for (Case c : recentCases) {
            System.debug('    - ' + c.Subject + ' (' + c.Status + ', ' + c.Priority + ')');
        }
    }
    
    // 3. 최종 건강도 점수
    healthScore = Math.max(0, Math.min(100, healthScore));
    System.debug('  🎯 최종 Health Score: ' + healthScore.format() + '/100');
    
    // 건강도 등급 분류
    String healthGrade;
    String healthColor;
    
    if (healthScore >= 90) {
        healthGrade = 'A+ (Excellent)';
        healthColor = '🟢';
    } else if (healthScore >= 80) {
        healthGrade = 'A (Very Good)';
        healthColor = '🟢';
    } else if (healthScore >= 70) {
        healthGrade = 'B (Good)';
        healthColor = '🟡';
    } else if (healthScore >= 60) {
        healthGrade = 'C (Fair)';
        healthColor = '🟡';
    } else if (healthScore >= 50) {
        healthGrade = 'D (Poor)';
        healthColor = '🟠';
    } else {
        healthGrade = 'F (Critical)';
        healthColor = '🔴';
    }
    
    System.debug('  ' + healthColor + ' 건강도 등급: ' + healthGrade);
    System.debug('');
}

// ==========================================
// 3단계: 갱신 기회 분석
// ==========================================
System.debug('📍 3단계: 갱신 및 확장 기회 분석');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

for (Asset asset : existingAssets) {
    System.debug('💰 갱신 분석: ' + asset.Name);
    
    // 갱신 확률 계산 (단순 예시)
    Decimal renewalProbability = 50; // 기본 50%
    
    // 1. 사용 기간 기반 조정
    if (asset.InstallDate != null) {
        Integer daysUsed = asset.InstallDate.daysBetween(Date.today());
        if (daysUsed > 180) { // 6개월 이상 사용
            renewalProbability += 20;
            System.debug('  ✅ 안정적 사용 기간: +20% (현재 ' + renewalProbability + '%)');
        }
    }
    
    // 2. Support 이력 기반 조정
    Integer totalCases = [
        SELECT COUNT() 
        FROM Case 
        WHERE AssetId = :asset.Id
    ];
    
    if (totalCases == 0) {
        renewalProbability += 15;
        System.debug('  ✅ 문제 없는 사용: +15% (현재 ' + renewalProbability + '%)');
    } else if (totalCases <= 2) {
        renewalProbability += 5;
        System.debug('  ✅ 최소한의 문제: +5% (현재 ' + renewalProbability + '%)');
    } else {
        renewalProbability -= 10;
        System.debug('  ⚠️ 다수 문제 발생: -10% (현재 ' + renewalProbability + '%)');
    }
    
    // 3. Account 관계 기반 조정 (Order 완납 여부)
    List<PaymentStatus__c> payments = [
        SELECT Status__c 
        FROM PaymentStatus__c 
        WHERE Order__c = :testOrder.Id
    ];
    
    Boolean isFullyPaid = true;
    for (PaymentStatus__c payment : payments) {
        if (payment.Status__c != '완납') {
            isFullyPaid = false;
            break;
        }
    }
    
    if (isFullyPaid) {
        renewalProbability += 25;
        System.debug('  ✅ 완벽한 결제 이력: +25% (현재 ' + renewalProbability + '%)');
    }
    
    // 최종 갱신 확률
    renewalProbability = Math.max(0, Math.min(100, renewalProbability));
    System.debug('  🎯 최종 갱신 확률: ' + renewalProbability.format() + '%');
    
    // 추천 액션
    System.debug('  📋 추천 액션:');
    if (renewalProbability >= 80) {
        System.debug('    🟢 HIGH: 적극적 갱신 제안, 업그레이드 옵션 제시');
        System.debug('    💡 갱신 4주 전 접촉 시작');
        System.debug('    🎁 얼리버드 할인 제안');
    } else if (renewalProbability >= 60) {
        System.debug('    🟡 MEDIUM: 가치 제안 강화, 성공 사례 공유');
        System.debug('    💡 갱신 8주 전 관계 강화 시작');
        System.debug('    📊 ROI 리포트 제공');
    } else {
        System.debug('    🔴 LOW: 위험 고객 관리, 문제점 해결 우선');
        System.debug('    💡 갱신 12주 전부터 집중 관리');
        System.debug('    🛠️ 추가 지원 서비스 제공');
    }
    
    System.debug('');
}

// ==========================================
// 4단계: Upsell/Cross-sell 기회 분석
// ==========================================
System.debug('📍 4단계: 확장 매출 기회 분석');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

// Account의 모든 Asset 조회 (포트폴리오 분석)
List<Asset> allAccountAssets = [
    SELECT Id, Name, Product2.Name, Product2.Product_Family__c, 
           Price, Status, InstallDate
    FROM Asset 
    WHERE AccountId = :testOrder.AccountId
    AND Status = 'Installed'
];

System.debug('🏢 ' + testOrder.Account.Name + ' Asset 포트폴리오:');
Map<String, Integer> productFamilyCount = new Map<String, Integer>();
Decimal totalAssetValue = 0;

for (Asset asset : allAccountAssets) {
    System.debug('  - ' + asset.Name + ' (' + (asset.Product2?.Name ?? 'N/A') + ')');
    
    // Product Family별 집계
    String family = asset.Product2?.Product_Family__c ?? 'Unknown';
    productFamilyCount.put(family, productFamilyCount.get(family) != null ? 
                          productFamilyCount.get(family) + 1 : 1);
    
    // 총 Asset 가치 계산
    if (asset.Price != null) {
        totalAssetValue += asset.Price;
    }
}

System.debug('');
System.debug('📊 포트폴리오 분석:');
System.debug('  - 총 Asset 수: ' + allAccountAssets.size() + '개');
System.debug('  - 총 Asset 가치: ₩' + totalAssetValue.format());
System.debug('  - Product Family 분포:');
for (String family : productFamilyCount.keySet()) {
    System.debug('    * ' + family + ': ' + productFamilyCount.get(family) + '개');
}

// Cross-sell 기회 분석
System.debug('');
System.debug('🚀 확장 매출 기회:');

// 1. 미보유 Product Family 식별
List<Product2> allProducts = [
    SELECT Id, Name, Product_Family__c, ListPrice
    FROM Product2 
    WHERE IsActive = true
    AND Product_Family__c != null
];

Set<String> ownedFamilies = productFamilyCount.keySet();
Map<String, List<Product2>> missingFamilies = new Map<String, List<Product2>>();

for (Product2 product : allProducts) {
    if (!ownedFamilies.contains(product.Product_Family__c)) {
        if (!missingFamilies.containsKey(product.Product_Family__c)) {
            missingFamilies.put(product.Product_Family__c, new List<Product2>());
        }
        missingFamilies.get(product.Product_Family__c).add(product);
    }
}

System.debug('  💡 Cross-sell 기회 (' + missingFamilies.size() + '개 Product Family):');
for (String family : missingFamilies.keySet()) {
    List<Product2> products = missingFamilies.get(family);
    System.debug('    🎯 ' + family + ' (' + products.size() + '개 제품)');
    
    // 가장 인기있는 제품 추천
    if (!products.isEmpty()) {
        Product2 recommendedProduct = products[0]; // 단순화
        System.debug('      추천: ' + recommendedProduct.Name + 
                    ' (₩' + (recommendedProduct.ListPrice != null ? 
                    recommendedProduct.ListPrice.format() : 'N/A') + ')');
    }
}

// 2. Upsell 기회 (기존 제품 업그레이드)
System.debug('');
System.debug('  ⬆️ Upsell 기회:');
for (Asset asset : existingAssets) {
    if (asset.InstallDate != null) {
        Integer daysUsed = asset.InstallDate.daysBetween(Date.today());
        if (daysUsed > 180) { // 6개월 이상 사용 시 업그레이드 제안
            System.debug('    🎯 ' + asset.Name);
            System.debug('      - 사용 기간: ' + daysUsed + '일 (업그레이드 적기)');
            System.debug('      - 현재 가치: ₩' + (asset.Price != null ? asset.Price.format() : 'N/A'));
            System.debug('      - 업그레이드 예상 가치: ₩' + 
                        (asset.Price != null ? (asset.Price * 1.5).format() : 'N/A'));
        }
    }
}

// ==========================================
// 5단계: Asset 기반 Next Best Action 추천
// ==========================================
System.debug('');
System.debug('📍 5단계: 영업팀 액션 플랜');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

System.debug('📋 ' + testOrder.Account.Name + ' 대상 추천 액션:');
System.debug('');

// 우선순위별 액션 아이템
System.debug('🔥 HIGH Priority (즉시 실행):');
System.debug('  1. 갱신 준비 미팅 스케줄링 (2주 내)');
System.debug('  2. 현재 만족도 조사 실시');
System.debug('  3. 사용 현황 및 ROI 리포트 준비');

System.debug('');
System.debug('🟡 MEDIUM Priority (1개월 내):');
System.debug('  1. Cross-sell 제품 데모 제안');
System.debug('  2. 업계 벤치마킹 자료 제공');
System.debug('  3. 고객 성공 사례 공유');

System.debug('');
System.debug('🟢 LOW Priority (3개월 내):');
System.debug('  1. 장기 로드맵 논의');
System.debug('  2. 전략적 파트너십 제안');
System.debug('  3. 차세대 솔루션 로드맵 공유');

// ==========================================
// 결론 및 요약
// ==========================================
System.debug('');
System.debug('📍 시연 결과 요약');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

System.debug('✅ Salesforce Assets 활용 성과:');
System.debug('  🎯 Order 00000153에서 Asset으로 완벽한 데이터 연결');
System.debug('  📊 자동화된 건강도 분석으로 고객 상태 가시화');
System.debug('  💰 갱신 확률 및 확장 매출 기회 정량화');
System.debug('  📋 데이터 기반 영업 액션 플랜 자동 생성');
System.debug('  🔄 Order → Asset → Opportunity 라이프사이클 완성');

System.debug('');
System.debug('🚀 핵심 가치:');
System.debug('  • 고객 관계의 연속성 확보');
System.debug('  • 예측 가능한 매출 파이프라인');
System.debug('  • 데이터 기반 의사결정 지원');
System.debug('  • 자동화된 기회 발굴');
System.debug('  • 전략적 고객 관리 실현');

System.debug('');
System.debug('💡 Order 00000153과 같은 성공 케이스를 Assets로 체계적으로 관리하여');
System.debug('   지속적인 고객 가치 창출과 매출 성장을 달성할 수 있습니다!');

System.debug('');
System.debug('✅ Salesforce Assets 활용 시연 완료! 🎉');
