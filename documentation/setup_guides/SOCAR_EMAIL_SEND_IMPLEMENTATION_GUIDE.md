# SOCAR Agentforce 이메일 전송 시스템 구현 가이드

## 📧 이메일 전송 기능 구현 방안

### 🎯 추천 방안: Standard Flow 기반 구현

## 📋 구현 계획

### 1단계: Email Template 생성
```
Setup → Communication Templates → Email Templates
- Developer Name: SOCAR_Order_Confirmation_Template
- Subject: [주문 확인] Order {!Order.OrderNumber} - {!Order.Account.Name}
- Body: Merge Field를 활용한 한국어 템플릿
```

### 2단계: Send Email Flow 생성
```
Setup → Flow → New Flow
- Flow Type: Screen Flow / Autolaunched Flow
- 입력 변수: orderRecord, emailBody, emailSubject
- Send Email 액션으로 실제 이메일 전송
```

### 3단계: Agentforce Action 업데이트
```
기존 Draft Email Action → Send Email Action으로 확장
- 이메일 생성 + 즉시 전송
- 또는 별도 "Send Email" 액션 추가
```

## 🔧 구체적 구현 방법

### Flow 구성요소:
1. **Input Variables**
   - orderId (Text)
   - recipientEmail (Text) 
   - emailSubject (Text)
   - emailBody (Text)

2. **Core Actions**
   - Send Email (Standard Action)
   - Create Email Message Record
   - Update Order with Email Sent Flag

3. **Output Variables**
   - success (Boolean)
   - emailId (Text)
   - errorMessage (Text)

## 📝 Flow 세부 설계

### Send Email Action 설정:
```xml
Action: Send Email
Body: {!emailBody}
Subject: {!emailSubject} 
To Addresses: {!recipientEmail}
Related Record ID: {!orderId}
What ID: {!orderId}
Save as Activity: true
```

### Error Handling:
```
Try-Catch 패턴으로 이메일 전송 실패 시 적절한 오류 메시지 반환
```

## 🚀 Agentforce Integration

### 새로운 Send Email Action 생성:
```apex
@InvocableMethod(label='Send Order Email' description='Order 이메일을 실제로 전송합니다')
public static List<EmailSendResult> sendOrderEmail(List<EmailSendRequest> requests)
```

### 또는 기존 Action 확장:
```
Draft Order Email Action에 "sendImmediately" 파라미터 추가
true면 이메일 생성 후 즉시 전송
false면 기존처럼 초안만 생성
```

## 🎯 사용자 경험 개선

### Conversation Flow:
```
사용자: "Order 00000167 확인 이메일 작성해줘"
Agent: 이메일 초안 생성 → 사용자 확인
사용자: "전송해줘"
Agent: Flow 실행 → 실제 이메일 전송 → 전송 완료 안내
```

### 또는 한 번에:
```
사용자: "Order 00000167 확인 이메일 보내줘"
Agent: 이메일 생성 + 즉시 전송 → 전송 완료 안내
```

## 🔒 보안 및 권한

### 필요한 권한:
- Send Email (User Permission)
- Email Administration (Admin)
- Flow User (User Permission)

### 보안 고려사항:
- 이메일 주소 검증
- 스팸 방지 로직
- 일일 이메일 발송 제한

## 📊 모니터링 및 로깅

### 추적 가능한 정보:
- 이메일 전송 성공/실패 여부
- 전송 시간
- 수신자 정보
- 이메일 열람 여부 (가능한 경우)

## 🎉 최종 결과

### 완성된 기능:
1. ✅ Order 이메일 초안 생성 (완료)
2. 🚧 이메일 실제 전송 (구현 예정)
3. 🚧 Payment 이메일 시스템 (다음 단계)
4. 🚧 Asset 이메일 시스템 (다음 단계)
5. 🚧 이메일 수정/개선 기능 (다음 단계)

이제 **Send Email Flow**를 생성하여 실제 이메일 전송 기능을 구현해보겠습니다!
