/**
 * @description       : 연체 즉시 처리 서비스 클래스
 * @author            : JH Moon
 * @last modified on  : 07-17-2025
 * @last modified by  : JH Moon
**/
public class PaymentOverdueService {
    
    /**
     * 실시간 연체 체크 - 매 시간마다 실행
     */
    public static void checkRealTimeOverdue() {
        Date today = Date.today();
        
        // 어제가 기일이었던 미납 PaymentStatus 조회
        List<PaymentStatus__c> overduePayments = [
            SELECT Id, Order__c, Order__r.OrderNumber, Order__r.Account.Name,
                   Amount__c, DueDate__c, Installment_Number__c, Status__c
            FROM PaymentStatus__c 
            WHERE DueDate__c = :today.addDays(-1)
            AND Status__c = '미납'
        ];
        
        if (!overduePayments.isEmpty()) {
            // 이미 오늘 생성된 연체 알림 Task들 확인
            Set<String> existingTaskSubjects = new Set<String>();
            List<Task> todayTasks = [
                SELECT Subject FROM Task 
                WHERE Subject LIKE '연체 알림%' 
                AND CreatedDate = TODAY
            ];
            
            for (Task t : todayTasks) {
                existingTaskSubjects.add(t.Subject);
            }
            
            // 중복되지 않은 연체 건들만 처리
            List<Id> newOverdueIds = new List<Id>();
            for (PaymentStatus__c ps : overduePayments) {
                String expectedSubject = '연체 알림 - ' + ps.Order__r.OrderNumber + ' ' + ps.Installment_Number__c + '차';
                if (!existingTaskSubjects.contains(expectedSubject)) {
                    newOverdueIds.add(ps.Id);
                }
            }
            
            if (!newOverdueIds.isEmpty()) {
                PaymentStatusTimelineController.checkOverdueAndCreateTasks(newOverdueIds);
            }
        }
    }
    
    /**
     * 새로운 PaymentStatus 생성 시 즉시 연체 체크
     */
    public static void checkNewPaymentStatus(List<PaymentStatus__c> newPayments) {
        Date today = Date.today();
        List<Id> overdueIds = new List<Id>();
        
        for (PaymentStatus__c ps : newPayments) {
            // 생성 시점에 이미 연체된 상태인지 체크
            if (ps.DueDate__c != null && ps.DueDate__c < today && ps.Status__c == '미납') {
                overdueIds.add(ps.Id);
            }
        }
        
        if (!overdueIds.isEmpty()) {
            PaymentStatusTimelineController.checkOverdueAndCreateTasks(overdueIds);
        }
    }
    
    /**
     * 매일 자정에 실행될 연체 전환 체크
     */
    public static void dailyOverdueCheck() {
        Date today = Date.today();
        
        // 오늘부터 연체가 되는 PaymentStatus 조회
        List<PaymentStatus__c> newlyOverduePayments = [
            SELECT Id
            FROM PaymentStatus__c 
            WHERE DueDate__c < :today
            AND Status__c = '미납'
        ];
        
        if (!newlyOverduePayments.isEmpty()) {
            List<Id> overdueIds = new List<Id>();
            for (PaymentStatus__c ps : newlyOverduePayments) {
                overdueIds.add(ps.Id);
            }
            PaymentStatusTimelineController.checkOverdueAndCreateTasks(overdueIds);
        }
    }
}
