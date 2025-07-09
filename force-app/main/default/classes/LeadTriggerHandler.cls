public class LeadTriggerHandler {
    public static void assignLeadOwnerOnInsert(List<Lead> newLeads) {
        // 새로운 로직을 위해 비워둡니다.
   // 1. 배정에 필요한 '영업팀' 대기열의 ID를 미리 조회합니다.
Map<String, Id> queueMap = new Map<String, Id>();
for (Group q : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name IN ('Sales_Team_1', 'Sales_Team_2', 'Sales_Team_3', 'Sales_Team_4', 'Sales_Team_5')]) {
    queueMap.put(q.Name, q.Id);
}

// 2. 여러 산업군을 팀별로 묶어서 관리하기 위해 Set을 사용합니다.
Set<String> team1_Industries = new Set<String>{'Technology', 'Communications', 'Electronics'};
Set<String> team2_Industries = new Set<String>{'Manufacturing', 'Chemicals', 'Construction', 'Machinery', 'Engineering'};
Set<String> team3_Industries = new Set<String>{'Finance', 'Consulting', 'Banking', 'Insurance'};
Set<String> team4_Industries = new Set<String>{'Retail', 'Apparel', 'Food & Beverage', 'Hospitality', 'Entertainment'};

// 3. 전달받은 모든 리드에 대해 산업군별 배정 규칙을 적용합니다.
for (Lead ld : newLeads) {
    String industry = ld.Industry;

    if (team1_Industries.contains(industry)) {
        ld.OwnerId = queueMap.get('Sales_Team_1');

    } else if (team2_Industries.contains(industry)) {
        ld.OwnerId = queueMap.get('Sales_Team_2');

    } else if (team3_Industries.contains(industry)) {
        ld.OwnerId = queueMap.get('Sales_Team_3');

    } else if (team4_Industries.contains(industry)) {
        ld.OwnerId = queueMap.get('Sales_Team_4');

    } else {
        // 위 어떤 팀에도 해당하지 않는 모든 경우
        ld.OwnerId = queueMap.get('Sales_Team_5');
    }
} }
}