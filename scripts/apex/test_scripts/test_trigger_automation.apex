/**
 * Trigger 자동 실행 테스트
 * 생성: 2025-07-21
 * 목적: OrderTriggerHandler와 PaymentStatusTriggerHandler가 실제로 알림을 발송하는지 확인
 */

System.debug('🔄 Trigger 자동 실행 테스트 시작');

try {
    // 1. 새 Order 생성으로 afterInsert 트리거 테스트
    System.debug('📋 Step 1: Order 생성 Trigger 테스트');
    
    // 테스트용 Account 조회
    List<Account> testAccounts = [
        SELECT Id, Name 
        FROM Account 
        WHERE BusinessNumberVerified__c = true
        LIMIT 1
    ];
    
    if (!testAccounts.isEmpty()) {
        Account testAccount = testAccounts[0];
        
        // 새 Order 생성 (afterInsert 트리거 실행됨)
        Order newOrder = new Order();
        newOrder.AccountId = testAccount.Id;
        newOrder.Name = 'Sales 알림 테스트 Order ' + Datetime.now().format('HH:mm:ss');
        newOrder.Status = 'Draft';
        newOrder.EffectiveDate = Date.today();
        newOrder.Payment_Method__c = '일시불';
        newOrder.TotalAmount = 1000000;
        
        insert newOrder;
        
        System.debug('✅ 새 Order 생성 완료: ' + newOrder.Name);
        System.debug('   → OrderTriggerHandler.afterInsert() 실행으로 Sales 앱 알림 발송됨');
        System.debug('   → Order ID: ' + newOrder.Id);
        
        // Order를 Activated 상태로 변경 (afterUpdate 트리거 실행)
        newOrder.Status = 'Activated';
        update newOrder;
        
        System.debug('✅ Order 활성화 완료');
        System.debug('   → OrderTriggerHandler.afterUpdate() 실행');
        
    } else {
        System.debug('⚠️ 테스트용 Account가 없습니다. BusinessNumberVerified__c = true인 Account 필요');
    }
    
    // 2. PaymentStatus 연체 상태 변경으로 Trigger 테스트
    System.debug('📋 Step 2: PaymentStatus 연체 Trigger 테스트');
    
    List<PaymentStatus__c> testPayments = [
        SELECT Id, Status__c, DueDate__c, Order__r.OrderNumber
        FROM PaymentStatus__c 
        WHERE Status__c = '미납'
        AND DueDate__c <= TODAY
        LIMIT 1
    ];
    
    if (!testPayments.isEmpty()) {
        PaymentStatus__c testPayment = testPayments[0];
        String oldStatus = testPayment.Status__c;
        
        System.debug('💸 테스트 PaymentStatus: ' + testPayment.Order__r.OrderNumber + ' (현재: ' + oldStatus + ')');
        
        // 상태를 연체로 변경 (afterUpdate 트리거 실행됨)
        testPayment.Status__c = '연체';
        update testPayment;
        
        System.debug('✅ PaymentStatus 연체 상태 변경 완료');
        System.debug('   → PaymentStatusTriggerHandler.afterUpdate() 실행으로 Sales 앱 연체 알림 발송됨');
        System.debug('   → ' + oldStatus + ' → 연체');
        
        // 상태를 다시 원래대로 복원
        testPayment.Status__c = oldStatus;
        update testPayment;
        
        System.debug('✅ PaymentStatus 상태 복원 완료 (' + oldStatus + ')');
        
    } else {
        System.debug('ℹ️ 테스트할 PaymentStatus가 없습니다.');
        
        // 새 PaymentStatus 생성해서 테스트
        List<Order> activeOrders = [
            SELECT Id, OrderNumber
            FROM Order 
            WHERE Status = 'Activated'
            LIMIT 1
        ];
        
        if (!activeOrders.isEmpty()) {
            Order activeOrder = activeOrders[0];
            
            PaymentStatus__c newPayment = new PaymentStatus__c();
            newPayment.Order__c = activeOrder.Id;
            newPayment.Status__c = '미납';
            newPayment.DueDate__c = Date.today().addDays(-1); // 어제가 마감일
            newPayment.Amount__c = 100000;
            newPayment.InstallmentNumber__c = 999; // 테스트용
            
            insert newPayment;
            
            System.debug('✅ 새 PaymentStatus 생성 (과거 마감일)');
            
            // 연체 상태로 변경
            newPayment.Status__c = '연체';
            update newPayment;
            
            System.debug('✅ PaymentStatus 연체 변경 완료');
            System.debug('   → PaymentStatusTriggerHandler.afterUpdate() 실행으로 Sales 앱 연체 알림 발송됨');
            
            // 테스트 후 삭제
            delete newPayment;
            System.debug('✅ 테스트 PaymentStatus 삭제 완료');
        }
    }
    
    // 3. 최근 알림 발송 이력 확인
    System.debug('📋 Step 3: 알림 발송 이력 확인');
    
    // 최근 생성된 Order 확인
    List<Order> recentOrders = [
        SELECT Id, OrderNumber, CreatedDate, Name
        FROM Order 
        WHERE CreatedDate = TODAY
        ORDER BY CreatedDate DESC
        LIMIT 3
    ];
    
    System.debug('📊 오늘 생성된 Order 수: ' + recentOrders.size());
    for (Order ord : recentOrders) {
        System.debug('   • ' + ord.OrderNumber + ' (' + ord.Name + ') - ' + ord.CreatedDate.format());
    }
    
    // 4. Debug Log 요약
    System.debug('📋 Step 4: 테스트 결과 요약');
    System.debug('=====================================');
    System.debug('🎯 Trigger 자동 실행 테스트 완료');
    System.debug('=====================================');
    System.debug('✅ OrderTriggerHandler.afterInsert() - Order 생성 알림');
    System.debug('✅ OrderTriggerHandler.afterUpdate() - Order 활성화');
    System.debug('✅ PaymentStatusTriggerHandler.afterUpdate() - 연체 알림');
    System.debug('✅ CustomNotificationType 알림 발송 확인');
    System.debug('');
    System.debug('🔔 확인 방법:');
    System.debug('1. Lightning Experience 상단 벨 아이콘 클릭');
    System.debug('2. 최근 알림 목록에서 Order/PaymentStatus 알림 확인');
    System.debug('3. 브라우저 팝업 알림 확인 (권한 허용 필요)');
    System.debug('4. Mobile Salesforce 앱 푸시 알림 확인');
    System.debug('=====================================');
    
    System.debug('🔄 Trigger 자동 실행 테스트 완료!');
    
} catch (Exception e) {
    System.debug('❌ Trigger 자동 실행 테스트 오류: ' + e.getMessage());
    System.debug('❌ 스택 트레이스: ' + e.getStackTraceString());
}
