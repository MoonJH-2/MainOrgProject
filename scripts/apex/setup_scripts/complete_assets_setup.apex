// 🚀 완전한 Assets 테스트 데이터 생성 스크립트
// 한국 대기업 5개사 + 즉시 갱신 가능한 Assets 생성

System.debug('=== 한국 대기업 Assets 테스트 데이터 생성 시작 ===');

// 1. 기존 테스트 데이터 정리 (선택사항)
try {
    List<Asset> existingAssets = [SELECT Id FROM Asset WHERE Name LIKE '%테스트%' LIMIT 100];
    if (!existingAssets.isEmpty()) {
        delete existingAssets;
        System.debug('기존 테스트 Assets ' + existingAssets.size() + '개 정리 완료');
    }
} catch (Exception e) {
    System.debug('기존 데이터 정리 중 오류 (무시): ' + e.getMessage());
}

// 2. 한국 대기업 계정 생성
List<Account> companies = new List<Account>();

// 삼성전자
companies.add(new Account(
    Name = '삼성전자',
    Type = 'Customer',
    Industry = '전자제품',
    Phone = '02-2255-0114',
    BillingStreet = '경기도 수원시 영통구 삼성로 129',
    BillingCity = '수원시',
    BillingState = '경기도',
    BillingCountry = '대한민국',
    AnnualRevenue = 2500000000000.00,
    NumberOfEmployees = 267937
));

// LG전자
companies.add(new Account(
    Name = 'LG전자',
    Type = 'Customer', 
    Industry = '전자제품',
    Phone = '02-3777-1114',
    BillingStreet = '서울특별시 영등포구 여의대로 128',
    BillingCity = '서울특별시',
    BillingState = '서울특별시',
    BillingCountry = '대한민국',
    AnnualRevenue = 750000000000.00,
    NumberOfEmployees = 75000
));

// 네이버
companies.add(new Account(
    Name = '네이버',
    Type = 'Customer',
    Industry = 'IT 서비스',
    Phone = '1588-3820',
    BillingStreet = '경기도 성남시 분당구 불정로 6',
    BillingCity = '성남시',
    BillingState = '경기도',
    BillingCountry = '대한민국',
    AnnualRevenue = 56000000000.00,
    NumberOfEmployees = 3500
));

// 카카오
companies.add(new Account(
    Name = '카카오',
    Type = 'Customer',
    Industry = 'IT 서비스',
    Phone = '1577-3754',
    BillingStreet = '제주특별자치도 제주시 첨단로 242',
    BillingCity = '제주시',
    BillingState = '제주특별자치도',
    BillingCountry = '대한민국',
    AnnualRevenue = 65000000000.00,
    NumberOfEmployees = 4500
));

// 현대자동차
companies.add(new Account(
    Name = '현대자동차',
    Type = 'Customer',
    Industry = '자동차',
    Phone = '02-3464-1114',
    BillingStreet = '서울특별시 서초구 헌릉로 12',
    BillingCity = '서울특별시',
    BillingState = '서울특별시',
    BillingCountry = '대한민국',
    AnnualRevenue = 1200000000000.00,
    NumberOfEmployees = 120000
));

try {
    insert companies;
    System.debug('✅ 대기업 계정 ' + companies.size() + '개 생성 완료');
} catch (Exception e) {
    System.debug('❌ 계정 생성 오류: ' + e.getMessage());
    return;
}

// 3. Product 생성 (Assets용)
List<Product2> products = new List<Product2>();

products.add(new Product2(
    Name = 'Enterprise Cloud Platform',
    Family = 'Software',
    Description = '엔터프라이즈급 클라우드 플랫폼 솔루션',
    IsActive = true
));

products.add(new Product2(
    Name = 'AI Analytics Suite',
    Family = 'Software', 
    Description = 'AI 기반 데이터 분석 플랫폼',
    IsActive = true
));

products.add(new Product2(
    Name = 'Security Management System',
    Family = 'Software',
    Description = '통합 보안 관리 시스템',
    IsActive = true
));

products.add(new Product2(
    Name = 'Mobile App Development Kit',
    Family = 'Software',
    Description = '모바일 앱 개발 도구',
    IsActive = true
));

products.add(new Product2(
    Name = 'IoT Device Management',
    Family = 'Hardware',
    Description = 'IoT 디바이스 통합 관리 솔루션',
    IsActive = true
));

try {
    insert products;
    System.debug('✅ 제품 ' + products.size() + '개 생성 완료');
} catch (Exception e) {
    System.debug('❌ 제품 생성 오류: ' + e.getMessage());
    return;
}

// 4. Assets 생성 - 즉시 갱신 가능하도록 InstallDate 조정
List<Asset> assets = new List<Asset>();
Date installDate = Date.today().addDays(-2); // 2일 전 설치로 즉시 갱신 가능
Integer assetCounter = 1;

for (Account company : companies) {
    for (Product2 product : products) {
        // 각 회사마다 각 제품의 Asset 생성
        Asset newAsset = new Asset(
            Name = company.Name + ' - ' + product.Name + ' 테스트',
            AccountId = company.Id,
            Product2Id = product.Id,
            Status = 'Installed',
            InstallDate = installDate,
            PurchaseDate = installDate,
            UsageEndDate = installDate.addDays(365), // 1년 계약
            Price = 50000000 + (assetCounter * 5000000), // 5천만원 ~ 1억원
            Quantity = Math.mod(assetCounter, 5) + 1, // 1~5개
            Description = company.Name + '에서 사용 중인 ' + product.Name + ' 시스템'
        );
        
        assets.add(newAsset);
        assetCounter++;
        
        // 추가 Asset (일부 회사에만)
        if (Math.mod(assetCounter, 3) == 0) {
            Asset additionalAsset = new Asset(
                Name = company.Name + ' - ' + product.Name + ' 추가 테스트',
                AccountId = company.Id,
                Product2Id = product.Id,
                Status = 'Installed',
                InstallDate = installDate.addDays(-1), // 1일 전
                PurchaseDate = installDate.addDays(-1),
                UsageEndDate = installDate.addDays(730), // 2년 계약
                Price = 30000000 + (assetCounter * 3000000),
                Quantity = 1,
                Description = company.Name + ' 추가 라이선스'
            );
            assets.add(additionalAsset);
        }
    }
}

try {
    insert assets;
    System.debug('✅ Assets ' + assets.size() + '개 생성 완료');
    
    // 생성된 Assets 요약 출력
    Decimal totalValue = 0;
    for (Asset a : assets) {
        totalValue += a.Price * a.Quantity;
    }
    
    System.debug('📊 생성 완료 요약:');
    System.debug('- 대기업 계정: ' + companies.size() + '개');
    System.debug('- 제품: ' + products.size() + '개');  
    System.debug('- Assets: ' + assets.size() + '개');
    System.debug('- 총 자산 가치: ₩' + String.valueOf(totalValue.longValue()) + '원');
    System.debug('- 모든 Assets는 즉시 갱신 가능 상태입니다 (설치일: ' + installDate + ')');
    
} catch (Exception e) {
    System.debug('❌ Assets 생성 오류: ' + e.getMessage());
    System.debug('스택 트레이스: ' + e.getStackTraceString());
    return;
}

// 5. 생성된 Assets 확인
try {
    List<Asset> createdAssets = [
        SELECT Id, Name, Account.Name, Product2.Name, Status, InstallDate, Price, Quantity
        FROM Asset 
        WHERE Name LIKE '%테스트%' 
        ORDER BY Account.Name, Product2.Name
        LIMIT 50
    ];
    
    System.debug('🔍 생성된 Assets 확인:');
    for (Asset a : createdAssets) {
        System.debug('- ' + a.Account.Name + ': ' + a.Name + 
                    ' (₩' + String.valueOf(a.Price.longValue()) + 'x' + a.Quantity + ')');
    }
    
} catch (Exception e) {
    System.debug('Assets 확인 중 오류: ' + e.getMessage());
}

// 6. AssetPriorityCalculator 테스트
try {
    System.debug('🧮 Asset 우선순위 계산 테스트...');
    List<AssetPriorityCalculator.AssetScore> priorities = AssetPriorityCalculator.calculateAssetPriorities();
    
    System.debug('계산된 우선순위 Assets: ' + priorities.size() + '개');
    for (Integer i = 0; i < Math.min(5, priorities.size()); i++) {
        AssetPriorityCalculator.AssetScore score = priorities[i];
        System.debug('우선순위 ' + (i+1) + ': ' + score.assetName + 
                    ' (점수: ' + score.totalScore + ', 고객: ' + score.accountName + ')');
    }
    
} catch (Exception e) {
    System.debug('우선순위 계산 테스트 오류: ' + e.getMessage());
}

System.debug('=== 🎉 Assets 테스트 데이터 생성 완료! ===');
System.debug('이제 성과 추적 대시보드에서 "Assets 데이터 생성" 및 "전체 갱신 실행" 버튼을 테스트해보세요!');
