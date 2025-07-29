/**
 * @description 영업사원 전용 Agentforce Agent 설정 및 테스트 스크립트
 * @author AI Assistant
 * @created 2025-07-24
 */

System.debug('🤖 =====Agentforce Sales Agent 구축 가이드=====');

System.debug('');
System.debug('📋 1단계: Einstein & Agentforce 활성화 확인');
System.debug('Setup → Einstein Setup → Einstein 토글 확인');
System.debug('Setup → Agents (Agent Studio) → Agentforce 토글 확인');

System.debug('');
System.debug('🎯 2단계: Sales Performance Agent 구성 정보');
System.debug('Label: Sales Performance Agent');
System.debug('API Name: Sales_Performance_Agent');
System.debug('Description: 영업사원을 위한 종합 AI 어시스턴트');
System.debug('Role: Order-Asset 관리, 성과 분석, 고객 인사이트 제공');

System.debug('');
System.debug('📚 3단계: 필요한 지식 문서 목록');
System.debug('✅ Sales_Assets_Strategic_Design.md');
System.debug('✅ Account_Based_Asset_System_Final.md');
System.debug('✅ Einstein_Sales_Analytics_System.md');
System.debug('✅ Order_Product_Automation_Design.md');
System.debug('✅ Sales_App_Notification_Design.md');
System.debug('✅ Sales_Assets_Daily_Guide.md');
System.debug('✅ Salesforce_Assets_Action_Checklist.md');
System.debug('✅ Order_Asset_Navigation_Solution.md');

System.debug('');
System.debug('🔍 4단계: 현재 조직의 데이터 준비도 확인');

// Order 데이터 확인
List<Order> recentOrders = [
    SELECT Id, OrderNumber, Account.Name, Status, TotalAmount
    FROM Order 
    WHERE OrderNumber IN ('00000138', '00000151', '00000153', '00000156', '00000157', '00000158')
    ORDER BY CreatedDate DESC
    LIMIT 10
];

System.debug('📊 실제 Order 데이터: ' + recentOrders.size() + '개');
for(Order ord : recentOrders) {
    System.debug('   • ' + ord.OrderNumber + ' (' + ord.Account.Name + ') - ' + ord.Status);
}

// Asset 데이터 확인
List<Asset> assets = [
    SELECT Id, Name, Account.Name, Status, InstallDate
    FROM Asset 
    WHERE Account.Name LIKE '%그린파워텍%' OR Account.Name LIKE '%테스트%'
    LIMIT 5
];

System.debug('');
System.debug('🏭 Asset 데이터: ' + assets.size() + '개');
for(Asset asset : assets) {
    System.debug('   • ' + asset.Name + ' (' + asset.Account.Name + ') - ' + asset.Status);
}

// Payment 데이터 확인 (Custom Object)
try {
    List<SObject> payments = Database.query(
        'SELECT Id, Name, NotificationType__c, NotificationStatus__c ' +
        'FROM Payment_Notification__c LIMIT 5'
    );
    System.debug('');
    System.debug('💰 Payment Notification 데이터: ' + payments.size() + '개');
} catch(Exception e) {
    System.debug('');
    System.debug('⚠️ Payment_Notification__c 오브젝트 확인 필요');
}

System.debug('');
System.debug('🎪 5단계: Agent Topics 설정 가이드');
System.debug('Topic 1: Order Management - 주문 생성, 상태 추적, Payment 관리');
System.debug('Topic 2: Asset Analytics - Asset 성과 분석 및 갱신 예측');
System.debug('Topic 3: Customer Relationship - 고객 관계 관리');
System.debug('Topic 4: Performance Insights - 영업사원 개인 성과 분석');

System.debug('');
System.debug('🔧 6단계: Custom Actions 개발 필요 목록');
System.debug('1. Einstein Search 통합');
System.debug('2. Flow Actions for Order Process');
System.debug('3. Apex Actions for Complex Analytics');

System.debug('');
System.debug('📱 7단계: 실전 시나리오');
System.debug('시나리오 1: 신규 Order 생성 지원');
System.debug('시나리오 2: Payment 관리 최적화');
System.debug('시나리오 3: Asset 갱신 전략');
System.debug('시나리오 4: 팀 협업 지원 (Slack 연동)');

System.debug('');
System.debug('📈 8단계: 성과 측정 KPI');
System.debug('• Order 성공률: 90% → 95%');
System.debug('• Payment 완료 시간: 5일 → 2일');
System.debug('• Asset 갱신률: 70% → 85%');
System.debug('• 고객 만족도: 8.5 → 9.0');

System.debug('');
System.debug('🚀 다음 단계 액션 아이템');
System.debug('1. Setup에서 Einstein & Agentforce 활성화');
System.debug('2. Sales Performance Agent 생성');
System.debug('3. 8개 지식 문서를 PDF로 변환 후 업로드');
System.debug('4. 실제 Order 데이터로 Agent 테스트');
System.debug('5. 영업팀 대상 사용법 교육');

System.debug('');
System.debug('✅ Agentforce Sales Agent 구축 준비 완료!');
System.debug('📋 상세 가이드: Agentforce_Sales_Agent_Setup_Guide.md 참조');
