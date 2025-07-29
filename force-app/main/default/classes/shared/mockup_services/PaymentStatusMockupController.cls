/**
 * @description PaymentStatus 테스트를 위한 Mockup Controller
 * 실제 데이터 변경 없이 다양한 납부 상태 시나리오를 테스트
 * @author JH Moon
 * @since 2025-07-28
 */
public with sharing class PaymentStatusMockupController {
    
    /**
     * @description 다양한 납부 상태 시나리오를 반환하는 Mockup API
     * @param orderId Order ID
     * @param scenario 테스트 시나리오 ('completed', 'partial', 'overdue', 'mixed')
     * @return PaymentMockupResponse 래퍼 클래스
     */
    @AuraEnabled
    public static PaymentMockupResponse getMockupPaymentStatus(Id orderId, String scenario) {
        try {
            PaymentMockupResponse response = new PaymentMockupResponse();
            
            // 실제 Order 정보 조회
            Order orderInfo = [
                SELECT Id, OrderNumber, AccountId, Account.Name, TotalAmount, 
                       Status, EffectiveDate, EndDate, CreatedDate,
                       (SELECT Id, Product2Id, Product2.Name, Quantity, UnitPrice, TotalPrice, ListPrice
                        FROM OrderItems 
                        ORDER BY CreatedDate DESC 
                        LIMIT 1)
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            response.orderInfo = orderInfo;
            response.scenario = scenario;
            response.paymentSummary = generateMockupPaymentSummary(scenario, orderInfo.TotalAmount);
            response.mockupPayments = generateMockupPayments(scenario, orderId, orderInfo.TotalAmount);
            
            return response;
            
        } catch (Exception e) {
            throw new AuraHandledException('Mockup API 오류: ' + e.getMessage());
        }
    }
    
    /**
     * @description 시나리오별 납부 요약 정보 생성
     */
    private static PaymentSummaryMockup generateMockupPaymentSummary(String scenario, Decimal totalAmount) {
        PaymentSummaryMockup summary = new PaymentSummaryMockup();
        
        switch on scenario {
            when 'completed' {
                // 완납 시나리오
                summary.totalPayments = 4;
                summary.completedPayments = 4;
                summary.remainingPayments = 0;
                summary.overduePayments = 0;
                summary.isFullyPaid = true;
                summary.totalAmount = totalAmount;
                summary.paidAmount = totalAmount;
                summary.progressPercentage = 100;
            }
            when 'partial' {
                // 부분 납부 시나리오
                summary.totalPayments = 4;
                summary.completedPayments = 2;
                summary.remainingPayments = 2;
                summary.overduePayments = 0;
                summary.isFullyPaid = false;
                summary.totalAmount = totalAmount;
                summary.paidAmount = totalAmount * 0.5;
                summary.progressPercentage = 50;
            }
            when 'overdue' {
                // 연체 시나리오
                summary.totalPayments = 4;
                summary.completedPayments = 1;
                summary.remainingPayments = 1;
                summary.overduePayments = 2;
                summary.isFullyPaid = false;
                summary.totalAmount = totalAmount;
                summary.paidAmount = totalAmount * 0.25;
                summary.progressPercentage = 25;
            }
            when 'mixed' {
                // 혼합 시나리오 (완납 + 연체)
                summary.totalPayments = 4;
                summary.completedPayments = 2;
                summary.remainingPayments = 1;
                summary.overduePayments = 1;
                summary.isFullyPaid = false;
                summary.totalAmount = totalAmount;
                summary.paidAmount = totalAmount * 0.5;
                summary.progressPercentage = 50;
            }
            when else {
                // 기본값: 납부 진행 중
                summary.totalPayments = 4;
                summary.completedPayments = 1;
                summary.remainingPayments = 3;
                summary.overduePayments = 0;
                summary.isFullyPaid = false;
                summary.totalAmount = totalAmount;
                summary.paidAmount = totalAmount * 0.25;
                summary.progressPercentage = 25;
            }
        }
        
        return summary;
    }
    
    /**
     * @description 시나리오별 개별 납부 정보 생성
     */
    private static List<PaymentStatusMockup> generateMockupPayments(String scenario, Id orderId, Decimal totalAmount) {
        List<PaymentStatusMockup> payments = new List<PaymentStatusMockup>();
        Decimal installmentAmount = totalAmount / 4;
        Date baseDate = Date.today().addMonths(-6);
        
        for (Integer i = 1; i <= 4; i++) {
            PaymentStatusMockup payment = new PaymentStatusMockup();
            payment.orderId = orderId;
            payment.installmentNumber = i;
            payment.amount = installmentAmount;
            payment.dueDate = baseDate.addMonths((i-1) * 3); // 분기별
            
            // 시나리오별 상태 설정
            switch on scenario {
                when 'completed' {
                    payment.status = '완납';
                    payment.paidDate = payment.dueDate.addDays(Math.mod(i, 3) - 1); // 약간의 변화
                }
                when 'partial' {
                    payment.status = i <= 2 ? '완납' : '미납';
                    payment.paidDate = i <= 2 ? payment.dueDate.addDays(Math.mod(i, 3)) : null;
                }
                when 'overdue' {
                    if (i == 1) {
                        payment.status = '완납';
                        payment.paidDate = payment.dueDate.addDays(1);
                    } else if (i <= 3) {
                        payment.status = '연체';
                        payment.paidDate = null;
                    } else {
                        payment.status = '미납';
                        payment.paidDate = null;
                    }
                }
                when 'mixed' {
                    if (i <= 2) {
                        payment.status = '완납';
                        payment.paidDate = payment.dueDate.addDays(Math.mod(i, 2));
                    } else if (i == 3) {
                        payment.status = '연체';
                        payment.paidDate = null;
                    } else {
                        payment.status = '미납';
                        payment.paidDate = null;
                    }
                }
                when else {
                    payment.status = i == 1 ? '완납' : '미납';
                    payment.paidDate = i == 1 ? payment.dueDate : null;
                }
            }
            
            payments.add(payment);
        }
        
        return payments;
    }
    
    /**
     * @description Mockup 응답 래퍼 클래스
     */
    public class PaymentMockupResponse {
        @AuraEnabled public Order orderInfo { get; set; }
        @AuraEnabled public String scenario { get; set; }
        @AuraEnabled public PaymentSummaryMockup paymentSummary { get; set; }
        @AuraEnabled public List<PaymentStatusMockup> mockupPayments { get; set; }
        
        public PaymentMockupResponse() {
            this.mockupPayments = new List<PaymentStatusMockup>();
        }
    }
    
    /**
     * @description Mockup 납부 요약 정보
     */
    public class PaymentSummaryMockup {
        @AuraEnabled public Integer totalPayments { get; set; }
        @AuraEnabled public Integer completedPayments { get; set; }
        @AuraEnabled public Integer remainingPayments { get; set; }
        @AuraEnabled public Integer overduePayments { get; set; }
        @AuraEnabled public Boolean isFullyPaid { get; set; }
        @AuraEnabled public Decimal totalAmount { get; set; }
        @AuraEnabled public Decimal paidAmount { get; set; }
        @AuraEnabled public Integer progressPercentage { get; set; }
    }
    
    /**
     * @description Mockup 개별 납부 정보
     */
    public class PaymentStatusMockup {
        @AuraEnabled public Id orderId { get; set; }
        @AuraEnabled public Integer installmentNumber { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public Date dueDate { get; set; }
        @AuraEnabled public Date paidDate { get; set; }
        @AuraEnabled public String status { get; set; }
    }
}
