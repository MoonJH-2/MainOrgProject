// 새 Order 생성으로 실제 Sales 앱 생성 알림 테스트
System.debug('🎉 =====실제 Order 생성 알림 테스트=====');

try {
    // 1. 테스트용 Account 확인/생성
    List<Account> testAccounts = [
        SELECT Id, Name 
        FROM Account 
        WHERE Name = 'Test Notification Account'
        LIMIT 1
    ];
    
    Account testAccount;
    if (testAccounts.isEmpty()) {
        // 테스트용 Account 생성
        testAccount = new Account();
        testAccount.Name = 'Test Notification Account';
        testAccount.Type = 'Customer';
        insert testAccount;
        System.debug('✅ 테스트용 Account 생성: ' + testAccount.Name);
    } else {
        testAccount = testAccounts[0];
        System.debug('✅ 기존 테스트용 Account 사용: ' + testAccount.Name);
    }
    
    // 2. CustomNotificationType 설정 확인
    List<CustomNotificationType> salesTypes = [
        SELECT Id FROM CustomNotificationType
        WHERE DeveloperName = 'Sales_Order_Notification'
        LIMIT 1
    ];
    
    if (salesTypes.isEmpty()) {
        System.debug('❌ Sales_Order_Notification이 설정되지 않았습니다!');
        System.debug('   Setup에서 CustomNotificationType을 먼저 생성해주세요.');
        return;
    }
    
    System.debug('✅ Sales_Order_Notification 설정 확인됨');
    
    // 3. 표준 Pricebook 조회
    List<Pricebook2> standardPricebooks = [
        SELECT Id, Name 
        FROM Pricebook2 
        WHERE IsStandard = true 
        LIMIT 1
    ];
    
    if (standardPricebooks.isEmpty()) {
        System.debug('❌ Standard Pricebook을 찾을 수 없습니다.');
        return;
    }
    
    // 4. 새 Order 생성 (실제 트리거 발동)
    System.debug('');
    System.debug('📝 새 Order 생성 중...');
    
    Order newOrder = new Order();
    newOrder.AccountId = testAccount.Id;
    newOrder.EffectiveDate = Date.today();
    newOrder.Status = 'Draft';
    newOrder.Pricebook2Id = standardPricebooks[0].Id;
    newOrder.TotalAmount = 5000000; // 5백만원
    newOrder.Payment_Method__c = '분기별';
    
    // 실제 Order 생성 - 이때 OrderTriggerHandler가 작동함
    insert newOrder;
    
    System.debug('✅ 새 Order 생성 완료:');
    System.debug('   Order ID: ' + newOrder.Id);
    System.debug('   📡 OrderTriggerHandler.afterInsert() 트리거됨');
    System.debug('   🔔 OrderNotificationService.notifyOrderCreated() 호출됨');
    
    // 5. 생성된 Order 정보 다시 조회
    Order createdOrder = [
        SELECT Id, OrderNumber, Status, TotalAmount, Account.Name,
               Owner.Name, Owner.Email, CreatedDate, CreatedBy.Name
        FROM Order 
        WHERE Id = :newOrder.Id
    ];
    
    System.debug('');
    System.debug('📋 생성된 Order 정보:');
    System.debug('   Order Number: ' + createdOrder.OrderNumber);
    System.debug('   Status: ' + createdOrder.Status);
    System.debug('   Account: ' + createdOrder.Account.Name);
    System.debug('   Total Amount: ₩' + createdOrder.TotalAmount.format());
    System.debug('   Owner: ' + createdOrder.Owner.Name);
    System.debug('   Created: ' + createdOrder.CreatedDate);
    System.debug('   Created By: ' + createdOrder.CreatedBy.Name);
    
    // 6. Order를 Activated 상태로 변경 (추가 트리거 테스트)
    System.debug('');
    System.debug('⚡ Order를 Activated 상태로 변경 중...');
    
    createdOrder.Status = 'Activated';
    update createdOrder;
    
    System.debug('✅ Order 활성화 완료');
    System.debug('   📡 OrderTriggerHandler.afterUpdate() 트리거됨');
    
    // 7. PaymentStatus 자동 생성 확인
    List<PaymentStatus__c> generatedPayments = [
        SELECT Id, InstallmentNumber__c, Amount__c, DueDate__c, Status__c
        FROM PaymentStatus__c 
        WHERE Order__c = :createdOrder.Id
        ORDER BY InstallmentNumber__c ASC
    ];
    
    System.debug('');
    System.debug('💰 자동 생성된 PaymentStatus: ' + generatedPayments.size() + '개');
    for (PaymentStatus__c payment : generatedPayments) {
        System.debug('   ' + payment.InstallmentNumber__c + '차: ₩' + 
                    payment.Amount__c.format() + ' (due: ' + payment.DueDate__c.format() + ')');
    }
    
    // 8. 수신자 정보 확인
    System.debug('');
    System.debug('👥 알림 수신자:');
    
    User currentUser = [
        SELECT Id, Name, Email, ManagerId, Manager.Name
        FROM User 
        WHERE Id = :UserInfo.getUserId()
    ];
    
    System.debug('   📧 현재 사용자 (Order 생성자): ' + currentUser.Name);
    System.debug('   👤 Order Owner: ' + createdOrder.Owner.Name);
    if (currentUser.ManagerId != null) {
        System.debug('   👔 Manager: ' + currentUser.Manager.Name);
    }
    
    // 9. 즉시 확인 방법 안내
    System.debug('');
    System.debug('🔔 즉시 확인 방법:');
    System.debug('1. Salesforce 상단의 🔔 벨 아이콘 클릭');
    System.debug('2. "🎉 새 주문 생성" 알림이 표시되는지 확인');
    System.debug('3. 알림 내용: "' + createdOrder.Account.Name + ' - Order ' + createdOrder.OrderNumber + ' (₩' + createdOrder.TotalAmount.format() + ')"');
    System.debug('4. 알림 클릭 시 새로 생성된 Order 레코드로 이동하는지 확인');
    
    System.debug('');
    System.debug('📱 Mobile 앱에서도 확인:');
    System.debug('1. Mobile Salesforce 앱에서 푸시 알림 수신 확인');
    System.debug('2. 알림 터치 시 Order 상세 페이지로 이동 확인');
    
    // 10. 연체 테스트를 위한 준비
    if (!generatedPayments.isEmpty()) {
        System.debug('');
        System.debug('🧪 추가 연체 테스트 준비:');
        System.debug('생성된 PaymentStatus 중 하나를 연체로 변경하여 연체 알림도 테스트할 수 있습니다:');
        System.debug('');
        System.debug('PaymentStatus__c testPayment = [SELECT Id FROM PaymentStatus__c WHERE Order__c = \'' + createdOrder.Id + '\' LIMIT 1];');
        System.debug('testPayment.Status__c = \'연체\';');
        System.debug('update testPayment;');
    }
    
    // 11. 정리 안내
    System.debug('');
    System.debug('🗑️ 테스트 데이터 정리 (필요시):');
    System.debug('생성된 테스트 Order를 삭제하려면:');
    System.debug('delete [SELECT Id FROM Order WHERE Id = \'' + createdOrder.Id + '\'];');
    
} catch (DmlException dmlEx) {
    System.debug('❌ Order 생성 실패:');
    for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
        System.debug('   • ' + dmlEx.getDmlMessage(i));
        System.debug('   • 필드: ' + dmlEx.getDmlFieldNames(i));
    }
} catch (Exception e) {
    System.debug('❌ Order 생성 테스트 중 오류: ' + e.getMessage());
    System.debug('   타입: ' + e.getTypeName());
    System.debug('   라인: ' + e.getLineNumber());
}

System.debug('');
System.debug('🎯 =====Order 생성 알림 테스트 완료=====');
System.debug('📢 지금 바로 상단 벨 아이콘을 확인해보세요!');
