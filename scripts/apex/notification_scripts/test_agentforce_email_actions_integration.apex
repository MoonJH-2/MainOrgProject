/**
 * @description Agentforce 이메일 액션 통합 테스트 스크립트
 * @author AI Assistant
 * @created 2025-07-24
 * @usage Developer Console → Execute Anonymous에서 실행
 */

// ========================================
// Agentforce 이메일 액션 통합 테스트
// ========================================

System.debug('=== Agentforce 이메일 액션 통합 테스트 시작 ===');

// 테스트용 데이터 준비 (실제 데이터로 변경 필요)
String testOrderId = '8013m00000EXAMPLE';  // 실제 Order ID로 변경
String testPaymentId = 'a0Y3m00000EXAMPLE'; // 실제 PaymentStatus__c ID로 변경  
String testAssetId = '02i3m00000EXAMPLE';   // 실제 Asset ID로 변경

// ========================================
// 테스트 1: Order 이메일 액션
// ========================================
System.debug('\n--- 테스트 1: Order 확인 이메일 ---');
try {
    AgentforceOrderEmailAction.EmailRequest orderReq = new AgentforceOrderEmailAction.EmailRequest();
    orderReq.orderId = testOrderId;
    orderReq.emailType = 'Order_Confirmation';
    
    List<AgentforceOrderEmailAction.EmailRequest> orderRequests = 
        new List<AgentforceOrderEmailAction.EmailRequest>{orderReq};
    
    List<AgentforceOrderEmailAction.EmailDraftResult> orderResults = 
        AgentforceOrderEmailAction.draftOrderEmail(orderRequests);
    
    for(AgentforceOrderEmailAction.EmailDraftResult result : orderResults) {
        if(result.success) {
            System.debug('✅ Order 이메일 생성 성공');
            System.debug('제목: ' + result.emailSubject);
            System.debug('수신자: ' + result.recipientEmail);
            System.debug('주문번호: ' + result.orderNumber);
        } else {
            System.debug('❌ Order 이메일 생성 실패: ' + result.errorMessage);
        }
    }
} catch(Exception e) {
    System.debug('❌ Order 이메일 테스트 오류: ' + e.getMessage());
}

// ========================================
// 테스트 2: Payment 이메일 액션
// ========================================
System.debug('\n--- 테스트 2: Payment 알림 이메일 ---');
try {
    AgentforcePaymentEmailAction.PaymentEmailRequest paymentReq = 
        new AgentforcePaymentEmailAction.PaymentEmailRequest();
    paymentReq.paymentId = testPaymentId;
    paymentReq.emailType = 'Payment_Reminder';
    
    List<AgentforcePaymentEmailAction.PaymentEmailRequest> paymentRequests = 
        new List<AgentforcePaymentEmailAction.PaymentEmailRequest>{paymentReq};
    
    List<AgentforcePaymentEmailAction.EmailDraftResult> paymentResults = 
        AgentforcePaymentEmailAction.draftPaymentEmail(paymentRequests);
    
    for(AgentforcePaymentEmailAction.EmailDraftResult result : paymentResults) {
        if(result.success) {
            System.debug('✅ Payment 이메일 생성 성공');
            System.debug('제목: ' + result.emailSubject);
            System.debug('타입: ' + result.emailType);
            System.debug('주문번호: ' + result.orderNumber);
        } else {
            System.debug('❌ Payment 이메일 생성 실패: ' + result.errorMessage);
        }
    }
} catch(Exception e) {
    System.debug('❌ Payment 이메일 테스트 오류: ' + e.getMessage());
}

// ========================================  
// 테스트 3: Asset 이메일 액션
// ========================================
System.debug('\n--- 테스트 3: Asset 갱신 이메일 ---');
try {
    AgentforceAssetEmailAction.AssetEmailRequest assetReq = 
        new AgentforceAssetEmailAction.AssetEmailRequest();
    assetReq.assetId = testAssetId;
    assetReq.emailType = 'Renewal_Reminder';
    
    List<AgentforceAssetEmailAction.AssetEmailRequest> assetRequests = 
        new List<AgentforceAssetEmailAction.AssetEmailRequest>{assetReq};
    
    List<AgentforceAssetEmailAction.EmailDraftResult> assetResults = 
        AgentforceAssetEmailAction.draftAssetRenewalEmail(assetRequests);
    
    for(AgentforceAssetEmailAction.EmailDraftResult result : assetResults) {
        if(result.success) {
            System.debug('✅ Asset 이메일 생성 성공');
            System.debug('제목: ' + result.emailSubject);
            System.debug('Asset명: ' + result.assetName);
            System.debug('타입: ' + result.emailType);
        } else {
            System.debug('❌ Asset 이메일 생성 실패: ' + result.errorMessage);
        }
    }
} catch(Exception e) {
    System.debug('❌ Asset 이메일 테스트 오류: ' + e.getMessage());
}

// ========================================
// 테스트 4: 이메일 수정 액션
// ========================================
System.debug('\n--- 테스트 4: 이메일 수정 액션 ---');
try {
    AgentforceEmailRevisionAction.EmailRevisionRequest revisionReq = 
        new AgentforceEmailRevisionAction.EmailRevisionRequest();
    revisionReq.originalSubject = '[안내] Order 00000153 - 주문 확인 안내';
    revisionReq.originalBody = '안녕하세요, 고객님\n\n주문이 접수되었습니다.\n\n감사합니다.';
    revisionReq.revisionType = 'Make_Urgent';
    revisionReq.revisionInstructions = '빠른 확인이 필요한 주문입니다';
    
    List<AgentforceEmailRevisionAction.EmailRevisionRequest> revisionRequests = 
        new List<AgentforceEmailRevisionAction.EmailRevisionRequest>{revisionReq};
    
    List<AgentforceEmailRevisionAction.EmailRevisionResult> revisionResults = 
        AgentforceEmailRevisionAction.reviseEmailDraft(revisionRequests);
    
    for(AgentforceEmailRevisionAction.EmailRevisionResult result : revisionResults) {
        if(result.success) {
            System.debug('✅ 이메일 수정 성공');
            System.debug('수정 타입: ' + result.revisionType);
            System.debug('원본 제목: ' + result.originalSubject);
            System.debug('수정된 제목: ' + result.revisedSubject);
        } else {
            System.debug('❌ 이메일 수정 실패: ' + result.errorMessage);
        }
    }
} catch(Exception e) {
    System.debug('❌ 이메일 수정 테스트 오류: ' + e.getMessage());
}

// ========================================
// 테스트 5: 실제 데이터 조회 테스트
// ========================================
System.debug('\n--- 테스트 5: 실제 데이터 존재 확인 ---');

// Order 데이터 확인
try {
    List<Order> orders = [SELECT Id, OrderNumber, Account.Name FROM Order LIMIT 3];
    System.debug('📋 사용 가능한 Order 데이터:');
    for(Order ord : orders) {
        System.debug('  Order ID: ' + ord.Id + ', 주문번호: ' + ord.OrderNumber + ', 고객: ' + ord.Account.Name);
    }
} catch(Exception e) {
    System.debug('❌ Order 데이터 조회 오류: ' + e.getMessage());
}

// PaymentStatus 데이터 확인  
try {
    List<SObject> payments = Database.query('SELECT Id, Name, Order__r.OrderNumber FROM PaymentStatus__c LIMIT 3');
    System.debug('💰 사용 가능한 PaymentStatus 데이터:');
    for(SObject payment : payments) {
        System.debug('  Payment ID: ' + payment.Id + ', 이름: ' + payment.get('Name') + 
                    ', 주문: ' + payment.get('Order__r.OrderNumber'));
    }
} catch(Exception e) {
    System.debug('❌ PaymentStatus 데이터 조회 오류: ' + e.getMessage());
}

// Asset 데이터 확인
try {
    List<Asset> assets = [SELECT Id, Name, Account.Name, Product2.Name FROM Asset LIMIT 3];
    System.debug('🚗 사용 가능한 Asset 데이터:');
    for(Asset asset : assets) {
        System.debug('  Asset ID: ' + asset.Id + ', 이름: ' + asset.Name + 
                    ', 고객: ' + asset.Account.Name + ', 제품: ' + asset.Product2.Name);
    }
} catch(Exception e) {
    System.debug('❌ Asset 데이터 조회 오류: ' + e.getMessage());
}

System.debug('\n=== Agentforce 이메일 액션 통합 테스트 완료 ===');

// ========================================
// 다음 단계 안내
// ========================================
System.debug('\n📋 다음 단계:');
System.debug('1. 위 로그에서 실제 ID를 확인하여 테스트 스크립트 상단의 변수 업데이트');
System.debug('2. Setup → Agentforce Studio → Actions에서 커스텀 액션 등록');
System.debug('3. Agent Builder에서 Email Communications 토픽 설정');
System.debug('4. Conversation Preview에서 실제 Agent 테스트');
System.debug('5. 성능 모니터링 및 오류 처리 개선');

/*
========================================
실제 사용 예시 (Agent에서):
========================================

User: "Order 00000153 확인 이메일 작성해줘"
→ Agent가 Draft Order Email 액션 실행

User: "결제 예정일 안내 이메일 만들어줘" 
→ Agent가 Draft Payment Email 액션 실행

User: "위 이메일을 좀 더 정중하게 수정해줘"
→ Agent가 Revise Email Draft 액션 실행

User: "Asset 갱신 시기 안내 이메일 초안 작성"
→ Agent가 Draft Asset Renewal Email 액션 실행

User: "최종 이메일 전송 준비해줘"
→ Agent가 표준 "Draft or Revise Email" 액션 실행
========================================
*/
