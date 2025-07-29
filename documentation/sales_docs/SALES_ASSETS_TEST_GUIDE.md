# 🚀 Salesforce Sales Assets 화면 데이터 확인 가이드

## 📌 실행 순서

### 1단계: 테스트 데이터 생성
1. **Developer Console 열기**
   - Setup → Developer Console 클릭
   
2. **Execute Anonymous 실행**
   - Debug → Execute Anonymous Apex 클릭
   - `/scripts/apex/sales_assets_test_data.apex` 파일 내용 복사
   - 코드 붙여넣기 후 Execute 클릭
   
3. **실행 결과 확인**
   - 로그에서 "테스트 데이터 생성 완료" 메시지 확인
   - 각 객체별 생성 개수 확인

### 2단계: Assets Performance 대시보드 확인
1. **앱 이동**
   - App Launcher (9점 아이콘) 클릭
   - "Sales" 앱 선택
   
2. **Assets Performance 탭 접속**
   - 상단 탭에서 "Assets Performance" 클릭
   
3. **데이터 새로고침**
   - 페이지 새로고침 (F5 또는 Cmd+R)
   - 또는 대시보드의 새로고침 버튼 클릭

## 🎯 예상 결과 확인

### 💰 오늘의 예상 매출
- **목표값**: 약 1억 4,435만원
- **구성**: 5개 우선순위 고객의 갱신 확률별 계산
- **최고액**: 네이버 클라우드 인프라 (6,000만원)

### 🎯 이번 달 갱신 현황  
- **완료된 갱신**: 2건, 4,800만원
  - 삼성전자: 3,000만원
  - LG디스플레이: 1,800만원
- **진행 중인 갱신**: 3건, 17,000만원
  - 네이버: 9,000만원 (75% 확률)
  - 카카오: 3,500만원 (85% 확률)  
  - 현대자동차: 4,500만원 (60% 확률)

### 🏥 고객 건강도 분포
- **🟢 건강한 고객**: 2명 (40%) - 삼성전자, 네이버
- **🟡 주의 고객**: 2명 (40%) - LG디스플레이, 카카오
- **🔴 위험 고객**: 1명 (20%) - 현대자동차 (Case 3건)

### 🏆 현재 레벨
- **달성 레벨**: 🥈 실버 (4,800만원)
- **다음 목표**: 🥇 골드 (5,000만원까지 200만원 남음)
- **진행률**: 96%

## 🔍 상세 확인 포인트

### A. 우선순위 순서 확인
1. **1위**: 삼성전자 ERP (5,000만원, 10일 후 만료)
2. **2위**: 네이버 클라우드 (8,000만원, 65일 후 만료)  
3. **3위**: 카카오 보안 (2,500만원, 30일 후 만료)
4. **4위**: LG CRM (1,500만원, 20일 후 만료)
5. **5위**: 현대차 오피스 (300만원, 15일 후 만료)

### B. 색상 코딩 확인
- **🔴 빨강**: 80점 이상 (긴급) - 삼성전자, 네이버
- **🟡 노랑**: 60-79점 (중요) - 카카오, LG디스플레이  
- **🟢 초록**: 40-59점 (일반) - 현대자동차

### C. 실시간 업데이트 테스트
대시보드가 열려있는 상태에서 추가 테스트:

```apex
// 새로운 고액 Opportunity 생성하여 실시간 반영 확인
Opportunity newOpp = new Opportunity(
    Name = '긴급 갱신 기회',
    AccountId = [SELECT Id FROM Account WHERE Name = '삼성전자' LIMIT 1].Id,
    StageName = 'Closed Won',
    CloseDate = Date.today(),
    Amount = 20000000,
    Type = 'Renewal'
);
insert newOpp;
```

## 🛠️ 문제 해결

### 여전히 0값이 표시되는 경우:

#### 1. 권한 확인
```apex
// 현재 사용자 데이터 접근 권한 확인
System.debug('Asset 접근: ' + Schema.sObjectType.Asset.isAccessible());
System.debug('Opportunity 접근: ' + Schema.sObjectType.Opportunity.isAccessible());
System.debug('Account 접근: ' + Schema.sObjectType.Account.isAccessible());
```

#### 2. 데이터 존재 확인
```apex
// 생성된 데이터 수량 확인
System.debug('생성된 Asset: ' + [SELECT COUNT() FROM Asset WHERE CreatedDate = TODAY]);
System.debug('생성된 Account: ' + [SELECT COUNT() FROM Account WHERE CreatedDate = TODAY]);
System.debug('생성된 Opportunity: ' + [SELECT COUNT() FROM Opportunity WHERE CreatedDate = TODAY]);
```

#### 3. 브라우저 캐시 삭제
- 브라우저 새로고침 (Ctrl+F5 또는 Cmd+Shift+R)
- 브라우저 캐시 삭제 후 재접속

#### 4. 컴포넌트 재배포
Lightning Web Component가 최신 버전인지 확인

## 🎮 추가 테스트 시나리오

### 극한 상황 테스트:
```apex
// 초고액 자산 추가 (10억원)
Asset megaAsset = new Asset(
    Name = '엔터프라이즈 플랫폼',
    AccountId = [SELECT Id FROM Account WHERE Name = '삼성전자' LIMIT 1].Id,
    Status = 'Installed',
    Price = 1000000000, // 10억원!
    InstallDate = Date.today().addDays(-360),
    UsageEndDate = Date.today().addDays(3) // 3일 후 만료
);
insert megaAsset;
```

### 레벨 업 테스트:
```apex
// 골드 레벨 달성을 위한 추가 매출
Opportunity goldOpp = new Opportunity(
    Name = '골드 달성 기회',
    AccountId = [SELECT Id FROM Account WHERE Name = '네이버' LIMIT 1].Id,
    StageName = 'Closed Won',
    CloseDate = Date.today(),
    Amount = 5000000, // 500만원 (골드 달성)
    Type = 'Renewal'
);
insert goldOpp;
```

## ✅ 성공 기준

테스트가 성공적으로 완료되면:
- [ ] 모든 메트릭에 0이 아닌 값 표시
- [ ] 우선순위 고객 5명 정확히 나열
- [ ] 실버 레벨 달성 표시 (96% 진행률)
- [ ] 건강도 분석에 실제 퍼센트 표시
- [ ] 월간 목표 대비 적절한 달성률 표시
- [ ] 스마트 알림 정상 작동

이제 스크립트를 실행하고 대시보드에서 실제 데이터를 확인해보세요! 🚀
