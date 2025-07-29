/**
 * @description VIBA Risk Calculator - AI 기반 위험도 계산 서비스
 * @author VIBA AI Assistant
 * @date 2025-01-27
 */
public with sharing class VIBARiskCalculator {
    
    // 위험도 계산 상수
    private static final Decimal BASE_RISK_SCORE = 10.0;
    private static final Decimal MAX_RISK_SCORE = 100.0;
    
    /**
     * @description PaymentStatus 기반 위험도 계산
     * @param paymentStatus PaymentStatus 레코드
     * @return Decimal 위험도 점수 (0-100)
     */
    public static Decimal calculatePaymentRisk(PaymentStatus__c paymentStatus) {
        Decimal riskScore = BASE_RISK_SCORE;
        
        try {
            // 1. 상태별 기본 위험도
            riskScore += getStatusRiskScore(paymentStatus.Status__c);
            
            // 2. 지연 일수 기반 위험도
            riskScore += getDelayRiskScore(paymentStatus);
            
            // 3. 고객 이력 기반 위험도
            riskScore += getCustomerHistoryRiskScore(paymentStatus.Order__c);
            
            // 4. 금액 기반 위험도
            riskScore += getAmountRiskScore(paymentStatus.Amount__c);
            
            // 5. 시간적 패턴 위험도
            riskScore += getTemporalRiskScore(paymentStatus);
            
            System.debug('VIBARiskCalculator: PaymentStatusId=' + paymentStatus.Id + ', RiskScore=' + riskScore);
            
        } catch (Exception e) {
            System.debug('VIBARiskCalculator 오류: ' + e.getMessage());
            riskScore = 50.0; // 안전한 중간값
        }
        
        return Math.min(riskScore, MAX_RISK_SCORE);
    }
    
    /**
     * @description Account 전체 위험도 계산
     * @param accountId Account ID
     * @return Decimal 종합 위험도 점수
     */
    public static Decimal calculateAccountRisk(Id accountId) {
        Decimal totalRiskScore = BASE_RISK_SCORE;
        
        try {
            // Account의 모든 PaymentStatus 조회
            List<PaymentStatus__c> payments = [
                SELECT Id, Status__c, DueDate__c, Amount__c, Order__c
                FROM PaymentStatus__c 
                WHERE Order__r.AccountId = :accountId
                ORDER BY DueDate__c DESC
                LIMIT 50
            ];
            
            if (payments.isEmpty()) {
                return 20.0; // 신규 고객 기본 위험도
            }
            
            Decimal sumRiskScore = 0;
            Integer riskPaymentCount = 0;
            
            for (PaymentStatus__c payment : payments) {
                Decimal paymentRisk = calculatePaymentRisk(payment);
                
                if (paymentRisk > 30.0) { // 위험 임계값
                    sumRiskScore += paymentRisk;
                    riskPaymentCount++;
                }
            }
            
            // 평균 위험도 계산
            if (riskPaymentCount > 0) {
                totalRiskScore = sumRiskScore / riskPaymentCount;
                
                // 위험 패턴 빈도에 따른 가중치
                if (riskPaymentCount > payments.size() * 0.5) {
                    totalRiskScore *= 1.3; // 30% 증가
                }
            }
            
            // Account 특성 기반 조정
            totalRiskScore += getAccountCharacteristicRisk(accountId);
            
        } catch (Exception e) {
            System.debug('VIBARiskCalculator Account 위험도 계산 오류: ' + e.getMessage());
            totalRiskScore = 40.0;
        }
        
        return Math.min(totalRiskScore, MAX_RISK_SCORE);
    }
    
    // ============================================================================
    // Private Helper Methods
    // ============================================================================
    
    /**
     * @description 상태별 위험도 점수
     */
    private static Decimal getStatusRiskScore(String status) {
        switch on status {
            when '연체' { return 40.0; }
            when '미납' { return 20.0; }
            when '완납' { return 0.0; }
            when else { return 15.0; }
        }
    }
    
    /**
     * @description 지연 일수 기반 위험도
     */
    private static Decimal getDelayRiskScore(PaymentStatus__c paymentStatus) {
        if (paymentStatus.DueDate__c == null) return 5.0;
        
        Date today = Date.today();
        Integer delayDays = today.daysBetween(paymentStatus.DueDate__c);
        
        if (delayDays <= 0) return 0.0; // 아직 만료되지 않음
        
        // 지연 일수에 따른 점진적 위험도 증가
        if (delayDays <= 7) return 10.0;
        else if (delayDays <= 30) return 25.0;
        else if (delayDays <= 60) return 35.0;
        else return 45.0;
    }
    
    /**
     * @description 고객 이력 기반 위험도
     */
    private static Decimal getCustomerHistoryRiskScore(Id orderId) {
        try {
            // Order의 Account 조회
            List<Order> orders = [SELECT AccountId FROM Order WHERE Id = :orderId LIMIT 1];
            if (orders.isEmpty()) return 10.0;
            
            Id accountId = orders[0].AccountId;
            
            // 과거 연체 이력 확인
            Integer overdueCount = [
                SELECT COUNT() 
                FROM PaymentStatus__c 
                WHERE Order__r.AccountId = :accountId 
                AND Status__c = '연체'
            ];
            
            // 전체 PaymentStatus 수 확인
            Integer totalPayments = [
                SELECT COUNT() 
                FROM PaymentStatus__c 
                WHERE Order__r.AccountId = :accountId
            ];
            
            if (totalPayments == 0) return 15.0;
            
            // 연체율 기반 위험도
            Decimal overdueRate = (overdueCount * 100.0) / totalPayments;
            
            if (overdueRate > 50) return 30.0;
            else if (overdueRate > 20) return 20.0;
            else if (overdueRate > 10) return 10.0;
            else return 0.0;
            
        } catch (Exception e) {
            System.debug('고객 이력 위험도 계산 오류: ' + e.getMessage());
            return 10.0;
        }
    }
    
    /**
     * @description 금액 기반 위험도
     */
    private static Decimal getAmountRiskScore(Decimal amount) {
        if (amount == null) return 5.0;
        
        // 금액이 클수록 위험도 증가 (상대적)
        if (amount > 10000000) return 15.0; // 1천만원 이상
        else if (amount > 5000000) return 10.0; // 500만원 이상
        else if (amount > 1000000) return 5.0; // 100만원 이상
        else return 0.0;
    }
    
    /**
     * @description 시간적 패턴 위험도
     */
    private static Decimal getTemporalRiskScore(PaymentStatus__c paymentStatus) {
        try {
            // 같은 Order의 다른 PaymentStatus 패턴 분석
            List<PaymentStatus__c> orderPayments = [
                SELECT Status__c, DueDate__c 
                FROM PaymentStatus__c 
                WHERE Order__c = :paymentStatus.Order__c 
                ORDER BY Installment_Number__c
            ];
            
            Integer consecutiveIssues = 0;
            
            for (PaymentStatus__c payment : orderPayments) {
                if (payment.Status__c == '연체' || payment.Status__c == '미납') {
                    consecutiveIssues++;
                } else {
                    consecutiveIssues = 0; // 연속성 끊김
                }
            }
            
            // 연속적 문제 발생 시 위험도 증가
            if (consecutiveIssues >= 3) return 25.0;
            else if (consecutiveIssues >= 2) return 15.0;
            else if (consecutiveIssues >= 1) return 5.0;
            else return 0.0;
            
        } catch (Exception e) {
            System.debug('시간적 패턴 위험도 계산 오류: ' + e.getMessage());
            return 0.0;
        }
    }
    
    /**
     * @description Account 특성 기반 위험도
     */
    private static Decimal getAccountCharacteristicRisk(Id accountId) {
        try {
            List<Account> accounts = [
                SELECT Industry, NumberOfEmployees, AnnualRevenue, 
                       CustomerPriority__c, Key_Account__c
                FROM Account 
                WHERE Id = :accountId 
                LIMIT 1
            ];
            
            if (accounts.isEmpty()) return 10.0;
            
            Account account = accounts[0];
            Decimal characteristicRisk = 0.0;
            
            // 업종별 위험도
            if (account.Industry == 'Technology') {
                characteristicRisk -= 5.0; // IT는 일반적으로 안정적
            } else if (account.Industry == 'Retail') {
                characteristicRisk += 5.0; // 소매업은 변동성 높음
            }
            
            // 회사 규모별 위험도
            if (account.NumberOfEmployees != null) {
                if (account.NumberOfEmployees < 10) {
                    characteristicRisk += 10.0; // 소규모 기업 위험
                } else if (account.NumberOfEmployees > 1000) {
                    characteristicRisk -= 5.0; // 대기업 안정성
                }
            }
            
            // Key Account는 위험도 감소
            if (account.Key_Account__c == true) {
                characteristicRisk -= 10.0;
            }
            
            // 고객 우선순위 기반 조정
            if (account.CustomerPriority__c == 'High') {
                characteristicRisk -= 5.0;
            }
            
            return characteristicRisk;
            
        } catch (Exception e) {
            System.debug('Account 특성 위험도 계산 오류: ' + e.getMessage());
            return 0.0;
        }
    }
}
