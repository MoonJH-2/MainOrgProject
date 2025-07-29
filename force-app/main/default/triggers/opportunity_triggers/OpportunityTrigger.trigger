/**
 * @description Opportunity가 Closed Won으로 변경될 때 자동으로 Order와 Order Product를 생성하는 트리거
 * @author Moon JeongHyeon
 * @date 2025-07-21
 */
trigger OpportunityTrigger on Opportunity (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Opportunity> closedWonOpps = new List<Opportunity>();
        
        for (Opportunity opp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
            
            // StageName이 Closed Won으로 변경된 경우
            if (oldOpp.StageName != 'Closed Won' && opp.StageName == 'Closed Won') {
                closedWonOpps.add(opp);
            }
        }
        
        if (!closedWonOpps.isEmpty()) {
            OpportunityToOrderService.createOrdersWithProducts(closedWonOpps);
        }
    }
}
