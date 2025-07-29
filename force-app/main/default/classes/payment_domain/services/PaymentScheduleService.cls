/**
 * @description PaymentSchedule 생성 서비스 (Order Product 자동 생성 지원)
 * @author JH Moon
 * @last modified on 07-21-2025
 * @last modified by JH Moon
**/
public with sharing class PaymentScheduleService {
    
    public PaymentScheduleService() {

    }

    @future
    public static void createSchedules(Set<Id> orderIds) {
        System.debug('PaymentScheduleService.createSchedules 시작 - Order IDs: ' + orderIds);
        
        // 1. 데이터 준비: 관련 Order 조회
        List<Order> ordersToProcess = [
            SELECT Id, TotalAmount, EffectiveDate, Payment_Method__c
            FROM Order
            WHERE Id IN :orderIds
        ];
        
        System.debug('조회된 Order 목록: ' + ordersToProcess.size() + '개');
        for (Order ord : ordersToProcess) {
            System.debug('Order ID: ' + ord.Id + ', TotalAmount: ' + ord.TotalAmount + ', Payment_Method: ' + ord.Payment_Method__c + ', EffectiveDate: ' + ord.EffectiveDate);
        }

        // 2. 기존 납부 현황 레코드 조회 및 삭제
        List<PaymentStatus__c> existingSchedules = [
            SELECT Id FROM PaymentStatus__c WHERE Order__c IN :orderIds
        ];
        if (!existingSchedules.isEmpty()) {
            System.debug('기존 PaymentStatus 삭제: ' + existingSchedules.size() + '개');
            delete existingSchedules;
        }

        // 3. 신규 레코드 리스트 생성
        List<PaymentStatus__c> newSchedulesToCreate = new List<PaymentStatus__c>();
        Map<String, Integer> frequencyMap = new Map<String, Integer>{
            '월별' => 12, '분기별' => 4, '반기별' => 2, '년별' => 1
        };

        for (Order ord : ordersToProcess) {
            System.debug('Order 처리 중: ' + ord.Id);
            
            if (String.isBlank(ord.Payment_Method__c)) {
                System.debug('Payment_Method__c가 비어있음: ' + ord.Id);
                continue;
            }
            
            if (ord.TotalAmount == null || ord.TotalAmount <= 0) {
                System.debug('TotalAmount가 null이거나 0 이하: ' + ord.Id + ', TotalAmount: ' + ord.TotalAmount);
                continue;
            }

            Integer numberOfInstallments = frequencyMap.get(ord.Payment_Method__c);
            if (numberOfInstallments == null) {
                System.debug('Payment_Method에 대한 매핑을 찾을 수 없음: ' + ord.Payment_Method__c);
                continue;
            }
            
            System.debug('PaymentStatus 생성 시작 - 회차: ' + numberOfInstallments);

            Decimal installmentAmount = ord.TotalAmount.divide(numberOfInstallments, 2, RoundingMode.HALF_UP);
            Integer monthIncrement = 12 / numberOfInstallments;

            for (Integer i = 1; i <= numberOfInstallments; i++) {
                PaymentStatus__c newSchedule = new PaymentStatus__c();
                newSchedule.Order__c = ord.Id;
                newSchedule.Amount__c = installmentAmount;
                newSchedule.Installment_Number__c = i;
                newSchedule.Status__c = '미납';
                newSchedule.PaidDate__c = null; // 초기에는 납부일자 없음
                if (ord.EffectiveDate != null) {
                   newSchedule.DueDate__c = ord.EffectiveDate.addMonths((i - 1) * monthIncrement);
                } else {
                    System.debug('EffectiveDate가 null - 오늘 날짜 기준으로 설정');
                    newSchedule.DueDate__c = Date.today().addMonths((i - 1) * monthIncrement);
                }
                newSchedulesToCreate.add(newSchedule);
            }
        }

        // 4. DML 실행
        if (!newSchedulesToCreate.isEmpty()) {
            System.debug('PaymentStatus 생성 시도: ' + newSchedulesToCreate.size() + '개');
            try {
                insert newSchedulesToCreate;
                System.debug('PaymentStatus 생성 완료: ' + newSchedulesToCreate.size() + '개');
            } catch (Exception e) {
                System.debug('PaymentStatus 생성 실패: ' + e.getMessage());
                throw e;
            }
        } else {
            System.debug('생성할 PaymentStatus가 없습니다.');
        }
    }
    
    /**
     * @description 단일 Order에 대한 PaymentSchedule 생성 (동기식)
     * @param orderId Order ID
     * @param totalAmount 총 금액
     */
    public static void createPaymentSchedule(Id orderId, Decimal totalAmount) {
        try {
            // Order 정보 조회
            Order orderInfo = [
                SELECT Id, Payment_Method__c, EffectiveDate 
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            List<PaymentStatus__c> paymentStatuses = new List<PaymentStatus__c>();
            Map<String, Integer> frequencyMap = new Map<String, Integer>{
                '월별' => 12, '분기별' => 4, '반기별' => 2, '년별' => 1
            };
            
            String paymentMethod = orderInfo.Payment_Method__c;
            if (String.isBlank(paymentMethod)) {
                paymentMethod = '년별'; // 기본값
            }
            
            Integer numberOfInstallments = frequencyMap.get(paymentMethod);
            if (numberOfInstallments == null) {
                numberOfInstallments = 1; // 기본값
            }
            
            Decimal installmentAmount = totalAmount.divide(numberOfInstallments, 2, RoundingMode.HALF_UP);
            Integer monthIncrement = 12 / numberOfInstallments;
            Date baseDate = orderInfo.EffectiveDate != null ? orderInfo.EffectiveDate : Date.today();
            
            for (Integer i = 1; i <= numberOfInstallments; i++) {
                PaymentStatus__c payment = new PaymentStatus__c();
                payment.Order__c = orderId;
                payment.Amount__c = installmentAmount;
                payment.DueDate__c = baseDate.addMonths((i - 1) * monthIncrement);
                payment.Status__c = '미납';
                payment.Installment_Number__c = i;
                payment.PaidDate__c = null;
                
                paymentStatuses.add(payment);
            }
            
            if (!paymentStatuses.isEmpty()) {
                insert paymentStatuses;
                System.debug('PaymentSchedule 생성 완료: ' + paymentStatuses.size() + '개');
            }
            
        } catch (Exception e) {
            System.debug('PaymentSchedule 생성 실패: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description 수동으로 PaymentStatus 생성 (디버깅 및 복구용)
     * @param orderId Order ID
     */
    @AuraEnabled
    public static String createPaymentStatusManually(Id orderId) {
        try {
            System.debug('수동 PaymentStatus 생성 시작 - Order ID: ' + orderId);
            
            // Order 정보 조회
            Order orderInfo = [
                SELECT Id, TotalAmount, EffectiveDate, Payment_Method__c 
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            System.debug('Order 정보: TotalAmount=' + orderInfo.TotalAmount + ', Payment_Method=' + orderInfo.Payment_Method__c);
            
            // 기존 PaymentStatus 삭제
            List<PaymentStatus__c> existingSchedules = [
                SELECT Id FROM PaymentStatus__c WHERE Order__c = :orderId
            ];
            if (!existingSchedules.isEmpty()) {
                delete existingSchedules;
                System.debug('기존 PaymentStatus 삭제: ' + existingSchedules.size() + '개');
            }
            
            // 새로운 PaymentStatus 생성
            List<PaymentStatus__c> newSchedulesToCreate = new List<PaymentStatus__c>();
            Map<String, Integer> frequencyMap = new Map<String, Integer>{
                '월별' => 12, '분기별' => 4, '반기별' => 2, '년별' => 1
            };
            
            if (String.isBlank(orderInfo.Payment_Method__c)) {
                return 'Payment_Method__c가 설정되지 않았습니다.';
            }
            
            if (orderInfo.TotalAmount == null || orderInfo.TotalAmount <= 0) {
                return 'TotalAmount가 설정되지 않았거나 0 이하입니다. TotalAmount: ' + orderInfo.TotalAmount;
            }

            Integer numberOfInstallments = frequencyMap.get(orderInfo.Payment_Method__c);
            if (numberOfInstallments == null) {
                return 'Payment_Method에 대한 매핑을 찾을 수 없습니다: ' + orderInfo.Payment_Method__c;
            }

            Decimal installmentAmount = orderInfo.TotalAmount.divide(numberOfInstallments, 2, RoundingMode.HALF_UP);
            Integer monthIncrement = 12 / numberOfInstallments;
            Date baseDate = orderInfo.EffectiveDate != null ? orderInfo.EffectiveDate : Date.today();

            for (Integer i = 1; i <= numberOfInstallments; i++) {
                PaymentStatus__c newSchedule = new PaymentStatus__c();
                newSchedule.Order__c = orderInfo.Id;
                newSchedule.Amount__c = installmentAmount;
                newSchedule.Installment_Number__c = i;
                newSchedule.Status__c = '미납';
                newSchedule.PaidDate__c = null;
                newSchedule.DueDate__c = baseDate.addMonths((i - 1) * monthIncrement);
                newSchedulesToCreate.add(newSchedule);
            }
            
            if (!newSchedulesToCreate.isEmpty()) {
                insert newSchedulesToCreate;
                return 'PaymentStatus ' + newSchedulesToCreate.size() + '개가 성공적으로 생성되었습니다.';
            } else {
                return '생성할 PaymentStatus가 없습니다.';
            }
            
        } catch (Exception e) {
            System.debug('수동 PaymentStatus 생성 실패: ' + e.getMessage());
            return 'PaymentStatus 생성 실패: ' + e.getMessage();
        }
    }
}