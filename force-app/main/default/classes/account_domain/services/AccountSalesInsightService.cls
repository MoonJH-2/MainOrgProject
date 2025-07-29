/**
 * @description Account 영업 효율성을 위한 통합 인사이트 서비스
 * @author JH Moon
 * @created 2025-07-23
 */
public with sharing class AccountSalesInsightService {
    
    /**
     * Account 영업 요약 정보 조회
     */
    @AuraEnabled(cacheable=true)
    public static AccountSalesData getAccountSalesInsight(Id accountId) {
        try {
            // Account 기본 정보 조회
            Account acc = [
                SELECT Id, Name, Key_Account__c, Industry, Phone, Website, 
                       AnnualRevenue, NumberOfEmployees, Type, AccountSource,
                       ShippingCity, ShippingCountry, Description
                FROM Account 
                WHERE Id = :accountId
                LIMIT 1
            ];
            
            // 관련 데이터 개별 조회 (COUNT는 별도 쿼리로)
            Integer opportunityCount = [SELECT COUNT() FROM Opportunity WHERE AccountId = :accountId AND StageName != 'Closed Lost'];
            Integer caseCount = [SELECT COUNT() FROM Case WHERE AccountId = :accountId AND Status != 'Closed'];
            Integer orderCount = [SELECT COUNT() FROM Order WHERE AccountId = :accountId AND Status = 'Activated'];
            Integer contactCount = [SELECT COUNT() FROM Contact WHERE AccountId = :accountId];
            
            AccountSalesData data = new AccountSalesData();
            data.account = acc;
            data.opportunityCount = opportunityCount;
            data.caseCount = caseCount;
            data.orderCount = orderCount;
            data.contactCount = contactCount;
            data.priorityLevel = calculatePriority(acc);
            data.recentRevenue = calculateRecentRevenue(accountId);
            data.recommendedActions = generateRecommendedActions(acc, opportunityCount, contactCount);
            data.salesInsights = generateSalesInsights(acc, opportunityCount, orderCount);
            data.alertSettings = getAlertSettings(accountId);
            data.opportunityForecast = predictOpportunityValue(acc);
            
            return data;
            
        } catch (Exception e) {
            System.debug('Account Sales Insight 조회 오류: ' + e.getMessage());
            throw new AuraHandledException('Account 정보를 불러올 수 없습니다: ' + e.getMessage());
        }
    }
    
    /**
     * 고객 우선순위 계산
     */
    private static String calculatePriority(Account acc) {
        Integer score = 0;
        
        // Key Account 여부 (가장 높은 가중치)
        if (acc.Key_Account__c) score += 50;
        
        // 연간 매출액
        if (acc.AnnualRevenue != null) {
            if (acc.AnnualRevenue >= 1000000000) score += 30; // 10억 이상
            else if (acc.AnnualRevenue >= 500000000) score += 20; // 5억 이상
            else if (acc.AnnualRevenue >= 100000000) score += 10; // 1억 이상
        }
        
        // 직원 수
        if (acc.NumberOfEmployees != null) {
            if (acc.NumberOfEmployees >= 1000) score += 20;
            else if (acc.NumberOfEmployees >= 100) score += 10;
            else if (acc.NumberOfEmployees >= 50) score += 5;
        }
        
        // 우선순위 등급 결정
        if (score >= 70) return '최우선';
        else if (score >= 50) return '높음';
        else if (score >= 30) return '중간';
        else return '보통';
    }
    
    /**
     * 최근 매출 계산
     */
    private static Decimal calculateRecentRevenue(Id accountId) {
        try {
            AggregateResult result = [
                SELECT SUM(TotalAmount) totalRevenue
                FROM Order 
                WHERE AccountId = :accountId 
                AND Status = 'Activated'
                AND EffectiveDate >= :Date.today().addYears(-1)
            ];
            
            return (Decimal)result.get('totalRevenue') ?? 0;
            
        } catch (Exception e) {
            System.debug('매출 계산 오류: ' + e.getMessage());
            return 0;
        }
    }
    
    /**
     * 추천 액션 생성
     */
    private static List<RecommendedAction> generateRecommendedActions(Account acc, Integer opportunityCount, Integer contactCount) {
        List<RecommendedAction> actions = new List<RecommendedAction>();
        
        // Key Account 전용 액션
        if (acc.Key_Account__c) {
            actions.add(new RecommendedAction(
                '🎯', 
                'Key Account 정기 미팅 일정', 
                'Key Account이므로 분기별 정기 미팅 필요',
                'High',
                'createTask'
            ));
        }
        
        // 웹사이트 분석 액션
        if (String.isNotBlank(acc.Website)) {
            actions.add(new RecommendedAction(
                '🌐', 
                '웹사이트 동향 분석', 
                '고객 웹사이트 방문하여 최신 비즈니스 동향 파악',
                'Medium',
                'visitWebsite'
            ));
        }
        
        // 연락처 부족 시 액션
        if (contactCount == 0) {
            actions.add(new RecommendedAction(
                '👥', 
                '의사결정자 연락처 확보', 
                '영업 진행을 위한 핵심 연락처 정보 수집 필요',
                'High',
                'addContact'
            ));
        }
        
        // Opportunity 부족 시 액션
        if (opportunityCount == 0) {
            actions.add(new RecommendedAction(
                '💰', 
                '신규 영업 기회 생성', 
                '활성 영업 기회가 없어 신규 기회 발굴 필요',
                'High',
                'createOpportunity'
            ));
        }
        
        // 업종별 맞춤 액션
        if (String.isNotBlank(acc.Industry)) {
            if (acc.Industry.containsIgnoreCase('Technology') || 
                (acc.Website != null && acc.Website.containsIgnoreCase('ai'))) {
                actions.add(new RecommendedAction(
                    '🤖', 
                    'AI/기술 솔루션 제안', 
                    '기술 기업 특성상 혁신적 솔루션 제안 기회',
                    'Medium',
                    'prepareProposal'
                ));
            }
        }
        
        return actions;
    }
    
    /**
     * 영업 인사이트 생성
     */
    private static List<String> generateSalesInsights(Account acc, Integer opportunityCount, Integer orderCount) {
        List<String> insights = new List<String>();
        
        // Key Account 인사이트
        if (acc.Key_Account__c) {
            insights.add('⭐ Key Account로 최우선 관리 대상입니다');
            insights.add('📈 장기적 파트너십 구축 및 확장 기회 검토 필요');
        }
        
        // 매출 규모 기반 인사이트
        if (acc.AnnualRevenue != null) {
            if (acc.AnnualRevenue >= 1000000000) {
                insights.add('💼 대기업 고객으로 확장 가능성이 높습니다');
            } else if (acc.AnnualRevenue >= 100000000) {
                insights.add('🏢 중견기업으로 성장 단계별 솔루션 확장 가능');
            } else {
                insights.add('🚀 중소기업으로 효율성 중심 제안 필요');
            }
        }
        
        // 직원 수 기반 인사이트
        if (acc.NumberOfEmployees != null) {
            if (acc.NumberOfEmployees >= 1000) {
                insights.add('👥 대규모 조직으로 부서별 확산 기회 존재');
            } else if (acc.NumberOfEmployees >= 100) {
                insights.add('👥 중간 규모 조직으로 단계적 도입 전략 필요');
            }
        }
        
        // 활동 부족 경고
        if (opportunityCount == 0 && orderCount == 0) {
            insights.add('⚠️ 최근 영업 활동이 부족합니다 - 즉시 접촉 필요');
        }
        
        // 웹사이트 기반 비즈니스 분석
        if (String.isNotBlank(acc.Website)) {
            if (acc.Website.containsIgnoreCase('coach') || acc.Website.containsIgnoreCase('golf')) {
                insights.add('⛳ 스포츠/레저 업종으로 B2B 솔루션 확장 기회');
            }
        }
        
        return insights;
    }
    
    /**
     * 기회 예측 값 계산
     */
    private static OpportunityForecast predictOpportunityValue(Account acc) {
        OpportunityForecast forecast = new OpportunityForecast();
        
        // 기본 예측 금액 계산
        Decimal baseAmount = 50000000; // 5천만원 기본
        
        // Key Account 보정
        if (acc.Key_Account__c) {
            baseAmount *= 2;
            forecast.probability = 80;
        } else {
            forecast.probability = 60;
        }
        
        // 연간 매출 기반 보정
        if (acc.AnnualRevenue != null) {
            if (acc.AnnualRevenue >= 1000000000) {
                baseAmount *= 1.5;
                forecast.probability += 10;
            } else if (acc.AnnualRevenue >= 500000000) {
                baseAmount *= 1.2;
                forecast.probability += 5;
            }
        }
        
        // 기존 Order 존재 시 보정 (별도 조회 필요시)
        // 성능을 위해 일단 생략하고 기본 로직만 적용
        
        forecast.expectedAmount = baseAmount;
        forecast.timeframe = acc.Key_Account__c ? '2-3개월' : '3-4개월';
        
        return forecast;
    }
    
    /**
     * 알림 설정 조회
     */
    private static AlertSettings getAlertSettings(Id accountId) {
        AlertSettings settings = new AlertSettings();
        
        // 기존 알림 Task 조회
        List<Task> alerts = [
            SELECT Id, Subject, ActivityDate 
            FROM Task 
            WHERE WhatId = :accountId 
            AND Subject LIKE '%체크인%'
            AND ActivityDate >= :Date.today()
            LIMIT 5
        ];
        
        settings.hasActiveAlerts = !alerts.isEmpty();
        settings.nextAlertDate = alerts.isEmpty() ? null : alerts[0].ActivityDate;
        
        return settings;
    }
    
    /**
     * 즉시 액션 실행
     */
    @AuraEnabled
    public static String executeAction(Id accountId, String actionType, String actionData) {
        try {
            switch on actionType {
                when 'createTask' {
                    return createFollowUpTask(accountId, actionData);
                }
                when 'createOpportunity' {
                    return createNewOpportunity(accountId);
                }
                when 'addContact' {
                    return prepareContactForm(accountId);
                }
                when 'visitWebsite' {
                    return getWebsiteUrl(accountId);
                }
                when 'prepareProposal' {
                    return prepareProposalTemplate(accountId);
                }
                when else {
                    return '알 수 없는 액션입니다.';
                }
            }
        } catch (Exception e) {
            System.debug('액션 실행 오류: ' + e.getMessage());
            throw new AuraHandledException('액션 실행 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * 후속 Task 생성
     */
    private static String createFollowUpTask(Id accountId, String actionData) {
        Task newTask = new Task();
        newTask.WhatId = accountId;
        newTask.Subject = 'Account 후속 조치: ' + actionData;
        newTask.ActivityDate = Date.today().addDays(7);
        newTask.Priority = 'High';
        newTask.Description = '영업 효율성 시스템에서 자동 생성된 후속 조치 Task';
        newTask.Status = 'Open';
        
        insert newTask;
        
        return 'Task가 성공적으로 생성되었습니다. (ID: ' + newTask.Id + ')';
    }
    
    /**
     * 신규 Opportunity 생성
     */
    private static String createNewOpportunity(Id accountId) {
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = accountId;
        newOpp.Name = '신규 영업 기회';
        newOpp.StageName = 'Prospecting';
        newOpp.CloseDate = Date.today().addDays(90);
        newOpp.Amount = 50000000;
        newOpp.Description = '영업 효율성 시스템에서 자동 생성된 기회';
        
        insert newOpp;
        
        return 'Opportunity가 성공적으로 생성되었습니다. (ID: ' + newOpp.Id + ')';
    }
    
    /**
     * 웹사이트 URL 반환
     */
    private static String getWebsiteUrl(Id accountId) {
        Account acc = [SELECT Website FROM Account WHERE Id = :accountId LIMIT 1];
        return acc.Website;
    }
    
    /**
     * 제안서 템플릿 준비
     */
    private static String prepareProposalTemplate(Id accountId) {
        return 'proposal_template_' + accountId;
    }
    
    /**
     * 연락처 폼 준비
     */
    private static String prepareContactForm(Id accountId) {
        return '/lightning/o/Contact/new?defaultFieldValues=AccountId=' + accountId;
    }
    
    // Inner Classes
    public class AccountSalesData {
        @AuraEnabled public Account account;
        @AuraEnabled public String priorityLevel;
        @AuraEnabled public Decimal recentRevenue;
        @AuraEnabled public Integer opportunityCount;
        @AuraEnabled public Integer caseCount;
        @AuraEnabled public Integer orderCount;
        @AuraEnabled public Integer contactCount;
        @AuraEnabled public List<RecommendedAction> recommendedActions;
        @AuraEnabled public List<String> salesInsights;
        @AuraEnabled public AlertSettings alertSettings;
        @AuraEnabled public OpportunityForecast opportunityForecast;
    }
    
    public class RecommendedAction {
        @AuraEnabled public String icon;
        @AuraEnabled public String title;
        @AuraEnabled public String description;
        @AuraEnabled public String priority;
        @AuraEnabled public String actionType;
        
        public RecommendedAction(String icon, String title, String description, String priority, String actionType) {
            this.icon = icon;
            this.title = title;
            this.description = description;
            this.priority = priority;
            this.actionType = actionType;
        }
    }
    
    public class AlertSettings {
        @AuraEnabled public Boolean hasActiveAlerts;
        @AuraEnabled public Date nextAlertDate;
    }
    
    public class OpportunityForecast {
        @AuraEnabled public Decimal expectedAmount;
        @AuraEnabled public Integer probability;
        @AuraEnabled public String timeframe;
    }
}
