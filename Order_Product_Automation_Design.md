# 📋 Order Product 등록 시 자동화 시스템 설계서

## 🎯 핵심 요구사항
1. **Order에 Product 등록** → **PDF 자동 다운로드**
2. **Order에 Product 등록** → **Slack 채널 자동 생성**

## 🏗️ 시스템 아키텍처

### 📊 이벤트 플로우
```
Order Product 등록 (OrderItem Insert/Update)
           ↓
OrderTriggerHandler.afterUpdate()
           ↓
OrderProductAutomationService 호출
           ↓
    ┌─────────────┬─────────────┐
    ↓             ↓             ↓
PDF 자동 생성   Slack 채널    알림 발송
& 다운로드      자동 생성      (이메일/Chatter)
```

### 🔧 구현 컴포넌트

#### 1. **OrderProductAutomationService.cls** (신규)
```apex
/**
 * Order Product 등록 시 자동화 서비스
 * - PDF 자동 생성 및 다운로드
 * - Slack 채널 자동 생성
 * - 알림 발송
 */
public with sharing class OrderProductAutomationService {
    
    @future(callout=true)
    public static void processOrderProductAutomation(Set<Id> orderIds) {
        // 1. PDF 자동 생성 및 다운로드
        // 2. Slack 채널 자동 생성 
        // 3. 알림 발송 (이메일/Chatter)
    }
    
    // PDF 생성 로직
    private static void generateOrderProductPDF(List<Order> orders)
    
    // Slack 채널 생성 로직 
    private static void createSlackChannels(List<Order> orders)
    
    // 알림 발송 로직
    private static void sendNotifications(List<Order> orders)
}
```

#### 2. **SlackChannelService.cls** (신규)
```apex
/**
 * Slack 채널 생성 및 관리 서비스
 */
public with sharing class SlackChannelService {
    
    // Slack API를 통한 채널 생성
    public static Boolean createOrderChannel(Order orderInfo)
    
    // 채널 정보를 Order에 업데이트
    private static void updateOrderSlackInfo(Id orderId, String channelId, String channelName)
    
    // Slack 초기 메시지 발송
    private static void sendWelcomeMessage(String channelId, Order orderInfo)
}
```

#### 3. **OrderProductPDFService.cls** (신규)
```apex
/**
 * Order Product PDF 생성 및 관리 서비스
 */
public with sharing class OrderProductPDFService {
    
    // Order Product 상세 PDF 생성
    public static ContentVersion generateProductDetailPDF(Order orderInfo)
    
    // PDF 자동 다운로드 링크 생성
    public static String generateDownloadLink(Id contentVersionId)
    
    // PDF를 Order Files에 첨부
    private static void attachPDFToOrder(Id orderId, ContentVersion cv)
}
```

#### 4. **OrderTriggerHandler.cls** (기존 확장)
```apex
// afterUpdate 메서드에 추가
protected override void afterUpdate(List<SObject> news, List<SObject> olds, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
    // 기존 로직...
    
    // Order Product 자동화 처리
    Set<Id> orderIdsForAutomation = new Set<Id>();
    for (Order newOrd : (List<Order>)news) {
        Order oldOrd = oldOrderMap.get(newOrd.Id);
        
        // Order Products가 새로 등록되었거나 Status가 Activated로 변경된 경우
        if ((oldOrd.TotalAmount == 0 && newOrd.TotalAmount > 0) || 
            (oldOrd.Status != 'Activated' && newOrd.Status == 'Activated')) {
            orderIdsForAutomation.add(newOrd.Id);
        }
    }
    
    // 자동화 서비스 호출
    if (!orderIdsForAutomation.isEmpty()) {
        OrderProductAutomationService.processOrderProductAutomation(orderIdsForAutomation);
    }
}
```

## 🎨 PDF 생성 상세 설계

### 📄 Order Product Detail PDF 구성
```
┌─────────────────────────────────────┐
│  Order Product 상세서                │
│  ─────────────────────────────────  │
│  📋 Order 정보                       │
│  • Order Number: 00000141           │
│  • Customer: 김캐디 (Kimcaddie)      │
│  • Order Date: 2025.07.20           │
│  • Status: Activated                │
│                                     │
│  🛒 Product 상세                     │
│  • Product: 카셰어링 플래티넘         │
│  • Quantity: 100.00                 │
│  • Unit Price: ₩127,200             │
│  • Total: ₩12,720,000               │
│                                     │
│  💰 Payment 정보                     │
│  • Method: 분기별                    │
│  • Schedule: 4회 분할                │
│  • 1차: ₩3,180,000 (2025.07.20)     │
│  • 2차: ₩3,180,000 (2025.10.20)     │
│  • 3차: ₩3,180,000 (2026.01.20)     │
│  • 4차: ₩3,180,000 (2026.04.20)     │
│                                     │
│  📞 Contact 정보                     │
│  • Slack Channel: #00000141         │
│  • Contact: 수진 최                  │
│                                     │
│  생성일: 2025.07.21                  │
└─────────────────────────────────────┘
```

## 🔗 Slack 채널 생성 상세 설계

### 📱 Slack API 연동
```apex
// Slack 채널 생성 API 호출
Http http = new Http();
HttpRequest request = new HttpRequest();
request.setEndpoint('https://slack.com/api/conversations.create');
request.setMethod('POST');
request.setHeader('Authorization', 'Bearer ' + getSlackBotToken());
request.setHeader('Content-Type', 'application/json');

Map<String, Object> payload = new Map<String, Object>{
    'name' => orderInfo.OrderNumber.toLowerCase(), // "00000141"
    'is_private' => false,
    'is_channel' => true
};
request.setBody(JSON.serialize(payload));

HttpResponse response = http.send(request);
```

### 🎯 채널 초기 설정
```
채널명: #00000141
목적: Order 00000141 (김캐디) 전용 채널
초기 멤버: Order Owner, Account Owner, Customer Contact
초기 메시지:
  🎉 Order 00000141 채널이 생성되었습니다!
  
  📋 Order 정보
  • Customer: 김캐디 (Kimcaddie)
  • Product: 카셰어링 플래티넘 100개
  • Amount: ₩12,720,000
  • Payment: 분기별 4회 분할
  
  📎 관련 문서
  • Order Product 상세서.pdf
  • 납부 일정서.pdf
```

## 📦 구현 단계

### Phase 1: 핵심 서비스 구축 ⚡
1. **OrderProductAutomationService.cls** 생성
2. **OrderProductPDFService.cls** 생성  
3. **SlackChannelService.cls** 생성
4. **OrderTriggerHandler.cls** 확장

### Phase 2: PDF 자동 생성 시스템 📄
1. **Order Product Detail PDF 템플릿** 구축
2. **자동 다운로드 링크** 생성
3. **Files 자동 첨부** 기능

### Phase 3: Slack 연동 시스템 💬
1. **Slack API 인증** 설정
2. **채널 자동 생성** 기능
3. **초기 메시지 발송** 기능
4. **Order 필드 업데이트** 기능

### Phase 4: 통합 테스트 🧪
1. **Order 00000141 테스트**
2. **신규 Order 생성 테스트**
3. **에러 핸들링 검증**

## 🎯 성공 지표

### ✅ 검증 체크리스트
- [ ] Order Product 등록 시 PDF 자동 생성
- [ ] PDF 파일이 Order Files에 자동 첨부
- [ ] Slack 채널이 Order Number로 자동 생성
- [ ] Order의 Slack 관련 필드가 자동 업데이트
- [ ] 초기 환영 메시지가 Slack 채널에 발송
- [ ] 에러 발생 시 적절한 로깅 및 알림

### 📊 모니터링 포인트
- PDF 생성 성공률
- Slack 채널 생성 성공률  
- API 호출 응답 시간
- 에러 발생 빈도 및 원인

---

## 💡 추가 개선 아이디어

### 🔄 향후 확장 가능성
1. **고객 셀프서비스 포털**: Customer Community에서 PDF 직접 다운로드
2. **실시간 알림**: Slack 채널로 납부 상태 실시간 업데이트
3. **AI 챗봇**: Slack 채널 내 고객 문의 자동 응답
4. **모바일 앱 연동**: 모바일에서 PDF 자동 다운로드

이 설계를 바탕으로 단계별 구현을 진행하겠습니다! 🚀
