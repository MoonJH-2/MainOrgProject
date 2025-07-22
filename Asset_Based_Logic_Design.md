# Order Payment 시스템 분석 및 Asset 기반 로직 설계

## 🔍 현재 시스템 구조 분석

### 📋 현재 Order Payment 관리 구조
```
Order (표준 오브젝트)
├── PaymentStatus__c (커스텀 오브젝트) - Master-Detail
    ├── Amount__c: Currency (납부 금액)
    ├── DueDate__c: Date (납부 예정일)
    ├── Status__c: Picklist (완납/미납/연체)
    ├── InstallmentNumber__c: Number (1차, 2차...)
    ├── PaidDate__c: Date (실제 납부일)
    └── Order__c: Master-Detail to Order
```

### 🎯 핵심 비즈니스 로직
1. **분할 납부 관리**: 월별/분기별/반기별/년별
2. **납부 상태 추적**: 완납/미납/연체
3. **자동화 시스템**: 알림, Task 생성, PDF 생성
4. **완납 감지**: 모든 PaymentStatus가 '완납' 상태일 때

## 🚀 Asset 기반 로직 설계

### 💡 Asset 표준 필드 활용 전략

#### Asset 표준 필드 매핑
```apex
Asset 표준 필드 → 비즈니스 의미
├── Name: "Order {OrderNumber} Asset"
├── AccountId: Order.AccountId
├── ContactId: Order.Contact__c
├── Product2Id: OrderItem에서 주요 제품
├── SerialNumber: Order.OrderNumber (역추적용)
├── PurchaseDate: Order.ActivatedDate
├── InstallDate: Order.OrderStartDate
├── UsageEndDate: Order.OrderEndDate
├── Status: Purchased/Installed/Registered
├── Price: Order.TotalAmount
├── Quantity: 1 (기본값)
└── Description: Order 상세 정보 + 납부 내역
```

#### 필요한 커스텀 필드 (최소화)
```apex
Asset 커스텀 필드:
├── Payment_Status__c: Picklist (진행중/완납완료)
├── Payment_Progress__c: Percent (납부 진행률)
├── Renewal_Date__c: Date (갱신 예정일)
└── Original_Order__c: Lookup to Order (역참조)
```

### 🔄 완납 → Asset 생성 프로세스

#### 1단계: 완납 감지 로직
```apex
// PaymentStatus 업데이트 시 트리거
public static Boolean isOrderFullyPaid(Id orderId) {
    List<AggregateResult> results = [
        SELECT COUNT(Id) total,
               COUNT_DISTINCT(CASE WHEN Status__c = '완납' THEN Id END) completed
        FROM PaymentStatus__c 
        WHERE Order__c = :orderId
        GROUP BY Order__c
    ];
    
    if (results.isEmpty()) return false;
    
    Integer total = (Integer)results[0].get('total');
    Integer completed = (Integer)results[0].get('completed');
    
    return total > 0 && total == completed;
}
```

#### 2단계: Asset 자동 생성
```apex
public static Asset createAssetFromCompletedOrder(Id orderId) {
    Order orderInfo = [
        SELECT Id, OrderNumber, AccountId, Contact__c, TotalAmount,
               ActivatedDate, OrderStartDate, OrderEndDate, OwnerId,
               Account.Name, Owner.Name
        FROM Order WHERE Id = :orderId LIMIT 1
    ];
    
    Asset newAsset = new Asset();
    
    // 표준 필드 매핑
    newAsset.Name = orderInfo.Account.Name + ' - Order ' + orderInfo.OrderNumber;
    newAsset.AccountId = orderInfo.AccountId;
    newAsset.ContactId = orderInfo.Contact__c;
    newAsset.SerialNumber = orderInfo.OrderNumber;
    newAsset.PurchaseDate = orderInfo.ActivatedDate?.date() ?? Date.today();
    newAsset.InstallDate = orderInfo.OrderStartDate;
    newAsset.UsageEndDate = orderInfo.OrderEndDate;
    newAsset.Status = 'Purchased';
    newAsset.Price = orderInfo.TotalAmount;
    newAsset.Quantity = 1;
    
    // 커스텀 필드
    newAsset.Payment_Status__c = '완납완료';
    newAsset.Payment_Progress__c = 100;
    newAsset.Renewal_Date__c = orderInfo.OrderEndDate?.addMonths(-6); // 6개월 전 갱신 알림
    newAsset.Original_Order__c = orderId;
    
    // Description 상세 정보
    newAsset.Description = buildAssetDescription(orderInfo);
    
    return newAsset;
}
```

### 📈 Asset 기반 고객 관리 기능

#### 1. 자산 포트폴리오 대시보드
```apex
@AuraEnabled(cacheable=true)
public static List<Asset> getCustomerAssets(Id accountId) {
    return [
        SELECT Id, Name, Product2.Name, PurchaseDate, UsageEndDate,
               Status, Price, Payment_Progress__c, Renewal_Date__c
        FROM Asset 
        WHERE AccountId = :accountId 
        ORDER BY PurchaseDate DESC
    ];
}
```

#### 2. 갱신 영업 기회 관리
```apex
@AuraEnabled
public static List<Asset> getUpcomingRenewals(Integer monthsAhead) {
    Date cutoffDate = Date.today().addMonths(monthsAhead);
    
    return [
        SELECT Id, Name, Account.Name, Account.Owner.Name,
               UsageEndDate, Price, Renewal_Date__c
        FROM Asset 
        WHERE Renewal_Date__c <= :cutoffDate
        AND Status = 'Purchased'
        ORDER BY Renewal_Date__c ASC
    ];
}
```

#### 3. 자산 기반 매출 분석
```apex
@AuraEnabled(cacheable=true)
public static Map<String, Object> getAssetAnalytics(Id accountId) {
    List<AggregateResult> results = [
        SELECT SUM(Price) totalValue,
               COUNT(Id) assetCount,
               AVG(Price) avgAssetValue
        FROM Asset 
        WHERE AccountId = :accountId
        AND Status = 'Purchased'
    ];
    
    return new Map<String, Object>{
        'totalAssetValue' => results[0].get('totalValue'),
        'totalAssetCount' => results[0].get('assetCount'),
        'averageAssetValue' => results[0].get('avgAssetValue')
    };
}
```

## 🎯 구현 우선순위

### Phase 1: 기본 Asset 생성 (표준 필드만)
1. PaymentStatus 완납 감지 트리거
2. Asset 기본 생성 로직
3. Order → Asset 매핑

### Phase 2: 커스텀 필드 추가
1. Payment_Status__c 필드
2. Payment_Progress__c 필드  
3. Renewal_Date__c 필드

### Phase 3: 고급 기능
1. 갱신 영업 알림 시스템
2. 자산 포트폴리오 대시보드
3. 매출 분석 리포트

## 📊 기대 효과

### 영업 관점
- ✅ 고객별 자산 포트폴리오 한눈에 파악
- ✅ 갱신 시점 자동 알림으로 영업 기회 놓치지 않음
- ✅ 자산 기반 Up-sell/Cross-sell 기회 발굴

### 고객 관리 관점  
- ✅ 구매 이력 기반 고객 세그멘테이션
- ✅ 고객 생애 가치(CLV) 정확한 산정
- ✅ 서비스 연속성 보장

### 시스템 관점
- ✅ Salesforce 표준 Asset 기능 최대 활용
- ✅ 기존 Order/PaymentStatus 로직과 완벽 연동
- ✅ 확장 가능한 아키텍처 구성
