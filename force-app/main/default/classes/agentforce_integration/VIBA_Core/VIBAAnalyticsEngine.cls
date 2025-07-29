/**
 * @description VIBA Analytics Engine - AI 기반 종합 분석 엔진
 * @author VIBA AI Assistant
 * @date 2025-01-27
 */
public with sharing class VIBAAnalyticsEngine {
    
    // AI 분석 상수
    private static final Decimal BASE_CONFIDENCE = 75.0;
    private static final Decimal HIGH_QUALITY_THRESHOLD = 90.0;
    private static final Decimal MEDIUM_QUALITY_THRESHOLD = 70.0;
    
    /**
     * @description 종합 AI 분석 수행
     * @param context 분석 컨텍스트
     * @return VIBAInsight 분석 결과
     */
    public static VIBAInsight analyze(VIBAContext context) {
        VIBAInsight insight = new VIBAInsight();
        
        try {
            // 1. 데이터 품질 평가
            insight.dataQuality = assessDataQuality(context);
            
            // 2. 고객 등급 분석
            insight.customerTier = determineCustomerTier(context);
            
            // 3. 위험도 분석
            insight.riskLevel = analyzeRiskLevel(context);
            
            // 4. 기회 점수 계산
            insight.opportunityScore = calculateOpportunityScore(context);
            
            // 5. 분석 복잡도 계산
            insight.analysisComplexity = calculateAnalysisComplexity(context);
            
            // 6. VIBA 점수 산정
            insight.vibaScore = calculateVIBAScore(insight);
            
            // 7. 개인화 메시지 생성
            insight.personalizedMessage = generatePersonalizedInsight(context, insight);
            
            System.debug('VIBAAnalyticsEngine: 분석 완료. VIBA Score: ' + insight.vibaScore + '%, 고객등급: ' + insight.customerTier);
            
        } catch (Exception e) {
            System.debug('VIBAAnalyticsEngine 오류: ' + e.getMessage());
            insight = createFallbackInsight();
        }
        
        return insight;
    }
    
    /**
     * @description 데이터 품질 평가
     */
    private static Decimal assessDataQuality(VIBAContext context) {
        Decimal qualityScore = 50.0; // 기본 점수
        
        try {
            if (context.recordId != null) {
                qualityScore += 20.0; // 레코드 ID 존재
                
                // Order 컨텍스트 품질 평가
                if (context.orderContext != null) {
                    if (context.orderContext.hasCompleteData) qualityScore += 15.0;
                    if (context.orderContext.hasPaymentHistory) qualityScore += 10.0;
                    if (context.orderContext.hasCustomerHistory) qualityScore += 5.0;
                }
                
                // PaymentStatus 컨텍스트 품질 평가
                if (context.paymentContext != null) {
                    if (context.paymentContext.hasTimelineData) qualityScore += 10.0;
                    if (context.paymentContext.hasCompletionData) qualityScore += 10.0;
                }
                
                // Asset 컨텍스트 품질 평가
                if (context.assetContext != null) {
                    if (context.assetContext.hasUsageData) qualityScore += 10.0;
                    if (context.assetContext.hasPerformanceData) qualityScore += 5.0;
                }
            }
            
        } catch (Exception e) {
            System.debug('데이터 품질 평가 오류: ' + e.getMessage());
            qualityScore = 60.0; // 안전한 기본값
        }
        
        return Math.min(qualityScore, 100.0);
    }
    
    /**
     * @description 고객 등급 결정
     */
    private static String determineCustomerTier(VIBAContext context) {
        try {
            if (context.recordId == null) return 'New';
            
            // Account 정보 조회
            List<Account> accounts = getAccountInfo(context.recordId, context.requestType);
            
            if (accounts.isEmpty()) return 'Standard';
            
            Account account = accounts[0];
            
            // 프리미엄 고객 조건
            if (account.Key_Account__c == true || 
                account.CustomerPriority__c == 'High' ||
                account.AnnualRevenue > 1000000) {
                return 'Premium';
            }
            
            // VIP 고객 조건 (추가 분석)
            if (hasMultipleOrders(account.Id) && hasExcellentPaymentHistory(account.Id)) {
                return 'VIP';
            }
            
            return 'Standard';
            
        } catch (Exception e) {
            System.debug('고객 등급 결정 오류: ' + e.getMessage());
            return 'Standard';
        }
    }
    
    /**
     * @description 위험도 레벨 분석
     */
    private static String analyzeRiskLevel(VIBAContext context) {
        try {
            Decimal riskScore = 0.0;
            
            // PaymentStatus 기반 위험도 분석
            if (context.paymentContext != null) {
                riskScore += analyzePaymentRisk(context.paymentContext);
            }
            
            // Order 기반 위험도 분석
            if (context.orderContext != null) {
                riskScore += analyzeOrderRisk(context.orderContext);
            }
            
            // Asset 기반 위험도 분석
            if (context.assetContext != null) {
                riskScore += analyzeAssetRisk(context.assetContext);
            }
            
            // 위험도 레벨 결정
            if (riskScore > 70) return 'High';
            else if (riskScore > 40) return 'Medium';
            else return 'Low';
            
        } catch (Exception e) {
            System.debug('위험도 분석 오류: ' + e.getMessage());
            return 'Medium';
        }
    }
    
    /**
     * @description 기회 점수 계산
     */
    private static Decimal calculateOpportunityScore(VIBAContext context) {
        Decimal opportunityScore = 50.0; // 기본 점수
        
        try {
            // 고객 등급별 기회 점수 조정
            String customerTier = determineCustomerTier(context);
            if (customerTier == 'Premium') opportunityScore += 20.0;
            else if (customerTier == 'VIP') opportunityScore += 30.0;
            
            // 완납 이력 기반 기회 점수
            if (context.paymentContext != null && context.paymentContext.hasExcellentHistory) {
                opportunityScore += 15.0;
            }
            
            // Asset 사용 패턴 기반 기회 점수
            if (context.assetContext != null && context.assetContext.hasHighUsage) {
                opportunityScore += 10.0;
            }
            
            // 최근 소통 이력 기반 점수
            if (hasRecentPositiveEngagement(context.recordId)) {
                opportunityScore += 5.0;
            }
            
        } catch (Exception e) {
            System.debug('기회 점수 계산 오류: ' + e.getMessage());
            opportunityScore = 60.0;
        }
        
        return Math.min(opportunityScore, 100.0);
    }
    
    /**
     * @description 분석 복잡도 계산
     */
    private static Decimal calculateAnalysisComplexity(VIBAContext context) {
        Decimal complexity = 30.0; // 기본 복잡도
        
        // 컨텍스트 유형별 복잡도 추가
        if (context.orderContext != null) complexity += 20.0;
        if (context.paymentContext != null) complexity += 25.0;
        if (context.assetContext != null) complexity += 15.0;
        
        // 데이터 양에 따른 복잡도 조정
        if (context.recordId != null) {
            Integer relatedRecordsCount = getRelatedRecordsCount(context.recordId, context.requestType);
            complexity += Math.min(relatedRecordsCount * 2.0, 20.0);
        }
        
        return Math.min(complexity, 100.0);
    }
    
    /**
     * @description VIBA 점수 계산
     */
    private static Decimal calculateVIBAScore(VIBAInsight insight) {
        Decimal score = BASE_CONFIDENCE;
        
        // 데이터 품질에 따른 점수 조정
        if (insight.dataQuality >= HIGH_QUALITY_THRESHOLD) {
            score += 20.0;
        } else if (insight.dataQuality >= MEDIUM_QUALITY_THRESHOLD) {
            score += 10.0;
        }
        
        // 분석 복잡도에 따른 신뢰도 조정
        if (insight.analysisComplexity > 80.0) {
            score += 5.0; // 복잡한 분석일수록 더 정확
        }
        
        // 최대 95% (겸손한 VIBA)
        return Math.min(score, 95.0);
    }
    
    /**
     * @description 개인화된 인사이트 생성
     */
    private static String generatePersonalizedInsight(VIBAContext context, VIBAInsight insight) {
        String message = '';
        
        try {
            // 고객 등급별 맞춤 메시지
            if (insight.customerTier == 'VIP') {
                message = '💎 VIP 고객으로서 최우선 관리가 필요합니다. ';
            } else if (insight.customerTier == 'Premium') {
                message = '⭐ 프리미엄 고객으로서 특별한 관심이 필요합니다. ';
            } else {
                message = '👥 소중한 고객으로서 지속적인 관계 발전이 중요합니다. ';
            }
            
            // 위험도별 메시지 추가
            if (insight.riskLevel == 'High') {
                message += '현재 높은 위험 상황이 감지되어 즉시 액션이 필요합니다.';
            } else if (insight.riskLevel == 'Medium') {
                message += '주의 깊은 모니터링과 선제적 대응이 권장됩니다.';
            } else {
                message += '안정적인 상태이며 기회 발굴에 집중할 수 있습니다.';
            }
            
            // 기회 점수별 메시지 추가
            if (insight.opportunityScore > 80) {
                message += ' 🚀 높은 성공 가능성의 기회가 있습니다!';
            } else if (insight.opportunityScore > 60) {
                message += ' 💡 좋은 기회가 발견되었습니다.';
            }
            
        } catch (Exception e) {
            System.debug('개인화 메시지 생성 오류: ' + e.getMessage());
            message = '📊 종합 분석을 통해 최적의 전략을 수립했습니다.';
        }
        
        return message;
    }
    
    // ============================================================================
    // Helper Methods
    // ============================================================================
    
    /**
     * @description Account 정보 조회
     */
    private static List<Account> getAccountInfo(Id recordId, String requestType) {
        String accountId = '';
        
        if (requestType == 'Order') {
            List<Order> orders = [SELECT AccountId FROM Order WHERE Id = :recordId LIMIT 1];
            if (!orders.isEmpty()) accountId = orders[0].AccountId;
        } else if (requestType == 'PaymentStatus') {
            List<PaymentStatus__c> payments = [SELECT Order__r.AccountId FROM PaymentStatus__c WHERE Id = :recordId LIMIT 1];
            if (!payments.isEmpty()) accountId = payments[0].Order__r.AccountId;
        } else if (requestType == 'Asset') {
            List<Asset> assets = [SELECT AccountId FROM Asset WHERE Id = :recordId LIMIT 1];
            if (!assets.isEmpty()) accountId = assets[0].AccountId;
        }
        
        if (String.isBlank(accountId)) return new List<Account>();
        
        return [
            SELECT Id, Name, Key_Account__c, CustomerPriority__c, AnnualRevenue,
                   Industry, NumberOfEmployees, Active__c
            FROM Account 
            WHERE Id = :accountId 
            LIMIT 1
        ];
    }
    
    /**
     * @description 다수 주문 이력 확인
     */
    private static Boolean hasMultipleOrders(Id accountId) {
        Integer orderCount = [SELECT COUNT() FROM Order WHERE AccountId = :accountId];
        return orderCount > 1;
    }
    
    /**
     * @description 우수한 결제 이력 확인
     */
    private static Boolean hasExcellentPaymentHistory(Id accountId) {
        // 전체 PaymentStatus 조회
        Integer totalPayments = [
            SELECT COUNT() 
            FROM PaymentStatus__c 
            WHERE Order__r.AccountId = :accountId
        ];
        
        if (totalPayments == 0) return false;
        
        // 완납된 PaymentStatus 조회
        Integer completedPayments = [
            SELECT COUNT() 
            FROM PaymentStatus__c 
            WHERE Order__r.AccountId = :accountId 
            AND Status__c = '완납'
        ];
        
        // 90% 이상 완납률
        return (completedPayments * 100 / totalPayments) >= 90;
    }
    
    /**
     * @description 결제 위험도 분석
     */
    private static Decimal analyzePaymentRisk(VIBAPaymentContext paymentContext) {
        Decimal riskScore = 0.0;
        
        if (paymentContext.hasOverduePayments) riskScore += 30.0;
        if (paymentContext.hasRepeatedDelays) riskScore += 20.0;
        if (!paymentContext.hasRecentCommunication) riskScore += 15.0;
        
        return riskScore;
    }
    
    /**
     * @description Order 위험도 분석
     */
    private static Decimal analyzeOrderRisk(VIBAOrderContext orderContext) {
        Decimal riskScore = 0.0;
        
        if (!orderContext.hasCompleteData) riskScore += 10.0;
        if (orderContext.hasComplexPaymentTerms) riskScore += 15.0;
        
        return riskScore;
    }
    
    /**
     * @description Asset 위험도 분석
     */
    private static Decimal analyzeAssetRisk(VIBAAssetContext assetContext) {
        Decimal riskScore = 0.0;
        
        if (assetContext.hasLowUsage) riskScore += 20.0;
        if (assetContext.isNearingExpiry) riskScore += 25.0;
        
        return riskScore;
    }
    
    /**
     * @description 최근 긍정적 소통 확인
     */
    private static Boolean hasRecentPositiveEngagement(Id recordId) {
        // 최근 30일 내 긍정적 Task/Event 확인
        Date recentDate = Date.today().addDays(-30);
        
        Integer positiveActivities = [
            SELECT COUNT() 
            FROM Task 
            WHERE WhatId = :recordId 
            AND CreatedDate >= :recentDate
            AND (Subject LIKE '%완납%' OR Subject LIKE '%성공%' OR Subject LIKE '%만족%')
        ];
        
        return positiveActivities > 0;
    }
    
    /**
     * @description 관련 레코드 개수 조회
     */
    private static Integer getRelatedRecordsCount(Id recordId, String requestType) {
        Integer count = 0;
        
        try {
            if (requestType == 'Order') {
                count = [SELECT COUNT() FROM PaymentStatus__c WHERE Order__c = :recordId];
            } else if (requestType == 'Asset') {
                // Asset과 관련된 Order 찾기
                List<Asset> assets = [SELECT SerialNumber FROM Asset WHERE Id = :recordId LIMIT 1];
                if (!assets.isEmpty()) {
                    count = [SELECT COUNT() FROM PaymentStatus__c WHERE Order__r.OrderNumber = :assets[0].SerialNumber];
                }
            }
        } catch (Exception e) {
            System.debug('관련 레코드 개수 조회 오류: ' + e.getMessage());
            count = 0;
        }
        
        return count;
    }
    
    /**
     * @description 실패 시 기본 인사이트 생성
     */
    private static VIBAInsight createFallbackInsight() {
        VIBAInsight insight = new VIBAInsight();
        insight.vibaScore = 70.0;
        insight.dataQuality = 60.0;
        insight.analysisComplexity = 50.0;
        insight.customerTier = 'Standard';
        insight.riskLevel = 'Medium';
        insight.opportunityScore = 60.0;
        insight.personalizedMessage = '📊 기본 분석을 완료했습니다. 추가 정보가 확보되면 더 정확한 인사이트를 제공해드릴게요.';
        
        return insight;
    }
}
