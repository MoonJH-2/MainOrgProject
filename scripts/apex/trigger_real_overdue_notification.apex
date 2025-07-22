// Order 00000149의 1차 납부를 연체로 업데이트하여 실제 Sales 앱 알림 발송
System.debug('⚡ =====실시간 연체 알림 테스트=====');

try {
    // 1. Order 00000149의 PaymentStatus 조회
    List<PaymentStatus__c> payments = [
        SELECT Id, InstallmentNumber__c, Amount__c, DueDate__c, Status__c,
               Order__c, Order__r.Account.Name, Order__r.OrderNumber
        FROM PaymentStatus__c 
        WHERE Order__r.OrderNumber = '00000149'
        AND InstallmentNumber__c = 1
        LIMIT 1
    ];
    
    if (payments.isEmpty()) {
        System.debug('❌ Order 00000149의 1차 PaymentStatus를 찾을 수 없습니다.');
        return;
    }
    
    PaymentStatus__c payment = payments[0];
    String oldStatus = payment.Status__c;
    
    System.debug('📋 현재 상태:');
    System.debug('   Order: ' + payment.Order__r.OrderNumber);
    System.debug('   회차: ' + payment.InstallmentNumber__c + '차');
    System.debug('   금액: ₩' + payment.Amount__c.format());
    System.debug('   납기일: ' + payment.DueDate__c.format());
    System.debug('   현재 상태: ' + oldStatus);
    
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
    
    // 3. 상태를 연체로 업데이트 (실제 트리거 발동)
    System.debug('');
    System.debug('🚨 PaymentStatus를 연체로 업데이트 중...');
    
    payment.Status__c = '연체';
    
    // 실제 업데이트 실행 - 이때 PaymentStatusTriggerHandler가 작동함
    update payment;
    
    System.debug('✅ PaymentStatus 업데이트 완료: ' + oldStatus + ' → 연체');
    System.debug('   📡 PaymentStatusTriggerHandler.afterUpdate() 트리거됨');
    System.debug('   🔔 OrderNotificationService.notifyOverduePayments() 호출됨');
    
    // 4. 업데이트된 상태 확인
    PaymentStatus__c updatedPayment = [
        SELECT Id, Status__c, LastModifiedDate, LastModifiedBy.Name
        FROM PaymentStatus__c 
        WHERE Id = :payment.Id
    ];
    
    System.debug('');
    System.debug('📊 업데이트 결과:');
    System.debug('   새 상태: ' + updatedPayment.Status__c);
    System.debug('   수정일시: ' + updatedPayment.LastModifiedDate);
    System.debug('   수정자: ' + updatedPayment.LastModifiedBy.Name);
    
    // 5. 연체 일수 계산 및 표시
    Integer overdueDays = payment.DueDate__c.daysBetween(Date.today());
    System.debug('   연체 일수: ' + overdueDays + '일');
    
    // 6. 수신자 확인
    System.debug('');
    System.debug('👥 알림 수신자:');
    
    User currentUser = [
        SELECT Id, Name, Email, ManagerId, Manager.Name
        FROM User 
        WHERE Id = :UserInfo.getUserId()
    ];
    
    Order order = [
        SELECT Id, OwnerId, Owner.Name, Owner.Email
        FROM Order 
        WHERE Id = :payment.Order__c
    ];
    
    System.debug('   📧 현재 사용자: ' + currentUser.Name);
    System.debug('   👤 Order Owner: ' + order.Owner.Name);
    if (currentUser.ManagerId != null) {
        System.debug('   👔 Manager: ' + currentUser.Manager.Name);
    }
    
    // 7. 즉시 확인 방법 안내
    System.debug('');
    System.debug('🔔 즉시 확인 방법:');
    System.debug('1. Salesforce 상단의 🔔 벨 아이콘 클릭');
    System.debug('2. "🚨 납부 연체 발생" 알림이 표시되는지 확인');
    System.debug('3. 알림 내용: "' + payment.Order__r.Account.Name + ' - 1차 납부 연체 (' + overdueDays + '일)"');
    System.debug('4. 알림 클릭 시 Order 레코드로 이동하는지 확인');
    
    System.debug('');
    System.debug('📱 Mobile 앱에서도 확인:');
    System.debug('1. Mobile Salesforce 앱에서 푸시 알림 수신 확인');
    System.debug('2. 알림 터치 시 Order 상세 페이지로 이동 확인');
    
    // 8. 추가 테스트 옵션
    System.debug('');
    System.debug('🧪 추가 테스트 옵션:');
    System.debug('1. 다른 회차도 연체로 변경하여 추가 알림 테스트');
    System.debug('2. 연체 상태를 "완납"으로 변경하여 알림 중단 테스트');
    System.debug('3. 새 Order 생성하여 생성 알림 테스트');
    
    // 9. 롤백 안내 (필요시)
    System.debug('');
    System.debug('🔄 상태 롤백 (필요시):');
    System.debug('   Status__c를 다시 "미납"으로 변경하면 연체 상태 해제');
    
} catch (DmlException dmlEx) {
    System.debug('❌ PaymentStatus 업데이트 실패:');
    for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
        System.debug('   • ' + dmlEx.getDmlMessage(i));
        System.debug('   • 필드: ' + dmlEx.getDmlFieldNames(i));
    }
} catch (Exception e) {
    System.debug('❌ 실시간 테스트 중 오류: ' + e.getMessage());
    System.debug('   타입: ' + e.getTypeName());
    System.debug('   라인: ' + e.getLineNumber());
}

System.debug('');
System.debug('🎯 =====실시간 연체 알림 테스트 완료=====');
System.debug('📢 지금 바로 상단 벨 아이콘을 확인해보세요!');
