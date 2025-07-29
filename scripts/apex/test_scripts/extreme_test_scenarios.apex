# 🧪 Assets Performance 대시보드 테스트 가이드

## 📋 테스트 목적
현재 대시보드에 모든 값이 0으로 표시되는 문제를 해결하고, 각 로직이 올바르게 동작하는지 검증

## 🚀 1단계: 테스트 데이터 생성

### 실행 방법:
1. Developer Console → Execute Anonymous
2. `/scripts/apex/dashboard_test_data_setup.apex` 파일 내용 복사
3. 실행 후 로그 확인

### 예상 생성 데이터:
- **Account**: 5개 대기업 고객
- **Asset**: 6개 다양한 시나리오 (갱신 임박, 고액, 소액 등)
- **Opportunity**: 4개 (완료 2건, 진행 2건)
- **Case**: 4개 (고객 건강도 테스트용)

## 🔍 2단계: 대시보드 확인 체크리스트

### A. 오늘의 예상 매출 💰
- [ ] **예상값**: 약 6,600만원
- [ ] **구성요소**:
  - 삼성전자 Enterprise Server: 1,500만원 × 90% = 1,350만원
  - LG전자 CRM 소프트웨어: 800만원 × 85% = 680만원
  - 현대차 클라우드: 2,500만원 × 80% = 2,000만원
  - SK텔레콤 보안: 1,200만원 × 80% = 960만원
  - 네이버 오피스: 500만원 × 70% = 350만원
- [ ] **목표 대비**: 5,000만원 목표 대비 132% 달성
- [ ] **우선순위 고객**: 5명 표시

### B. 이번 달 갱신 현황 🎯
- [ ] **완료된 갱신**: 2건, 3,500만원
  - 삼성전자 서버 갱신: 2,000만원
  - LG전자 소프트웨어 갱신: 1,500만원
- [ ] **진행 중인 갱신**: 2건, 4,800만원
  - 현대차 클라우드 갱신: 3,000만원 
  - SK텔레콤 보안 갱신: 1,800만원
- [ ] **예상 총 매출**: 8,300만원
- [ ] **월 목표**: 3억원 대비 28% 달성

### C. 고객 건강도 분포 🏥
- [ ] **🟢 건강한 고객**: 3명 (60%)
  - 삼성전자, LG전자, 현대자동차 (Case 없음)
- [ ] **🟡 주의 고객**: 1명 (20%)
  - SK텔레콤 (Case 1건)
- [ ] **🔴 위험 고객**: 1명 (20%)
  - 네이버 (Case 3건)

### D. 업무 효율성 지표 ⚡
- [ ] **평균 처리 시간**: 계산 가능한 값
- [ ] **성공률**: 100% (완료된 갱신 / 전체 갱신)
- [ ] **월 처리 건수**: 2건 (완료된 갱신)
- [ ] **시간 절약**: Logic 2 효과 계산

### E. 레벨 시스템 🏆
- [ ] **현재 레벨**: 🥈 실버
- [ ] **현재 매출**: 3,500만원 (완료 기준)
- [ ] **다음 레벨**: 골드 (5,000만원)
- [ ] **진행률**: 70% 달성

## 🛠️ 3단계: 문제 해결 체크리스트

### 데이터가 여전히 0으로 표시되는 경우:

#### A. 권한 확인
```apex
// 현재 사용자 권한 확인
System.debug('현재 사용자: ' + UserInfo.getName());
System.debug('Profile: ' + [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name);

// 필수 객체 접근 권한 확인
System.debug('Asset 접근: ' + Schema.sObjectType.Asset.isAccessible());
System.debug('Opportunity 접근: ' + Schema.sObjectType.Opportunity.isAccessible());
System.debug('Case 접근: ' + Schema.sObjectType.Case.isAccessible());
```

#### B. 데이터 존재 확인
```apex
// 생성된 데이터 확인
System.debug('Asset 수: ' + [SELECT COUNT() FROM Asset]);
System.debug('Opportunity 수: ' + [SELECT COUNT() FROM Opportunity WHERE CreatedDate = TODAY]);
System.debug('Account 수: ' + [SELECT COUNT() FROM Account WHERE CreatedDate = TODAY]);
```

#### C. SOQL 쿼리 테스트
```apex
// 대시보드에서 사용하는 주요 쿼리 테스트
List<Asset> priorityAssets = [
    SELECT Id, Name, AccountId, Account.Name, Price, InstallDate, UsageEndDate, Status
    FROM Asset 
    WHERE Status = 'Installed' 
    AND InstallDate <= :Date.today().addDays(-300)
    ORDER BY Price DESC
    LIMIT 10
];
System.debug('우선순위 Asset 수: ' + priorityAssets.size());
```

## 🎯 4단계: 추가 시나리오 테스트

### 극한 상황 테스트:

<function_calls>
<invoke name="create_file">
<parameter name="content">/**
 * 극한 상황 테스트 데이터 생성
 * 목적: 대시보드의 한계점과 예외 처리 검증
 */

System.debug('🔥 === 극한 상황 테스트 데이터 생성 ===');

try {
    // 시나리오 1: 초고액 자산 (억 단위)
    Account megaAccount = new Account(
        Name = '메가코프',
        Type = 'Customer',
        Industry = 'Finance'
    );
    insert megaAccount;
    
    Asset megaAsset = new Asset(
        Name = '엔터프라이즈 솔루션',
        AccountId = megaAccount.Id,
        Status = 'Installed',
        Price = 500000000, // 5억원!
        Quantity = 1,
        InstallDate = Date.today().addDays(-360),
        UsageEndDate = Date.today().addDays(5) // 초긴급!
    );
    insert megaAsset;
    
    // 시나리오 2: 만료된 자산 (과거 만료일)
    Asset expiredAsset = new Asset(
        Name = '만료된 라이선스',
        AccountId = megaAccount.Id,
        Status = 'Installed',
        Price = 10000000,
        Quantity = 1,
        InstallDate = Date.today().addDays(-400),
        UsageEndDate = Date.today().addDays(-10) // 이미 만료!
    );
    insert expiredAsset;
    
    // 시나리오 3: 초단기 자산 (1일 전 설치)
    Asset newAsset = new Asset(
        Name = '신규 설치 시스템',
        AccountId = megaAccount.Id,
        Status = 'Installed',
        Price = 5000000,
        Quantity = 1,
        InstallDate = Date.today().addDays(-1), // 어제 설치
        UsageEndDate = Date.today().addDays(364) // 1년 후
    );
    insert newAsset;
    
    System.debug('✅ 극한 상황 테스트 데이터 생성 완료');
    System.debug('🔥 5억원 초고액 자산 - 우선순위 1위 예상');
    System.debug('⚠️ 만료된 자산 - 예외 처리 확인');
    System.debug('🆕 신규 자산 - 우선순위 제외 확인');
    
} catch(Exception e) {
    System.debug('❌ 극한 상황 테스트 실패: ' + e.getMessage());
}
