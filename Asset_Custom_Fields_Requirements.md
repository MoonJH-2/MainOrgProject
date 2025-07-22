# Asset 오브젝트 커스텀 필드 요구사항

## 🎯 필수 커스텀 필드

### 1. Order__c (Lookup to Order)
- **Field Type**: Lookup Relationship
- **Related To**: Order
- **Field Label**: "Order"
- **Field Name**: "Order__c"
- **Description**: "Asset을 생성한 원본 Order와의 연결"
- **Required**: No (기존 Asset과의 호환성)

### 2. Renewal_Reminder_Date__c (Date)
- **Field Type**: Date
- **Field Label**: "Renewal Reminder Date" 
- **Field Name**: "Renewal_Reminder_Date__c"
- **Description**: "갱신 알림 날짜 (종료일 6개월 전)"
- **Required**: No

### 3. Asset_Type__c (Picklist)
- **Field Type**: Picklist
- **Field Label**: "Asset Type"
- **Field Name**: "Asset_Type__c"
- **Values**: 
  - "Service Contract" (서비스 계약)
  - "Product License" (제품 라이선스)
  - "Subscription" (구독)
  - "Other" (기타)
- **Default**: "Service Contract"

## 🛠️ 커스텀 필드 생성 방법

### Setup에서 생성:
1. **Setup** → **Object Manager** → **Asset**
2. **Fields & Relationships** → **New**
3. 위의 필드 정보에 따라 생성

### 대안: 기존 필드 활용
기존 Asset 표준 필드들로도 구현 가능:
- **SerialNumber**: Order Number 저장
- **Description**: Order 정보 저장

## 📝 현재 구현에서 Order 연결 대안

커스텀 필드 생성 전까지 다음 방법으로 연결:

```apex
// Description 필드에 Order ID 저장
newAsset.Description = 'Order ' + order.OrderNumber + ' (ID: ' + order.Id + ')';

// SerialNumber에 Order Number 저장  
newAsset.SerialNumber = order.OrderNumber;
```

이렇게 하면 Order 조회가 가능합니다:
```apex
// Asset에서 Order 찾기
List<Asset> assets = [SELECT Description FROM Asset WHERE Id = :assetId];
String orderNumber = assets[0].Description.substringBetween('Order ', ' (');
```
