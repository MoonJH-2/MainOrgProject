# 💰 Payment Domain

## 🎯 목적
PaymentStatus 관리, 납부 스케줄링, 연체 처리, 알림 시스템 등 납부와 관련된 모든 기능을 관리하는 도메인입니다.

## 📁 폴더 구조

### 🎮 controllers/
Payment 관련 Lightning Web Component 컨트롤러들
- `PaymentStatusTimelineController.cls`: 납부 타임라인 컨트롤러
- `PaymentNotificationDashboardController.cls`: 납부 알림 대시보드
- `PaymentStatusPDFController.cls`: 납부 스케줄 PDF 컨트롤러

### ⚙️ services/
Payment 핵심 비즈니스 로직들
- `PaymentScheduleService.cls`: 납부 스케줄 생성 및 관리
- `PaymentNotificationService.cls`: 납부 알림 서비스
- `PaymentOverdueService.cls`: 연체 처리 서비스
- `PaymentCompletionEmailService.cls`: 완납 이메일 서비스

### 🤖 automation/
Payment 자동화 처리들
- `PaymentStatusTriggerHandler.cls`: PaymentStatus 트리거 핸들러
- `PaymentScheduleAssetTriggerHandler.cls`: Payment-Asset 연동 핸들러

### ⏰ scheduling/
Payment 스케줄링 및 배치 작업들
- `PaymentNotificationScheduler.cls`: 납부 알림 스케줄러
- `PaymentMidnightOverdueScheduler.cls`: 자정 연체 체크 스케줄러
- `PaymentOverdueCheckScheduler.cls`: 연체 확인 스케줄러
- `PaymentNotificationBatch.cls`: 납부 알림 배치

### 📢 notifications/
Payment 알림 관련 서비스들
- `ChannelNotificationService.cls`: 채널 알림 서비스
- `PaymentNotificationService_Simplified.cls`: 간소화된 알림 서비스

## 🔄 주요 비즈니스 플로우
```
Order 생성 → PaymentStatus 자동 생성 → 스케줄링 → 사전 알림 → 연체 감지 → 완납 처리 → Asset 생성 트리거
```

## 📊 자동화 프로세스
1. **사전 알림**: 납부일 3일 전 자동 알림
2. **연체 감지**: 매일 자정 자동 연체 상태 전환
3. **완납 감지**: 완납 시 Asset 자동 생성 트리거
4. **다단계 독촉**: 연체 3일/7일/14일 후 단계별 알림

## 🤝 연관 도메인
- **Order Domain**: Order 생성 시 PaymentStatus 자동 생성
- **Asset Domain**: 완납 시 Asset 생성 연동
- **Integration**: Slack, Email 알림 연동

## 📞 담당자
- **Lead Developer**: Moon JeongHyeon
- **Domain Expert**: Payment Domain Team
