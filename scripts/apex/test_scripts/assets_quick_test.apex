/**
 * 간단한 Assets 활용 테스트
 * Order 00000153 기반 핵심 기능만 시연
 */

System.debug('=== 간단 Assets 활용 테스트 ===');

// Order 조회
List<Order> orders = [
    SELECT Id, OrderNumber, AccountId, Account.Name, Status, TotalAmount
    FROM Order 
    WHERE OrderNumber = '00000153'
    LIMIT 1
];

if (orders.isEmpty()) {
    System.debug('❌ Order 00000153을 찾을 수 없습니다.');
    return;
}

Order testOrder = orders[0];
System.debug('✅ Order 정보: ' + testOrder.OrderNumber + ' - ' + testOrder.Account.Name);

// 연결된 Asset 조회
List<Asset> assets = [
    SELECT Id, Name, Status, SerialNumber, AccountId
    FROM Asset 
    WHERE SerialNumber = :testOrder.OrderNumber
    OR Name LIKE '%' + testOrder.OrderNumber + '%'
];

System.debug('🏭 연결된 Assets: ' + assets.size() + '개');
for (Asset asset : assets) {
    System.debug('  - ' + asset.Name + ' (' + asset.Status + ')');
}

// PaymentStatus 확인
List<PaymentStatus__c> payments = [
    SELECT Id, Status__c, Amount__c
    FROM PaymentStatus__c 
    WHERE Order__c = :testOrder.Id
];

System.debug('💳 Payment Status: ' + payments.size() + '건');
Integer completedPayments = 0;
for (PaymentStatus__c payment : payments) {
    System.debug('  - Status: ' + payment.Status__c + ', Amount: ' + payment.Amount__c);
    if (payment.Status__c == '완납') {
        completedPayments++;
    }
}

// 갱신 기회 분석
Decimal renewalScore = 50; // 기본 50%
if (completedPayments == payments.size() && payments.size() > 0) {
    renewalScore += 30;
    System.debug('✅ 완벽한 결제 이력: +30%');
}

if (assets.size() > 0) {
    renewalScore += 20;
    System.debug('✅ Asset 보유: +20%');
}

System.debug('🎯 갱신 가능성: ' + renewalScore + '%');

if (renewalScore >= 80) {
    System.debug('🟢 HIGH: 적극적 갱신 제안 권장');
} else if (renewalScore >= 60) {
    System.debug('🟡 MEDIUM: 관계 강화 필요');
} else {
    System.debug('🔴 LOW: 위험 고객 관리');
}

System.debug('');
System.debug('✅ Assets 기반 고객 분석 완료!');
System.debug('💡 ' + testOrder.Account.Name + '는 ' + renewalScore + '% 확률로 갱신 예상됩니다.');
