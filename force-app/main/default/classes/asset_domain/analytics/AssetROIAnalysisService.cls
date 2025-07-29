/**
 * @description Asset ROI 분석 및 성과 측정 서비스
 * @author AI Assistant  
 * @created 2025-07-24
 */
public with sharing class AssetROIAnalysisService {
    
    /**
     * Asset의 ROI 분석 결과를 반환
     */
    @AuraEnabled(cacheable=true)
    public static AssetROIResult calculateAssetROI(Id assetId) {
        try {
            // Asset 정보 조회
            Asset asset = [
                SELECT Id, Name, Price, PurchaseDate, UsageEndDate, Status,
                       Account.Name, Account.Industry, Account.NumberOfEmployees,
                       Account.Key_Account__c, Account.AnnualRevenue,
                       Contact.Name, Contact.Email
                FROM Asset 
                WHERE Id = :assetId 
                LIMIT 1
            ];
            
            AssetROIResult result = new AssetROIResult();
            result.assetId = asset.Id;
            result.assetName = asset.Name;
            result.accountName = asset.Account.Name;
            result.assetValue = asset.Price;
            result.purchaseDate = asset.PurchaseDate;
            result.usageEndDate = asset.UsageEndDate;
            
            // ROI 계산
            result.roiMetrics = calculateROIMetrics(asset);
            
            // 사용 현황 분석
            result.usageAnalysis = analyzeAssetUsage(asset);
            
            // 갱신 추천 사항
            result.renewalRecommendations = generateRenewalRecommendations(asset);
            
            // 위험 요소 분석
            result.riskFactors = analyzeRiskFactors(asset);
            
            return result;
            
        } catch(Exception e) {
            throw new AuraHandledException('Asset ROI 분석 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * ROI 지표 계산
     */
    private static ROIMetrics calculateROIMetrics(Asset asset) {
        ROIMetrics metrics = new ROIMetrics();
        
        // 기본 ROI 계산 (가정 기반)
        Decimal assetValue = asset.Price != null ? asset.Price : 0;
        
        // SOCAR 모빌리티 서비스 기준 ROI 계산
        if(asset.Account.Industry == 'Transportation') {
            // 운송업: 연간 20% 비용 절감 효과 가정
            metrics.costSavingPercentage = 20;
            metrics.annualCostSaving = assetValue * 0.20;
        } else if(asset.Account.Industry == 'Technology') {
            // 기술업: 연간 15% 효율성 향상
            metrics.costSavingPercentage = 15;
            metrics.annualCostSaving = assetValue * 0.15;
        } else {
            // 일반업: 연간 12% 비용 절감
            metrics.costSavingPercentage = 12;
            metrics.annualCostSaving = assetValue * 0.12;
        }
        
        // 회사 규모별 추가 혜택
        if(asset.Account.NumberOfEmployees != null) {
            if(asset.Account.NumberOfEmployees >= 1000) {
                // 대기업: 추가 5% 혜택
                metrics.annualCostSaving *= 1.05;
                metrics.costSavingPercentage += 5;
            } else if(asset.Account.NumberOfEmployees >= 100) {
                // 중견기업: 추가 3% 혜택
                metrics.annualCostSaving *= 1.03;
                metrics.costSavingPercentage += 3;
            }
        }
        
        // Key Account 프리미엄 혜택
        if(asset.Account.Key_Account__c) {
            metrics.annualCostSaving *= 1.10; // 10% 추가 혜택
            metrics.keyAccountBonus = assetValue * 0.10;
        }
        
        // ROI 백분율 계산
        if(assetValue > 0) {
            metrics.roiPercentage = (metrics.annualCostSaving / assetValue) * 100;
        }
        
        // 투자 회수 기간 계산 (개월)
        if(metrics.annualCostSaving > 0) {
            metrics.paybackPeriodMonths = Integer.valueOf((assetValue / metrics.annualCostSaving) * 12);
        }
        
        return metrics;
    }
    
    /**
     * Asset 사용 현황 분석
     */
    private static UsageAnalysis analyzeAssetUsage(Asset asset) {
        UsageAnalysis analysis = new UsageAnalysis();
        
        // 사용 기간 계산
        if(asset.PurchaseDate != null) {
            analysis.usageDays = asset.PurchaseDate.daysBetween(Date.today());
            analysis.usageMonths = Integer.valueOf(analysis.usageDays / 30);
        }
        
        // 남은 사용 기간
        if(asset.UsageEndDate != null) {
            analysis.remainingDays = Date.today().daysBetween(asset.UsageEndDate);
            analysis.remainingMonths = Integer.valueOf(analysis.remainingDays / 30);
        }
        
        // 사용률 분석 (가정 기반)
        analysis.utilizationRate = calculateUtilizationRate(asset);
        analysis.usageScore = calculateUsageScore(analysis.utilizationRate);
        
        // 사용 패턴 분석
        analysis.usagePattern = analyzeUsagePattern(asset);
        
        return analysis;
    }
    
    /**
     * 사용률 계산 (업종별 기준)
     */
    private static Decimal calculateUtilizationRate(Asset asset) {
        // 기본 사용률 70%에서 시작
        Decimal baseRate = 70;
        
        // Key Account는 높은 사용률 가정
        if(asset.Account.Key_Account__c) {
            baseRate += 15; // 85%
        }
        
        // 업종별 조정
        if(asset.Account.Industry == 'Transportation') {
            baseRate += 10; // 운송업은 높은 사용률
        } else if(asset.Account.Industry == 'Financial Services') {
            baseRate += 5;  // 금융업은 중간 사용률
        }
        
        // 회사 규모별 조정
        if(asset.Account.NumberOfEmployees != null) {
            if(asset.Account.NumberOfEmployees >= 1000) {
                baseRate += 8; // 대기업
            } else if(asset.Account.NumberOfEmployees >= 100) {
                baseRate += 5; // 중견기업
            }
        }
        
        // 최대 95%로 제한
        return Math.min(baseRate, 95);
    }
    
    /**
     * 사용 점수 계산
     */
    private static String calculateUsageScore(Decimal utilizationRate) {
        if(utilizationRate >= 85) return '매우 우수';
        else if(utilizationRate >= 75) return '우수';
        else if(utilizationRate >= 65) return '양호';
        else if(utilizationRate >= 50) return '보통';
        else return '개선 필요';
    }
    
    /**
     * 사용 패턴 분석
     */
    private static String analyzeUsagePattern(Asset asset) {
        List<String> patterns = new List<String>();
        
        if(asset.Account.Key_Account__c) {
            patterns.add('집중적 사용');
        }
        
        if(asset.Account.Industry == 'Transportation') {
            patterns.add('업무 중심 활용');
        } else if(asset.Account.Industry == 'Financial Services') {
            patterns.add('정기적 업무 활용');
        } else {
            patterns.add('일반적 활용');
        }
        
        if(asset.Account.NumberOfEmployees != null && asset.Account.NumberOfEmployees >= 100) {
            patterns.add('다부서 활용');
        }
        
        return String.join(patterns, ', ');
    }
    
    /**
     * 갱신 추천 사항 생성
     */
    private static List<String> generateRenewalRecommendations(Asset asset) {
        List<String> recommendations = new List<String>();
        
        // 기본 갱신 추천
        recommendations.add('현재 서비스 연장 (동일 조건)');
        
        // Key Account 특별 제안
        if(asset.Account.Key_Account__c) {
            recommendations.add('VIP 고객 할인 혜택 적용');
            recommendations.add('전담 매니저 서비스 제공');
            recommendations.add('우선 지원 서비스 포함');
        }
        
        // 업종별 추천
        if(asset.Account.Industry == 'Transportation') {
            recommendations.add('프리미엄 차량 옵션 업그레이드');
            recommendations.add('운행 관리 서비스 추가');
        } else if(asset.Account.Industry == 'Technology') {
            recommendations.add('최신 기술 적용 서비스 제공');
            recommendations.add('API 연동 서비스 확장');
        }
        
        // 회사 규모별 추천
        if(asset.Account.NumberOfEmployees != null) {
            if(asset.Account.NumberOfEmployees >= 1000) {
                recommendations.add('대기업 전용 패키지 제안');
                recommendations.add('복수 지역 서비스 확장');
            } else if(asset.Account.NumberOfEmployees >= 100) {
                recommendations.add('중견기업 성장 지원 패키지');
                recommendations.add('단계적 확장 옵션');
            }
        }
        
        // 장기 계약 혜택
        recommendations.add('2년 계약 시 10% 할인');
        recommendations.add('3년 계약 시 15% 할인 + 추가 혜택');
        
        return recommendations;
    }
    
    /**
     * 위험 요소 분석
     */
    private static List<String> analyzeRiskFactors(Asset asset) {
        List<String> risks = new List<String>();
        
        // 만료 임박 위험
        if(asset.UsageEndDate != null) {
            Integer daysUntilExpiry = Date.today().daysBetween(asset.UsageEndDate);
            if(daysUntilExpiry <= 30) {
                risks.add('⚠️ 만료 임박 (30일 이내) - 즉시 갱신 논의 필요');
            } else if(daysUntilExpiry <= 60) {
                risks.add('📅 갱신 준비 시기 - 제안서 준비 시작');
            } else if(daysUntilExpiry <= 90) {
                risks.add('📋 갱신 계획 수립 - 고객 니즈 파악');
            }
        }
        
        // 업종별 위험 요소
        if(asset.Account.Industry == 'Financial Services') {
            risks.add('규제 변화에 따른 서비스 요구사항 변경 가능');
        } else if(asset.Account.Industry == 'Healthcare') {
            risks.add('의료 규정 변화 모니터링 필요');
        }
        
        // 경쟁 위험
        if(!asset.Account.Key_Account__c) {
            risks.add('경쟁사 접촉 가능성 - 관계 강화 필요');
        }
        
        // 기본 위험이 없으면 긍정적 메시지
        if(risks.isEmpty()) {
            risks.add('✅ 안정적인 고객 관계 - 갱신 성공 가능성 높음');
        }
        
        return risks;
    }
    
    // Wrapper Classes
    public class AssetROIResult {
        @AuraEnabled public Id assetId { get; set; }
        @AuraEnabled public String assetName { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public Decimal assetValue { get; set; }
        @AuraEnabled public Date purchaseDate { get; set; }
        @AuraEnabled public Date usageEndDate { get; set; }
        @AuraEnabled public ROIMetrics roiMetrics { get; set; }
        @AuraEnabled public UsageAnalysis usageAnalysis { get; set; }
        @AuraEnabled public List<String> renewalRecommendations { get; set; }
        @AuraEnabled public List<String> riskFactors { get; set; }
    }
    
    public class ROIMetrics {
        @AuraEnabled public Decimal roiPercentage { get; set; }
        @AuraEnabled public Decimal annualCostSaving { get; set; }
        @AuraEnabled public Decimal costSavingPercentage { get; set; }
        @AuraEnabled public Integer paybackPeriodMonths { get; set; }
        @AuraEnabled public Decimal keyAccountBonus { get; set; }
    }
    
    public class UsageAnalysis {
        @AuraEnabled public Integer usageDays { get; set; }
        @AuraEnabled public Integer usageMonths { get; set; }
        @AuraEnabled public Integer remainingDays { get; set; }
        @AuraEnabled public Integer remainingMonths { get; set; }
        @AuraEnabled public Decimal utilizationRate { get; set; }
        @AuraEnabled public String usageScore { get; set; }
        @AuraEnabled public String usagePattern { get; set; }
    }
}
