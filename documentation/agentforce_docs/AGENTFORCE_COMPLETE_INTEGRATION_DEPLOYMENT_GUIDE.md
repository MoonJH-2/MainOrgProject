# SOCAR Agentforce 완전 통합 배포 가이드

## 🚀 배포 개요

모든 Phase가 연결된 통합 Agentforce 시스템을 배포하는 단계별 가이드입니다.

## 📋 배포 순서

### 1단계: 기본 서비스 배포

```bash
# Phase 1 서비스 배포
sf project deploy start -d force-app/main/default/classes/AgentforceSalesAssistantService.cls
sf project deploy start -d force-app/main/default/classes/AgentforceEmailIntegrationService.cls

# Phase 2 서비스 배포
sf project deploy start -d force-app/main/default/classes/AgentforceSlackIntegrationService.cls

# Phase 3 서비스 배포
sf project deploy start -d force-app/main/default/classes/AgentforceAdvancedAnalyticsService.cls

# 마스터 오케스트레이션 서비스 배포
sf project deploy start -d force-app/main/default/classes/AgentforceMasterOrchestrationService.cls
```

### 2단계: Agentforce Studio 설정

#### Topics 생성
1. **Manage Deals** Topic
   - 사용자 의도: 거래 관리, 영업 기회 추적
   - 연결 서비스: `AgentforceSalesAssistantService`

2. **B2B Email Communication** Topic
   - 사용자 의도: 이메일 작성, 고객 커뮤니케이션
   - 연결 서비스: `AgentforceEmailIntegrationService`

3. **General CRM** Topic
   - 사용자 의도: 일반적인 CRM 관리
   - 연결 서비스: `AgentforceMasterOrchestrationService`

4. **General Slack** Topic
   - 사용자 의도: 팀 커뮤니케이션, 알림 관리
   - 연결 서비스: `AgentforceSlackIntegrationService`

5. **Order Inquiries** Topic
   - 사용자 의도: 주문 조회, 상태 확인
   - 연결 서비스: `AgentforceMasterOrchestrationService`

#### Actions 생성

**1. Process Agentforce Request Action**
```yaml
Name: Process Agentforce Request
Description: 사용자 요청을 분석하고 적절한 서비스로 라우팅
Service Class: AgentforceMasterOrchestrationService.processAgentforceRequest
Input Parameters:
  - userMessage (String): 사용자 메시지
  - userId (String): 사용자 ID
  - recordId (String, optional): 관련 레코드 ID
```

**2. Manage Order Lifecycle Action**
```yaml
Name: Manage Order Lifecycle
Description: 주문 전체 라이프사이클 자동 관리
Service Class: AgentforceMasterOrchestrationService.manageOrderLifecycle
Input Parameters:
  - orderId (String): 주문 ID
  - lifecycleEvent (String): 라이프사이클 이벤트
  - paymentId (String, optional): 결제 ID
```

**3. Generate Daily Briefing Action**
```yaml
Name: Generate Daily Briefing
Description: 일일 영업 브리핑 생성
Service Class: AgentforceSalesAssistantService.getDailyBriefing
Input Parameters:
  - userId (String): 영업담당자 ID
```

**4. Generate Smart Email Action**
```yaml
Name: Generate Smart Email
Description: AI 기반 스마트 이메일 생성
Service Class: AgentforceEmailIntegrationService.generateSmartEmail
Input Parameters:
  - recordId (String): 관련 레코드 ID
  - emailType (String): 이메일 유형
```

**5. Predict Customer Churn Action**
```yaml
Name: Predict Customer Churn
Description: 고객 이탈 위험도 예측
Service Class: AgentforceAdvancedAnalyticsService.predictCustomerChurnRisk
Input Parameters:
  - customerId (String): 고객 ID
```

### 3단계: Flow 설정

#### Order Lifecycle Automation Flow
```yaml
Flow Name: Order_Lifecycle_Automation
Trigger: Order 상태 변경
Process:
  1. Order 상태 확인
  2. AgentforceMasterOrchestrationService.manageOrderLifecycle 호출
  3. 결과에 따른 후속 처리
```

#### Payment Status Automation Flow
```yaml
Flow Name: Payment_Status_Automation
Trigger: PaymentStatus__c 변경
Process:
  1. 결제 상태 확인
  2. 연체 여부 판단
  3. 적절한 라이프사이클 이벤트 발생
```

### 4단계: 사용자 권한 설정

#### Permission Set 생성
```yaml
Permission Set: Agentforce_Sales_Assistant_User
Permissions:
  - Read/Write: Order, Account, Task, Event
  - Read: PaymentStatus__c, Asset
  - Execute Apex: All Agentforce Services
  - Access Agentforce Actions
```

### 5단계: 통합 테스트

#### 테스트 시나리오 1: 완전 자동화된 Order 처리
```apex
// 1. Order 활성화
Order testOrder = createTestOrder();
testOrder.Status = 'Activated';
update testOrder;

// 2. 자동 처리 확인
// - Slack 채널 생성 여부
// - 환영 이메일 생성 여부
// - 초기 Task 생성 여부

// 3. 결제 완료
PaymentStatus__c payment = createTestPayment(testOrder.Id);
payment.Status__c = '완납';
update payment;

// 4. 자동 처리 확인
// - Slack 알림 발송 여부
// - 다음 결제 안내 Task 생성 여부
```

#### 테스트 시나리오 2: 일일 자동화
```apex
// 일일 자동화 실행
AgentforceMasterOrchestrationService.DailyAutomationResult result = 
    AgentforceMasterOrchestrationService.executeDailyAutomation(UserInfo.getUserId());

// 결과 검증
System.assert(result.success);
System.assert(result.dailyBriefing != null);
System.assert(result.salesInsights != null);
```

#### 테스트 시나리오 3: 고객 360도 뷰
```apex
// 고객 정보 조회
AgentforceMasterOrchestrationService.Customer360View customerView = 
    AgentforceMasterOrchestrationService.getCustomer360View(testAccount.Id);

// 결과 검증
System.assert(customerView.success);
System.assert(customerView.churnRisk != null);
System.assert(customerView.contactTiming != null);
```

## 🔧 Agentforce Agent 설정

### Agent 생성
1. **Agent Name**: SOCAR Sales Assistant
2. **Description**: SOCAR B2B 영업 효율성을 높이는 AI 어시스턴트
3. **Personality**: 전문적이고 친근한 B2B 영업 전문가

### Agent Instructions
```
당신은 SOCAR의 B2B 영업팀을 위한 전문 AI 어시스턴트입니다.

주요 역할:
1. 일일 영업 브리핑 제공
2. 고객 이메일 작성 지원
3. 고객 이탈 위험도 분석
4. 갱신 기회 식별
5. 팀 커뮤니케이션 지원

응답 스타일:
- 간결하고 실용적인 정보 제공
- 구체적인 액션 아이템 포함
- 데이터 기반 인사이트 제공
- 한국어로 친근하게 소통

금지사항:
- 개인정보 노출
- 부정확한 데이터 제공
- 승인되지 않은 액션 실행
```

### Topic-Action 매핑
```yaml
Manage Deals:
  - Process Agentforce Request
  - Generate Daily Briefing
  - Predict Customer Churn

B2B Email Communication:
  - Generate Smart Email
  - Process Agentforce Request

General CRM:
  - Process Agentforce Request
  - Get Customer 360 View

General Slack:
  - Process Agentforce Request
  - Manage Order Lifecycle

Order Inquiries:
  - Manage Order Lifecycle
  - Process Agentforce Request
```

## 📊 모니터링 및 운영

### 성능 모니터링
1. **Daily Automation 실행 통계**
   - 실행 횟수, 성공률, 평균 처리 시간
   
2. **Agentforce 상호작용 분석**
   - 사용자별 질의 패턴
   - 응답 만족도
   - 오류율

3. **Order Lifecycle 자동화 효과**
   - 처리 시간 단축
   - 수동 개입 감소
   - 고객 만족도 향상

### 알림 설정
```yaml
Critical Alerts:
  - Agentforce 서비스 오류
  - Order 라이프사이클 중단
  - 고위험 고객 감지

Daily Reports:
  - 일일 자동화 실행 결과
  - 새로운 갱신 기회
  - 팀 활동 요약
```

## 🚨 문제 해결

### 일반적인 문제
1. **Agentforce 응답 없음**
   - Service 배포 상태 확인
   - 사용자 권한 확인
   - Topic-Action 매핑 확인

2. **Order 자동화 실패**
   - Flow 활성화 상태 확인
   - 필수 필드 값 존재 확인
   - 권한 문제 확인

3. **이메일 생성 오류**
   - AgentforceEmailActions 서비스 상태 확인
   - 템플릿 존재 여부 확인
   - 수신자 정보 유효성 확인

### 로그 확인
```apex
// Debug 로그에서 Agentforce 상호작용 추적
System.debug('Agentforce Interaction Log');

// Setup → Debug Logs에서 상세 로그 확인
```

## 📈 성공 측정 지표

### KPI
1. **영업 효율성**
   - 일일 Task 완료율 20% 향상
   - 고객 응답 시간 50% 단축
   - 이메일 작성 시간 70% 절약

2. **고객 관리**
   - 이탈 위험 고객 조기 발견 80% 증가  
   - 갱신 성공률 30% 향상
   - 고객 만족도 25% 향상

3. **팀 협업**
   - Slack 알림 응답률 90% 달성
   - 정보 공유 시간 60% 단축
   - 팀 간 커뮤니케이션 효율성 40% 향상

## 🔄 지속적 개선

### Phase 4 계획
- **고급 AI 분석**: 더 정교한 예측 모델
- **개인화**: 사용자별 맞춤 기능
- **외부 시스템 통합**: ERP, 회계 시스템 연동
- **모바일 최적화**: Salesforce Mobile에서 완벽 지원

이제 모든 Phase가 완전히 연결된 통합 Agentforce 시스템이 준비되었습니다! 🎉
