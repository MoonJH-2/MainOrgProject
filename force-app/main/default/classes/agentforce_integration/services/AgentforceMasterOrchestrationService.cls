/**
 * @description Agentforce Sales Assistant 마스터 오케스트레이션 서비스
 * 모든 Phase의 기능을 통합하고 연결하는 중앙 제어 서비스
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceMasterOrchestrationService {
    
    /**
     * Agentforce Agent가 호출하는 메인 엔트리포인트
     * 사용자 요청을 분석하고 적절한 서비스로 라우팅
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
    
    /**
     * 완전 자동화된 Order Lifecycle 관리
     */
    @InvocableMethod(label='Manage Order Lifecycle' description='Order 전체 라이프사이클 자동 관리')
    public static List<OrderLifecycleResult> manageOrderLifecycle(List<OrderLifecycleRequest> requests) {
        List<OrderLifecycleResult> results = new List<OrderLifecycleResult>();
        
        for (OrderLifecycleRequest request : requests) {
            try {
                OrderLifecycleResult result = processOrderLifecycle(request);
                results.add(result);
            } catch (Exception e) {
                OrderLifecycleResult errorResult = new OrderLifecycleResult();
                errorResult.success = false;
                errorResult.errorMessage = e.getMessage();
                results.add(errorResult);
            }
        }
        
        return results;
    }
    
    /**
     * 일일 영업 활동 완전 자동화
     */
    @AuraEnabled
    public static DailyAutomationResult executeDailyAutomation(Id userId) {
        try {
            DailyAutomationResult result = new DailyAutomationResult();
            
            // 1. 일일 브리핑 생성 (Phase 1)
            AgentforceSalesAssistantService.DailyBriefingResult briefing = 
                AgentforceSalesAssistantService.getDailyBriefing(userId);
            result.dailyBriefing = briefing;
            
            // 2. 실시간 영업 인사이트 (Phase 3)
            AgentforceAdvancedAnalyticsService.SalesInsightResult insights = 
                AgentforceAdvancedAnalyticsService.getRealTimeSalesInsights(userId);
            result.salesInsights = insights;
            
            // 3. 긴급 처리 필요 고객 분석 (Phase 3)
            result.churnRiskCustomers = analyzeHighRiskCustomers(userId);
            
            // 4. 갱신 기회 식별 (Phase 3)
            result.renewalOpportunities = identifyRenewalOpportunities(userId);
            
            // 5. 추천 액션 생성
            result.recommendedActions = generateDailyRecommendations(result);
            
            // 6. Slack 알림 발송 (Phase 2)
            if (result.recommendedActions.size() > 0) {
                sendDailySummaryToSlack(userId, result);
            }
            
            result.success = true;
            result.executionTime = System.now();
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('일일 자동화 실행 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * 고객별 360도 뷰 제공
     */
    @AuraEnabled(cacheable=true)
    public static Customer360View getCustomer360View(Id customerId) {
        try {
            Customer360View result = new Customer360View();
            
            // 1. 기본 고객 정보
            result.customerInfo = getCustomerBasicInfo(customerId);
            
            // 2. 이탈 위험도 분석 (Phase 3)
            AgentforceAdvancedAnalyticsService.ChurnPredictionRequest churnRequest = 
                new AgentforceAdvancedAnalyticsService.ChurnPredictionRequest();
            churnRequest.customerId = customerId;
            
            List<AgentforceAdvancedAnalyticsService.ChurnPredictionRequest> churnRequests = 
                new List<AgentforceAdvancedAnalyticsService.ChurnPredictionRequest>{churnRequest};
            
            List<AgentforceAdvancedAnalyticsService.ChurnPredictionResult> churnResults = 
                AgentforceAdvancedAnalyticsService.predictCustomerChurnRisk(churnRequests);
            
            result.churnRisk = churnResults[0];
            
            // 3. 최적 연락 시점 (Phase 3)
            result.contactTiming = AgentforceAdvancedAnalyticsService.getOptimalContactTiming(customerId);
            
            // 4. 갱신 기회 분석 (Phase 3)
            result.renewalAnalysis = AgentforceAdvancedAnalyticsService.analyzeRenewalOpportunity(customerId);
            
            // 5. 최근 이메일 분석 (Phase 1)
            result.emailRecommendations = getEmailRecommendations(customerId);
            
            // 6. 최근 활동 이력
            result.recentActivities = getRecentCustomerActivities(customerId);
            
            // 7. ROI 분석 (기존 AssetROIAnalysisService 연동)
            result.roiAnalysis = getCustomerROIAnalysis(customerId);
            
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
            when 'MEETING_FOLLOWUP' {
                response = handleMeetingFollowupRequest(request);
            }
            when 'RENEWAL_ANALYSIS' {
                response = handleRenewalAnalysisRequest(request);
            }
            when else {
                response = handleGeneralRequest(request);
            }
        }
        
        // 응답 로깅
        logAgentforceInteraction(request, response);
        
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
        } else if (message.contains('미팅') && message.contains('후')) {
            return 'MEETING_FOLLOWUP';
        } else if (message.contains('갱신') || message.contains('renewal')) {
            return 'RENEWAL_ANALYSIS';
        } else {
            return 'GENERAL';
        }
    }
    
    private static AgentforceResponse handleDailyBriefingRequest(AgentforceRequest request) {
        AgentforceResponse response = new AgentforceResponse();
        
        // Phase 1 서비스 호출
        AgentforceSalesAssistantService.DailyBriefingResult briefing = 
            AgentforceSalesAssistantService.getDailyBriefing(request.userId);
        
        // 응답 구성
        response.responseType = 'DAILY_BRIEFING';
        response.title = '오늘의 영업 브리핑';
        response.content = formatDailyBriefingResponse(briefing);
        response.success = true;
        
        return response;
    }
    
    private static AgentforceResponse handleEmailGenerationRequest(AgentforceRequest request) {
        AgentforceResponse response = new AgentforceResponse();
        
        // Phase 1 이메일 통합 서비스 호출
        AgentforceEmailIntegrationService.EmailGenerationRequest emailRequest = 
            new AgentforceEmailIntegrationService.EmailGenerationRequest();
        emailRequest.recordId = request.recordId;
        emailRequest.emailType = determineEmailType(request.userMessage);
        emailRequest.agentforceRecommendations = request.additionalContext;
        
        List<AgentforceEmailIntegrationService.EmailGenerationRequest> emailRequests = 
            new List<AgentforceEmailIntegrationService.EmailGenerationRequest>{emailRequest};
        
        List<AgentforceEmailIntegrationService.EmailGenerationResult> emailResults = 
            AgentforceEmailIntegrationService.generateSmartEmail(emailRequests);
        
        response.responseType = 'EMAIL_DRAFT';
        response.title = '이메일 초안이 생성되었습니다';
        response.content = formatEmailResponse(emailResults[0]);
        response.success = emailResults[0].success;
        
        return response;
    }
    
    private static AgentforceResponse handleCustomerAnalysisRequest(AgentforceRequest request) {
        AgentforceResponse response = new AgentforceResponse();
        
        // Phase 3 고급 분석 서비스 호출
        AgentforceAdvancedAnalyticsService.ChurnPredictionRequest churnRequest = 
            new AgentforceAdvancedAnalyticsService.ChurnPredictionRequest();
        churnRequest.customerId = request.recordId;
        
        List<AgentforceAdvancedAnalyticsService.ChurnPredictionRequest> churnRequests = 
            new List<AgentforceAdvancedAnalyticsService.ChurnPredictionRequest>{churnRequest};
        
        List<AgentforceAdvancedAnalyticsService.ChurnPredictionResult> churnResults = 
            AgentforceAdvancedAnalyticsService.predictCustomerChurnRisk(churnRequests);
        
        response.responseType = 'CUSTOMER_ANALYSIS';
        response.title = '고객 이탈 위험도 분석';
        response.content = formatChurnAnalysisResponse(churnResults[0]);
        response.success = churnResults[0].success;
        
        return response;
    }
    
    private static AgentforceResponse handleSlackNotificationRequest(AgentforceRequest request) {
        AgentforceResponse response = new AgentforceResponse();
        
        // Phase 2 Slack 통합 서비스 호출
        AgentforceSlackIntegrationService.SlackNotificationResult slackResult = 
            AgentforceSlackIntegrationService.notifyTeamActivity(
                request.recordId, 
                'GENERAL', 
                request.additionalContext
            );
        
        response.responseType = 'SLACK_NOTIFICATION';
        response.title = 'Slack 알림이 발송되었습니다';
        response.content = slackResult.success ? 
            '팀 채널에 알림이 성공적으로 발송되었습니다.' : 
            '알림 발송에 실패했습니다: ' + slackResult.errorMessage;
        response.success = slackResult.success;
        
        return response;
    }
    
    private static AgentforceResponse handleMeetingFollowupRequest(AgentforceRequest request) {
        AgentforceResponse response = new AgentforceResponse();
        
        // Phase 1 미팅 후속 처리 서비스 호출
        AgentforceSalesAssistantService.PostMeetingRequest meetingRequest = 
            new AgentforceSalesAssistantService.PostMeetingRequest();
        meetingRequest.customerId = request.recordId;
        meetingRequest.customerName = extractCustomerName(request.additionalContext);
        meetingRequest.meetingNotes = request.additionalContext;
        meetingRequest.needsProposal = request.additionalContext.contains('제안서');
        meetingRequest.followUpDays = extractFollowUpDays(request.additionalContext);
        
        AgentforceSalesAssistantService.PostMeetingResult meetingResult = 
            AgentforceSalesAssistantService.processMeetingFollowUp(
                new List<AgentforceSalesAssistantService.PostMeetingRequest>{meetingRequest}
            )[0];
        
        response.responseType = 'MEETING_FOLLOWUP';
        response.title = '미팅 후속 처리 완료';
        response.content = formatMeetingFollowupResponse(meetingResult);
        response.success = meetingResult.success;
        
        return response;
    }
    
    private static AgentforceResponse handleRenewalAnalysisRequest(AgentforceRequest request) {
        AgentforceResponse response = new AgentforceResponse();
        
        // Phase 3 갱신 분석 서비스 호출
        AgentforceAdvancedAnalyticsService.RenewalOpportunityResult renewalResult = 
            AgentforceAdvancedAnalyticsService.analyzeRenewalOpportunity(request.recordId);
        
        response.responseType = 'RENEWAL_ANALYSIS';
        response.title = '갱신 기회 분석';
        response.content = formatRenewalAnalysisResponse(renewalResult);
        response.success = renewalResult.success;
        
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
            '• "팀에 알림 보내줘" - Slack 알림\n' +
            '• "미팅 후속 처리해줘" - 미팅 관리\n' +
            '• "갱신 기회 분석해줘" - 갱신 분석';
        response.success = true;
        
        return response;
    }
    
    private static OrderLifecycleResult processOrderLifecycle(OrderLifecycleRequest request) {
        OrderLifecycleResult result = new OrderLifecycleResult();
        
        // 1. Order 정보 조회
        Order orderInfo = [SELECT Id, OrderNumber, Status, AccountId FROM Order WHERE Id = :request.orderId LIMIT 1];
        
        switch on request.lifecycleEvent {
            when 'ORDER_ACTIVATED' {
                result = handleOrderActivation(orderInfo);
            }
            when 'PAYMENT_COMPLETED' {
                result = handlePaymentCompletion(orderInfo, request.paymentId);
            }
            when 'PAYMENT_OVERDUE' {
                result = handlePaymentOverdue(orderInfo, request.paymentId);
            }
            when 'ORDER_COMPLETED' {
                result = handleOrderCompletion(orderInfo);
            }
            when else {
                result.success = false;
                result.errorMessage = '지원되지 않는 라이프사이클 이벤트입니다.';
            }
        }
        
        return result;
    }
    
    private static OrderLifecycleResult handleOrderActivation(Order orderInfo) {
        OrderLifecycleResult result = new OrderLifecycleResult();
        List<String> completedActions = new List<String>();
        
        try {
            // 1. Slack 채널 생성 (Phase 2)
            AgentforceSlackIntegrationService.SlackChannelRequest channelRequest = 
                new AgentforceSlackIntegrationService.SlackChannelRequest();
            channelRequest.orderId = orderInfo.Id;
            channelRequest.includeTeamMembers = true;
            
            List<AgentforceSlackIntegrationService.SlackChannelResult> channelResults = 
                AgentforceSlackIntegrationService.createOrderSlackChannel(
                    new List<AgentforceSlackIntegrationService.SlackChannelRequest>{channelRequest}
                );
            
            if (channelResults[0].success) {
                completedActions.add('Slack 채널 생성: ' + channelResults[0].channelName);
            }
            
            // 2. 초기 환영 이메일 생성 (Phase 1)
            AgentforceEmailIntegrationService.EmailGenerationRequest emailRequest = 
                new AgentforceEmailIntegrationService.EmailGenerationRequest();
            emailRequest.recordId = orderInfo.Id;
            emailRequest.emailType = 'order';
            emailRequest.subType = 'Order_Confirmation';
            
            List<AgentforceEmailIntegrationService.EmailGenerationResult> emailResults = 
                AgentforceEmailIntegrationService.generateSmartEmail(
                    new List<AgentforceEmailIntegrationService.EmailGenerationRequest>{emailRequest}
                );
            
            if (emailResults[0].success) {
                completedActions.add('환영 이메일 생성 완료');
            }
            
            // 3. 초기 Task 생성
            createInitialOrderTasks(orderInfo.Id);
            completedActions.add('초기 Task 생성 완료');
            
            result.success = true;
            result.completedActions = completedActions;
            result.message = 'Order ' + orderInfo.OrderNumber + ' 활성화 처리가 완료되었습니다.';
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    private static OrderLifecycleResult handlePaymentCompletion(Order orderInfo, String paymentId) {
        OrderLifecycleResult result = new OrderLifecycleResult();
        List<String> completedActions = new List<String>();
        
        try {
            // 1. Slack 알림 발송 (Phase 2)
            AgentforceSlackIntegrationService.PaymentNotificationRequest notificationRequest = 
                new AgentforceSlackIntegrationService.PaymentNotificationRequest();
            notificationRequest.paymentId = paymentId;
            notificationRequest.notificationType = 'PAYMENT_COMPLETED';
            
            List<AgentforceSlackIntegrationService.PaymentNotificationResult> notificationResults = 
                AgentforceSlackIntegrationService.sendPaymentNotification(
                    new List<AgentforceSlackIntegrationService.PaymentNotificationRequest>{notificationRequest}
                );
            
            if (notificationResults[0].success) {
                completedActions.add('Slack 결제 완료 알림 발송');
            }
            
            // 2. 다음 결제 안내 이메일 예약
            createNextPaymentReminderTask(orderInfo.Id, paymentId);
            completedActions.add('다음 결제 안내 Task 생성');
            
            // 3. 완납 여부 확인 및 Asset 생성 체크
            if (isOrderFullyPaid(orderInfo.Id)) {
                completedActions.add('완납 감지 - Asset 생성 프로세스 시작');
            }
            
            result.success = true;
            result.completedActions = completedActions;
            result.message = 'Payment 완료 처리가 완료되었습니다.';
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    private static OrderLifecycleResult handlePaymentOverdue(Order orderInfo, String paymentId) {
        OrderLifecycleResult result = new OrderLifecycleResult();
        List<String> completedActions = new List<String>();
        
        try {
            // 1. 긴급 Slack 알림 (Phase 2)
            AgentforceSlackIntegrationService.PaymentNotificationRequest notificationRequest = 
                new AgentforceSlackIntegrationService.PaymentNotificationRequest();
            notificationRequest.paymentId = paymentId;
            notificationRequest.notificationType = 'PAYMENT_OVERDUE';
            
            List<AgentforceSlackIntegrationService.PaymentNotificationResult> notificationResults = 
                AgentforceSlackIntegrationService.sendPaymentNotification(
                    new List<AgentforceSlackIntegrationService.PaymentNotificationRequest>{notificationRequest}
                );
            
            if (notificationResults[0].success) {
                completedActions.add('긴급 연체 알림 발송');
            }
            
            // 2. 연체 처리 Task 생성
            createOverdueHandlingTask(orderInfo.Id, paymentId);
            completedActions.add('연체 처리 Task 생성');
            
            // 3. 고객 이탈 위험도 재계산 (Phase 3)
            AgentforceAdvancedAnalyticsService.ChurnPredictionRequest churnRequest = 
                new AgentforceAdvancedAnalyticsService.ChurnPredictionRequest();
            churnRequest.customerId = orderInfo.AccountId;
            
            List<AgentforceAdvancedAnalyticsService.ChurnPredictionResult> churnResults = 
                AgentforceAdvancedAnalyticsService.predictCustomerChurnRisk(
                    new List<AgentforceAdvancedAnalyticsService.ChurnPredictionRequest>{churnRequest}
                );
            
            if (churnResults[0].success) {
                completedActions.add('고객 이탈 위험도 재계산 완료: ' + churnResults[0].riskLevel);
            }
            
            result.success = true;
            result.completedActions = completedActions;
            result.message = 'Payment 연체 처리가 완료되었습니다.';
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    private static OrderLifecycleResult handleOrderCompletion(Order orderInfo) {
        OrderLifecycleResult result = new OrderLifecycleResult();
        List<String> completedActions = new List<String>();
        
        try {
            // 1. 완료 축하 메시지 발송
            completedActions.add('Order 완료 축하 메시지 준비');
            
            // 2. 갱신 기회 분석 시작 (Phase 3)
            AgentforceAdvancedAnalyticsService.RenewalOpportunityResult renewalResult = 
                AgentforceAdvancedAnalyticsService.analyzeRenewalOpportunity(orderInfo.AccountId);
            
            if (renewalResult.success) {
                completedActions.add('갱신 기회 분석 완료');
            }
            
            // 3. 고객 만족도 조사 Task 생성
            createCustomerSatisfactionTask(orderInfo.Id);
            completedActions.add('고객 만족도 조사 Task 생성');
            
            result.success = true;
            result.completedActions = completedActions;
            result.message = 'Order 완료 처리가 완료되었습니다.';
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    // Additional Helper Methods
    
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
    
    private static String formatEmailResponse(AgentforceEmailIntegrationService.EmailGenerationResult emailResult) {
        return '📧 **제목**: ' + emailResult.emailSubject + '\n\n' +
               '📝 **본문**:\n' + emailResult.emailBody + '\n\n' +
               '📮 **수신자**: ' + emailResult.recipientEmail;
    }
    
    private static String formatChurnAnalysisResponse(AgentforceAdvancedAnalyticsService.ChurnPredictionResult churnResult) {
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
    
    private static String formatMeetingFollowupResponse(AgentforceSalesAssistantService.PostMeetingResult meetingResult) {
        String response = '🤝 **미팅 후속 처리 완료**\n\n';
        response += '📝 콜 로그 생성: ' + meetingResult.callLogId + '\n';
        
        if (!meetingResult.followUpTaskIds.isEmpty()) {
            response += '✅ 후속 Task 생성: ' + meetingResult.followUpTaskIds.size() + '건\n';
        }
        
        return response;
    }
    
    private static String formatRenewalAnalysisResponse(AgentforceAdvancedAnalyticsService.RenewalOpportunityResult renewalResult) {
        String response = '🔄 **갱신 기회 분석**\n\n';
        response += '📈 **전체 전략**: ' + renewalResult.overallRenewalStrategy + '\n\n';
        
        if (!renewalResult.renewalOpportunities.isEmpty()) {
            response += '🎯 **갱신 기회** (' + renewalResult.renewalOpportunities.size() + '건):\n';
            for (AgentforceAdvancedAnalyticsService.AssetRenewalAnalysis opp : renewalResult.renewalOpportunities) {
                response += '• ' + opp.assetName + ' (' + opp.renewalProbability + '% 확률, ' + 
                           opp.urgencyLevel + ' 우선순위)\n';
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
    
    private static String extractCustomerName(String context) {
        // 간단한 고객명 추출 로직 (실제로는 더 정교한 NLP 필요)
        if (String.isNotBlank(context) && context.contains('고객')) {
            return context.substringBefore(' ').substringAfter('고객');
        }
        return '고객';
    }
    
    private static Integer extractFollowUpDays(String context) {
        // 후속 연락 일수 추출 로직
        if (context.contains('다음주')) {
            return 7;
        } else if (context.contains('내일')) {
            return 1;
        } else {
            return 3; // 기본값
        }
    }
    
    private static void logAgentforceInteraction(AgentforceRequest request, AgentforceResponse response) {
        // 상호작용 로깅 (향후 ML 학습 데이터로 활용)
        System.debug('Agentforce Interaction - User: ' + request.userMessage + 
                     ', Response Type: ' + response.responseType + 
                     ', Success: ' + response.success);
    }
    
    private static List<AgentforceAdvancedAnalyticsService.ChurnPredictionResult> analyzeHighRiskCustomers(Id userId) {
        // 영업담당자의 고위험 고객 분석
        List<Account> userAccounts = [
            SELECT Id 
            FROM Account 
            WHERE OwnerId = :userId 
            AND LastActivityDate < LAST_N_DAYS:30
            LIMIT 5
        ];
        
        List<AgentforceAdvancedAnalyticsService.ChurnPredictionRequest> churnRequests = 
            new List<AgentforceAdvancedAnalyticsService.ChurnPredictionRequest>();
        
        for (Account acc : userAccounts) {
            AgentforceAdvancedAnalyticsService.ChurnPredictionRequest req = 
                new AgentforceAdvancedAnalyticsService.ChurnPredictionRequest();
            req.customerId = acc.Id;
            churnRequests.add(req);
        }
        
        return churnRequests.isEmpty() ? 
            new List<AgentforceAdvancedAnalyticsService.ChurnPredictionResult>() :
            AgentforceAdvancedAnalyticsService.predictCustomerChurnRisk(churnRequests);
    }
    
    private static List<AgentforceAdvancedAnalyticsService.AssetRenewalAnalysis> identifyRenewalOpportunities(Id userId) {
        // 영업담당자의 갱신 기회 식별
        List<Account> userAccounts = [
            SELECT Id 
            FROM Account 
            WHERE OwnerId = :userId 
            LIMIT 3
        ];
        
        List<AgentforceAdvancedAnalyticsService.AssetRenewalAnalysis> allOpportunities = 
            new List<AgentforceAdvancedAnalyticsService.AssetRenewalAnalysis>();
        
        for (Account acc : userAccounts) {
            AgentforceAdvancedAnalyticsService.RenewalOpportunityResult result = 
                AgentforceAdvancedAnalyticsService.analyzeRenewalOpportunity(acc.Id);
            
            if (result.success) {
                allOpportunities.addAll(result.renewalOpportunities);
            }
        }
        
        return allOpportunities;
    }
    
    private static List<DailyRecommendation> generateDailyRecommendations(DailyAutomationResult dailyResult) {
        List<DailyRecommendation> recommendations = new List<DailyRecommendation>();
        
        // 긴급 처리 추천
        if (!dailyResult.dailyBriefing.urgentItems.isEmpty()) {
            DailyRecommendation urgent = new DailyRecommendation();
            urgent.type = 'URGENT';
            urgent.title = '긴급 처리 필요';
            urgent.description = dailyResult.dailyBriefing.urgentItems.size() + '건의 긴급 사항이 있습니다.';
            urgent.priority = 'HIGH';
            recommendations.add(urgent);
        }
        
        // 고위험 고객 추천
        for (AgentforceAdvancedAnalyticsService.ChurnPredictionResult churn : dailyResult.churnRiskCustomers) {
            if (churn.riskLevel == 'HIGH') {
                DailyRecommendation churnRec = new DailyRecommendation();
                churnRec.type = 'CHURN_PREVENTION';
                churnRec.title = '고위험 고객 관리';
                churnRec.description = churn.customerName + ' 고객의 이탈 위험도가 높습니다.';
                churnRec.priority = 'HIGH';
                recommendations.add(churnRec);
            }
        }
        
        // 갱신 기회 추천
        for (AgentforceAdvancedAnalyticsService.AssetRenewalAnalysis renewal : dailyResult.renewalOpportunities) {
            if (renewal.urgencyLevel == 'HIGH') {
                DailyRecommendation renewalRec = new DailyRecommendation();
                renewalRec.type = 'RENEWAL_OPPORTUNITY';
                renewalRec.title = '갱신 기회';
                renewalRec.description = renewal.assetName + ' 갱신 기회를 놓치지 마세요.';
                renewalRec.priority = 'MEDIUM';
                recommendations.add(renewalRec);
            }
        }
        
        return recommendations;
    }
    
    private static void sendDailySummaryToSlack(Id userId, DailyAutomationResult dailyResult) {
        // 일일 요약을 Slack으로 발송
        String summary = '📊 **일일 영업 요약**\n\n';
        summary += '• 긴급 사항: ' + dailyResult.dailyBriefing.urgentItems.size() + '건\n';
        summary += '• 고위험 고객: ' + dailyResult.churnRiskCustomers.size() + '건\n';
        summary += '• 갱신 기회: ' + dailyResult.renewalOpportunities.size() + '건\n';
        
        // 개인 DM 발송 로직 (실제 구현 시 Slack API 연동 필요)
        System.debug('Daily Summary for User ' + userId + ': ' + summary);
    }
    
    // 기타 Helper Methods
    private static void createInitialOrderTasks(Id orderId) {
        List<Task> tasks = new List<Task>();
        
        Task onboardingTask = new Task();
        onboardingTask.Subject = '고객 온보딩 미팅 일정 조율';
        onboardingTask.WhatId = orderId;
        onboardingTask.ActivityDate = Date.today().addDays(1);
        onboardingTask.Priority = 'High';
        onboardingTask.Status = 'Not Started';
        tasks.add(onboardingTask);
        
        Task emailTask = new Task();
        emailTask.Subject = '첫 번째 납부 안내 이메일 발송';
        emailTask.WhatId = orderId;
        emailTask.ActivityDate = Date.today().addDays(2);
        emailTask.Priority = 'Normal';
        emailTask.Status = 'Not Started';
        tasks.add(emailTask);
        
        insert tasks;
    }
    
    private static void createNextPaymentReminderTask(Id orderId, String paymentId) {
        Task reminderTask = new Task();
        reminderTask.Subject = '다음 결제 안내 이메일 발송';
        reminderTask.WhatId = orderId;
        reminderTask.ActivityDate = Date.today().addDays(30); // 다음 분기 전
        reminderTask.Priority = 'Normal';
        reminderTask.Status = 'Not Started';
        reminderTask.Description = 'Payment ID: ' + paymentId;
        
        insert reminderTask;
    }
    
    private static Boolean isOrderFullyPaid(Id orderId) {
        List<PaymentStatus__c> payments = [
            SELECT Status__c 
            FROM PaymentStatus__c 
            WHERE Order__c = :orderId
        ];
        
        for (PaymentStatus__c payment : payments) {
            if (payment.Status__c != '완납') {
                return false;
            }
        }
        
        return !payments.isEmpty();
    }
    
    private static void createOverdueHandlingTask(Id orderId, String paymentId) {
        Task overdueTask = new Task();
        overdueTask.Subject = '연체 고객 즉시 연락';
        overdueTask.WhatId = orderId;
        overdueTask.ActivityDate = Date.today();
        overdueTask.Priority = 'High';
        overdueTask.Status = 'Not Started';
        overdueTask.Description = 'Payment ID: ' + paymentId + ' - 즉시 고객 연락 필요';
        
        insert overdueTask;
    }
    
    private static void createCustomerSatisfactionTask(Id orderId) {
        Task satisfactionTask = new Task();
        satisfactionTask.Subject = '고객 만족도 조사 실시';
        satisfactionTask.WhatId = orderId;
        satisfactionTask.ActivityDate = Date.today().addDays(7);
        satisfactionTask.Priority = 'Normal';
        satisfactionTask.Status = 'Not Started';
        
        insert satisfactionTask;
    }
    
    private static Account getCustomerBasicInfo(Id customerId) {
        return [
            SELECT Id, Name, Type, Industry, Phone, BillingAddress, 
                   AnnualRevenue, NumberOfEmployees, CreatedDate, LastActivityDate
            FROM Account 
            WHERE Id = :customerId 
            LIMIT 1
        ];
    }
    
    private static List<AgentforceEmailIntegrationService.EmailGenerationResult> getEmailRecommendations(Id customerId) {
        // 고객별 최적 이메일 추천
        AgentforceEmailIntegrationService.EmailGenerationRequest request = 
            new AgentforceEmailIntegrationService.EmailGenerationRequest();
        request.recordId = customerId;
        request.emailType = 'general';
        
        return AgentforceEmailIntegrationService.generateSmartEmail(
            new List<AgentforceEmailIntegrationService.EmailGenerationRequest>{request}
        );
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
    
    private static AssetROIAnalysisService.AssetROIResult getCustomerROIAnalysis(Id customerId) {
        // 고객의 주요 Asset ROI 분석
        List<Asset> customerAssets = [
            SELECT Id 
            FROM Asset 
            WHERE AccountId = :customerId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        if (!customerAssets.isEmpty()) {
            return AssetROIAnalysisService.calculateAssetROI(customerAssets[0].Id);
        }
        
        return null;
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
    
    public class OrderLifecycleRequest {
        @InvocableVariable(label='Order ID' required=true)
        public String orderId;
        
        @InvocableVariable(label='Lifecycle Event' required=true)
        public String lifecycleEvent; // ORDER_ACTIVATED, PAYMENT_COMPLETED, PAYMENT_OVERDUE, ORDER_COMPLETED
        
        @InvocableVariable(label='Payment ID')
        public String paymentId;
    }
    
    public class OrderLifecycleResult {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String message;
        
        @InvocableVariable
        public List<String> completedActions;
        
        @InvocableVariable
        public String errorMessage;
        
        public OrderLifecycleResult() {
            this.success = false;
            this.completedActions = new List<String>();
        }
    }
    
    public class DailyAutomationResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public DateTime executionTime { get; set; }
        @AuraEnabled public AgentforceSalesAssistantService.DailyBriefingResult dailyBriefing { get; set; }
        @AuraEnabled public AgentforceAdvancedAnalyticsService.SalesInsightResult salesInsights { get; set; }
        @AuraEnabled public List<AgentforceAdvancedAnalyticsService.ChurnPredictionResult> churnRiskCustomers { get; set; }
        @AuraEnabled public List<AgentforceAdvancedAnalyticsService.AssetRenewalAnalysis> renewalOpportunities { get; set; }
        @AuraEnabled public List<DailyRecommendation> recommendedActions { get; set; }
        
        public DailyAutomationResult() {
            this.success = false;
            this.churnRiskCustomers = new List<AgentforceAdvancedAnalyticsService.ChurnPredictionResult>();
            this.renewalOpportunities = new List<AgentforceAdvancedAnalyticsService.AssetRenewalAnalysis>();
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
        @AuraEnabled public AgentforceAdvancedAnalyticsService.ChurnPredictionResult churnRisk { get; set; }
        @AuraEnabled public AgentforceAdvancedAnalyticsService.ContactTimingRecommendation contactTiming { get; set; }
        @AuraEnabled public AgentforceAdvancedAnalyticsService.RenewalOpportunityResult renewalAnalysis { get; set; }
        @AuraEnabled public List<AgentforceEmailIntegrationService.EmailGenerationResult> emailRecommendations { get; set; }
        @AuraEnabled public List<Task> recentActivities { get; set; }
        @AuraEnabled public AssetROIAnalysisService.AssetROIResult roiAnalysis { get; set; }
        
        public Customer360View() {
            this.success = false;
            this.emailRecommendations = new List<AgentforceEmailIntegrationService.EmailGenerationResult>();
            this.recentActivities = new List<Task>();
        }
    }
}
