/**
 * Asset 로직 단계별 실행 시연
 * 각 단계의 실제 동작을 보여주는 시뮬레이션
 */

System.debug('=== Asset 로직 단계별 실행 시연 ===');
System.debug('');

// 테스트용 Order 선택
List<Order> testOrders = [
    SELECT Id, OrderNumber, AccountId, Account.Name, Account.Industry,
           Account.NumberOfEmployees, Account.AnnualRevenue, Account.Key_Account__c,
           Account.CustomerPriority__c, TotalAmount, EffectiveDate
    FROM Order 
    WHERE AccountId != null
    LIMIT 1
];

if (testOrders.isEmpty()) {
    System.debug('테스트용 Order가 없습니다.');
    return;
}

Order testOrder = testOrders[0];
System.debug('🎯 선택된 Order: ' + testOrder.OrderNumber + ' (' + testOrder.Account.Name + ')');
System.debug('');

// ============================================
// 1단계: PaymentStatus 완납 감지 시뮬레이션
// ============================================
System.debug('📍 1단계: PaymentStatus 완납 감지');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

List<PaymentStatus__c> payments = [
    SELECT Status__c, InstallmentNumber__c, Amount__c
    FROM PaymentStatus__c 
    WHERE Order__c = :testOrder.Id
    ORDER BY InstallmentNumber__c
];

if (payments.isEmpty()) {
    System.debug('⚠️ PaymentStatus가 없습니다. 시뮬레이션을 위해 생성 필요');
} else {
    System.debug('💳 현재 PaymentStatus 상태:');
    for (PaymentStatus__c payment : payments) {
        System.debug('  ' + payment.InstallmentNumber__c + '차: ' + payment.Status__c + 
                    ' (' + (payment.Amount__c != null ? payment.Amount__c.format() : '0') + '원)');
    }
}
System.debug('🔍 트리거 조건: Status__c가 "완납"으로 변경된 경우');
System.debug('');

// ============================================
// 2단계: 완납 상태 검증
// ============================================
System.debug('📍 2단계: 완납 상태 검증');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

Boolean isFullyPaid = true;
Integer totalPayments = payments.size();
Integer completedPayments = 0;

for (PaymentStatus__c payment : payments) {
    if (payment.Status__c == '완납') {
        completedPayments++;
    } else {
        isFullyPaid = false;
    }
}

System.debug('📊 납부 통계:');
System.debug('  - 총 납부 회차: ' + totalPayments);
System.debug('  - 완료된 회차: ' + completedPayments);
System.debug('  - 완납 여부: ' + isFullyPaid);
System.debug('✅ 검증 결과: ' + (isFullyPaid ? 'Asset 생성 가능' : '납부 미완료'));
System.debug('');

// ============================================
// 3단계: Account 인텔리전스 분석
// ============================================
System.debug('📍 3단계: Account 인텔리전스 분석');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

System.debug('🏢 Account 기본 정보:');
System.debug('  - 회사명: ' + testOrder.Account.Name);
System.debug('  - 산업군: ' + (testOrder.Account.Industry ?? '미분류'));
System.debug('  - 직원 수: ' + (testOrder.Account.NumberOfEmployees != null ? testOrder.Account.NumberOfEmployees.format() : '미확인') + '명');
System.debug('  - 연매출: ' + (testOrder.Account.AnnualRevenue != null ? testOrder.Account.AnnualRevenue.format() : '미확인') + '원');
System.debug('  - Key Account: ' + (testOrder.Account.Key_Account__c ? 'Yes' : 'No'));
System.debug('  - 고객 우선순위: ' + (testOrder.Account.CustomerPriority__c ?? '일반'));
System.debug('');

// ============================================
// 4단계: 비즈니스 규칙 적용
// ============================================
System.debug('📍 4단계: 비즈니스 규칙 적용');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

Integer lifecycleMonths = 12; // 기본값
String companySize = '중소기업';

// 기업 규모별 분류
if (testOrder.Account.NumberOfEmployees != null) {
    if (testOrder.Account.NumberOfEmployees >= 1000) {
        lifecycleMonths = 36;
        companySize = '대기업';
        System.debug('🏢 기업 규모: 대기업 (1000명+) → 36개월 기본 Lifecycle');
    } else if (testOrder.Account.NumberOfEmployees >= 100) {
        lifecycleMonths = 24;
        companySize = '중견기업';
        System.debug('🏢 기업 규모: 중견기업 (100-999명) → 24개월 기본 Lifecycle');
    } else {
        lifecycleMonths = 12;
        companySize = '중소기업';
        System.debug('🏢 기업 규모: 중소기업 (~99명) → 12개월 기본 Lifecycle');
    }
}

// Key Account 보너스
if (testOrder.Account.Key_Account__c) {
    lifecycleMonths += 12;
    System.debug('🌟 Key Account 보너스: +12개월 연장');
}

// 고매출 보너스
if (testOrder.Account.AnnualRevenue != null && testOrder.Account.AnnualRevenue >= 100000000) {
    lifecycleMonths += 6;
    System.debug('💰 고매출 기업 보너스: +6개월 연장');
}

System.debug('⏰ 최종 Lifecycle: ' + lifecycleMonths + '개월');
System.debug('');

// ============================================
// 5단계: Industry별 맞춤 전략
// ============================================
System.debug('📍 5단계: Industry별 맞춤 전략');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

List<String> industryInsights = new List<String>();
String industry = testOrder.Account.Industry;

if (String.isNotBlank(industry)) {
    System.debug('🎯 ' + industry + ' 업계 맞춤 전략:');
    
    switch on industry {
        when 'Technology' {
            industryInsights.add('최신 기술 트렌드 및 혁신 솔루션 제안');
            industryInsights.add('빠른 기술 도입 성향으로 조기 갱신 가능성 높음');
        }
        when 'Manufacturing' {
            industryInsights.add('생산성 향상 및 비용 절감 효과 강조');
            industryInsights.add('장기 계약 선호하는 업계 특성 활용');
        }
        when 'Healthcare' {
            industryInsights.add('규제 준수 및 보안 강화 솔루션 중점');
            industryInsights.add('안정성과 신뢰성 우선 고려');
        }
        when 'Financial Services' {
            industryInsights.add('보안 및 컴플라이언스 최우선');
            industryInsights.add('고가용성 솔루션 요구사항 반영');
        }
        when else {
            industryInsights.add('일반적인 비즈니스 솔루션 접근');
            industryInsights.add('업계 특성 파악 후 맞춤 전략 수립');
        }
    }
    
    for (String insight : industryInsights) {
        System.debug('  • ' + insight);
    }
} else {
    System.debug('⚠️ Industry 정보 없음 - 일반 전략 적용');
}
System.debug('');

// ============================================
// 6단계: Asset 설계
// ============================================
System.debug('📍 6단계: Asset 설계');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

// Asset 이름 구성
List<String> nameParts = new List<String>();
nameParts.add(testOrder.Account.Name);
nameParts.add('[' + companySize + ']');

if (testOrder.Account.Key_Account__c) {
    nameParts.add('(Key Account)');
}

if (String.isNotBlank(industry)) {
    nameParts.add('[' + industry + ']');
}

String finalAssetName = String.join(nameParts, ' ') + ' - ' + testOrder.OrderNumber;

System.debug('🏷️ Asset 설계 정보:');
System.debug('  - Asset 이름: ' + finalAssetName);
System.debug('  - Serial Number: ' + testOrder.OrderNumber);
System.debug('  - 상태: Installed');
System.debug('  - 구매일: ' + (testOrder.EffectiveDate != null ? testOrder.EffectiveDate.format() : Date.today().format()));
System.debug('  - 설치일: ' + Date.today().format());
System.debug('');

// ============================================
// 7단계: 상세 Description 생성
// ============================================
System.debug('📍 7단계: 상세 Description 생성');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

List<String> descriptionParts = new List<String>();

descriptionParts.add('=== Order 정보 ===');
descriptionParts.add('Order Number: ' + testOrder.OrderNumber);
descriptionParts.add('총 금액: ' + (testOrder.TotalAmount != null ? testOrder.TotalAmount.format() : '0') + '원');

descriptionParts.add('=== Account 분석 ===');
descriptionParts.add('산업군: ' + (industry ?? '미분류'));
descriptionParts.add('기업규모: ' + companySize);
descriptionParts.add('예상 Lifecycle: ' + lifecycleMonths + '개월');

if (!industryInsights.isEmpty()) {
    descriptionParts.add('=== 비즈니스 인사이트 ===');
    for (String insight : industryInsights) {
        descriptionParts.add('• ' + insight);
    }
}

String finalDescription = String.join(descriptionParts, '\n');
System.debug('📝 Asset Description 미리보기:');
System.debug(finalDescription);
System.debug('');

// ============================================
// 8단계: 후속 액션 계획
// ============================================
System.debug('📍 8단계: 후속 액션 계획');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

List<String> plannedTasks = new List<String>();

// Account Manager Task
System.debug('📋 생성될 Task 목록:');

// Key Account 특별 관리
if (testOrder.Account.Key_Account__c) {
    plannedTasks.add('[Key Account] VIP 고객 특별 관리 - 1일 후, 높은 우선순위');
}

// 고우선순위 고객
if (testOrder.Account.CustomerPriority__c == 'High') {
    plannedTasks.add('[고우선순위] 즉시 대응 필요 - 당일, 높은 우선순위');
}

// 기본 갱신 관리 Task
plannedTasks.add('[Asset 관리] 정기 점검 및 갱신 준비 - 7일 후, 보통 우선순위');

for (String task : plannedTasks) {
    System.debug('  • ' + task);
}

if (plannedTasks.isEmpty()) {
    System.debug('  • 기본 Asset 관리 Task만 생성됩니다.');
}
System.debug('');

// ============================================
// 9단계: UI 네비게이션 지원
// ============================================
System.debug('📍 9단계: UI 네비게이션 지원');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

System.debug('🖥️ Order 화면에 표시될 정보:');
System.debug('  - 납부 진행률: ' + (totalPayments > 0 ? (completedPayments * 100 / totalPayments) : 0) + '%');
System.debug('  - 완료 회차: ' + completedPayments + '/' + totalPayments);
System.debug('  - Asset 상태: ' + (isFullyPaid ? 'Asset 생성 가능/완료' : '납부 진행 중'));
System.debug('  - 네비게이션: ' + (isFullyPaid ? 'Asset 보기 버튼 표시' : '진행률 바 표시'));
System.debug('');

// ============================================
// 시스템 흐름 요약
// ============================================
System.debug('📍 전체 시스템 흐름 요약');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

System.debug('');
System.debug('🔄 PaymentStatus 완납 → Account 분석 → Asset 생성 → 후속 관리');
System.debug('   ↓');
System.debug('1️⃣ 트리거 자동 감지 (PaymentStatus__c)');
System.debug('   ↓');
System.debug('2️⃣ 완납 상태 검증 (모든 PaymentStatus 확인)');
System.debug('   ↓');
System.debug('3️⃣ Account 정보 수집 (기업규모, 업계, 고객등급)');
System.debug('   ↓');
System.debug('4️⃣ 비즈니스 규칙 적용 (' + lifecycleMonths + '개월 Lifecycle)');
System.debug('   ↓');
System.debug('5️⃣ Industry 맞춤 전략 (' + (industry ?? '일반') + ' 특화)');
System.debug('   ↓');
System.debug('6️⃣ Asset 생성 (' + finalAssetName + ')');
System.debug('   ↓');
System.debug('7️⃣ 상세 분석 Description 포함');
System.debug('   ↓');
System.debug('8️⃣ 후속 Task 자동 생성 (' + plannedTasks.size() + '개)');
System.debug('   ↓');
System.debug('9️⃣ Order 화면에서 원클릭 Asset 네비게이션');
System.debug('');

System.debug('✅ Asset 로직 단계별 시연 완료!');
System.debug('💡 이 전체 프로세스는 PaymentStatus 완납 시 자동으로 실행됩니다.');
System.debug('🚀 Account 특성별 맞춤형 Asset 관리로 고객 만족도와 매출 향상을 달성합니다!');
