# 🎯 구현된 Asset 로직 단계별 상세 설명

## 📋 전체 Asset 생성 및 관리 시스템 개요

구현된 Asset 시스템은 **PaymentStatus 완납 감지 → Account 분석 → Asset 생성 → 후속 관리**의 완전한 자동화 워크플로우입니다.

---

## 🔄 **1단계: PaymentStatus 완납 감지 (자동 트리거)**

### 📍 **PaymentStatusAssetTrigger.trigger**
```apex
trigger PaymentStatusAssetTrigger on PaymentStatus__c (after insert, after update) {
    PaymentStatusAssetTriggerHandler.handleAfterInsert(Trigger.new);
    PaymentStatusAssetTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}
```

**동작 시점**: PaymentStatus__c 레코드가 생성되거나 업데이트될 때

### 📍 **PaymentStatusAssetTriggerHandler.cls**
```apex
public static void handleAfterUpdate(List<PaymentStatus__c> newPayments, Map<Id, PaymentStatus__c> oldMap) {
    Set<Id> orderIds = new Set<Id>();
    
    for (PaymentStatus__c payment : newPayments) {
        PaymentStatus__c oldPayment = oldMap.get(payment.Id);
        
        // '완납' 상태로 변경된 경우만 처리
        if (payment.Status__c == '완납' && oldPayment.Status__c != '완납') {
            orderIds.add(payment.Order__c);
        }
    }
    
    if (!orderIds.isEmpty()) {
        createAssetsAsync(orderIds);
    }
}
```

**핵심 로직**:
1. PaymentStatus가 '완납'으로 변경되는 경우만 감지
2. 해당 Order ID 수집
3. 비동기 Asset 생성 프로세스 시작

---

## 🔍 **2단계: 완납 상태 검증 (OrderAssetCreationService)**

### 📍 **OrderAssetCreationService.isOrderFullyPaid()**
```apex
public static Boolean isOrderFullyPaid(Id orderId) {
    List<PaymentStatus__c> allPayments = [
        SELECT Status__c 
        FROM PaymentStatus__c 
        WHERE Order__c = :orderId
    ];
    
    if (allPayments.isEmpty()) {
        return false;
    }
    
    for (PaymentStatus__c payment : allPayments) {
        if (payment.Status__c != '완납') {
            return false;
        }
    }
    
    return true;
}
```

**검증 단계**:
1. 해당 Order의 모든 PaymentStatus 조회
2. 하나라도 '완납'이 아니면 false 반환
3. 모든 PaymentStatus가 '완납'이어야 true 반환

---

## 🧠 **3단계: Account 인텔리전스 분석 (AccountBasedAssetService)**

### 📍 **주요 데이터 수집**
```apex
Order orderInfo = [
    SELECT Id, OrderNumber, AccountId, TotalAmount, Status,
           EffectiveDate, EndDate, CreatedDate, OwnerId,
           Contact__c, Account.Name, Account.AccountNumber, Account.Industry,
           Account.AnnualRevenue, Account.NumberOfEmployees,
           Account.CustomerPriority__c, Account.Key_Account__c, Account.Active__c,
           Account.AccountSource, Account.Ownership, Account.Site,
           Account.Manager__c, Account.Manager__r.Name, Owner.Name
    FROM Order 
    WHERE Id = :orderId 
    LIMIT 1
];
```

**수집되는 Account 정보**:
- **기업 규모**: NumberOfEmployees, AnnualRevenue
- **업계 정보**: Industry
- **고객 등급**: Key_Account__c, CustomerPriority__c
- **관리 정보**: Manager__c, Active__c, AccountSource

---

## 🏗️ **4단계: 비즈니스 규칙 기반 Asset 설계**

### 📍 **기업 규모별 Lifecycle 설정**
```apex
private static void setAssetCategoryAndLifecycle(Asset newAsset, Order orderInfo) {
    Integer lifecycleMonths = 12; // 기본 12개월
    
    // 기업 규모별 차별화
    if (orderInfo.Account.NumberOfEmployees != null) {
        if (orderInfo.Account.NumberOfEmployees >= 1000) {
            // 대기업: 36개월 장기 파트너십
            lifecycleMonths = 36;
            newAsset.Name = orderInfo.Account.Name + ' [대기업] ';
        } else if (orderInfo.Account.NumberOfEmployees >= 100) {
            // 중견기업: 24개월 성장 지원
            lifecycleMonths = 24;
            newAsset.Name = orderInfo.Account.Name + ' [중견기업] ';
        } else {
            // 중소기업: 12개월 효율성 중심
            lifecycleMonths = 12;
            newAsset.Name = orderInfo.Account.Name + ' [중소기업] ';
        }
    }
    
    // Key Account 보너스: +12개월
    if (orderInfo.Account.Key_Account__c) {
        lifecycleMonths += 12;
    }
    
    // 고매출 기업: +6개월
    if (orderInfo.Account.AnnualRevenue != null && orderInfo.Account.AnnualRevenue >= 100000000) {
        lifecycleMonths += 6;
    }
}
```

**비즈니스 규칙**:
- **대기업 (1000명+)**: 36개월 기본 + 장기 관계 전략
- **중견기업 (100-999명)**: 24개월 + 성장 단계별 지원
- **중소기업 (~99명)**: 12개월 + 효율성 중심 서비스
- **Key Account**: 추가 12개월 연장
- **고매출 (1억+)**: 추가 6개월 연장

---

## 🎨 **5단계: Industry별 맞춤 전략 수립**

### 📍 **업계별 Asset 이름 및 설명 생성**
```apex
// Industry 표시
if (String.isNotBlank(orderInfo.Account.Industry)) {
    nameParts.add('[' + orderInfo.Account.Industry + ']');
}

// Asset 이름 조합
newAsset.Name = String.join(nameParts, ' ') + ' - ' + orderInfo.OrderNumber;
```

### 📍 **업계별 비즈니스 인사이트**
```apex
private static List<String> generateAccountInsights(Order orderInfo) {
    List<String> insights = new List<String>();
    
    // Industry 기반 전략
    switch on orderInfo.Account.Industry {
        when 'Technology' {
            insights.add('• 최신 기술 트렌드 및 혁신 솔루션 제안');
            insights.add('• 빠른 기술 도입 성향으로 조기 갱신 가능성 높음');
        }
        when 'Manufacturing' {
            insights.add('• 생산성 향상 및 비용 절감 효과 강조');
            insights.add('• 장기 계약 선호하는 업계 특성 활용');
        }
        when 'Healthcare' {
            insights.add('• 규제 준수 및 보안 강화 솔루션 중점');
            insights.add('• 안정성과 신뢰성 우선 고려');
        }
        when 'Financial Services' {
            insights.add('• 보안 및 컴플라이언스 최우선');
            insights.add('• 고가용성 솔루션 요구사항 반영');
        }
    }
    
    return insights;
}
```

**업계별 전략**:
- **Technology**: 혁신 중심, 빠른 업그레이드 사이클
- **Manufacturing**: 생산성 향상, 장기 안정성
- **Healthcare**: 규제 준수, 보안 강화
- **Financial**: 컴플라이언스, 고가용성

---

## 🏭 **6단계: Asset 레코드 생성**

### 📍 **기본 Asset 필드 설정**
```apex
// 기본 Asset 생성
Asset newAsset = new Asset();
newAsset.Name = finalAssetName;
newAsset.SerialNumber = orderInfo.OrderNumber; // Order 추적용
newAsset.AccountId = orderInfo.AccountId;
newAsset.Product2Id = null; // 필요시 Order에서 참조
newAsset.Status = 'Installed';
newAsset.Description = buildAccountBasedDescription(orderInfo);

// 날짜 설정
newAsset.InstallDate = Date.today();
if (orderInfo.EffectiveDate != null) {
    newAsset.PurchaseDate = orderInfo.EffectiveDate;
} else {
    newAsset.PurchaseDate = Date.today();
}

// Contact 설정
if (orderInfo.Contact__c != null) {
    newAsset.ContactId = orderInfo.Contact__c;
}

// Asset 저장
insert newAsset;
```

**설정되는 핵심 필드**:
- **Name**: Account명 + 기업규모 + Industry + Order번호
- **SerialNumber**: OrderNumber (Order 추적용)
- **AccountId**: Order의 Account 연결
- **Status**: 'Installed' (활성 상태)
- **InstallDate**: 오늘 날짜
- **PurchaseDate**: Order EffectiveDate
- **ContactId**: Order의 Contact 연결
- **Description**: Account 분석 + PaymentStatus 이력

---

## 📝 **7단계: Account 분석 기반 Description 생성**

### 📍 **상세 분석 정보 포함**
```apex
private static String buildAccountBasedDescription(Order orderInfo) {
    List<String> descriptionParts = new List<String>();
    
    // Order 기본 정보
    descriptionParts.add('=== Order 정보 ===');
    descriptionParts.add('Order Number: ' + orderInfo.OrderNumber);
    descriptionParts.add('생성일: ' + orderInfo.CreatedDate.format());
    descriptionParts.add('총 금액: ' + (orderInfo.TotalAmount != null ? orderInfo.TotalAmount.format() : '0') + '원');
    
    // Account 분석 정보
    descriptionParts.add('=== Account 분석 ===');
    descriptionParts.add('산업군: ' + (orderInfo.Account.Industry ?? '미분류'));
    descriptionParts.add('직원수: ' + (orderInfo.Account.NumberOfEmployees != null ? orderInfo.Account.NumberOfEmployees.format() : '미확인') + '명');
    descriptionParts.add('연매출: ' + (orderInfo.Account.AnnualRevenue != null ? orderInfo.Account.AnnualRevenue.format() : '미확인') + '원');
    descriptionParts.add('고객 우선순위: ' + (orderInfo.Account.CustomerPriority__c ?? '일반'));
    descriptionParts.add('Key Account: ' + (orderInfo.Account.Key_Account__c ? 'Yes' : 'No'));
    
    // PaymentStatus 이력 포함
    descriptionParts.add('=== 납부 이력 ===');
    // [PaymentStatus 조회 로직]
    
    return String.join(descriptionParts, '\n');
}
```

**Description에 포함되는 정보**:
- **Order 정보**: 번호, 생성일, 총 금액
- **Account 분석**: 산업군, 직원수, 매출, 우선순위
- **비즈니스 인사이트**: 업계별 맞춤 전략
- **납부 이력**: PaymentStatus 완료 내역

---

## 🎯 **8단계: 후속 액션 자동 생성**

### 📍 **Account 특성별 차별화된 Task 생성**
```apex
private static void performAccountBasedActions(Order orderInfo, Asset newAsset) {
    List<Task> tasksToCreate = new List<Task>();
    
    // Account Manager 배정된 경우
    if (orderInfo.Account.Manager__c != null) {
        Task managerTask = new Task();
        managerTask.Subject = '[Asset 생성] ' + newAsset.Name + ' - 전담 관리 시작';
        managerTask.Description = 'Account Manager 전담 Asset이 생성되었습니다. 고객 관계 관리를 시작하세요.';
        managerTask.WhatId = newAsset.Id;
        managerTask.WhoId = orderInfo.Contact__c;
        managerTask.OwnerId = orderInfo.Account.Manager__c;
        managerTask.ActivityDate = Date.today().addDays(3);
        managerTask.Priority = 'High';
        tasksToCreate.add(managerTask);
    }
    
    // Key Account 특별 관리
    if (orderInfo.Account.Key_Account__c) {
        Task keyAccountTask = new Task();
        keyAccountTask.Subject = '[Key Account] ' + newAsset.Name + ' - VIP 고객 특별 관리';
        keyAccountTask.Description = 'Key Account Asset 생성. 특별 관리 프로토콜을 적용하세요.';
        keyAccountTask.WhatId = newAsset.Id;
        keyAccountTask.OwnerId = orderInfo.OwnerId;
        keyAccountTask.ActivityDate = Date.today().addDays(1);
        keyAccountTask.Priority = 'High';
        tasksToCreate.add(keyAccountTask);
    }
    
    // 고우선순위 고객
    if (orderInfo.Account.CustomerPriority__c == 'High') {
        Task priorityTask = new Task();
        priorityTask.Subject = '[고우선순위] ' + newAsset.Name + ' - 즉시 대응 필요';
        priorityTask.Description = '고우선순위 고객의 Asset이 생성되었습니다. 즉시 대응하세요.';
        priorityTask.WhatId = newAsset.Id;
        priorityTask.OwnerId = orderInfo.OwnerId;
        priorityTask.ActivityDate = Date.today();
        priorityTask.Priority = 'High';
        tasksToCreate.add(priorityTask);
    }
    
    if (!tasksToCreate.isEmpty()) {
        insert tasksToCreate;
    }
}
```

**생성되는 Task 유형**:
- **Account Manager Task**: 전담 관리자 배정 시 (3일 후)
- **Key Account Task**: VIP 고객 특별 관리 (1일 후)
- **High Priority Task**: 고우선순위 고객 즉시 대응 (당일)

---

## 🚀 **9단계: UI 네비게이션 지원 (OrderAssetNavigator)**

### 📍 **Order 화면에서 실시간 상태 표시**
```javascript
// 납부 진행률 계산
get paymentProgress() {
    if (!this.paymentSummary) return 0;
    return Math.round((this.paymentSummary.completedPayments / this.paymentSummary.totalPayments) * 100);
}

// Asset 연결 상태 확인
get hasAsset() {
    return this.assetInfo?.Id;
}

// Asset 생성 가능 여부
get canCreateAsset() {
    return this.isFullyPaid && !this.hasAsset;
}
```

### 📍 **원클릭 Asset 네비게이션**
```javascript
handleNavigateToAsset() {
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: this.assetInfo.Id,
            objectApiName: 'Asset',
            actionName: 'view'
        }
    });
}
```

**UI 제공 기능**:
- **실시간 납부 진행률**: Progress Bar + 통계
- **Asset 연결 상태**: 존재/미생성/생성가능 표시
- **원클릭 네비게이션**: Asset 보기, Task 보기, Asset 목록
- **수동 Asset 생성**: 완납 시 즉시 생성 가능

---

## 🎮 **10단계: 오류 처리 및 알림**

### 📍 **트리거 레벨 오류 처리**
```apex
@future
public static void createAssetsAsync(Set<Id> orderIds) {
    List<Task> errorTasks = new List<Task>();
    
    for (Id orderId : orderIds) {
        try {
            if (OrderAssetCreationService.isOrderFullyPaid(orderId)) {
                AccountBasedAssetService.createAssetWithAccountAnalysis(orderId);
            }
        } catch (Exception e) {
            // 오류 발생 시 알림 Task 생성
            Task errorTask = new Task();
            errorTask.Subject = '[Asset 생성 오류] Order ' + orderId;
            errorTask.Description = 'Asset 자동 생성 중 오류 발생: ' + e.getMessage();
            errorTask.WhatId = orderId;
            errorTask.ActivityDate = Date.today();
            errorTask.Priority = 'High';
            errorTasks.add(errorTask);
        }
    }
    
    if (!errorTasks.isEmpty()) {
        insert errorTasks;
    }
}
```

### 📍 **UI 레벨 사용자 알림**
```javascript
async handleCreateAsset() {
    try {
        const result = await createAssetFromOrder({ orderId: this.recordId });
        
        if (result.success) {
            this.showToast('성공', 'Asset이 성공적으로 생성되었습니다.', 'success');
            await refreshApex(this.wiredResult);
            
            if (result.assetId) {
                this.navigateToAsset(result.assetId);
            }
        } else {
            this.showToast('오류', result.message, 'error');
        }
    } catch (error) {
        this.showToast('오류', 'Asset 생성 중 오류가 발생했습니다.', 'error');
    }
}
```

**오류 처리 메커니즘**:
- **트리거 레벨**: 오류 시 알림 Task 자동 생성
- **UI 레벨**: Toast 메시지로 즉시 피드백
- **로그 기록**: System.debug로 상세 오류 추적

---

## 🏆 **전체 시스템 흐름 요약**

```
1. PaymentStatus '완납' 변경
   ↓
2. Trigger 자동 감지
   ↓
3. Order 완납 상태 검증
   ↓
4. Account 정보 수집 및 분석
   ↓
5. 비즈니스 규칙 적용 (기업규모/업계/고객등급)
   ↓
6. Asset 생성 (맞춤형 이름/설명/속성)
   ↓
7. 후속 Task 자동 생성 (Account 특성별)
   ↓
8. Order 화면에서 Asset 연결 상태 표시
   ↓
9. 원클릭 Asset 네비게이션 제공
```

이 전체 시스템은 **100% 자동화**되어 있으며, **Account 특성별 맞춤형 전략**을 적용하여 단순한 Asset 생성을 넘어 **전략적 고객 관리 플랫폼**으로 진화한 솔루션입니다! 🚀
