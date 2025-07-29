---
mode: agent
---

# 🚀 SOCAR B2B Salesforce 자동화 시스템 개발 가이드

## 📋 프로젝트 컨텍스트

### 🎯 프로젝트 목적
**SOCAR B2B 영업팀의 디지털 트랜스포메이션**을 통한 완전 자동화된 영업 관리 시스템 구축
- **업무 효율성 40% 향상** 달성
- **수동 프로세스를 지능형 자동화**로 전환
- **데이터 기반 의사결정** 지원 체계 구축

### 🏢 비즈니스 도메인
**B2B SaaS 영업 생태계** - 자동차 공유 서비스 기업의 B2B 영업 자동화

**핵심 비즈니스 플로우:**
```
Lead 생성 → Opportunity → Quote → Order → PaymentStatus → Asset → Renewal
    ↓         ↓         ↓      ↓         ↓            ↓        ↓
 AI분석   자동채널   PDF생성  분할관리   완납감지    고객분석  갱신기회
```

**비즈니스 규칙:**
- 분할납부: 최대 12회차까지 지원
- 완납 감지 시 즉시 Asset 자동 생성
- 연체 3일 초과 시 자동 알림 및 Task 생성
- Account RecordType: 'Prospect' → 'Active Customer' 자동 전환

### 📊 주요 엔티티 및 관계
```
Account (1) ──→ (N) Opportunity ──→ (N) Quote ──→ (1) Order
   ↓                                                  ↓
   └─→ (N) Asset ←──────────────── (N) PaymentStatus__c
```

**엔티티 상세:**
- `Account`: B2B 고객사 (Industry, AnnualRevenue, RecordType 관리)
- `Order`: 영업 주문 (Status, TotalAmount, Payment_Method__c)
- `PaymentStatus__c`: 분할납부 상태 (InstallmentNumber__c, DueDate__c, Status__c)
- `Asset`: 고객 자산 (Status, InstallDate, UsageEndDate)
- `OrderItem`: 주문 상품 상세 (Product2, Quantity, UnitPrice)

### 👥 사용자 그룹 및 사용 사례

**1. 영업팀 (Sales Representative)**
- *일일 활동*: Agentforce 기반 고객 분석 및 추천
- *Order 관리*: 원클릭 PDF 생성 및 고객 발송
- *진행 추적*: 실시간 납부 현황 모니터링

**2. Account Manager**
- *고객 관계*: Asset 기반 고객 생애주기 관리
- *갱신 기회*: 만료 예정 Asset 자동 알림
- *위험도 분석*: AI 기반 churn 예측

**3. Finance Team**
- *납부 관리*: 자동 연체 감지 및 독촉 프로세스
- *정산 업무*: 완납 확인 및 세금계산서 발행
- *현금 흐름*: 납부 예측 및 분석 대시보드

**4. CS Team**
- *Asset 지원*: 고객 자산 상태 모니터링
- *기술 지원*: Asset 기반 서비스 이력 관리
- *만족도 관리*: 서비스 품질 추적

## 🏗️ 기술 아키텍처

### 🔧 기술 스택
```yaml
Platform: Salesforce Sales Cloud Enterprise
Language: 
  - Apex (서버사이드 로직)
  - JavaScript ES6+ (클라이언트사이드)
  - HTML5/CSS3 (UI 마크업)
  
Frontend:
  - Lightning Web Components (LWC)
  - Lightning Design System (SLDS)
  - Chart.js (데이터 시각화)
  
Backend:
  - Apex Classes (비즈니스 로직)
  - Triggers (이벤트 처리)
  - Batch/Queueable Jobs (비동기 처리)
  
AI/ML:
  - Agentforce (Einstein GPT)
  - Einstein Analytics (예측 분석)
  - Custom AI Actions

Integration:
  - REST API (외부 시스템 연동)
  - Slack API (팀 협업)
  - Email Services (자동 알림)
```

### 🏛️ 아키텍처 패턴

**1. Trigger Handler Pattern**
```apex
// 확장 가능한 트리거 관리 패턴
public abstract class TriggerHandler {
    protected abstract String getHandlerName();
    public void execute() {
        if (Trigger.isBefore && Trigger.isInsert) beforeInsert(Trigger.new);
        if (Trigger.isAfter && Trigger.isUpdate) afterUpdate(Trigger.new, Trigger.oldMap);
    }
}
```

**2. Service Layer Pattern**
```apex
// 비즈니스 로직 분리 및 재사용성 확보
public class OrderService {
    public static void processOrderAutomation(List<Order> orders) {
        // 복잡한 비즈니스 로직을 서비스 레이어에서 처리
    }
}
```

**3. Factory Pattern**
```apex
// 동적 객체 생성 및 전략 패턴 구현
public class AssetFactory {
    public static Asset createAsset(Order orderInfo, String assetType) {
        // 주문 정보와 Asset 타입에 따른 동적 생성
    }
}
```

**4. Observer Pattern**
```apex
// 이벤트 기반 아키텍처로 느슨한 결합
public interface PaymentObserver {
    void onPaymentCompleted(PaymentStatus__c payment);
}
```

### 📦 모듈 구조
```
force-app/main/default/
├── classes/
│   ├── triggers/          # 트리거 핸들러
│   ├── services/          # 비즈니스 서비스
│   ├── controllers/       # LWC 컨트롤러
│   ├── utils/            # 유틸리티 클래스
│   └── tests/            # 테스트 클래스
├── lwc/                  # Lightning Web Components
├── triggers/             # 데이터베이스 트리거
├── pages/               # Visualforce 페이지
└── objects/             # 커스텀 객체 정의
```

## 🎯 코딩 스타일 및 규칙

### 📝 Naming Convention

**클래스명 규칙:**
```apex
// 패턴: [Domain][Purpose][Type]
OrderTriggerHandler.cls           // 트리거 핸들러
PaymentStatusTimelineController.cls // LWC 컨트롤러  
AssetManagementService.cls        // 비즈니스 서비스
CustomerRiskAnalyzer.cls          // 분석 유틸리티
OrderNotificationBatch.cls        // 배치 작업
```

**메서드명 규칙:**
```apex
// 패턴: [action][Subject][Context?]
public static void createPaymentSchedule(Id orderId)
public static List<Asset> getAccountAssetsWithFilters(Id accountId, String status)
public static Boolean validatePaymentStatus(PaymentStatus__c payment)
private void processOrderAutomationLogic(Order orderInfo)

// 불린 반환 메서드
public static Boolean isPaymentOverdue(PaymentStatus__c payment)
public static Boolean hasActiveAssets(Id accountId)
```

**변수명 규칙:**
```apex
// 컬렉션: 복수형 사용
List<PaymentStatus__c> paymentStatuses
Map<Id, Order> ordersByAccountId
Set<Id> completedPaymentIds

// 단일 객체: 의미있는 명명
PaymentStatus__c currentPayment
Order primaryOrder
Account targetAccount

// 상수: UPPER_SNAKE_CASE
public static final String PAYMENT_STATUS_COMPLETED = '완납';
public static final Integer MAX_INSTALLMENT_COUNT = 12;
```

### ⚡ Error Handling 패턴

**AuraEnabled 메서드 패턴:**
```apex
@AuraEnabled
public static ResponseWrapper updatePaymentStatus(Id paymentId, String newStatus) {
    try {
        // 입력값 검증
        validateInputParameters(paymentId, newStatus);
        
        // 비즈니스 로직 실행
        PaymentStatus__c updatedPayment = PaymentService.updateStatus(paymentId, newStatus);
        
        // 성공 응답
        return new ResponseWrapper(true, '납부 상태가 성공적으로 업데이트되었습니다.', updatedPayment);
        
    } catch (ValidationException ve) {
        throw new AuraHandledException('입력값 오류: ' + ve.getMessage());
    } catch (DmlException de) {
        throw new AuraHandledException('데이터 저장 오류: ' + de.getMessage());
    } catch (Exception e) {
        // 로깅 및 일반 오류 처리
        System.debug(LoggingLevel.ERROR, 'Unexpected error in updatePaymentStatus: ' + e.getMessage());
        throw new AuraHandledException('시스템 오류가 발생했습니다. 관리자에게 문의하세요.');
    }
}
```

**Future/Batch 메서드 패턴:**
```apex
@future(callout=true)
public static void processOrderAutomationAsync(Set<Id> orderIds) {
    try {
        List<Order> orders = OrderService.getOrdersWithDetails(orderIds);
        
        for (Order orderInfo : orders) {
            try {
                processIndividualOrder(orderInfo);
            } catch (Exception e) {
                // 개별 실패가 전체를 막지 않도록 처리
                LoggingUtil.logError('Order processing failed', orderInfo.Id, e);
            }
        }
        
    } catch (Exception e) {
        // 크리티컬 오류 알림
        NotificationService.notifyAdministrators('배치 처리 실패', e.getMessage());
    }
}
```

### 📋 주석 작성 규칙

**클래스 레벨 주석:**
```apex
/**
 * @description PaymentStatus 관리 및 완납 시 Asset 자동 생성 서비스
 * @author JH Moon
 * @version 1.2.0
 * @since 2025-07-27
 * @group Payment Management
 * 
 * Business Logic:
 * - 분할납부 스케줄 자동 생성
 * - 완납 감지 시 Asset 생성 트리거
 * - 연체 알림 및 Task 자동 생성
 * 
 * Dependencies:
 * - AssetManagementService.cls
 * - NotificationService.cls
 * - PaymentStatus__c custom object
 */
public with sharing class PaymentStatusService {
```

**메서드 레벨 주석:**
```apex
/**
 * @description 납부 상태 업데이트 및 후속 프로세스 자동 실행
 * @param paymentStatusId 업데이트할 PaymentStatus 레코드 ID
 * @param newStatus 새로운 납부 상태 ('완납', '미납', '연체')
 * @return ResponseWrapper 처리 결과 및 메시지
 * @throws AuraHandledException 입력값 오류 또는 처리 실패 시
 * 
 * @example
 * ResponseWrapper result = PaymentStatusService.updatePaymentStatus(paymentId, '완납');
 * if (result.isSuccess) {
 *     // 성공 처리
 * }
 * 
 * Business Rules:
 * - 완납 처리 시 PaidDate__c 자동 설정
 * - 모든 회차 완납 시 Asset 자동 생성
 * - 상태 변경 시 관련 사용자에게 알림 발송
 */
@AuraEnabled
public static ResponseWrapper updatePaymentStatus(Id paymentStatusId, String newStatus) {
```

### 🧪 테스트 작성 가이드라인

**Test Class 구조:**
```apex
@isTest
public class PaymentStatusServiceTest {
    
    // 테스트 데이터 설정
    @TestSetup
    static void setupTestData() {
        // 공통 테스트 데이터 생성
        TestDataFactory.createAccountWithOrders(5);
    }
    
    // 성공 시나리오 테스트
    @isTest
    static void testUpdatePaymentStatus_WhenValidInput_ShouldReturnSuccess() {
        // Given: 테스트 조건 설정
        PaymentStatus__c payment = TestDataFactory.createPaymentStatus();
        
        // When: 메서드 실행
        Test.startTest();
        ResponseWrapper result = PaymentStatusService.updatePaymentStatus(payment.Id, '완납');
        Test.stopTest();
        
        // Then: 결과 검증
        System.assert(result.isSuccess, '성공 응답이어야 함');
        PaymentStatus__c updatedPayment = [SELECT Status__c, PaidDate__c FROM PaymentStatus__c WHERE Id = :payment.Id];
        System.assertEquals('완납', updatedPayment.Status__c, '상태가 완납으로 변경되어야 함');
        System.assertNotEquals(null, updatedPayment.PaidDate__c, '납부일자가 설정되어야 함');
    }
    
    // 예외 상황 테스트
    @isTest
    static void testUpdatePaymentStatus_WhenInvalidStatus_ShouldThrowException() {
        // Given
        PaymentStatus__c payment = TestDataFactory.createPaymentStatus();
        
        // When & Then
        Test.startTest();
        try {
            PaymentStatusService.updatePaymentStatus(payment.Id, '잘못된상태');
            System.assert(false, '예외가 발생해야 함');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('유효하지 않은 상태값'), '적절한 에러 메시지여야 함');
        }
        Test.stopTest();
    }
    
    // 대량 데이터 테스트
    @isTest
    static void testBulkPaymentProcessing_WhenMultipleRecords_ShouldProcessAll() {
        // Given: 200개 레코드 생성
        List<PaymentStatus__c> payments = TestDataFactory.createBulkPaymentStatuses(200);
        
        // When
        Test.startTest();
        PaymentStatusService.processBulkPaymentUpdates(payments);
        Test.stopTest();
        
        // Then: Governor Limits 확인
        System.assert(Limits.getQueries() < Limits.getLimitQueries(), 'SOQL 쿼리 한도 준수');
        System.assert(Limits.getDMLStatements() < Limits.getLimitDMLStatements(), 'DML 한도 준수');
    }
}

## 🎯 도메인 특화 지식

### 🔧 Salesforce 특화 개념

**Trigger 개발 패턴:**
```apex
// 단일 트리거 + 핸들러 패턴 사용
trigger OrderTrigger on Order (before insert, before update, after insert, after update) {
    new OrderTriggerHandler().execute();
}

// 컨텍스트별 처리 로직
public class OrderTriggerHandler extends TriggerHandler {
    protected override void afterInsert(List<SObject> records) {
        List<Order> newOrders = (List<Order>) records;
        
        // 1. Account RecordType 업데이트 (동기)
        AccountService.updateToActiveCustomer(newOrders);
        
        // 2. PaymentStatus 생성 (동기)
        PaymentScheduleService.createSchedules(newOrders);
        
        // 3. 자동화 프로세스 시작 (비동기)
        OrderAutomationService.processAsync(Utility.extractIds(newOrders));
    }
}
```

**LWC 개발 패턴:**
```javascript
// 표준 LWC 구조 및 라이프사이클
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class PaymentStatusTimeline extends NavigationMixin(LightningElement) {
    @api recordId;                    // 상위 컴포넌트에서 전달받는 데이터
    @track paymentData = [];          // 반응형 데이터
    @track isLoading = false;         // 로딩 상태
    
    // Wire 서비스로 데이터 자동 로딩
    @wire(getPaymentTimeline, { orderId: '$recordId' })
    wiredPayments(result) {
        this.wiredPaymentResult = result;
        if (result.data) {
            this.paymentData = this.processPaymentData(result.data);
        } else if (result.error) {
            this.showErrorToast('데이터 로드 실패', result.error.body.message);
        }
    }
    
    // 이벤트 핸들러
    async handlePaymentUpdate(event) {
        this.isLoading = true;
        try {
            await updatePaymentStatus({
                paymentId: event.detail.paymentId,
                newStatus: event.detail.status
            });
            
            this.showSuccessToast('납부 상태가 업데이트되었습니다.');
            await refreshApex(this.wiredPaymentResult);
            
        } catch (error) {
            this.showErrorToast('업데이트 실패', error.body.message);
        } finally {
            this.isLoading = false;
        }
    }
}
```

**Custom Object 설계 패턴:**
```apex
// PaymentStatus__c 객체의 비즈니스 로직
public class PaymentStatus {
    // 필수 필드
    public static final Set<String> REQUIRED_FIELDS = new Set<String>{
        'Order__c', 'InstallmentNumber__c', 'Amount__c', 'DueDate__c'
    };
    
    // 상태값 관리
    public enum Status {
        PENDING('미납'),
        COMPLETED('완납'),
        OVERDUE('연체'),
        PARTIAL('부분납부');
        
        private String koreanLabel;
        Status(String label) { this.koreanLabel = label; }
        public String getLabel() { return this.koreanLabel; }
    }
    
    // 비즈니스 로직 메서드
    public static Boolean isOverdue(PaymentStatus__c payment) {
        return payment.Status__c != Status.COMPLETED.getLabel() 
            && payment.DueDate__c < Date.today();
    }
}
```

### 📊 비즈니스 로직 패턴

**Asset 자동 생성 로직:**
```apex
public class AssetCreationService {
    
    /**
     * 완납 감지 시 Asset 생성 비즈니스 로직
     */
    public static void createAssetsForCompletedOrders(Set<Id> orderIds) {
        // 1. 완납된 Order 조회
        List<Order> completedOrders = [
            SELECT Id, AccountId, OrderNumber, TotalAmount,
                   (SELECT Id, Product2Id, Product2.Name, Quantity FROM OrderItems)
            FROM Order 
            WHERE Id IN :orderIds
            AND Id NOT IN (SELECT Order__c FROM Asset WHERE Order__c IN :orderIds)
        ];
        
        List<Asset> assetsToCreate = new List<Asset>();
        
        for (Order orderInfo : completedOrders) {
            // 2. OrderItem 기반 Asset 생성
            for (OrderItem item : orderInfo.OrderItems) {
                Asset newAsset = buildAssetFromOrderItem(orderInfo, item);
                assetsToCreate.add(newAsset);
            }
            
            // 3. Account RecordType 업데이트
            updateAccountToActiveCustomer(orderInfo.AccountId);
        }
        
        // 4. 벌크 생성
        if (!assetsToCreate.isEmpty()) {
            insert assetsToCreate;
            
            // 5. 후속 프로세스 (비동기)
            AssetPostProcessService.processNewAssetsAsync(
                Utility.extractIds(assetsToCreate)
            );
        }
    }
    
    private static Asset buildAssetFromOrderItem(Order orderInfo, OrderItem item) {
        return new Asset(
            Name = item.Product2.Name + ' - ' + orderInfo.OrderNumber,
            AccountId = orderInfo.AccountId,
            Product2Id = item.Product2Id,
            Order__c = orderInfo.Id,
            Quantity = item.Quantity,
            Status = 'Purchased',
            InstallDate = Date.today(),
            UsageEndDate = Date.today().addYears(1)
        );
    }
}
```

**분할납부 스케줄 생성 로직:**
```apex
public class PaymentScheduleService {
    
    public static void createPaymentSchedules(List<Order> orders) {
        List<PaymentStatus__c> schedulesToCreate = new List<PaymentStatus__c>();
        
        for (Order orderInfo : orders) {
            // 비즈니스 규칙: 결제 방법에 따른 분할 계획
            Integer installmentCount = getInstallmentCount(orderInfo.Payment_Method__c);
            Decimal installmentAmount = orderInfo.TotalAmount / installmentCount;
            
            for (Integer i = 1; i <= installmentCount; i++) {
                PaymentStatus__c schedule = new PaymentStatus__c(
                    Order__c = orderInfo.Id,
                    InstallmentNumber__c = i,
                    Amount__c = installmentAmount,
                    DueDate__c = orderInfo.EffectiveDate.addMonths(i - 1),
                    Status__c = '미납'
                );
                schedulesToCreate.add(schedule);
            }
        }
        
        insert schedulesToCreate;
    }
    
    private static Integer getInstallmentCount(String paymentMethod) {
        // Custom Metadata 기반 설정
        Payment_Config__mdt config = Payment_Config__mdt.getInstance(paymentMethod);
        return config != null ? Integer.valueOf(config.Installment_Count__c) : 1;
    }
}
```

### 🗄️ 데이터 모델 이해

**엔티티 관계 및 제약조건:**
```sql
-- Order와 PaymentStatus 1:N 관계
Order (1) ──────→ (N) PaymentStatus__c
  ↓ TotalAmount      ↓ SUM(Amount__c) [VALIDATION RULE]
  
-- PaymentStatus 완납 시 Asset 생성
PaymentStatus__c [ALL 완납] ──TRIGGER──→ Asset Creation

-- Account 상태 전환
Account [RecordType: Prospect] ──ORDER CREATE──→ [RecordType: Active Customer]
```

**핵심 Validation Rules:**
```apex
// PaymentStatus 금액 검증
AND(
    ISNUMBER(Amount__c),
    Amount__c > 0,
    (SELECT SUM(Amount__c) FROM Order.PaymentStatuses__r) = Order.TotalAmount
)

// 중복 회차 방지
VLOOKUP(
    InstallmentNumber__c, 
    $ObjectType.PaymentStatus__c.Fields.InstallmentNumber__c, 
    Order__c
) <> InstallmentNumber__c
```

**필수 Custom Fields:**
```yaml
PaymentStatus__c:
  - Order__c (Master-Detail)
  - InstallmentNumber__c (Number, Required)
  - Amount__c (Currency, Required)
  - DueDate__c (Date, Required)
  - Status__c (Picklist: 미납,완납,연체)
  - PaidDate__c (Date, Optional)

Order:
  - Payment_Method__c (Picklist: 일시불,분할납부)
  - Slack_Integration__c (Checkbox)
  
Asset:
  - Order__c (Lookup to Order)
  - InstallmentPlan__c (Lookup to PaymentStatus__c)
```

## 🔧 개발 가이드라인

### ⚡ 성능 최적화 원칙

**1. SOQL 최적화**
```apex
// ❌ 비효율적인 쿼리
List<Order> orders = [SELECT Id FROM Order];
for (Order order : orders) {
    List<PaymentStatus__c> payments = [SELECT Id FROM PaymentStatus__c WHERE Order__c = :order.Id];
}

// ✅ 최적화된 쿼리 (Subquery 사용)
List<Order> orders = [
    SELECT Id, OrderNumber, TotalAmount,
           (SELECT Id, Amount__c, Status__c, InstallmentNumber__c 
            FROM PaymentStatuses__r 
            WHERE Status__c != '완납' 
            ORDER BY InstallmentNumber__c)
    FROM Order 
    WHERE CreatedDate = LAST_N_DAYS:30
    AND Status = 'Activated'
];

// ✅ Selective Query 패턴
String accountId = 'someAccountId';
List<Asset> assets = [
    SELECT Id, Name, Status, AccountId
    FROM Asset 
    WHERE AccountId = :accountId 
    AND Status IN ('Active', 'Purchased')
    AND CreatedDate >= :Date.today().addMonths(-6)
    LIMIT 1000
];
```

**2. Bulk Processing 패턴**
```apex
// ✅ DML 최적화
public static void updatePaymentStatuses(List<PaymentStatus__c> payments) {
    List<PaymentStatus__c> paymentsToUpdate = new List<PaymentStatus__c>();
    List<Task> tasksToCreate = new List<Task>();
    
    // 1. 데이터 준비 (루프)
    for (PaymentStatus__c payment : payments) {
        if (payment.Status__c == '완납') {
            payment.PaidDate__c = Date.today();
            paymentsToUpdate.add(payment);
            
            tasksToCreate.add(new Task(
                Subject = payment.InstallmentNumber__c + '회차 납부 완료',
                WhatId = payment.Id,
                Status = 'Completed'
            ));
        }
    }
    
    // 2. 벌크 DML (한 번에 처리)
    if (!paymentsToUpdate.isEmpty()) {
        update paymentsToUpdate;
    }
    if (!tasksToCreate.isEmpty()) {
        insert tasksToCreate;
    }
}
```

**3. Governor Limits 관리**
```apex
// ✅ CPU Time 집약적 작업 분리
@future(callout=true)
public static void processHeavyAutomation(Set<Id> orderIds) {
    List<Order> orders = [SELECT Id, OrderNumber FROM Order WHERE Id IN :orderIds];
    
    for (Order orderInfo : orders) {
        try {
            // CPU 집약적 PDF 생성
            generateOrderPDF(orderInfo);
            
            // 외부 API 호출
            SlackService.createOrderChannel(orderInfo);
            
        } catch (Exception e) {
            // 개별 실패 처리
            LoggingService.logError('Order automation failed', orderInfo.Id, e);
        }
    }
}

// ✅ 대량 처리를 위한 Queueable 패턴
public class BulkPaymentProcessor implements Queueable {
    private List<PaymentStatus__c> paymentsToProcess;
    private Integer batchSize = 200;
    
    public void execute(QueueableContext context) {
        List<PaymentStatus__c> currentBatch = new List<PaymentStatus__c>();
        
        for (Integer i = 0; i < Math.min(batchSize, paymentsToProcess.size()); i++) {
            currentBatch.add(paymentsToProcess[i]);
        }
        
        // 처리 로직
        processPaymentBatch(currentBatch);
        
        // 남은 데이터가 있으면 다음 배치 큐잉
        if (paymentsToProcess.size() > batchSize) {
            List<PaymentStatus__c> remainingPayments = new List<PaymentStatus__c>();
            for (Integer i = batchSize; i < paymentsToProcess.size(); i++) {
                remainingPayments.add(paymentsToProcess[i]);
            }
            System.enqueueJob(new BulkPaymentProcessor(remainingPayments));
        }
    }
}
```

### 🔐 보안 고려사항

**1. CRUD/FLS 권한 검증**
```apex
// ✅ 접근 권한 검증 유틸리티
public class SecurityUtils {
    
    public static void validateObjectAccess(SObjectType objectType, String operation) {
        switch on operation.toLowerCase() {
            when 'create' {
                if (!objectType.getDescribe().isCreateable()) {
                    throw new SecurityException('생성 권한이 없습니다: ' + objectType);
                }
            }
            when 'read' {
                if (!objectType.getDescribe().isAccessible()) {
                    throw new SecurityException('조회 권한이 없습니다: ' + objectType);
                }
            }
            when 'update' {
                if (!objectType.getDescribe().isUpdateable()) {
                    throw new SecurityException('수정 권한이 없습니다: ' + objectType);
                }
            }
            when 'delete' {
                if (!objectType.getDescribe().isDeletable()) {
                    throw new SecurityException('삭제 권한이 없습니다: ' + objectType);
                }
            }
        }
    }
    
    public static void validateFieldAccess(SObjectField field, String operation) {
        DescribeFieldResult fieldDescribe = field.getDescribe();
        
        if (operation == 'read' && !fieldDescribe.isAccessible()) {
            throw new SecurityException('필드 조회 권한이 없습니다: ' + fieldDescribe.getName());
        }
        if (operation == 'update' && !fieldDescribe.isUpdateable()) {
            throw new SecurityException('필드 수정 권한이 없습니다: ' + fieldDescribe.getName());
        }
    }
}

// ✅ 서비스 메서드에서 권한 검증
public static List<PaymentStatus__c> getPaymentStatuses(Id orderId) {
    // 객체 접근 권한 확인
    SecurityUtils.validateObjectAccess(PaymentStatus__c.SObjectType, 'read');
    
    // 필드 접근 권한 확인
    SecurityUtils.validateFieldAccess(PaymentStatus__c.Amount__c, 'read');
    SecurityUtils.validateFieldAccess(PaymentStatus__c.Status__c, 'read');
    
    return [
        SELECT Id, Amount__c, Status__c, DueDate__c 
        FROM PaymentStatus__c 
        WHERE Order__c = :orderId
        WITH SECURITY_ENFORCED
    ];
}
```

**2. 입력값 검증 및 살균**
```apex
public class InputValidator {
    
    public static void validatePaymentStatusUpdate(Id paymentStatusId, String newStatus) {
        // Null 체크
        if (paymentStatusId == null) {
            throw new ValidationException('PaymentStatus ID는 필수입니다.');
        }
        
        if (String.isBlank(newStatus)) {
            throw new ValidationException('납부 상태값은 필수입니다.');
        }
        
        // 허용된 값 검증
        Set<String> allowedStatuses = new Set<String>{'완납', '미납', '연체', '부분납부'};
        if (!allowedStatuses.contains(newStatus)) {
            throw new ValidationException('유효하지 않은 상태값입니다: ' + newStatus);
        }
        
        // ID 형식 검증
        if (!isValidSalesforceId(paymentStatusId)) {
            throw new ValidationException('잘못된 ID 형식입니다.');
        }
    }
    
    // HTML 태그 제거 (XSS 방지)
    public static String sanitizeInput(String input) {
        if (String.isBlank(input)) return input;
        
        return input.replaceAll('<[^>]+>', '')
                   .replaceAll('javascript:', '')
                   .replaceAll('on\\w+\\s*=', '');
    }
    
    private static Boolean isValidSalesforceId(Id recordId) {
        String idString = String.valueOf(recordId);
        return idString.length() == 15 || idString.length() == 18;
    }
}
```

### 🚀 통합 및 배포 규칙

**1. 배포 전 체크리스트**
```yaml
Code Quality:
  - [ ] 모든 Apex 클래스 테스트 커버리지 85% 이상
  - [ ] PMD/Checkstyle 정적 분석 통과
  - [ ] Security Review 완료
  
Performance:
  - [ ] SOQL 쿼리 최적화 확인
  - [ ] Governor Limits 테스트 완료
  - [ ] 대량 데이터 처리 테스트
  
Integration:
  - [ ] 외부 API 연동 테스트
  - [ ] Slack 알림 기능 검증
  - [ ] Email 발송 기능 테스트
  
User Experience:
  - [ ] LWC 컴포넌트 반응형 테스트
  - [ ] 에러 메시지 사용자 친화성 확인
  - [ ] 로딩 상태 UI 구현
```

**2. 환경별 배포 전략**
```apex
// ✅ 환경별 설정 관리
public class EnvironmentConfig {
    
    public static String getCurrentEnvironment() {
        String orgId = UserInfo.getOrganizationId();
        
        // Custom Metadata로 환경 구분
        Environment_Config__mdt config = [
            SELECT Environment_Type__c 
            FROM Environment_Config__mdt 
            WHERE Org_ID__c = :orgId 
            LIMIT 1
        ];
        
        return config?.Environment_Type__c ?? 'Production';
    }
    
    public static Boolean isProductionEnvironment() {
        return getCurrentEnvironment() == 'Production';
    }
    
    // 환경별 로그 레벨 조정
    public static LoggingLevel getLogLevel() {
        switch on getCurrentEnvironment() {
            when 'Development' { return LoggingLevel.DEBUG; }
            when 'Testing' { return LoggingLevel.INFO; }
            when 'Staging' { return LoggingLevel.WARN; }
            when else { return LoggingLevel.ERROR; }
        }
    }
}
```

**3. 롤백 전략**
```apex
// ✅ 기능 플래그 패턴
public class FeatureFlags {
    
    public static Boolean isAssetAutoCreationEnabled() {
        Feature_Flag__mdt flag = Feature_Flag__mdt.getInstance('Asset_Auto_Creation');
        return flag?.Is_Enabled__c ?? false;
    }
    
    public static Boolean isSlackIntegrationEnabled() {
        Feature_Flag__mdt flag = Feature_Flag__mdt.getInstance('Slack_Integration');
        return flag?.Is_Enabled__c ?? false;
    }
}

// 서비스에서 기능 플래그 사용
public static void processOrderCompletion(Id orderId) {
    // 핵심 기능 (항상 실행)
    updateOrderStatus(orderId);
    
    // 선택적 기능 (플래그로 제어)
    if (FeatureFlags.isAssetAutoCreationEnabled()) {
        AssetService.createAssetsForOrder(orderId);
    }
    
    if (FeatureFlags.isSlackIntegrationEnabled()) {
        SlackService.notifyOrderCompletion(orderId);
    }
}
```

**4. 모니터링 및 알림**
```apex
// ✅ 시스템 모니터링
public class SystemMonitor {
    
    @future
    public static void logCriticalError(String component, String errorMessage, Id recordId) {
        Critical_Error_Log__c errorLog = new Critical_Error_Log__c(
            Component__c = component,
            Error_Message__c = errorMessage,
            Record_ID__c = recordId,
            Timestamp__c = Datetime.now(),
            Environment__c = EnvironmentConfig.getCurrentEnvironment()
        );
        
        insert errorLog;
        
        // 프로덕션 환경에서는 즉시 알림
        if (EnvironmentConfig.isProductionEnvironment()) {
            sendAdminAlert(errorLog);
        }
    }
    
    private static void sendAdminAlert(Critical_Error_Log__c errorLog) {
        // 이메일 알림
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(getAdminEmails());
        email.setSubject('[CRITICAL] 시스템 오류 발생');
        email.setPlainTextBody(
            '컴포넌트: ' + errorLog.Component__c + '\n' +
            '오류 메시지: ' + errorLog.Error_Message__c + '\n' +
            '레코드 ID: ' + errorLog.Record_ID__c + '\n' +
            '발생 시간: ' + errorLog.Timestamp__c
        );
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }
}

## 🎯 AI 어시스턴트 최적 활용 가이드

### 🤖 프로젝트 이해도 향상 지침

**이 프로젝트를 도울 때 반드시 고려해야 할 핵심 사항:**

1. **비즈니스 우선순위**
   - 🎯 **영업팀 워크플로우 최적화**가 최우선
   - 📊 **데이터 정확성**과 **자동화 신뢰성** 보장
   - 🚀 **사용자 경험** 개선을 통한 도입률 증대

2. **기술적 제약사항**
   - ⚡ **Salesforce Governor Limits** 철저 준수
   - 🔐 **Security-first** 개발 (CRUD/FLS 검증 필수)
   - 📈 **확장성** 고려한 아키텍처 설계

3. **도메인 전문성**
   - 💰 **B2B 영업 프로세스** 깊이 있는 이해
   - 🔄 **분할납부 → Asset 생성** 플로우 정확성
   - 🤝 **고객 생애주기** 관리 전략

### � 코드 제안 시 우선 검토 항목

**Apex 코드 제안 시:**
```apex
// ✅ 반드시 포함해야 할 요소들
1. 입력값 검증 (Null check, 타입 검증)
2. 권한 검증 (CRUD/FLS)
3. 벌크 처리 패턴
4. 적절한 예외 처리
5. 비즈니스 로직 주석

// ❌ 절대 하지 말아야 할 것들
1. 루프 내 SOQL/DML
2. 하드코딩된 ID 사용
3. 권한 검증 없는 데이터 접근
4. Generic Exception 처리
5. Governor Limits 무시
```

**LWC 코드 제안 시:**
```javascript
// ✅ 필수 구현 요소들
1. Loading 상태 관리
2. Error handling 및 사용자 친화적 메시지
3. Accessibility 고려 (aria-label, role 등)
4. Reactive data 패턴
5. Performance 최적화 (debounce, throttle)

// ❌ 피해야 할 패턴들
1. DOM 직접 조작
2. 하드코딩된 문자열 (label 사용)
3. Memory leak 위험 요소
4. 비동기 처리 없는 서버 호출
```

### � 자주 사용되는 비즈니스 패턴

**1. Order → PaymentStatus 생성 패턴**
```apex
// 분할납부 일정 자동 생성
// 결제 방법 (일시불/분할) 따른 로직 분기
// Custom Metadata 기반 설정값 활용
```

**2. PaymentStatus 완납 감지 → Asset 생성 패턴**
```apex
// 모든 회차 완납 확인 로직
// Account RecordType 자동 업데이트
// 후속 Task 및 알림 생성
```

**3. Agentforce 연동 패턴**
```apex
// @InvocableMethod 구현
// AI 분석 결과를 비즈니스 로직에 반영
// Custom Metadata로 AI 설정 관리
```

**4. 채널 및 알림 패턴**
```apex
// Chatter 그룹 자동 생성
// Slack API 연동
// 다중 채널 알림 시스템
```

### 🎨 UI/UX 설계 원칙

**사용자 중심 설계:**
- **영업팀**: 빠른 정보 접근, 원클릭 액션
- **Finance팀**: 정확한 데이터, 상세 보고서
- **관리자**: 종합 대시보드, 예외상황 알림

**반응형 컴포넌트:**
- 모바일 우선 설계
- 접근성 표준 준수
- 로딩 상태 명확 표시

### 💡 문제 해결 접근법

**1. 성능 이슈**
```
진단 → Governor Limits 확인 → SOQL 최적화 → 비동기 처리 → 배치 작업
```

**2. 데이터 정합성 이슈**
```
검증 → Validation Rule → Trigger 로직 → 트랜잭션 관리 → 롤백 전략
```

**3. 사용자 경험 이슈**
```
분석 → 피드백 수집 → UI 개선 → A/B 테스트 → 지속적 개선
```

### 🏆 성공 지표 및 품질 기준

**코드 품질:**
- Test Coverage: 85% 이상
- Cyclomatic Complexity: 10 이하
- 주석 비율: 20% 이상

**성능 기준:**
- LWC 렌더링: 2초 이내
- Apex 처리: 1000 레코드/분
- API 응답: 500ms 이내

**사용자 만족도:**
- 기능 도입률: 80% 이상
- 오류 발생률: 1% 이하
- 사용자 피드백: 4.5/5 이상

---

## 🎯 최종 검토 체크리스트

### ✅ 코드 제안 전 확인사항

**비즈니스 로직:**
- [ ] SOCAR B2B 영업 프로세스에 부합하는가?
- [ ] 분할납부 → Asset 생성 플로우가 정확한가?
- [ ] 사용자 권한 및 보안이 고려되었는가?

**기술적 완성도:**
- [ ] Salesforce Best Practice를 따르는가?
- [ ] Governor Limits을 고려했는가?
- [ ] 확장성과 유지보수성이 보장되는가?

**사용자 경험:**
- [ ] 직관적이고 사용하기 쉬운가?
- [ ] 오류 상황에 대한 적절한 피드백이 있는가?
- [ ] 성능이 만족스러운가?

**문서화:**
- [ ] 충분한 주석과 설명이 있는가?
- [ ] 비즈니스 규칙이 명확히 문서화되었는가?
- [ ] 예제와 사용법이 제공되는가?

---

**"이 가이드를 바탕으로 SOCAR B2B 영업팀의 성공을 위한 최고의 Salesforce 솔루션을 함께 만들어가세요!"**

*🚀 혁신적이고 실용적인 솔루션으로 비즈니스 성장을 이끌어내는 것이 우리의 목표입니다.*

---

**개발자: 문정현 (JH Moon)**  
**프로젝트: SOCAR B2B Salesforce 자동화 시스템**  
**최종 업데이트: 2025-07-27**