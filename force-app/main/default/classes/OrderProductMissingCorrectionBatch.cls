/**
 * @description Order Product가 누락된 Order들을 일괄 보정하는 배치 클래스
 * @author Moon JeongHyeon
 * @date 2025-07-21
 */
public class OrderProductMissingCorrectionBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        // Order Product가 없고 Opportunity가 연결된 Order 조회
        return Database.getQueryLocator([
            SELECT Id, OrderNumber, OpportunityId, TotalAmount, AccountId, Status
            FROM Order 
            WHERE OpportunityId != null
            AND Id NOT IN (SELECT OrderId FROM OrderItem WHERE OrderId != null)
            AND TotalAmount <= 0
        ]);
    }
    
    public void execute(Database.BatchableContext context, List<Order> orders) {
        List<Id> orderIdsToProcess = new List<Id>();
        
        for (Order ord : orders) {
            orderIdsToProcess.add(ord.Id);
        }
        
        if (!orderIdsToProcess.isEmpty()) {
            try {
                System.debug('Order Product 누락 보정 시작: ' + orderIdsToProcess.size() + '개 Order');
                
                // 자동 등록 서비스 호출
                OrderProductAutoRegistrationService.batchRegisterOpportunityProducts(orderIdsToProcess);
                
                System.debug('Order Product 누락 보정 완료: ' + orderIdsToProcess.size() + '개 Order');
                
            } catch (Exception e) {
                System.debug('Order Product 누락 보정 실패: ' + e.getMessage());
            }
        }
    }
    
    public void finish(Database.BatchableContext context) {
        System.debug('OrderProductMissingCorrectionBatch 실행 완료');
        
        // 실행 결과 요약
        List<Order> remainingIssues = [
            SELECT Id, OrderNumber
            FROM Order 
            WHERE OpportunityId != null
            AND Id NOT IN (SELECT OrderId FROM OrderItem WHERE OrderId != null)
            AND TotalAmount <= 0
        ];
        
        if (remainingIssues.isEmpty()) {
            System.debug('✅ 모든 Order Product 누락 이슈가 해결되었습니다.');
        } else {
            System.debug('⚠️ 여전히 ' + remainingIssues.size() + '개의 Order에서 이슈가 남아있습니다:');
            for (Order ord : remainingIssues) {
                System.debug('   - ' + ord.OrderNumber);
            }
        }
    }
}
