/**
 * @description SOCAR Sales Assistant Agentforce 통합 서비스
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceSalesAssistantService {
    
    /**
     * 영업사원의 일일 브리핑 정보를 제공
     */
    @AuraEnabled(cacheable=true)
    public static DailyBriefingResult getDailyBriefing(Id userId) {
        try {
            DailyBriefingResult result = new DailyBriefingResult();
            
            // 오늘 미팅 일정 조회
            result.todayMeetings = getTodayMeetings(userId);
            
            // 팔로업 필요 고객 조회
            result.followUpNeeded = getFollowUpCustomers(userId);
            
            // 긴급 처리 필요 사항
            result.urgentItems = getUrgentItems(userId);
            
            // 우선순위 Task 조회
            result.priorityTasks = getPriorityTasks(userId);
            
            return result;
            
        } catch(Exception e) {
            throw new AuraHandledException('일일 브리핑 조회 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * 고객 미팅 후 자동 처리
     */
    @AuraEnabled
    public static PostMeetingResult processMeetingFollowUp(PostMeetingRequest request) {
        try {
            PostMeetingResult result = new PostMeetingResult();
            
            // 1. 콜 로그 생성
            Task callLog = createCallLog(request);
            result.callLogId = callLog.Id;
            
            // 2. 후속 Task 생성
            List<Task> followUpTasks = createFollowUpTasks(request);
            result.followUpTaskIds = new List<Id>();
            for(Task task : followUpTasks) {
                result.followUpTaskIds.add(task.Id);
            }
            
            // 3. Slack 알림 (Phase 2에서 구현)
            result.slackNotificationSent = false;
            
            result.success = true;
            result.message = '미팅 후속 처리가 완료되었습니다.';
            
            return result;
            
        } catch(Exception e) {
            throw new AuraHandledException('미팅 후속 처리 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * 고객별 맞춤 이메일 추천
     */
    @AuraEnabled
    public static EmailRecommendationResult getEmailRecommendation(Id customerId, String emailType) {
        try {
            EmailRecommendationResult result = new EmailRecommendationResult();
            
            // 고객 정보 조회
            Account customer = getCustomerInfo(customerId);
            
            // 최근 Order 정보 조회
            List<Order> recentOrders = getRecentOrders(customerId);
            
            // 이메일 추천 로직
            switch on emailType {
                when 'ORDER_FOLLOW_UP' {
                    result = generateOrderFollowUpRecommendation(customer, recentOrders);
                }
                when 'PAYMENT_REMINDER' {
                    result = generatePaymentReminderRecommendation(customer, recentOrders);
                }
                when 'ASSET_RENEWAL' {
                    result = generateAssetRenewalRecommendation(customer);
                }
                when else {
                    result = generateGeneralRecommendation(customer);
                }
            }
            
            return result;
            
        } catch(Exception e) {
            throw new AuraHandledException('이메일 추천 생성 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    // Private Helper Methods
    
    private static List<Event> getTodayMeetings(Id userId) {
        return [
            SELECT Id, Subject, StartDateTime, EndDateTime, Account.Name, Who.Name
            FROM Event 
            WHERE OwnerId = :userId 
            AND StartDateTime = TODAY
            ORDER BY StartDateTime ASC
        ];
    }
    
    private static List<Account> getFollowUpCustomers(Id userId) {
        return [
            SELECT Id, Name, LastActivityDate, Phone, Type
            FROM Account 
            WHERE OwnerId = :userId 
            AND LastActivityDate < LAST_N_DAYS:7
            ORDER BY LastActivityDate ASC
            LIMIT 10
        ];
    }
    
    private static List<Task> getUrgentItems(Id userId) {
        return [
            SELECT Id, Subject, ActivityDate, Priority, Status
            FROM Task 
            WHERE OwnerId = :userId 
            AND Status != 'Completed'
            AND (Priority = 'High' OR ActivityDate = TODAY)
            ORDER BY ActivityDate ASC
        ];
    }
    
    private static List<Task> getPriorityTasks(Id userId) {
        return [
            SELECT Id, Subject, ActivityDate, Priority, Status, What.Name
            FROM Task 
            WHERE OwnerId = :userId 
            AND Status != 'Completed'
            ORDER BY Priority DESC, ActivityDate ASC
            LIMIT 5
        ];
    }
    
    private static Task createCallLog(PostMeetingRequest request) {
        Task callLog = new Task();
        callLog.Subject = request.customerName + ' 미팅 - ' + request.meetingType;
        callLog.Description = request.meetingNotes;
        callLog.ActivityDate = Date.today();
        callLog.Status = 'Completed';
        callLog.Type = 'Call';
        callLog.WhatId = request.customerId;
        callLog.OwnerId = UserInfo.getUserId();
        
        insert callLog;
        return callLog;
    }
    
    private static List<Task> createFollowUpTasks(PostMeetingRequest request) {
        List<Task> tasks = new List<Task>();
        
        // 제안서 발송 Task
        if (request.needsProposal) {
            Task proposalTask = new Task();
            proposalTask.Subject = request.customerName + ' - 제안서 발송';
            proposalTask.ActivityDate = Date.today().addDays(1);
            proposalTask.Priority = 'High';
            proposalTask.Status = 'Not Started';
            proposalTask.WhatId = request.customerId;
            proposalTask.OwnerId = UserInfo.getUserId();
            tasks.add(proposalTask);
        }
        
        // 재연락 Task
        if (request.followUpDays > 0) {
            Task followUpTask = new Task();
            followUpTask.Subject = request.customerName + ' - 재연락';
            followUpTask.ActivityDate = Date.today().addDays(request.followUpDays);
            followUpTask.Priority = 'Normal';
            followUpTask.Status = 'Not Started';
            followUpTask.WhatId = request.customerId;
            followUpTask.OwnerId = UserInfo.getUserId();
            tasks.add(followUpTask);
        }
        
        if (!tasks.isEmpty()) {
            insert tasks;
        }
        
        return tasks;
    }
    
    private static Account getCustomerInfo(Id customerId) {
        return [
            SELECT Id, Name, Type, Industry, Phone, BillingAddress, AnnualRevenue
            FROM Account 
            WHERE Id = :customerId 
            LIMIT 1
        ];
    }
    
    private static List<Order> getRecentOrders(Id customerId) {
        return [
            SELECT Id, OrderNumber, Status, TotalAmount, EffectiveDate
            FROM Order 
            WHERE AccountId = :customerId 
            ORDER BY CreatedDate DESC 
            LIMIT 5
        ];
    }
    
    private static EmailRecommendationResult generateOrderFollowUpRecommendation(Account customer, List<Order> orders) {
        EmailRecommendationResult result = new EmailRecommendationResult();
        
        if (!orders.isEmpty()) {
            Order latestOrder = orders[0];
            result.subject = '[SOCAR] ' + customer.Name + ' Order ' + latestOrder.OrderNumber + ' 진행 상황 안내';
            result.recommendedTone = 'professional';
            result.keyPoints = new List<String>{
                '주문 진행 상황 업데이트',
                '다음 단계 안내',
                '문의사항 연락처 제공'
            };
            result.urgencyLevel = 'normal';
        }
        
        return result;
    }
    
    private static EmailRecommendationResult generatePaymentReminderRecommendation(Account customer, List<Order> orders) {
        EmailRecommendationResult result = new EmailRecommendationResult();
        
        result.subject = '[SOCAR] ' + customer.Name + ' 결제 일정 안내';
        result.recommendedTone = 'polite';
        result.keyPoints = new List<String>{
            '결제 예정일 안내',
            '결제 방법 확인',
            '문의사항 지원'
        };
        result.urgencyLevel = 'high';
        
        return result;
    }
    
    private static EmailRecommendationResult generateAssetRenewalRecommendation(Account customer) {
        EmailRecommendationResult result = new EmailRecommendationResult();
        
        result.subject = '[SOCAR] ' + customer.Name + ' Asset 갱신 기회 안내';
        result.recommendedTone = 'consultative';
        result.keyPoints = new List<String>{
            'Asset 만료일 안내',
            '갱신 혜택 소개',
            '맞춤 제안 준비'
        };
        result.urgencyLevel = 'normal';
        
        return result;
    }
    
    private static EmailRecommendationResult generateGeneralRecommendation(Account customer) {
        EmailRecommendationResult result = new EmailRecommendationResult();
        
        result.subject = '[SOCAR] ' + customer.Name + ' 안녕하세요';
        result.recommendedTone = 'friendly';
        result.keyPoints = new List<String>{
            '안부 인사',
            '서비스 현황 확인',
            '추가 지원 제안'
        };
        result.urgencyLevel = 'low';
        
        return result;
    }
    
    // Wrapper Classes
    
    public class DailyBriefingResult {
        @AuraEnabled public List<Event> todayMeetings { get; set; }
        @AuraEnabled public List<Account> followUpNeeded { get; set; }
        @AuraEnabled public List<Task> urgentItems { get; set; }
        @AuraEnabled public List<Task> priorityTasks { get; set; }
        
        public DailyBriefingResult() {
            this.todayMeetings = new List<Event>();
            this.followUpNeeded = new List<Account>();
            this.urgentItems = new List<Task>();
            this.priorityTasks = new List<Task>();
        }
    }
    
    public class PostMeetingRequest {
        @AuraEnabled public Id customerId { get; set; }
        @AuraEnabled public String customerName { get; set; }
        @AuraEnabled public String meetingType { get; set; }
        @AuraEnabled public String meetingNotes { get; set; }
        @AuraEnabled public Boolean needsProposal { get; set; }
        @AuraEnabled public Integer followUpDays { get; set; }
    }
    
    public class PostMeetingResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Id callLogId { get; set; }
        @AuraEnabled public List<Id> followUpTaskIds { get; set; }
        @AuraEnabled public Boolean slackNotificationSent { get; set; }
    }
    
    public class EmailRecommendationResult {
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String recommendedTone { get; set; }
        @AuraEnabled public List<String> keyPoints { get; set; }
        @AuraEnabled public String urgencyLevel { get; set; }
        
        public EmailRecommendationResult() {
            this.keyPoints = new List<String>();
        }
    }
}
