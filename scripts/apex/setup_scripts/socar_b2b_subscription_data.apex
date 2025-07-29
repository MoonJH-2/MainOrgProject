// 🚗 쏘카 B2B 기업 고객 및 구독 Assets 생성 스크립트
// 실제 한국 기업들의 차량 구독 서비스 시나리오

System.debug('=== 쏘카 B2B 기업 고객 및 구독 서비스 데이터 생성 ===');

// 1. 한국 대기업 고객 생성
List<Account> corporateCustomers = new List<Account>();

// 대기업 고객들
corporateCustomers.add(new Account(
    Name = '삼성전자',
    Type = 'Customer',
    Industry = '전자제품',
    Phone = '02-2255-0114',
    BillingStreet = '경기도 수원시 영통구 삼성로 129',
    BillingCity = '수원시',
    BillingState = '경기도', 
    BillingCountry = '대한민국',
    AnnualRevenue = 2500000000000.00,
    NumberOfEmployees = 267937,
    Description = '글로벌 전자제품 제조업체 - 임직원 통근 및 업무용 차량 필요'
));

corporateCustomers.add(new Account(
    Name = 'LG전자',
    Type = 'Customer',
    Industry = '전자제품', 
    Phone = '02-3777-1114',
    BillingStreet = '서울특별시 영등포구 여의대로 128',
    BillingCity = '서울특별시',
    BillingState = '서울특별시',
    BillingCountry = '대한민국',
    AnnualRevenue = 750000000000.00,
    NumberOfEmployees = 75000,
    Description = '가전제품 및 전자부품 제조 - 영업팀 차량 및 물류 차량 운영'
));

corporateCustomers.add(new Account(
    Name = '네이버',
    Type = 'Customer',
    Industry = 'IT 서비스',
    Phone = '1588-3820',
    BillingStreet = '경기도 성남시 분당구 불정로 6',
    BillingCity = '성남시',
    BillingState = '경기도',
    BillingCountry = '대한민국', 
    AnnualRevenue = 56000000000.00,
    NumberOfEmployees = 3500,
    Description = 'IT 서비스 및 플랫폼 운영 - 직원 셔틀 및 배송 서비스 차량'
));

corporateCustomers.add(new Account(
    Name = '카카오',
    Type = 'Customer',
    Industry = 'IT 서비스',
    Phone = '1577-3754', 
    BillingStreet = '제주특별자치도 제주시 첨단로 242',
    BillingCity = '제주시',
    BillingState = '제주특별자치도',
    BillingCountry = '대한민국',
    AnnualRevenue = 65000000000.00,
    NumberOfEmployees = 4500,
    Description = '모바일 플랫폼 및 콘텐츠 서비스 - 임직원 통근 지원 차량'
));

corporateCustomers.add(new Account(
    Name = '현대자동차',
    Type = 'Customer',
    Industry = '자동차',
    Phone = '02-3464-1114',
    BillingStreet = '서울특별시 서초구 헌릉로 12', 
    BillingCity = '서울특별시',
    BillingState = '서울특별시',
    BillingCountry = '대한민국',
    AnnualRevenue = 1200000000000.00,
    NumberOfEmployees = 120000,
    Description = '자동차 제조업체 - 시승 차량 및 임직원 업무용 차량'
));

// 중견기업 고객들
corporateCustomers.add(new Account(
    Name = '한화시스템',
    Type = 'Customer',
    Industry = '항공우주/방산',
    Phone = '02-729-3114',
    BillingStreet = '서울특별시 종로구 청계천로 86',
    BillingCity = '서울특별시', 
    BillingState = '서울특별시',
    BillingCountry = '대한민국',
    AnnualRevenue = 25000000000.00,
    NumberOfEmployees = 2500,
    Description = '항공우주 및 방산업체 - 보안 운송 및 임직원 차량'
));

corporateCustomers.add(new Account(
    Name = '신세계백화점',
    Type = 'Customer', 
    Industry = '유통업',
    Phone = '02-1234-1234',
    BillingStreet = '서울특별시 중구 소공로 63',
    BillingCity = '서울특별시',
    BillingState = '서울특별시',
    BillingCountry = '대한민국',
    AnnualRevenue = 180000000000.00,
    NumberOfEmployees = 8000,
    Description = '백화점 및 유통업 - 고객 서비스 및 물류 배송 차량'
));

corporateCustomers.add(new Account(
    Name = '우아한형제들',
    Type = 'Customer',
    Industry = '배달 플랫폼',
    Phone = '1588-8008',
    BillingStreet = '서울특별시 송파구 위례성대로 2',
    BillingCity = '서울특별시',
    BillingState = '서울특별시', 
    BillingCountry = '대한민국',
    AnnualRevenue = 8000000000.00,
    NumberOfEmployees = 1200,
    Description = '배달 플랫폼 서비스 - 배달 차량 및 임직원 이동 차량'
));

try {
    insert corporateCustomers;
    System.debug('✅ 기업 고객 ' + corporateCustomers.size() + '개 생성 완료'); 
} catch (Exception e) {
    System.debug('❌ 기업 고객 생성 오류: ' + e.getMessage());
    return;
}

// 2. 쏘카 B2B 제품 조회 (이미 생성되어 있다고 가정)
List<Product2> socarProducts = [
    SELECT Id, Name, ProductCode, Family
    FROM Product2 
    WHERE ProductCode LIKE 'SOCAR_%'
    AND IsActive = true
];

if (socarProducts.isEmpty()) {
    System.debug('❌ 쏘카 B2B 제품이 존재하지 않습니다. 먼저 socar_b2b_products_setup.apex를 실행해주세요.');
    return;
}

System.debug('✅ 쏘카 B2B 제품 ' + socarProducts.size() + '개 확인');

// 3. 구독 Assets 생성 (즉시 갱신 가능하도록 설정)
List<Asset> subscriptionAssets = new List<Asset>();
Date installDate = Date.today().addDays(-15); // 15일 전 설치
Date usageEndDate = Date.today().addDays(45);  // 45일 후 만료 (갱신 대상)

// 각 기업별 구독 서비스 시나리오
Map<String, List<String>> companySubscriptions = new Map<String, List<String>>{
    '삼성전자' => new List<String>{'SOCAR_BIZ_ENT', 'SOCAR_GREEN_BIZ', 'SOCAR_API_SERVICE'},
    'LG전자' => new List<String>{'SOCAR_BIZ_PRO', 'SOCAR_LONG_24M', 'SOCAR_DRIVER_MATCH'},
    '네이버' => new List<String>{'SOCAR_BIZ_PRO', 'SOCAR_CARSHARE_BIZ', 'SOCAR_API_SERVICE'},
    '카카오' => new List<String>{'SOCAR_BIZ_BASIC', 'SOCAR_CARSHARE_BIZ', 'SOCAR_GREEN_BIZ'},
    '현대자동차' => new List<String>{'SOCAR_BIZ_ENT', 'SOCAR_LONG_36M'},
    '한화시스템' => new List<String>{'SOCAR_BIZ_BASIC', 'SOCAR_DRIVER_MATCH'},
    '신세계백화점' => new List<String>{'SOCAR_BIZ_PRO', 'SOCAR_LONG_12M'},
    '우아한형제들' => new List<String>{'SOCAR_CARSHARE_BIZ', 'SOCAR_GREEN_BIZ'}
};

// 제품 가격 매핑
Map<String, Decimal> productPrices = new Map<String, Decimal>{
    'SOCAR_BIZ_BASIC' => 980000,
    'SOCAR_BIZ_PRO' => 2450000, 
    'SOCAR_BIZ_ENT' => 4900000,
    'SOCAR_LONG_12M' => 650000,
    'SOCAR_LONG_24M' => 580000,
    'SOCAR_LONG_36M' => 520000,
    'SOCAR_CARSHARE_BIZ' => 1200000,
    'SOCAR_GREEN_BIZ' => 1450000,
    'SOCAR_DRIVER_MATCH' => 350000,
    'SOCAR_API_SERVICE' => 150000
};

Integer assetCounter = 1;
for (Account company : corporateCustomers) {
    List<String> subscriptionCodes = companySubscriptions.get(company.Name);
    
    if (subscriptionCodes != null) {
        for (String productCode : subscriptionCodes) {
            // 해당 제품 찾기
            Product2 product = null;
            for (Product2 p : socarProducts) {
                if (p.ProductCode == productCode) {
                    product = p;
                    break;
                }
            }
            
            if (product != null) {
                // 회사 규모에 따른 차량 수량 결정
                Integer quantity = 1;
                if (company.NumberOfEmployees > 100000) quantity = 5;
                else if (company.NumberOfEmployees > 10000) quantity = 3; 
                else if (company.NumberOfEmployees > 1000) quantity = 2;
                
                Asset subscriptionAsset = new Asset(
                    Name = company.Name + ' - ' + product.Name,
                    AccountId = company.Id,
                    Product2Id = product.Id,
                    Status = 'Installed',
                    InstallDate = installDate.addDays(-(Math.mod(assetCounter, 30))), // 설치일 분산
                    PurchaseDate = installDate.addDays(-(Math.mod(assetCounter, 30))),
                    UsageEndDate = usageEndDate.addDays(Math.mod(assetCounter, 60)), // 만료일 분산
                    Price = productPrices.get(productCode),
                    Quantity = quantity,
                    Description = company.Name + '의 ' + product.Family + ' 구독 서비스 - ' + 
                                 quantity + '대 차량 포함, 월간 관리비 포함'
                );
                
                subscriptionAssets.add(subscriptionAsset);
                assetCounter++;
            }
        }
    }
}

try {
    insert subscriptionAssets;
    System.debug('✅ 구독 Assets ' + subscriptionAssets.size() + '개 생성 완료');
} catch (Exception e) {
    System.debug('❌ 구독 Assets 생성 오류: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
    return;
}

// 4. 생성 결과 요약
Decimal totalMonthlyRevenue = 0;
Integer totalVehicles = 0;
Map<String, Integer> serviceTypeCount = new Map<String, Integer>();

for (Asset asset : subscriptionAssets) {
    totalMonthlyRevenue += (asset.Price != null ? asset.Price : 0) * (asset.Quantity != null ? asset.Quantity : 1);
    totalVehicles += (asset.Quantity != null ? asset.Quantity : 1);
    
    String serviceType = asset.Name.split(' - ')[1];
    Integer count = serviceTypeCount.get(serviceType);
    serviceTypeCount.put(serviceType, (count != null ? count : 0) + 1);
}

System.debug('🎉 쏘카 B2B 구독 서비스 데이터 생성 완료!');
System.debug('📊 생성 완료 요약:');
System.debug('- 기업 고객: ' + corporateCustomers.size() + '개');
System.debug('- 구독 서비스: ' + subscriptionAssets.size() + '개');
System.debug('- 총 차량 수: ' + totalVehicles + '대');
System.debug('- 총 월간 수익: ₩' + String.valueOf(totalMonthlyRevenue.longValue()) + '원');

System.debug('📈 서비스별 구독 현황:');
for (String serviceType : serviceTypeCount.keySet()) {
    System.debug('- ' + serviceType + ': ' + serviceTypeCount.get(serviceType) + '개');
}

// 5. 갱신 대상 확인
List<Asset> renewalTargets = [
    SELECT Id, Name, Account.Name, UsageEndDate, Price
    FROM Asset 
    WHERE UsageEndDate <= :Date.today().addDays(60)
    AND Status = 'Installed'
    ORDER BY UsageEndDate ASC
];

System.debug('🔄 60일 내 갱신 대상: ' + renewalTargets.size() + '개');
for (Asset target : renewalTargets) {
    Integer daysToExpiry = Date.today().daysBetween(target.UsageEndDate);
    System.debug('- ' + target.Account.Name + ': ' + target.Name + 
                ' (만료: ' + daysToExpiry + '일 후, 수익: ₩' + 
                String.valueOf(target.Price.longValue()) + ')');
}

System.debug('🚗 쏘카 B2B 구독 관리 대시보드 테스트 준비 완료!');
