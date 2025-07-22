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
        // 1. 데이터 준비: 관련 Order 조회
        List<Order> ordersToProcess = [
            SELECT Id, TotalAmount, EffectiveDate, Payment_Method__c
            FROM Order
            WHERE Id IN :orderIds
        ];

        // 2. 기존 납부 현황 레코드 조회 및 삭제
        List<PaymentStatus__c> existingSchedules = [
            SELECT Id FROM PaymentStatus__c WHERE Order__c IN :orderIds
        ];
        if (!existingSchedules.isEmpty()) {
            delete existingSchedules;
        }

        // 3. 신규 레코드 리스트 생성
        List<PaymentStatus__c> newSchedulesToCreate = new List<PaymentStatus__c>();
        Map<String, Integer> frequencyMap = new Map<String, Integer>{
            '월별' => 12, '분기별' => 4, '반기별' => 2, '년별' => 1
        };

        for (Order ord : ordersToProcess) {
            if (String.isBlank(ord.Payment_Method__c) || ord.TotalAmount == null || ord.TotalAmount <= 0) {
                continue;
            }

            Integer numberOfInstallments = frequencyMap.get(ord.Payment_Method__c);
            if (numberOfInstallments == null) continue;

            Decimal installmentAmount = ord.TotalAmount.divide(numberOfInstallments, 2, RoundingMode.HALF_UP);
            Integer monthIncrement = 12 / numberOfInstallments;

            for (Integer i = 1; i <= numberOfInstallments; i++) {
                PaymentStatus__c newSchedule = new PaymentStatus__c();
                newSchedule.Order__c = ord.Id;
                newSchedule.Amount__c = installmentAmount;
                newSchedule.InstallmentNumber__c = i;
                newSchedule.Status__c = '미납';
                newSchedule.PaidDate__c = null; // 초기에는 납부일자 없음
                if (ord.EffectiveDate != null) {
                   newSchedule.DueDate__c = ord.EffectiveDate.addMonths((i - 1) * monthIncrement);
                }
                newSchedulesToCreate.add(newSchedule);
            }
        }

        // 4. DML 실행
        if (!newSchedulesToCreate.isEmpty()) {
            insert newSchedulesToCreate;
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
                payment.InstallmentNumber__c = i;
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
}