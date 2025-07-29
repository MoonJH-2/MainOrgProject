# 🏗️ MainOrgProject 구조 분석 및 정리 계획

## 📋 현재 구조 분석

### 🔍 분석 결과 요약

#### 현재 폴더 구조
```
force-app/main/default/
├── classes/                     # 84개 파일 (혼재된 구조)
│   ├── [개별 클래스들]           # 48개 개별 파일
│   ├── automation_services/     # 16개 파일
│   ├── payment_classes/         # 48개 파일  
│   ├── navigation_services/     # 2개 파일
│   ├── VIBA_Core/              # VIBA 핵심 기능
│   ├── VIBA_Enhanced/          # VIBA 확장 기능
│   └── [기타 서비스 폴더들]
├── lwc/                        # 30개 컴포넌트
├── triggers/                   # 14개 트리거
├── flexipages/                 # 1개 페이지
├── pages/                      # 8개 Visualforce 페이지
└── agentforce/                 # 1개 Agent 정의
```

#### 🚨 현재 구조의 문제점
1. **클래스 폴더 혼재**: 개별 파일과 폴더가 섞여 있음
2. **도메인별 분리 부족**: Order, Payment, Asset, Agentforce가 명확히 분리되지 않음
3. **네이밍 불일치**: 유사 기능이 다른 폴더에 분산
4. **확장성 제한**: 새로운 기능 추가 시 위치 모호

---

## 🎯 개선된 구조 설계

### 📁 목표 구조 (Domain-Driven Design)
```
force-app/main/default/
├── classes/
│   ├── order_management/           # Order 도메인
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── triggers/
│   │   └── utils/
│   ├── payment_management/         # PaymentStatus 도메인
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── automation/
│   │   ├── scheduling/
│   │   └── notifications/
│   ├── asset_management/           # Asset 도메인
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── analytics/
│   │   └── renewal/
│   ├── agentforce_integration/     # Agentforce 도메인
│   │   ├── actions/
│   │   ├── services/
│   │   ├── viba_core/
│   │   └── viba_enhanced/
│   ├── shared/                     # 공통 기능
│   │   ├── base/
│   │   ├── utils/
│   │   ├── wrappers/
│   │   └── exceptions/
│   └── integration/               # 외부 연동
│       ├── slack/
│       ├── email/
│       └── pdf/
├── lwc/
│   ├── order_components/
│   ├── payment_components/
│   ├── asset_components/
│   └── shared_components/
├── triggers/
│   ├── order_triggers/
│   ├── payment_triggers/
│   ├── asset_triggers/
│   └── shared_triggers/
├── pages/
│   ├── pdf_templates/
│   └── utility_pages/
└── agentforce/
    ├── agents/
    ├── topics/
    └── actions/
```

---

## 🔄 파일 분류 매핑

### 1️⃣ Order Management
```yaml
Controllers:
  - OrderCreatorController.cls
  - AccountOrderDashboardController.cls
  - OpportunityToOrderService.cls

Services:
  - OrderProductAutoRegistrationService.cls
  - OrderProductAutomationService.cls
  - OrderNotificationService.cls
  - OrderChannelFields.cls

Triggers:
  - OrderTriggerHandler.cls
  - OrderTrigger.trigger

Batch Jobs:
  - OrderProductCorrectionBatch.cls
  - OrderProductMissingCorrectionBatch.cls

LWC Components:
  - orderCreator/
  - accountOrderDashboard/
  - orderAssetNavigator/
```

### 2️⃣ Payment Management  
```yaml
Controllers:
  - PaymentStatusTimelineController.cls
  - PaymentNotificationDashboardController.cls
  - PaymentStatusPDFController.cls

Services:
  - PaymentScheduleService.cls
  - PaymentNotificationService.cls
  - PaymentOverdueService.cls
  - PaymentCompletionEmailService.cls

Automation:
  - PaymentStatusTriggerHandler.cls
  - PaymentScheduleAssetTriggerHandler.cls

Scheduling:
  - PaymentNotificationScheduler.cls
  - PaymentMidnightOverdueScheduler.cls
  - PaymentOverdueCheckScheduler.cls
  - PaymentNotificationBatch.cls

Triggers:
  - PaymentStatusTrigger.trigger
  - PaymentStatusAssetTrigger.trigger

LWC Components:
  - paymentStatusTimeline/
  - paymentNotificationDashboard/
  - customerPaymentManager/
  - paymentStatusController/
```

### 3️⃣ Asset Management
```yaml
Controllers:
  - AssetManagementController.cls
  - AssetManagementController_Enhanced.cls
  - SalesAssetSupportController.cls

Services:
  - AccountBasedAssetService.cls
  - OrderAssetCreationService.cls
  - AssetStatusManagementService.cls
  - OneClickRenewalService.cls

Analytics:
  - AssetBasedSalesOpportunityEngine.cls
  - AssetCustomerRiskAnalyzer.cls
  - AssetROIAnalysisService.cls
  - AssetRenewalOpportunityEngine.cls
  - AssetPriorityCalculator.cls

Automation:
  - PaymentStatusAssetTriggerHandler.cls
  - AssetStatusUpdateBatch.cls

LWC Components:
  - assetDashboard/
  - enhancedAssetDetails/
  - modernAssetDashboard/
  - assetVisualizationDashboard/
  - minimalAssetDashboard/
  - assetPriorityDashboard/
  - assetSalesInsightDashboard/
  - oneClickRenewal/
```

### 4️⃣ Agentforce Integration
```yaml
Actions:
  - AgentforceEmailActions.cls
  - AgentforceOrderEmailAction.cls
  - AgentforcePaymentEmailAction.cls
  - AgentforceAssetEmailAction.cls
  - AgentforceSalesActions.cls
  - SOCARAgentforceActions.cls

Services:
  - AgentforceSalesAssistantService.cls
  - AgentforceMasterOrchestrationService.cls
  - AgentforceAdvancedAnalyticsService.cls
  - AgentforceSimpleAnalyticsService.cls

VIBA Core:
  - VIBA_Core/ (전체 폴더)

VIBA Enhanced:
  - VIBA_Enhanced/ (전체 폴더)

Integration:
  - AgentforceEmailIntegrationService.cls
  - AgentforceSlackIntegrationService.cls

Agent Definition:
  - SOCAR_Sales_Assistant.agentforce-meta.xml
```

### 5️⃣ Shared & Integration
```yaml
Base Classes:
  - TriggerHandler.cls
  - TriggerManager.cls
  - WrapperUtils.cls

Channel Services:
  - SalesforceChannelService.cls
  - SimpleSalesforceChannelService.cls
  - SlackChannelService.cls
  - ChannelNotificationService.cls

Integration Services:
  - SlackToSalesforceChannelMigrationService.cls

Utilities:
  - SearchAddressModalController.cls
  - BusinessNumberCheckModalController.cls
  - QuoteCloneModalController.cls
  - PerformanceTrackingService.cls

PDF Services:
  - QuotationPDFController.cls
  - TaxInvoicePDFController.cls

Test Classes:
  - test_classes/ (전체 폴더)
  - mockup_services/ (전체 폴더)
```

---

## 🚀 구조 개선 실행 계획

### Phase 1: 기본 폴더 구조 생성 ✅
1. Domain별 폴더 구조 생성
2. 기능별 서브폴더 생성
3. 네이밍 규칙 정의

### Phase 2: 파일 이동 및 정리 
1. Order Management 파일 이동
2. Payment Management 파일 이동  
3. Asset Management 파일 이동
4. Agentforce Integration 파일 이동
5. Shared & Integration 파일 이동

### Phase 3: 참조 경로 업데이트
1. Import 문 수정
2. Test 클래스 경로 수정
3. Metadata 참조 경로 수정

### Phase 4: 문서화 및 가이드 생성
1. 새로운 구조 문서 작성
2. 개발 가이드라인 업데이트
3. 폴더별 README 생성

---

## 📊 개선 효과 예상

### 🎯 개발 생산성 향상
- **파일 검색 시간 50% 단축**: 도메인별 분류로 직관적 위치 파악
- **코드 재사용성 증대**: 기능별 모듈화로 중복 코드 감소
- **신규 기능 개발 속도 향상**: 명확한 위치 가이드라인

### 🔧 유지보수성 개선
- **버그 수정 시간 단축**: 관련 파일들의 집중화
- **리팩토링 용이성**: 도메인 경계 명확화
- **테스트 커버리지 향상**: 체계적인 테스트 구조

### 👥 팀 협업 효율성
- **신규 개발자 온보딩 시간 단축**: 직관적 구조 이해
- **코드 리뷰 품질 향상**: 컨텍스트별 집중 리뷰
- **지식 공유 활성화**: 도메인 전문성 축적

---

## 🔄 다음 단계

1. **현재 분석 검토 및 승인**
2. **Phase 1 폴더 구조 생성 시작**
3. **점진적 파일 이동 실행**
4. **테스트 및 검증**
5. **문서화 완료**

이 구조 개선을 통해 MainOrgProject가 더욱 체계적이고 확장 가능한 프로젝트로 발전할 수 있습니다.

---

**📅 예상 완료 시기**: 2-3일 (단계별 진행)  
**👨‍💻 담당자**: Moon JeongHyeon  
**🎯 목표**: Domain-Driven Design 기반 최적화된 프로젝트 구조 완성
