/**
 * @description Agentforce 마스터 오케스트레이션 서비스 - 간단한 버전
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceSimpleMasterService {
    
    /**
     * Agentforce Agent가 호출하는 메인 엔트리포인트
     */
    @InvocableMethod(label='Process Agentforce Request' description='Agentforce 요청을 분석하고 처리하는 마스터 서비스')
    public static List<AgentforceResponse> processAgentforceRequest(List<AgentforceRequest> requests) {
        List<AgentforceResponse> responses = new List<AgentforceResponse>();
        
        for (AgentforceRequest request : requests) {
            try {
                AgentforceResponse response = routeAndProcessRequest(request);
                responses.add(response);
            } catch (Exception e) {
                AgentforceResponse errorResponse = new AgentforceResponse();
                errorResponse.success = false;
                errorResponse.errorMessage = e.getMessage();
                errorResponse.responseType = 'ERROR';
                responses.add(errorResponse);
            }
        }
        
        return responses;
    }
    
    // 일일 자동화 실행 (AuraEnabled 메소드)
    @AuraEnabled
    public static DailyAutomationResult executeDailyAutomation(Id userId) {
        try {
            DailyAutomationResult result = new DailyAutomationResult();
            
            // 1. 일일 브리핑 생성
            result.dailyBriefing = AgentforceSalesAssistantService.getDailyBriefing(userId);
            
            // 2. 고위험 고객 분석
            result.churnRiskCustomers = analyzeHighRiskCustomers(userId);
            
            // 3. 갱신 기회 식별
            result.renewalOpportunities = identifyRenewalOpportunities(userId);
            
            // 4. 추천 액션 생성
            result.recommendedActions = generateDailyRecommendations(result);
            
            result.success = true;
            result.executionTime = System.now();
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('일일 자동화 실행 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    // 고객 360도 뷰 제공
    @AuraEnabled(cacheable=true)
    public static Customer360View getCustomer360View(Id customerId) {
        try {
            Customer360View result = new Customer360View();
            
            // 1. 기본 고객 정보
            result.customerInfo = getCustomerBasicInfo(customerId);
            
            // 2. 이탈 위험도 분석
            AgentforceSimpleAnalyticsService.ChurnPredictionRequest churnRequest = 
                new AgentforceSimpleAnalyticsService.ChurnPredictionRequest();
            churnRequest.customerId = customerId;
            
            List<AgentforceSimpleAnalyticsService.ChurnPredictionResult> churnResults = 
                AgentforceSimpleAnalyticsService.predictCustomerChurnRisk(
                    new List<AgentforceSimpleAnalyticsService.ChurnPredictionRequest>{churnRequest}
                );
            
            result.churnRisk = churnResults[0];
            
            // 3. 최적 연락 시점
            result.contactTiming = AgentforceSimpleAnalyticsService.getOptimalContactTiming(customerId);
            
            // 4. 갱신 기회 분석
            result.renewalAnalysis = AgentforceSimpleAnalyticsService.analyzeRenewalOpportunity(customerId);
            
            // 5. 최근 활동 이력
            result.recentActivities = getRecentCustomerActivities(customerId);
            
            result.success = true;
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('고객 360도 뷰 조회 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    // Private Helper Methods
    
    private static AgentforceResponse routeAndProcessRequest(AgentforceRequest request) {
        AgentforceResponse response = new AgentforceResponse();
        
        // Intent 분석 및 라우팅
        String intent = analyzeUserIntent(request.userMessage);
        
        switch on intent {
            when 'DAILY_BRIEFING' {
                response = handleDailyBriefingRequest(request);
            }
            when 'EMAIL_GENERATION' {
                response = handleEmailGenerationRequest(request);
            }
            when 'CUSTOMER_ANALYSIS' {
                response = handleCustomerAnalysisRequest(request);
            }
            when 'SLACK_NOTIFICATION' {
                response = handleSlackNotificationRequest(request);
            }
            when else {
                response = handleGeneralRequest(request);
            }
        }
        
        return response;
    }
    
    private static String analyzeUserIntent(String userMessage) {
        String message = userMessage.toLowerCase();
        
        if (message.contains('오늘') && (message.contains('할일') || message.contains('브리핑'))) {
            return 'DAILY_BRIEFING';
        } else if (message.contains('이메일') && (message.contains('보내') || message.contains('작성'))) {
            return 'EMAIL_GENERATION';
        } else if (message.contains('고객') && (message.contains('분석') || message.contains('위험'))) {
            return 'CUSTOMER_ANALYSIS';
        } else if (message.contains('팀') && (message.contains('알림') || message.contains('공유'))) {
            return 'SLACK_NOTIFICATION';
        } else {
            return 'GENERAL';
        }
    }
    
    private static AgentforceResponse handleDailyBriefingRequest(AgentforceRequest request) {
        AgentforceResponse response = new AgentforceResponse();
        
        try {
            // Phase 1 서비스 호출
            AgentforceSalesAssistantService.DailyBriefingResult briefing = 
                AgentforceSalesAssistantService.getDailyBriefing(request.userId);
            
            // 응답 구성
            response.responseType = 'DAILY_BRIEFING';
            response.title = '오늘의 영업 브리핑';
            response.content = formatDailyBriefingResponse(briefing);
            response.success = true;
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = e.getMessage();
        }
        
        return response;
    }
    
    private static AgentforceResponse handleEmailGenerationRequest(AgentforceRequest request) {
        AgentforceResponse response = new AgentforceResponse();
        
        try {
            // 이메일 생성 서비스 호출
            AgentforceSimpleEmailActions.EmailRequest emailRequest = 
                new AgentforceSimpleEmailActions.EmailRequest();
            emailRequest.recordId = request.recordId;
            emailRequest.emailType = determineEmailType(request.userMessage);
            emailRequest.additionalContext = request.additionalContext;
            
            List<AgentforceSimpleEmailActions.EmailResult> emailResults = 
                AgentforceSimpleEmailActions.generateEmailDraft(
                    new List<AgentforceSimpleEmailActions.EmailRequest>{emailRequest}
                );
            
            response.responseType = 'EMAIL_DRAFT';
            response.title = '이메일 초안이 생성되었습니다';
            response.content = formatEmailResponse(emailResults[0]);
            response.success = emailResults[0].success;
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = e.getMessage();
        }
        
        return response;
    }
    
    private static AgentforceResponse handleCustomerAnalysisRequest(AgentforceRequest request) {
        AgentforceResponse response = new AgentforceResponse();
        
        try {
            // Phase 3 고급 분석 서비스 호출
            AgentforceSimpleAnalyticsService.ChurnPredictionRequest churnRequest = 
                new AgentforceSimpleAnalyticsService.ChurnPredictionRequest();
            churnRequest.customerId = request.recordId;
            
            List<AgentforceSimpleAnalyticsService.ChurnPredictionResult> churnResults = 
                AgentforceSimpleAnalyticsService.predictCustomerChurnRisk(
                    new List<AgentforceSimpleAnalyticsService.ChurnPredictionRequest>{churnRequest}
                );
            
            response.responseType = 'CUSTOMER_ANALYSIS';
            response.title = '고객 이탈 위험도 분석';
            response.content = formatChurnAnalysisResponse(churnResults[0]);
            response.success = churnResults[0].success;
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = e.getMessage();
        }
        
        return response;
    }
    
    private static AgentforceResponse handleSlackNotificationRequest(AgentforceRequest request) {
        AgentforceResponse response = new AgentforceResponse();
        
        try {
            // Phase 2 Slack 통합 서비스 호출
            AgentforceSimpleSlackService.SlackNotificationRequest slackRequest = 
                new AgentforceSimpleSlackService.SlackNotificationRequest();
            slackRequest.recordId = request.recordId;
            slackRequest.notificationType = 'GENERAL';
            slackRequest.message = request.additionalContext;
            
            List<AgentforceSimpleSlackService.SlackNotificationResult> slackResults = 
                AgentforceSimpleSlackService.sendTeamNotification(
                    new List<AgentforceSimpleSlackService.SlackNotificationRequest>{slackRequest}
                );
            
            response.responseType = 'SLACK_NOTIFICATION';
            response.title = 'Slack 알림이 발송되었습니다';
            response.content = slackResults[0].success ? 
                '팀 채널에 알림이 성공적으로 발송되었습니다.' : 
                '알림 발송에 실패했습니다: ' + slackResults[0].errorMessage;
            response.success = slackResults[0].success;
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = e.getMessage();
        }
        
        return response;
    }
    
    private static AgentforceResponse handleGeneralRequest(AgentforceRequest request) {
        AgentforceResponse response = new AgentforceResponse();
        
        response.responseType = 'GENERAL';
        response.title = 'SOCAR Sales Assistant';
        response.content = '안녕하세요! 어떤 도움이 필요하신가요?\n\n' +
            '다음과 같은 요청을 처리할 수 있습니다:\n' +
            '• "오늘 할 일 정리해줘" - 일일 브리핑\n' +
            '• "고객에게 이메일 보내줘" - 이메일 작성\n' +
            '• "고객 이탈 위험도 분석해줘" - 고객 분석\n' +
            '• "팀에 알림 보내줘" - Slack 알림';
        response.success = true;
        
        return response;
    }
    
    // Helper Methods for Data Processing
    
    private static List<AgentforceSimpleAnalyticsService.ChurnPredictionResult> analyzeHighRiskCustomers(Id userId) {
        // 영업담당자의 고위험 고객 분석
        List<Account> userAccounts = [
            SELECT Id 
            FROM Account 
            WHERE OwnerId = :userId 
            AND LastActivityDate < LAST_N_DAYS:30
            LIMIT 5
        ];
        
        List<AgentforceSimpleAnalyticsService.ChurnPredictionRequest> churnRequests = 
            new List<AgentforceSimpleAnalyticsService.ChurnPredictionRequest>();
        
        for (Account acc : userAccounts) {
            AgentforceSimpleAnalyticsService.ChurnPredictionRequest req = 
                new AgentforceSimpleAnalyticsService.ChurnPredictionRequest();
            req.customerId = acc.Id;
            churnRequests.add(req);
        }
        
        return churnRequests.isEmpty() ? 
            new List<AgentforceSimpleAnalyticsService.ChurnPredictionResult>() :
            AgentforceSimpleAnalyticsService.predictCustomerChurnRisk(churnRequests);
    }
    
    private static List<AgentforceSimpleAnalyticsService.AssetRenewalAnalysis> identifyRenewalOpportunities(Id userId) {
        // 영업담당자의 갱신 기회 식별
        List<Account> userAccounts = [
            SELECT Id 
            FROM Account 
            WHERE OwnerId = :userId 
            LIMIT 3
        ];
        
        List<AgentforceSimpleAnalyticsService.AssetRenewalAnalysis> allOpportunities = 
            new List<AgentforceSimpleAnalyticsService.AssetRenewalAnalysis>();
        
        for (Account acc : userAccounts) {
            AgentforceSimpleAnalyticsService.RenewalOpportunityResult result = 
                AgentforceSimpleAnalyticsService.analyzeRenewalOpportunity(acc.Id);
            
            if (result.success) {
                allOpportunities.addAll(result.renewalOpportunities);
            }
        }
        
        return allOpportunities;
    }
    
    private static List<DailyRecommendation> generateDailyRecommendations(DailyAutomationResult dailyResult) {
        List<DailyRecommendation> recommendations = new List<DailyRecommendation>();
        
        // 긴급 처리 추천
        if (dailyResult.dailyBriefing != null && !dailyResult.dailyBriefing.urgentItems.isEmpty()) {
            DailyRecommendation urgent = new DailyRecommendation();
            urgent.type = 'URGENT';
            urgent.title = '긴급 처리 필요';
            urgent.description = dailyResult.dailyBriefing.urgentItems.size() + '건의 긴급 사항이 있습니다.';
            urgent.priority = 'HIGH';
            recommendations.add(urgent);
        }
        
        // 고위험 고객 추천
        for (AgentforceSimpleAnalyticsService.ChurnPredictionResult churn : dailyResult.churnRiskCustomers) {
            if (churn.riskLevel == 'HIGH') {
                DailyRecommendation churnRec = new DailyRecommendation();
                churnRec.type = 'CHURN_PREVENTION';
                churnRec.title = '고위험 고객 관리';
                churnRec.description = churn.customerName + ' 고객의 이탈 위험도가 높습니다.';
                churnRec.priority = 'HIGH';
                recommendations.add(churnRec);
            }
        }
        
        return recommendations;
    }
    
    private static Account getCustomerBasicInfo(Id customerId) {
        return [
            SELECT Id, Name, Type, Industry, Phone, 
                   AnnualRevenue, NumberOfEmployees, CreatedDate, LastActivityDate
            FROM Account 
            WHERE Id = :customerId 
            LIMIT 1
        ];
    }
    
    private static List<Task> getRecentCustomerActivities(Id customerId) {
        return [
            SELECT Id, Subject, ActivityDate, Status, CreatedDate, Owner.Name
            FROM Task 
            WHERE WhatId = :customerId 
            ORDER BY CreatedDate DESC 
            LIMIT 10
        ];
    }
    
    // Response Formatting Methods
    
    private static String formatDailyBriefingResponse(AgentforceSalesAssistantService.DailyBriefingResult briefing) {
        String response = '📋 **오늘의 영업 브리핑**\n\n';
        
        response += '📅 **오늘 미팅 일정** (' + briefing.todayMeetings.size() + '건)\n';
        for (Event meeting : briefing.todayMeetings) {
            response += '• ' + meeting.StartDateTime.format('HH:mm') + ' - ' + meeting.Subject + '\n';
        }
        
        response += '\n🔔 **팔로업 필요 고객** (' + briefing.followUpNeeded.size() + '건)\n';
        for (Account customer : briefing.followUpNeeded) {
            response += '• ' + customer.Name + ' (마지막 활동: ' + customer.LastActivityDate?.format() + ')\n';
        }
        
        response += '\n⚠️ **긴급 처리 사항** (' + briefing.urgentItems.size() + '건)\n';
        for (Task urgent : briefing.urgentItems) {
            response += '• ' + urgent.Subject + ' (예정: ' + urgent.ActivityDate?.format() + ')\n';
        }
        
        return response;
    }
    
    private static String formatEmailResponse(AgentforceSimpleEmailActions.EmailResult emailResult) {
        return '📧 **제목**: ' + emailResult.emailSubject + '\n\n' +
               '📝 **본문**:\n' + emailResult.emailBody + '\n\n' +
               '📮 **수신자**: ' + emailResult.recipientEmail;
    }
    
    private static String formatChurnAnalysisResponse(AgentforceSimpleAnalyticsService.ChurnPredictionResult churnResult) {
        String response = '🎯 **고객 이탈 위험도 분석**\n\n';
        response += '📊 **위험도**: ' + churnResult.riskLevel + ' (' + churnResult.riskPercentage + '%)\n\n';
        
        if (!churnResult.riskFactors.isEmpty()) {
            response += '⚠️ **위험 요소**:\n';
            for (String factor : churnResult.riskFactors) {
                response += '• ' + factor + '\n';
            }
        }
        
        if (!churnResult.recommendedActions.isEmpty()) {
            response += '\n💡 **추천 액션**:\n';
            for (String action : churnResult.recommendedActions) {
                response += '• ' + action + '\n';
            }
        }
        
        return response;
    }
    
    private static String determineEmailType(String userMessage) {
        String message = userMessage.toLowerCase();
        
        if (message.contains('주문') || message.contains('order')) {
            return 'order';
        } else if (message.contains('결제') || message.contains('payment')) {
            return 'payment';
        } else if (message.contains('갱신') || message.contains('asset')) {
            return 'asset_renewal';
        } else {
            return 'general';
        }
    }
    
    // Wrapper Classes
    
    public class AgentforceRequest {
        @InvocableVariable(label='User ID' required=true)
        public String userId;
        
        @InvocableVariable(label='User Message' required=true)
        public String userMessage;
        
        @InvocableVariable(label='Record ID')
        public String recordId;
        
        @InvocableVariable(label='Additional Context')
        public String additionalContext;
    }
    
    public class AgentforceResponse {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String responseType;
        
        @InvocableVariable
        public String title;
        
        @InvocableVariable
        public String content;
        
        @InvocableVariable
        public String errorMessage;
        
        @InvocableVariable
        public DateTime timestamp;
        
        public AgentforceResponse() {
            this.success = false;
            this.timestamp = System.now();
        }
    }
    
    public class DailyAutomationResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public DateTime executionTime { get; set; }
        @AuraEnabled public AgentforceSalesAssistantService.DailyBriefingResult dailyBriefing { get; set; }
        @AuraEnabled public List<AgentforceSimpleAnalyticsService.ChurnPredictionResult> churnRiskCustomers { get; set; }
        @AuraEnabled public List<AgentforceSimpleAnalyticsService.AssetRenewalAnalysis> renewalOpportunities { get; set; }
        @AuraEnabled public List<DailyRecommendation> recommendedActions { get; set; }
        
        public DailyAutomationResult() {
            this.success = false;
            this.churnRiskCustomers = new List<AgentforceSimpleAnalyticsService.ChurnPredictionResult>();
            this.renewalOpportunities = new List<AgentforceSimpleAnalyticsService.AssetRenewalAnalysis>();
            this.recommendedActions = new List<DailyRecommendation>();
        }
    }
    
    public class DailyRecommendation {
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String priority { get; set; } // HIGH, MEDIUM, LOW
    }
    
    public class Customer360View {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public Account customerInfo { get; set; }
        @AuraEnabled public AgentforceSimpleAnalyticsService.ChurnPredictionResult churnRisk { get; set; }
        @AuraEnabled public AgentforceSimpleAnalyticsService.ContactTimingRecommendation contactTiming { get; set; }
        @AuraEnabled public AgentforceSimpleAnalyticsService.RenewalOpportunityResult renewalAnalysis { get; set; }
        @AuraEnabled public List<Task> recentActivities { get; set; }
        
        public Customer360View() {
            this.success = false;
            this.recentActivities = new List<Task>();
        }
    }
}
