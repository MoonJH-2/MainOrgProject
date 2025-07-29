/**
 * @description 고객 납부 관리 시스템 Controller
 * 실제 PaymentStatus 데이터를 조작하여 납부 상태를 관리
 * @author JH Moon
 * @since 2025-07-28
 */
public with sharing class CustomerPaymentManagerController {
    
    /**
     * @description Order 목록 조회 (PaymentStatus 포함)
     */
    @AuraEnabled(cacheable=true)
    public static List<OrderWithPaymentInfo> getOrdersWithPayments() {
        try {
            List<OrderWithPaymentInfo> orderList = new List<OrderWithPaymentInfo>();
            
            List<Order> orders = [
                SELECT Id, OrderNumber, AccountId, Account.Name, TotalAmount, 
                       Status, EffectiveDate, Payment_Method__c, CreatedDate
                FROM Order 
                WHERE Status = 'Activated'
                ORDER BY CreatedDate DESC
                LIMIT 50
            ];
            
            for (Order ord : orders) {
                OrderWithPaymentInfo orderInfo = new OrderWithPaymentInfo();
                orderInfo.orderRecord = ord;
                orderInfo.accountName = ord.Account?.Name;
                orderInfo.formattedAmount = formatCurrency(ord.TotalAmount);
                orderInfo.paymentProgress = calculatePaymentProgress(ord.Id);
                orderInfo.paymentMethodLabel = getPaymentMethodLabel(ord.Payment_Method__c);
                orderList.add(orderInfo);
            }
            
            return orderList;
            
        } catch (Exception e) {
            throw new AuraHandledException('Order 목록 조회 실패: ' + e.getMessage());
        }
    }
    
    /**
     * @description 특정 Order의 PaymentStatus 상세 조회
     */
    @AuraEnabled
    public static PaymentDetailResponse getPaymentStatusDetails(Id orderId) {
        try {
            PaymentDetailResponse response = new PaymentDetailResponse();
            
            // Order 정보 조회
            Order orderInfo = [
                SELECT Id, OrderNumber, AccountId, Account.Name, TotalAmount,
                       Status, EffectiveDate, Payment_Method__c, CreatedDate
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            // PaymentStatus 목록 조회
            List<PaymentStatus__c> paymentList = [
                SELECT Id, Name, Order__c, Installment_Number__c, Amount__c, 
                       DueDate__c, PaidDate__c, Status__c, AI_Risk_Score__c,
                       AI_Recommended_Action__c, Next_Contact_Date__c, 
                       Slack_Notification_Sent__c, CreatedDate
                FROM PaymentStatus__c 
                WHERE Order__c = :orderId 
                ORDER BY Installment_Number__c ASC
            ];
            
            response.orderInfo = orderInfo;
            response.paymentList = paymentList;
            response.paymentSummary = calculatePaymentSummary(paymentList, orderInfo.TotalAmount);
            
            return response;
            
        } catch (Exception e) {
            throw new AuraHandledException('PaymentStatus 조회 실패: ' + e.getMessage());
        }
    }
    
    /**
     * @description Order의 Payment Method 변경
     */
    @AuraEnabled
    public static String updatePaymentMethod(Id orderId, String newPaymentMethod) {
        try {
            // Order Payment Method 업데이트
            Order orderToUpdate = new Order(
                Id = orderId,
                Payment_Method__c = newPaymentMethod
            );
            update orderToUpdate;
            
            // PaymentStatus 재생성
            regeneratePaymentSchedule(orderId, newPaymentMethod);
            
            return 'Payment Method가 성공적으로 변경되었습니다.';
            
        } catch (Exception e) {
            throw new AuraHandledException('Payment Method 변경 실패: ' + e.getMessage());
        }
    }
    
    /**
     * @description 개별 PaymentStatus 상태 업데이트
     */
    @AuraEnabled
    public static String updatePaymentStatus(Id paymentId, String newStatus, Date paidDate, String notes) {
        try {
            PaymentStatus__c paymentToUpdate = new PaymentStatus__c(
                Id = paymentId,
                Status__c = newStatus,
                PaidDate__c = (newStatus == '완납') ? (paidDate != null ? paidDate : Date.today()) : null
            );
            
            update paymentToUpdate;
            
            return '납부 상태가 성공적으로 업데이트되었습니다.';
            
        } catch (Exception e) {
            throw new AuraHandledException('납부 상태 업데이트 실패: ' + e.getMessage());
        }
    }
    
    /**
     * @description 전체 완납 처리
     */
    @AuraEnabled
    public static String markAllPaymentsAsCompleted(Id orderId) {
        try {
            List<PaymentStatus__c> paymentsToUpdate = [
                SELECT Id, Status__c, PaidDate__c
                FROM PaymentStatus__c 
                WHERE Order__c = :orderId AND Status__c != '완납'
            ];
            
            for (PaymentStatus__c payment : paymentsToUpdate) {
                payment.Status__c = '완납';
                payment.PaidDate__c = Date.today();
            }
            
            if (!paymentsToUpdate.isEmpty()) {
                update paymentsToUpdate;
            }
            
            return '모든 납부가 완납 처리되었습니다.';
            
        } catch (Exception e) {
            throw new AuraHandledException('전체 완납 처리 실패: ' + e.getMessage());
        }
    }
    
    /**
     * @description PaymentStatus 일정 재생성
     */
    private static void regeneratePaymentSchedule(Id orderId, String paymentMethod) {
        // 기존 PaymentStatus 삭제
        List<PaymentStatus__c> existingPayments = [
            SELECT Id FROM PaymentStatus__c WHERE Order__c = :orderId
        ];
        if (!existingPayments.isEmpty()) {
            delete existingPayments;
        }
        
        // Order 정보 조회
        Order orderInfo = [
            SELECT Id, TotalAmount, EffectiveDate 
            FROM Order 
            WHERE Id = :orderId 
            LIMIT 1
        ];
        
        // Payment Method에 따른 분할 횟수 결정
        Integer installmentCount = getInstallmentCount(paymentMethod);
        Decimal installmentAmount = orderInfo.TotalAmount / installmentCount;
        
        // 새로운 PaymentStatus 생성
        List<PaymentStatus__c> newPayments = new List<PaymentStatus__c>();
        
        for (Integer i = 1; i <= installmentCount; i++) {
            PaymentStatus__c payment = new PaymentStatus__c();
            payment.Order__c = orderId;
            payment.Installment_Number__c = i;
            payment.Amount__c = installmentAmount;
            payment.DueDate__c = calculateDueDate(orderInfo.EffectiveDate, paymentMethod, i);
            payment.Status__c = '미납';
            newPayments.add(payment);
        }
        
        insert newPayments;
    }
    
    /**
     * @description Payment Method별 분할 횟수 반환
     */
    private static Integer getInstallmentCount(String paymentMethod) {
        switch on paymentMethod {
            when '월별' { return 12; }
            when '분기별' { return 4; }
            when '반기별' { return 2; }
            when '년별' { return 1; }
            when else { return 4; }
        }
    }
    
    /**
     * @description Due Date 계산
     */
    private static Date calculateDueDate(Date startDate, String paymentMethod, Integer installmentNumber) {
        switch on paymentMethod {
            when '월별' { return startDate.addMonths(installmentNumber - 1); }
            when '분기별' { return startDate.addMonths((installmentNumber - 1) * 3); }
            when '반기별' { return startDate.addMonths((installmentNumber - 1) * 6); }
            when '년별' { return startDate.addYears(installmentNumber - 1); }
            when else { return startDate.addMonths((installmentNumber - 1) * 3); }
        }
    }
    
    /**
     * @description 납부 진행률 계산
     */
    private static String calculatePaymentProgress(Id orderId) {
        try {
            List<PaymentStatus__c> allPayments = [
                SELECT Id, Status__c
                FROM PaymentStatus__c 
                WHERE Order__c = :orderId
            ];
            
            Integer total = allPayments.size();
            Integer completed = 0;
            
            for (PaymentStatus__c payment : allPayments) {
                if (payment.Status__c == '완납') {
                    completed++;
                }
            }
            
            if (total > 0) {
                return completed + '/' + total + ' (' + Math.round((completed * 100.0) / total) + '%)';
            }
            return '0/0 (0%)';
        } catch (Exception e) {
            return 'N/A';
        }
    }
    
    /**
     * @description 납부 요약 정보 계산
     */
    private static PaymentSummary calculatePaymentSummary(List<PaymentStatus__c> payments, Decimal totalAmount) {
        PaymentSummary summary = new PaymentSummary();
        summary.totalPayments = payments.size();
        summary.totalAmount = totalAmount;
        summary.paidAmount = 0;
        summary.completedPayments = 0;
        summary.overduePayments = 0;
        summary.remainingPayments = 0;
        
        Date today = Date.today();
        
        for (PaymentStatus__c payment : payments) {
            if (payment.Status__c == '완납') {
                summary.completedPayments++;
                summary.paidAmount += payment.Amount__c != null ? payment.Amount__c : 0;
            } else if (payment.Status__c == '미납' && payment.DueDate__c != null && payment.DueDate__c < today) {
                // 미납이지만 납부일이 지난 경우 연체로 계산
                summary.overduePayments++;
            } else {
                // 그 외 미납 (아직 납부일이 지나지 않음)
                summary.remainingPayments++;
            }
        }
        
        summary.isFullyPaid = (summary.completedPayments == summary.totalPayments);
        summary.progressPercentage = summary.totalPayments > 0 ? 
            Math.round((summary.completedPayments * 100.0) / summary.totalPayments) : 0;
        
        return summary;
    }
    
    /**
     * @description 통화 포맷팅
     */
    private static String formatCurrency(Decimal amount) {
        if (amount == null) return '₩0';
        return '₩' + String.valueOf(amount.intValue()).replaceAll('(\\d)(?=(\\d{3})+$)', '$1,');
    }
    
    /**
     * @description Payment Method 라벨 반환
     */
    private static String getPaymentMethodLabel(String paymentMethod) {
        switch on paymentMethod {
            when '월별' { return '월별 (12회)'; }
            when '분기별' { return '분기별 (4회)'; }
            when '반기별' { return '반기별 (2회)'; }
            when '년별' { return '년별 (1회)'; }
            when else { return paymentMethod != null ? paymentMethod : '분기별 (4회)'; }
        }
    }
    
    // ========== Wrapper Classes ==========
    
    /**
     * @description Order 정보와 PaymentStatus 요약을 포함한 래퍼 클래스
     */
    public class OrderWithPaymentInfo {
        @AuraEnabled public Order orderRecord { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String formattedAmount { get; set; }
        @AuraEnabled public String paymentProgress { get; set; }
        @AuraEnabled public String paymentMethodLabel { get; set; }
    }
    
    /**
     * @description PaymentStatus 상세 응답 클래스
     */
    public class PaymentDetailResponse {
        @AuraEnabled public Order orderInfo { get; set; }
        @AuraEnabled public List<PaymentStatus__c> paymentList { get; set; }
        @AuraEnabled public PaymentSummary paymentSummary { get; set; }
    }
    
    /**
     * @description 납부 요약 정보 클래스
     */
    public class PaymentSummary {
        @AuraEnabled public Integer totalPayments { get; set; }
        @AuraEnabled public Integer completedPayments { get; set; }
        @AuraEnabled public Integer remainingPayments { get; set; }
        @AuraEnabled public Integer overduePayments { get; set; }
        @AuraEnabled public Boolean isFullyPaid { get; set; }
        @AuraEnabled public Decimal totalAmount { get; set; }
        @AuraEnabled public Decimal paidAmount { get; set; }
        @AuraEnabled public Integer progressPercentage { get; set; }
    }
}
