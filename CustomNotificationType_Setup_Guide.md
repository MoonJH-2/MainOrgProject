# 📱 CustomNotificationType 설정 완전 가이드

## 🎯 목적
Order 생성, Slack 채널 생성, 연체 알림을 위한 Salesforce 상단 벨 아이콘 알림 설정

---

## 📋 설정해야 할 CustomNotificationType

### 1️⃣ **Sales_Order_Notification** (필수)
- **용도**: Order 생성, Slack 채널 생성, 연체 알림
- **사용 클래스**: `OrderNotificationService.cls`
- **트리거 시점**: Order INSERT/UPDATE, PaymentStatus 연체 상태 변경

### 2️⃣ **Payment_Notification** (선택사항)
- **용도**: 납부 예정/연체 상세 알림
- **사용 클래스**: `PaymentNotificationService.cls`
- **트리거 시점**: 납부 예정일 3일 전, 연체 발생 시

---

## 🔧 Setup 단계별 가이드

### **Step 1: Setup 접근**
1. Salesforce 우상단 **⚙️ Setup** 클릭
2. Quick Find 검색창에 **"Custom Notifications"** 입력
3. **"Custom Notification Types"** 선택

### **Step 2: Sales_Order_Notification 생성**
1. **"New"** 버튼 클릭
2. 다음 정보 입력:
   ```
   Custom Notification Type Name: Sales Order Notification
   API Name: Sales_Order_Notification
   Description: Order 생성, Slack 채널 생성, 연체 알림을 위한 Sales 앱 알림
   ```
3. **Notification Channel** 설정:
   - ✅ **Desktop** 체크
   - ✅ **Mobile** 체크
4. **"Save"** 클릭

### **Step 3: Payment_Notification 생성 (선택사항)**
1. **"New"** 버튼 클릭
2. 다음 정보 입력:
   ```
   Custom Notification Type Name: Payment Notification
   API Name: Payment_Notification
   Description: 납부 예정 및 연체 알림을 위한 상세 알림
   ```
3. **Notification Channel** 설정:
   - ✅ **Desktop** 체크
   - ✅ **Mobile** 체크
4. **"Save"** 클릭

---

## ✅ 설정 완료 확인

### **방법 1: Setup에서 확인**
1. Setup > Custom Notification Types 페이지에서
2. 생성된 알림 타입들이 표시되는지 확인:
   - Sales Order Notification (Sales_Order_Notification)
   - Payment Notification (Payment_Notification)

### **방법 2: Apex 스크립트로 확인**
```bash
sfdx force:apex:execute -f scripts/apex/check_notification_types.apex
```

---

## 🧪 테스트 방법

### **1. 즉시 테스트**
설정 완료 후 다음 스크립트 실행:
```bash
sfdx force:apex:execute -f scripts/apex/check_notification_types.apex
```
→ 테스트 알림이 상단 벨 아이콘에 표시됨

### **2. Order 생성 알림 테스트**
```bash
sfdx force:apex:execute -f scripts/apex/review_order_149_notifications.apex
```

### **3. 실제 연체 알림 테스트**
PaymentStatus를 연체 상태로 변경:
```apex
PaymentStatus__c payment = [SELECT Id FROM PaymentStatus__c WHERE Order__r.OrderNumber = '00000149' AND InstallmentNumber__c = 1 LIMIT 1];
payment.Status__c = '연체';
update payment;
```

---

## 💡 중요 포인트

### **알림 수신자**
- **Order Owner**: 주문 소유자
- **Manager**: 현재 사용자 및 Order Owner의 매니저
- **시스템 관리자**: 연체 알림 시 추가 포함

### **알림 표시 위치**
- **Desktop**: Salesforce 상단 🔔 벨 아이콘
- **Mobile**: Salesforce Mobile 앱 푸시 알림

### **브라우저 설정**
- 브라우저에서 Salesforce 알림 권한 허용 필요
- Chrome: 주소창 왼쪽 🔒 아이콘 > 알림 > 허용

---

## 🔍 문제 해결

### **알림이 안 보이는 경우**
1. **CustomNotificationType 확인**: API Name 정확성 체크
2. **브라우저 권한**: 알림 권한 허용 확인
3. **사용자 권한**: Profile에서 Custom Notification 접근 권한 확인
4. **Lightning Experience**: Classic이 아닌 Lightning에서 사용

### **오류 메시지 확인**
```bash
# Debug Log에서 오류 확인
sfdx force:apex:execute -f scripts/apex/check_notification_types.apex
```

---

## 📱 완료 후 기대 효과

### **Order 생성 시**
```
🎉 새 주문 생성
김캐디 (Kimcaddie) - Order 00000149 (₩12,720,000)
```

### **연체 발생 시**
```
🚨 납부 연체 발생
김캐디 (Kimcaddie) - 1차 납부 연체 (1일)
```

### **Slack 채널 생성 시**
```
📢 Slack 채널 생성 완료
Order 00000149 Salesforce 연동 채널 생성 (#00000149)
```

---

## ✨ 추가 설정 (선택사항)

### **이메일 알림 추가**
OrderNotificationService에서 이메일 알림도 지원:
```apex
OrderNotificationService.sendEmailNotificationForOrder(order, 'Order_Created');
```

### **Custom Settings 활용**
알림 발송 주기나 수신자 그룹을 Custom Settings로 관리 가능

---

이 가이드를 따라 설정하면 Order 00000149의 모든 알림 시스템이 완벽하게 동작할 것입니다!
