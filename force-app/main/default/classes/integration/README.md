# 🔗 Integration Services Domain

## 🎯 목적
Salesforce와 외부 시스템 간의 통합, API 연동, 다채널 서비스 연동을 관리하는 도메인입니다.

## 📁 폴더 구조

### 💬 slack/
Slack 통합 서비스들
- `SlackChannelService.cls`: Slack 채널 서비스
- `SlackToSalesforceChannelMigrationService.cls`: Slack-Salesforce 채널 마이그레이션
- `AgentforceSlackIntegrationService.cls`: Agentforce Slack 통합

### 📧 email/
이메일 서비스들
- `PaymentCompletionEmailService.cls`: 납부 완료 이메일
- `AgentforceEmailIntegrationService.cls`: Agentforce 이메일 통합
- 이메일 템플릿 관리 및 발송

### 📄 pdf/
PDF 생성 및 관리 서비스들
- `QuotationPDFController.cls`: 견적서 PDF 생성
- `TaxInvoicePDFController.cls`: 세금계산서 PDF 생성
- `PaymentStatusPDFController.cls`: 납부 스케줄 PDF 생성

### 📢 channels/
채널 통합 서비스들
- `SalesforceChannelService.cls`: Salesforce 채널 서비스
- `SimpleSalesforceChannelService.cls`: 간소화된 채널 서비스
- `ChannelNotificationService.cls`: 채널 알림 서비스

## 🔄 주요 통합 패턴

### 📱 Slack Integration
```
Salesforce 이벤트 → Slack Webhook → 채널 알림 → 사용자 알림
```

**주요 기능:**
- 실시간 Order 생성 알림
- PaymentStatus 변경 알림  
- Asset 생성 완료 알림
- 연체/완납 상태 변경 알림

### 📧 Email Integration
```
비즈니스 이벤트 → 이메일 트리거 → 템플릿 적용 → 고객 발송
```

**주요 기능:**
- 납부 완료 확인 이메일
- 연체 안내 이메일
- 갱신 안내 이메일
- 영업 제안 이메일

### 📄 PDF Generation
```
데이터 조회 → Visualforce 페이지 → PDF 렌더링 → 파일 생성/발송
```

**주요 기능:**
- 견적서 자동 생성
- 세금계산서 발행
- 납부 스케줄표 생성
- 계약서 PDF 생성

## 🔧 통합 아키텍처

### 🌐 API Gateway Pattern
```apex
public interface IntegrationService {
    ResponseWrapper callExternalAPI(RequestWrapper request);
    void handleCallback(CallbackData data);
    Boolean validateConnection();
}
```

### 🔄 Event-Driven Integration
```apex
public class IntegrationEventHandler {
    @future(callout=true)
    public static void processIntegrationEvent(String eventData) {
        // 비동기 외부 시스템 호출
    }
}
```

### 📊 Integration Monitoring
```apex
public class IntegrationMonitor {
    public static void logAPICall(String service, String method, Integer statusCode);
    public static List<IntegrationLog> getFailedIntegrations();
    public static void retryFailedIntegrations();
}
```

## 🛡️ 보안 & 인증

### 🔐 인증 관리
- OAuth 2.0 토큰 관리
- API Key 암호화 저장
- 연결 상태 모니터링

### 🔒 데이터 보안
- 개인정보 마스킹
- 전송 데이터 암호화
- 로그 데이터 익명화

## 📊 모니터링 & 로깅

### 📈 성능 모니터링
- API 응답 시간 추적
- 실패율 모니터링
- 처리량 분석

### 📝 통합 로깅
- 모든 외부 API 호출 로깅
- 에러 및 예외 상황 추적
- 비즈니스 이벤트 로깅

## 🤝 연관 도메인
- **Payment Management**: 납부 관련 이메일/Slack 알림
- **Order Management**: 주문 생성 알림 및 PDF 생성
- **Asset Management**: Asset 생성 알림 및 갱신 안내
- **Agentforce Integration**: AI 기반 통합 서비스

## 📞 담당자
- **Integration Lead**: Moon JeongHyeon
- **DevOps Team**: Integration Services Team
