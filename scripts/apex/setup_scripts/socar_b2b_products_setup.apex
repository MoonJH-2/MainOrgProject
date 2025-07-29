// 🚗 쏘카 B2B 제품 카탈로그 및 구독 서비스 설정
// Product2 및 PricebookEntry 생성

System.debug('=== 쏘카 B2B 구독 서비스 제품 카탈로그 생성 ===');

// 1. 쏘카 B2B 제품 생성
List<Product2> socarProducts = new List<Product2>();

// 기업 차량 관리 서비스
socarProducts.add(new Product2(
    Name = '쏘카 비즈니스 베이직',
    ProductCode = 'SOCAR_BIZ_BASIC',
    Family = 'Fleet Management',
    Description = '중소기업을 위한 기본 차량 관리 서비스 (월 10대 이하)',
    IsActive = true
));

socarProducts.add(new Product2(
    Name = '쏘카 비즈니스 프로',
    ProductCode = 'SOCAR_BIZ_PRO', 
    Family = 'Fleet Management',
    Description = '중견기업을 위한 전문 차량 관리 서비스 (월 50대 이하)',
    IsActive = true
));

socarProducts.add(new Product2(
    Name = '쏘카 비즈니스 엔터프라이즈',
    ProductCode = 'SOCAR_BIZ_ENT',
    Family = 'Fleet Management', 
    Description = '대기업을 위한 통합 차량 관리 서비스 (무제한)',
    IsActive = true
));

// 장기렌터카 서비스
socarProducts.add(new Product2(
    Name = '쏘카 장기렌터카 12개월',
    ProductCode = 'SOCAR_LONG_12M',
    Family = 'Long-term Rental',
    Description = '12개월 장기렌터카 서비스 (경형/소형차)',
    IsActive = true
));

socarProducts.add(new Product2(
    Name = '쏘카 장기렌터카 24개월', 
    ProductCode = 'SOCAR_LONG_24M',
    Family = 'Long-term Rental',
    Description = '24개월 장기렌터카 서비스 (중형/대형차)',
    IsActive = true
));

socarProducts.add(new Product2(
    Name = '쏘카 장기렌터카 36개월',
    ProductCode = 'SOCAR_LONG_36M', 
    Family = 'Long-term Rental',
    Description = '36개월 장기렌터카 서비스 (프리미엄/전기차)',
    IsActive = true
));

// 카셰어링 서비스
socarProducts.add(new Product2(
    Name = '쏘카 비즈니스 카셰어링',
    ProductCode = 'SOCAR_CARSHARE_BIZ',
    Family = 'Car Sharing',
    Description = '기업 전용 카셰어링 서비스 (시간당 이용)',
    IsActive = true
));

// 전기차 특화 서비스
socarProducts.add(new Product2(
    Name = '쏘카 그린 비즈니스',
    ProductCode = 'SOCAR_GREEN_BIZ',
    Family = 'Electric Vehicle',
    Description = '친환경 전기차 전용 기업 서비스',
    IsActive = true
));

// 부가 서비스
socarProducts.add(new Product2(
    Name = '쏘카 드라이버 매칭',
    ProductCode = 'SOCAR_DRIVER_MATCH',
    Family = 'Additional Service',
    Description = '전문 드라이버 매칭 서비스',
    IsActive = true
));

socarProducts.add(new Product2(
    Name = '쏘카 차량 관리 API',
    ProductCode = 'SOCAR_API_SERVICE',
    Family = 'Digital Service',
    Description = '기업 시스템 연동을 위한 API 서비스',
    IsActive = true
));

try {
    insert socarProducts;
    System.debug('✅ 쏘카 B2B 제품 ' + socarProducts.size() + '개 생성 완료');
} catch (Exception e) {
    System.debug('❌ 제품 생성 오류: ' + e.getMessage());
    return;
}

// 2. Standard Pricebook Entry 생성 (필수)
Id standardPricebookId = Test.getStandardPricebookId();
List<PricebookEntry> standardEntries = new List<PricebookEntry>();

for (Product2 product : socarProducts) {
    standardEntries.add(new PricebookEntry(
        Pricebook2Id = standardPricebookId,
        Product2Id = product.Id,
        UnitPrice = 100000, // 기본 가격
        IsActive = true
    ));
}

try {
    insert standardEntries;
    System.debug('✅ Standard Pricebook Entry ' + standardEntries.size() + '개 생성 완료');
} catch (Exception e) {
    System.debug('❌ Standard Pricebook Entry 생성 오류: ' + e.getMessage());
}

// 3. 쏘카 B2B 전용 Pricebook 생성
Pricebook2 socarPricebook = new Pricebook2(
    Name = '쏘카 B2B 가격정책 2024',
    Description = '쏘카 B2B 서비스 전용 가격 정책',
    IsActive = true
);

try {
    insert socarPricebook;
    System.debug('✅ 쏘카 B2B Pricebook 생성 완료: ' + socarPricebook.Id);
} catch (Exception e) {
    System.debug('❌ Pricebook 생성 오류: ' + e.getMessage());
    return;
}

// 4. 쏘카 B2B Pricebook Entry 생성 (실제 구독 가격)
List<PricebookEntry> socarPricingEntries = new List<PricebookEntry>();

// 제품별 실제 구독 가격 설정
Map<String, Decimal> productPricing = new Map<String, Decimal>{
    'SOCAR_BIZ_BASIC' => 980000,      // 월 98만원
    'SOCAR_BIZ_PRO' => 2450000,       // 월 245만원  
    'SOCAR_BIZ_ENT' => 4900000,       // 월 490만원
    'SOCAR_LONG_12M' => 650000,       // 월 65만원
    'SOCAR_LONG_24M' => 580000,       // 월 58만원 (할인)
    'SOCAR_LONG_36M' => 520000,       // 월 52만원 (최대 할인)
    'SOCAR_CARSHARE_BIZ' => 1200000,  // 월 120만원
    'SOCAR_GREEN_BIZ' => 1450000,     // 월 145만원
    'SOCAR_DRIVER_MATCH' => 350000,   // 월 35만원
    'SOCAR_API_SERVICE' => 150000     // 월 15만원
};

for (Product2 product : socarProducts) {
    Decimal price = productPricing.get(product.ProductCode);
    if (price != null) {
        socarPricingEntries.add(new PricebookEntry(
            Pricebook2Id = socarPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = price,
            IsActive = true
        ));
    }
}

try {
    insert socarPricingEntries;
    System.debug('✅ 쏘카 B2B 가격 정책 ' + socarPricingEntries.size() + '개 설정 완료');
} catch (Exception e) {
    System.debug('❌ 가격 정책 설정 오류: ' + e.getMessage());
}

// 5. 생성 결과 요약
System.debug('🎉 쏘카 B2B 제품 카탈로그 생성 완료!');
System.debug('📊 생성 완료 요약:');
System.debug('- B2B 제품: ' + socarProducts.size() + '개');
System.debug('- 가격 정책: ' + socarPricingEntries.size() + '개');

Decimal totalMonthlyRevenuePotential = 0;
for (PricebookEntry entry : socarPricingEntries) {
    totalMonthlyRevenuePotential += entry.UnitPrice;
}
System.debug('- 전체 제품 월간 수익 잠재력: ₩' + String.valueOf(totalMonthlyRevenuePotential.longValue()) + '원');

System.debug('🚗 쏘카 B2B 구독 서비스 준비 완료!');
