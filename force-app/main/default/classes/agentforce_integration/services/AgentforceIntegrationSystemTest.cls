/**
 * @description Agentforce 통합 시스템 테스트 클래스
 * 모든 Phase의 기능을 종합적으로 테스트
 * @author AI Assistant
 * @created 2025-07-24
 */
@IsTest
public class AgentforceIntegrationSystemTest {
    
    @TestSetup
    static void setupTestData() {
        // 테스트 Account 생성
        Account testAccount = TestDataFactory.createAccount('Test Customer Corp');
        testAccount.Type = 'Customer';
        testAccount.Industry = 'Technology';
        testAccount.AnnualRevenue = 1000000;
        insert testAccount;
        
        // 테스트 Order 생성
        Order testOrder = TestDataFactory.createOrder(testAccount.Id);
        testOrder.Status = 'Draft';
        insert testOrder;
        
        // 테스트 PaymentStatus 생성
        PaymentStatus__c payment1 = new PaymentStatus__c();
        payment1.Order__c = testOrder.Id;
        payment1.분기__c = 'Q1';
        payment1.Status__c = '미납';
        payment1.Amount__c = 1000000;
        payment1.Due_Date__c = Date.today().addDays(30);
        
        PaymentStatus__c payment2 = new PaymentStatus__c();
        payment2.Order__c = testOrder.Id;
        payment2.분기__c = 'Q2';
        payment2.Status__c = '미납';
        payment2.Amount__c = 1000000;
        payment2.Due_Date__c = Date.today().addDays(120);
        
        insert new List<PaymentStatus__c>{payment1, payment2};
        
        // 테스트 Asset 생성
        Asset testAsset = TestDataFactory.createAsset(testAccount.Id);
        testAsset.Status = 'Installed';
        testAsset.InstallDate = Date.today().addDays(-365);
        insert testAsset;
        
        // 테스트 Task 생성
        Task urgentTask = new Task();
        urgentTask.Subject = '긴급 고객 미팅';
        urgentTask.WhatId = testAccount.Id;
        urgentTask.ActivityDate = Date.today();
        urgentTask.Priority = 'High';
        urgentTask.Status = 'Not Started';
        
        Task followUpTask = new Task();
        followUpTask.Subject = '후속 연락 필요';
        followUpTask.WhatId = testAccount.Id;
        followUpTask.ActivityDate = Date.today().addDays(-7);
        followUpTask.Priority = 'Normal';
        followUpTask.Status = 'Not Started';
        
        insert new List<Task>{urgentTask, followUpTask};
        
        // 테스트 Event 생성
        Event todayMeeting = new Event();
        todayMeeting.Subject = '고객 프레젠테이션';
        todayMeeting.WhatId = testAccount.Id;
        todayMeeting.StartDateTime = DateTime.now().addHours(2);
        todayMeeting.EndDateTime = DateTime.now().addHours(3);
        todayMeeting.ActivityDateTime = DateTime.now().addHours(2);
        
        insert todayMeeting;
    }
    
    @IsTest
    static void testAgentforceRequestProcessing() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        AgentforceMasterOrchestrationService.AgentforceRequest request = 
            new AgentforceMasterOrchestrationService.AgentforceRequest();
        request.userId = UserInfo.getUserId();
        request.userMessage = '오늘 할 일 정리해줘';
        request.recordId = testAccount.Id;
        request.additionalContext = '일일 브리핑 요청';
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.AgentforceResponse> responses = 
            AgentforceMasterOrchestrationService.processAgentforceRequest(
                new List<AgentforceMasterOrchestrationService.AgentforceRequest>{request}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, responses.size());
        AgentforceMasterOrchestrationService.AgentforceResponse response = responses[0];
        System.assertEquals(true, response.success);
        System.assertEquals('DAILY_BRIEFING', response.responseType);
        System.assertNotEquals(null, response.content);
        System.assert(response.content.contains('오늘의 영업 브리핑'));
    }
    
    @IsTest
    static void testEmailGenerationRequest() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        AgentforceMasterOrchestrationService.AgentforceRequest request = 
            new AgentforceMasterOrchestrationService.AgentforceRequest();
        request.userId = UserInfo.getUserId();
        request.userMessage = '고객에게 이메일 보내줘';
        request.recordId = testAccount.Id;
        request.additionalContext = '주문 관련 이메일';
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.AgentforceResponse> responses = 
            AgentforceMasterOrchestrationService.processAgentforceRequest(
                new List<AgentforceMasterOrchestrationService.AgentforceRequest>{request}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, responses.size());
        AgentforceMasterOrchestrationService.AgentforceResponse response = responses[0];
        System.assertEquals(true, response.success);
        System.assertEquals('EMAIL_DRAFT', response.responseType);
        System.assertNotEquals(null, response.content);
    }
    
    @IsTest
    static void testCustomerAnalysisRequest() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        AgentforceMasterOrchestrationService.AgentforceRequest request = 
            new AgentforceMasterOrchestrationService.AgentforceRequest();
        request.userId = UserInfo.getUserId();
        request.userMessage = '고객 이탈 위험도 분석해줘';
        request.recordId = testAccount.Id;
        request.additionalContext = '고객 분석 요청';
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.AgentforceResponse> responses = 
            AgentforceMasterOrchestrationService.processAgentforceRequest(
                new List<AgentforceMasterOrchestrationService.AgentforceRequest>{request}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, responses.size());
        AgentforceMasterOrchestrationService.AgentforceResponse response = responses[0];
        System.assertEquals(true, response.success);
        System.assertEquals('CUSTOMER_ANALYSIS', response.responseType);
        System.assertNotEquals(null, response.content);
        System.assert(response.content.contains('고객 이탈 위험도 분석'));
    }
    
    @IsTest
    static void testOrderLifecycleManagement() {
        // Given
        Order testOrder = [SELECT Id, OrderNumber FROM Order LIMIT 1];
        
        AgentforceMasterOrchestrationService.OrderLifecycleRequest request = 
            new AgentforceMasterOrchestrationService.OrderLifecycleRequest();
        request.orderId = testOrder.Id;
        request.lifecycleEvent = 'ORDER_ACTIVATED';
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.OrderLifecycleResult> results = 
            AgentforceMasterOrchestrationService.manageOrderLifecycle(
                new List<AgentforceMasterOrchestrationService.OrderLifecycleRequest>{request}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, results.size());
        AgentforceMasterOrchestrationService.OrderLifecycleResult result = results[0];
        System.assertEquals(true, result.success);
        System.assertNotEquals(0, result.completedActions.size());
        
        // 생성된 Task 확인
        List<Task> createdTasks = [SELECT Id, Subject FROM Task WHERE WhatId = :testOrder.Id];
        System.assertNotEquals(0, createdTasks.size());
    }
    
    @IsTest
    static void testPaymentCompletionLifecycle() {
        // Given
        Order testOrder = [SELECT Id, OrderNumber FROM Order LIMIT 1];
        PaymentStatus__c testPayment = [SELECT Id FROM PaymentStatus__c LIMIT 1];
        
        AgentforceMasterOrchestrationService.OrderLifecycleRequest request = 
            new AgentforceMasterOrchestrationService.OrderLifecycleRequest();
        request.orderId = testOrder.Id;
        request.lifecycleEvent = 'PAYMENT_COMPLETED';
        request.paymentId = testPayment.Id;
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.OrderLifecycleResult> results = 
            AgentforceMasterOrchestrationService.manageOrderLifecycle(
                new List<AgentforceMasterOrchestrationService.OrderLifecycleRequest>{request}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, results.size());
        AgentforceMasterOrchestrationService.OrderLifecycleResult result = results[0];
        System.assertEquals(true, result.success);
        System.assertNotEquals(0, result.completedActions.size());
    }
    
    @IsTest
    static void testPaymentOverdueLifecycle() {
        // Given
        Order testOrder = [SELECT Id, OrderNumber FROM Order LIMIT 1];
        PaymentStatus__c testPayment = [SELECT Id FROM PaymentStatus__c LIMIT 1];
        
        AgentforceMasterOrchestrationService.OrderLifecycleRequest request = 
            new AgentforceMasterOrchestrationService.OrderLifecycleRequest();
        request.orderId = testOrder.Id;
        request.lifecycleEvent = 'PAYMENT_OVERDUE';
        request.paymentId = testPayment.Id;
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.OrderLifecycleResult> results = 
            AgentforceMasterOrchestrationService.manageOrderLifecycle(
                new List<AgentforceMasterOrchestrationService.OrderLifecycleRequest>{request}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, results.size());
        AgentforceMasterOrchestrationService.OrderLifecycleResult result = results[0];
        System.assertEquals(true, result.success);
        System.assertNotEquals(0, result.completedActions.size());
        
        // 긴급 Task 생성 확인
        List<Task> overdueTask = [
            SELECT Id, Subject, Priority 
            FROM Task 
            WHERE WhatId = :testOrder.Id 
            AND Subject LIKE '%연체%'
        ];
        System.assertNotEquals(0, overdueTask.size());
        System.assertEquals('High', overdueTask[0].Priority);
    }
    
    @IsTest
    static void testDailyAutomation() {
        // Given - setup에서 생성된 데이터 사용
        
        // When
        Test.startTest();
        AgentforceMasterOrchestrationService.DailyAutomationResult result = 
            AgentforceMasterOrchestrationService.executeDailyAutomation(UserInfo.getUserId());
        Test.stopTest();
        
        // Then
        System.assertEquals(true, result.success);
        System.assertNotEquals(null, result.dailyBriefing);
        System.assertNotEquals(null, result.salesInsights);
        System.assertNotEquals(null, result.churnRiskCustomers);
        System.assertNotEquals(null, result.renewalOpportunities);
        System.assertNotEquals(null, result.recommendedActions);
        System.assertNotEquals(null, result.executionTime);
        
        // 브리핑 내용 검증
        System.assertNotEquals(0, result.dailyBriefing.todayMeetings.size());
        System.assertNotEquals(0, result.dailyBriefing.urgentItems.size());
    }
    
    @IsTest
    static void testDailyAutomationWithRecommendations() {
        // Given - 긴급 상황 시뮬레이션
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // 추가 긴급 Task 생성
        Task criticalTask = new Task();
        criticalTask.Subject = '매우 긴급한 고객 이슈';
        criticalTask.WhatId = testAccount.Id;
        criticalTask.ActivityDate = Date.today();
        criticalTask.Priority = 'High';
        criticalTask.Status = 'Not Started';
        insert criticalTask;
        
        // When
        Test.startTest();
        AgentforceMasterOrchestrationService.DailyAutomationResult result = 
            AgentforceMasterOrchestrationService.executeDailyAutomation(UserInfo.getUserId());
        Test.stopTest();
        
        // Then
        System.assertEquals(true, result.success);
        System.assertNotEquals(0, result.recommendedActions.size());
        
        // 긴급 추천 확인
        Boolean hasUrgentRecommendation = false;
        for (AgentforceMasterOrchestrationService.DailyRecommendation rec : result.recommendedActions) {
            if (rec.type == 'URGENT' && rec.priority == 'HIGH') {
                hasUrgentRecommendation = true;
                break;
            }
        }
        System.assertEquals(true, hasUrgentRecommendation);
    }
    
    @IsTest
    static void testCustomer360View() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // When
        Test.startTest();
        AgentforceMasterOrchestrationService.Customer360View result = 
            AgentforceMasterOrchestrationService.getCustomer360View(testAccount.Id);
        Test.stopTest();
        
        // Then
        System.assertEquals(true, result.success);
        System.assertNotEquals(null, result.customerInfo);
        System.assertNotEquals(null, result.churnRisk);
        System.assertNotEquals(null, result.contactTiming);
        System.assertNotEquals(null, result.renewalAnalysis);
        System.assertNotEquals(null, result.emailRecommendations);
        System.assertNotEquals(null, result.recentActivities);
        
        // 고객 정보 검증
        System.assertEquals(testAccount.Id, result.customerInfo.Id);
        System.assertEquals('Test Customer Corp', result.customerInfo.Name);
        
        // 이탈 위험도 검증
        System.assertNotEquals(null, result.churnRisk.riskLevel);
        System.assert(result.churnRisk.riskPercentage >= 0 && result.churnRisk.riskPercentage <= 100);
        
        // 갱신 분석 검증
        System.assertEquals(true, result.renewalAnalysis.success);
        System.assertNotEquals(null, result.renewalAnalysis.overallRenewalStrategy);
    }
    
    @IsTest
    static void testErrorHandling() {
        // Given - 잘못된 요청
        AgentforceMasterOrchestrationService.AgentforceRequest invalidRequest = 
            new AgentforceMasterOrchestrationService.AgentforceRequest();
        invalidRequest.userId = null; // null userId로 오류 유발
        invalidRequest.userMessage = '테스트 메시지';
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.AgentforceResponse> responses = 
            AgentforceMasterOrchestrationService.processAgentforceRequest(
                new List<AgentforceMasterOrchestrationService.AgentforceRequest>{invalidRequest}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, responses.size());
        AgentforceMasterOrchestrationService.AgentforceResponse response = responses[0];
        System.assertEquals(false, response.success);
        System.assertEquals('ERROR', response.responseType);
        System.assertNotEquals(null, response.errorMessage);
    }
    
    @IsTest
    static void testInvalidOrderLifecycleEvent() {
        // Given
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        
        AgentforceMasterOrchestrationService.OrderLifecycleRequest invalidRequest = 
            new AgentforceMasterOrchestrationService.OrderLifecycleRequest();
        invalidRequest.orderId = testOrder.Id;
        invalidRequest.lifecycleEvent = 'INVALID_EVENT';
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.OrderLifecycleResult> results = 
            AgentforceMasterOrchestrationService.manageOrderLifecycle(
                new List<AgentforceMasterOrchestrationService.OrderLifecycleRequest>{invalidRequest}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, results.size());
        AgentforceMasterOrchestrationService.OrderLifecycleResult result = results[0];
        System.assertEquals(false, result.success);
        System.assert(result.errorMessage.contains('지원되지 않는 라이프사이클'));
    }
    
    @IsTest
    static void testGeneralAgentforceRequest() {
        // Given
        AgentforceMasterOrchestrationService.AgentforceRequest generalRequest = 
            new AgentforceMasterOrchestrationService.AgentforceRequest();
        generalRequest.userId = UserInfo.getUserId();
        generalRequest.userMessage = '안녕하세요';
        generalRequest.additionalContext = '일반 질문';
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.AgentforceResponse> responses = 
            AgentforceMasterOrchestrationService.processAgentforceRequest(
                new List<AgentforceMasterOrchestrationService.AgentforceRequest>{generalRequest}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, responses.size());
        AgentforceMasterOrchestrationService.AgentforceResponse response = responses[0];
        System.assertEquals(true, response.success);
        System.assertEquals('GENERAL', response.responseType);
        System.assert(response.content.contains('SOCAR Sales Assistant'));
        System.assert(response.content.contains('어떤 도움이 필요하신가요'));
    }
    
    @IsTest
    static void testSlackNotificationRequest() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        AgentforceMasterOrchestrationService.AgentforceRequest slackRequest = 
            new AgentforceMasterOrchestrationService.AgentforceRequest();
        slackRequest.userId = UserInfo.getUserId();
        slackRequest.userMessage = '팀에 알림 보내줘';
        slackRequest.recordId = testAccount.Id;
        slackRequest.additionalContext = '중요한 고객 업데이트';
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.AgentforceResponse> responses = 
            AgentforceMasterOrchestrationService.processAgentforceRequest(
                new List<AgentforceMasterOrchestrationService.AgentforceRequest>{slackRequest}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, responses.size());
        AgentforceMasterOrchestrationService.AgentforceResponse response = responses[0];
        System.assertEquals('SLACK_NOTIFICATION', response.responseType);
        System.assertNotEquals(null, response.content);
    }
    
    @IsTest
    static void testMeetingFollowupRequest() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        AgentforceMasterOrchestrationService.AgentforceRequest meetingRequest = 
            new AgentforceMasterOrchestrationService.AgentforceRequest();
        meetingRequest.userId = UserInfo.getUserId();
        meetingRequest.userMessage = '미팅 후 처리해줘';
        meetingRequest.recordId = testAccount.Id;
        meetingRequest.additionalContext = '고객 Test Customer Corp와 미팅 완료. 제안서 필요. 다음주 후속 연락';
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.AgentforceResponse> responses = 
            AgentforceMasterOrchestrationService.processAgentforceRequest(
                new List<AgentforceMasterOrchestrationService.AgentforceRequest>{meetingRequest}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, responses.size());
        AgentforceMasterOrchestrationService.AgentforceResponse response = responses[0];
        System.assertEquals('MEETING_FOLLOWUP', response.responseType);
        System.assertNotEquals(null, response.content);
    }
    
    @IsTest
    static void testRenewalAnalysisRequest() {
        // Given
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        AgentforceMasterOrchestrationService.AgentforceRequest renewalRequest = 
            new AgentforceMasterOrchestrationService.AgentforceRequest();
        renewalRequest.userId = UserInfo.getUserId();
        renewalRequest.userMessage = '갱신 기회 분석해줘';
        renewalRequest.recordId = testAccount.Id;
        renewalRequest.additionalContext = '갱신 분석 요청';
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.AgentforceResponse> responses = 
            AgentforceMasterOrchestrationService.processAgentforceRequest(
                new List<AgentforceMasterOrchestrationService.AgentforceRequest>{renewalRequest}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, responses.size());
        AgentforceMasterOrchestrationService.AgentforceResponse response = responses[0];
        System.assertEquals('RENEWAL_ANALYSIS', response.responseType);
        System.assertNotEquals(null, response.content);
        System.assert(response.content.contains('갱신 기회 분석'));
    }
    
    @IsTest
    static void testOrderCompletionLifecycle() {
        // Given
        Order testOrder = [SELECT Id, OrderNumber FROM Order LIMIT 1];
        
        AgentforceMasterOrchestrationService.OrderLifecycleRequest request = 
            new AgentforceMasterOrchestrationService.OrderLifecycleRequest();
        request.orderId = testOrder.Id;
        request.lifecycleEvent = 'ORDER_COMPLETED';
        
        // When
        Test.startTest();
        List<AgentforceMasterOrchestrationService.OrderLifecycleResult> results = 
            AgentforceMasterOrchestrationService.manageOrderLifecycle(
                new List<AgentforceMasterOrchestrationService.OrderLifecycleRequest>{request}
            );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, results.size());
        AgentforceMasterOrchestrationService.OrderLifecycleResult result = results[0];
        System.assertEquals(true, result.success);
        System.assertNotEquals(0, result.completedActions.size());
        
        // 고객 만족도 Task 생성 확인
        List<Task> satisfactionTask = [
            SELECT Id, Subject 
            FROM Task 
            WHERE WhatId = :testOrder.Id 
            AND Subject LIKE '%만족도%'
        ];
        System.assertNotEquals(0, satisfactionTask.size());
    }
    
    // TestDataFactory 내부 클래스
    private class TestDataFactory {
        public static Account createAccount(String name) {
            return new Account(
                Name = name,
                Type = 'Customer',
                Industry = 'Technology',
                Phone = '02-1234-5678',
                AnnualRevenue = 1000000,
                NumberOfEmployees = 100
            );
        }
        
        public static Order createOrder(Id accountId) {
            return new Order(
                AccountId = accountId,
                Status = 'Draft',
                EffectiveDate = Date.today(),
                EndDate = Date.today().addYears(1),
                Type = 'New'
            );
        }
        
        public static Asset createAsset(Id accountId) {
            return new Asset(
                Name = 'Test Asset',
                AccountId = accountId,
                Status = 'Installed',
                InstallDate = Date.today().addDays(-365),
                UsageEndDate = Date.today().addDays(365)
            );
        }
    }
}
