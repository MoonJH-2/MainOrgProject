# 📋 Order Domain

## 🎯 목적
Order 생성, 관리, 자동화와 관련된 모든 클래스들을 관리하는 도메인입니다.

## 📁 폴더 구조

### 🎮 controllers/
Order 관련 Lightning Web Component 컨트롤러들
- `OrderCreatorController.cls`: 주문 생성 컨트롤러
- `AccountOrderDashboardController.cls`: 계정별 주문 대시보드

### ⚙️ services/
Order 비즈니스 로직 및 서비스들
- `OpportunityToOrderService.cls`: Opportunity에서 Order 생성
- `OrderProductAutoRegistrationService.cls`: 주문 상품 자동 등록
- `OrderProductAutomationService.cls`: 주문 상품 자동화
- `OrderNotificationService.cls`: 주문 알림 서비스
- `OrderChannelFields.cls`: 주문 채널 필드 관리

### 🔧 triggers/
Order 관련 트리거 핸들러들
- `OrderTriggerHandler.cls`: Order 트리거 핸들러

### ⏰ batch_jobs/
Order 관련 배치 작업들
- `OrderProductCorrectionBatch.cls`: 주문 상품 수정 배치
- `OrderProductMissingCorrectionBatch.cls`: 누락 주문 상품 수정 배치

## 🔄 주요 비즈니스 플로우
```
Opportunity → Order 생성 → OrderProduct 자동 등록 → 알림 발송 → PaymentStatus 생성
```

## 🤝 연관 도메인
- **Payment Domain**: Order 생성 시 PaymentStatus 자동 생성
- **Asset Domain**: Order 완납 시 Asset 생성 트리거
- **Agentforce Integration**: Order 분석 및 AI 추천

## 📞 담당자
- **Lead Developer**: Moon JeongHyeon
- **Domain Expert**: Order Domain Team
