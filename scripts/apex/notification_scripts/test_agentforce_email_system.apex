/**
 * @description Agentforce Email 시스템 테스트 스크립트
 * @author AI Assistant
 * @created 2025-07-24
 */

System.debug('📧 =====Agentforce Email 시스템 테스트=====');

System.debug('');
System.debug('🎯 테스트 대상');
System.debug('1. Order 관련 이메일 생성');
System.debug('2. Payment 알림 이메일 생성');
System.debug('3. Asset 갱신 이메일 생성');
System.debug('4. 이메일 수정 기능');

System.debug('');
System.debug('📋 1. Order Email 테스트');

try {
    // 테스트용 Order 조회
    List<Order> testOrders = [
        SELECT Id, OrderNumber, Status, Account.Name, Owner.Name
        FROM Order 
        WHERE OrderNumber IN ('00000153', '00000151', '00000138')
        LIMIT 3
    ];
    
    if (!testOrders.isEmpty()) {
        Order testOrder = testOrders[0];
        System.debug('✅ 테스트 Order: ' + testOrder.OrderNumber + ' (' + testOrder.Account.Name + ')');
        
        // Order Email Action 호출 시뮬레이션
        AgentforceEmailActions.OrderEmailRequest request = new AgentforceEmailActions.OrderEmailRequest();
        request.orderId = testOrder.Id;
        request.emailType = 'Order_Confirmation';
        
        List<AgentforceEmailActions.OrderEmailRequest> requests = new List<AgentforceEmailActions.OrderEmailRequest>{request};
        List<AgentforceEmailActions.EmailDraftResult> results = AgentforceEmailActions.draftOrderEmail(requests);
        
        if (!results.isEmpty() && results[0].success) {
            System.debug('📧 생성된 이메일 제목: ' + results[0].emailSubject);
            System.debug('📝 이메일 내용 (일부): ' + results[0].emailBody.substring(0, Math.min(100, results[0].emailBody.length())) + '...');
        } else {
            System.debug('❌ Order 이메일 생성 실패: ' + (results.isEmpty() ? 'No results' : results[0].errorMessage));
        }
    } else {
        System.debug('⚠️ 테스트용 Order가 없습니다.');
    }
    
} catch (Exception e) {
    System.debug('❌ Order Email 테스트 오류: ' + e.getMessage());
}

System.debug('');
System.debug('💰 2. Payment Email 테스트');

try {
    // PaymentStatus 조회 시도
    List<SObject> paymentRecords = Database.query(
        'SELECT Id, Name, Order__c, Order__r.OrderNumber, Status__c ' +
        'FROM PaymentStatus__c LIMIT 1'
    );
    
    if (!paymentRecords.isEmpty()) {
        SObject payment = paymentRecords[0];
        System.debug('✅ 테스트 Payment: ' + payment.get('Name') + ' (Order: ' + payment.get('Order__r.OrderNumber') + ')');
        
        // Payment Email Action 호출 시뮬레이션
        AgentforceEmailActions.PaymentEmailRequest request = new AgentforceEmailActions.PaymentEmailRequest();
        request.paymentId = (String)payment.get('Id');
        request.emailType = 'Payment_Reminder';
        
        List<AgentforceEmailActions.PaymentEmailRequest> requests = new List<AgentforceEmailActions.PaymentEmailRequest>{request};
        List<AgentforceEmailActions.EmailDraftResult> results = AgentforceEmailActions.draftPaymentEmail(requests);
        
        if (!results.isEmpty() && results[0].success) {
            System.debug('📧 생성된 이메일 제목: ' + results[0].emailSubject);
            System.debug('📝 이메일 내용 (일부): ' + results[0].emailBody.substring(0, Math.min(100, results[0].emailBody.length())) + '...');
        } else {
            System.debug('❌ Payment 이메일 생성 실패: ' + (results.isEmpty() ? 'No results' : results[0].errorMessage));
        }
    } else {
        System.debug('⚠️ PaymentStatus__c 레코드가 없습니다.');
    }
    
} catch (Exception e) {
    System.debug('❌ Payment Email 테스트 오류: ' + e.getMessage());
    System.debug('💡 PaymentStatus__c Custom Object가 필요합니다.');
}

System.debug('');
System.debug('🔄 3. Asset Email 테스트');

try {
    // Asset 조회
    List<Asset> testAssets = [
        SELECT Id, Name, Status, Account.Name, Account.Owner.Name
        FROM Asset 
        WHERE Status = 'Installed'
        LIMIT 1
    ];
    
    if (!testAssets.isEmpty()) {
        Asset testAsset = testAssets[0];
        System.debug('✅ 테스트 Asset: ' + testAsset.Name + ' (' + testAsset.Account.Name + ')');
        
        // Asset Email Action 호출 시뮬레이션
        AgentforceEmailActions.AssetEmailRequest request = new AgentforceEmailActions.AssetEmailRequest();
        request.assetId = testAsset.Id;
        request.emailType = 'Asset_Renewal_Notice';
        
        List<AgentforceEmailActions.AssetEmailRequest> requests = new List<AgentforceEmailActions.AssetEmailRequest>{request};
        List<AgentforceEmailActions.EmailDraftResult> results = AgentforceEmailActions.draftAssetRenewalEmail(requests);
        
        if (!results.isEmpty() && results[0].success) {
            System.debug('📧 생성된 이메일 제목: ' + results[0].emailSubject);
            System.debug('📝 이메일 내용 (일부): ' + results[0].emailBody.substring(0, Math.min(100, results[0].emailBody.length())) + '...');
        } else {
            System.debug('❌ Asset 이메일 생성 실패: ' + (results.isEmpty() ? 'No results' : results[0].errorMessage));
        }
    } else {
        System.debug('⚠️ 설치된 Asset이 없습니다.');
    }
    
} catch (Exception e) {
    System.debug('❌ Asset Email 테스트 오류: ' + e.getMessage());
}

System.debug('');
System.debug('✏️ 4. Email 수정 기능 테스트');

try {
    // 이메일 수정 테스트
    AgentforceEmailActions.EmailRevisionRequest request = new AgentforceEmailActions.EmailRevisionRequest();
    request.originalSubject = '[알림] Order 00000153 - 테스트 주문';
    request.originalBody = '안녕하세요, 고객님\n\n주문 관련 안내드립니다.\n\n감사합니다.';
    request.revisionInstructions = 'formal';
    request.recipientEmail = 'test@example.com';
    
    List<AgentforceEmailActions.EmailRevisionRequest> requests = new List<AgentforceEmailActions.EmailRevisionRequest>{request};
    List<AgentforceEmailActions.EmailDraftResult> results = AgentforceEmailActions.reviseEmailDraft(requests);
    
    if (!results.isEmpty() && results[0].success) {
        System.debug('✅ 수정된 이메일 제목: ' + results[0].emailSubject);
        System.debug('📝 수정된 내용: ' + results[0].emailBody);
        System.debug('📋 수정 내역: ' + results[0].revisionNotes);
    } else {
        System.debug('❌ 이메일 수정 실패: ' + (results.isEmpty() ? 'No results' : results[0].errorMessage));
    }
    
} catch (Exception e) {
    System.debug('❌ Email 수정 테스트 오류: ' + e.getMessage());
}

System.debug('');
System.debug('🎯 Agentforce 연동 테스트 시나리오');
System.debug('Agent Conversation에서 테스트할 질문들:');
System.debug('');
System.debug('1. "Order 00000153에 대한 확인 이메일을 작성해줘"');
System.debug('   → Draft Order Email Action 실행 확인');
System.debug('');
System.debug('2. "Payment 연체 알림 이메일이 필요해"');
System.debug('   → Draft Payment Email Action 실행 확인');
System.debug('');
System.debug('3. "Asset 갱신 안내 이메일을 만들어줘"');
System.debug('   → Draft Asset Renewal Email Action 실행 확인');
System.debug('');
System.debug('4. "위 이메일을 더 공식적으로 수정해줘"');
System.debug('   → Revise Email Draft Action 실행 확인');
System.debug('');
System.debug('5. "이메일을 간단하게 요약해서 다시 작성해줘"');
System.debug('   → Standard "Draft or Revise Email" Action 연동 확인');

System.debug('');
System.debug('📊 다음 단계');
System.debug('1. AgentforceEmailActions 클래스 배포');
System.debug('2. Agentforce Studio에서 Custom Actions 등록');
System.debug('3. Agent Builder에서 Email Communications Topic 생성');
System.debug('4. Conversation Preview에서 실제 테스트');
System.debug('5. 필요시 Email Templates Setup 추가 설정');

System.debug('');
System.debug('✅ Agentforce Email 시스템 테스트 완료!');
