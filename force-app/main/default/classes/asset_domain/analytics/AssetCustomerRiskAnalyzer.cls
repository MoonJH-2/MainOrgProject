/**
 * Asset 기반 고객 리스크 및 만족도 분석 시스템
 * 
 * 분석 대상: (주)그린파워텍 Order 00000162
 * - 납부 패턴: 4/4차 완납 (우수)
 * - 구매-설치 간격: 2일 (빠른 도입)
 * - Contact: 유나 김 (단일 접점)
 */
public class AssetCustomerRiskAnalyzer {
    
    /**
     * 고객 리스크 종합 분석
     */
    @AuraEnabled(cacheable=true)
    public static CustomerRiskAnalysis analyzeCustomerRisk(Id accountId) {
        
        CustomerRiskAnalysis analysis = new CustomerRiskAnalysis();
        
        // 1. Asset 포트폴리오 조회
        List<Asset> customerAssets = [
            SELECT Id, Name, SerialNumber, AccountId, ContactId, 
                   Price, PurchaseDate, InstallDate, UsageEndDate,
                   Status, Description, Product2.Name,
                   Account.Name, Account.Industry, Account.Key_Account__c,
                   Contact.Name, Contact.Email, Contact.DoNotCall
            FROM Asset 
            WHERE AccountId = :accountId
            ORDER BY PurchaseDate DESC
        ];
        
        // 2. 납부 이력 분석
        analysis.paymentRiskScore = analyzePaymentHistory(customerAssets);
        
        // 3. 사용 패턴 분석
        analysis.usageRiskScore = analyzeUsagePatterns(customerAssets);
        
        // 4. 커뮤니케이션 리스크
        analysis.communicationRiskScore = analyzeCommunicationRisk(customerAssets);
        
        // 5. 경쟁사 전환 리스크
        analysis.competitorRiskScore = analyzeCompetitorRisk(customerAssets);
        
        // 6. 종합 리스크 점수 (가중평균)
        analysis.overallRiskScore = calculateOverallRisk(analysis);
        
        // 7. 리스크 완화 액션 플랜
        analysis.riskMitigationActions = generateRiskMitigationPlan(analysis);
        
        // 8. 고객 만족도 예측
        analysis.satisfactionPrediction = predictCustomerSatisfaction(customerAssets);
        
        return analysis;
    }
    
    /**
     * 납부 이력 기반 리스크 분석
     */
    private static Integer analyzePaymentHistory(List<Asset> assets) {
        Integer riskScore = 0; // 0=최저 리스크, 100=최고 리스크
        
        // 그린파워텍 Order 00000162 분석
        for (Asset asset : assets) {
            if (asset.SerialNumber == '00000162') {
                // 완납 이력 분석 (Description에서 파싱)
                if (asset.Description != null && asset.Description.contains('완납 완료: 4/4차')) {
                    riskScore = 10; // 매우 낮은 리스크
                } else if (asset.Description != null && asset.Description.contains('연체')) {
                    riskScore = 80; // 높은 리스크
                } else {
                    riskScore = 30; // 보통 리스크
                }
                break;
            }
        }
        
        return riskScore;
    }
    
    /**
     * 사용 패턴 리스크 분석
     */
    private static Integer analyzeUsagePatterns(List<Asset> assets) {
        Integer riskScore = 20; // 기본값
        
        for (Asset asset : assets) {
            // 구매-설치 간격 분석
            if (asset.PurchaseDate != null && asset.InstallDate != null) {
                Integer daysBetween = asset.PurchaseDate.daysBetween(asset.InstallDate);
                
                if (daysBetween <= 3) {
                    riskScore = 15; // 빠른 도입 = 낮은 리스크
                } else if (daysBetween <= 7) {
                    riskScore = 25; // 보통
                } else {
                    riskScore = 40; // 느린 도입 = 높은 리스크
                }
            }
        }
        
        return riskScore;
    }
    
    /**
     * 커뮤니케이션 리스크 분석
     */
    private static Integer analyzeCommunicationRisk(List<Asset> assets) {
        Integer riskScore = 30;
        
        Set<Id> uniqueContacts = new Set<Id>();
        Boolean hasDoNotCallContact = false;
        
        for (Asset asset : assets) {
            if (asset.ContactId != null) {
                uniqueContacts.add(asset.ContactId);
                if (asset.Contact.DoNotCall) {
                    hasDoNotCallContact = true;
                }
            }
        }
        
        // Contact 다양성 분석
        if (uniqueContacts.size() == 1) {
            riskScore = 50; // 단일 접점 리스크
        } else if (uniqueContacts.size() >= 2) {
            riskScore = 20; // 다중 접점 = 낮은 리스크
        }
        
        // 연락 거부 설정
        if (hasDoNotCallContact) {
            riskScore += 20;
        }
        
        return Math.min(riskScore, 100);
    }
    
    /**
     * 경쟁사 전환 리스크 분석
     */
    private static Integer analyzeCompetitorRisk(List<Asset> assets) {
        Integer riskScore = 40;
        
        for (Asset asset : assets) {
            // Product 이름에서 경쟁사 제품 여부 확인
            if (asset.Product2 != null && asset.Product2.Name.contains('Competitor')) {
                riskScore = 60; // 이미 경쟁사 제품 사용 중
            }
        }
        
        return riskScore;
    }
    
    /**
     * 종합 리스크 점수 계산 (가중평균)
     */
    private static Integer calculateOverallRisk(CustomerRiskAnalysis analysis) {
        // 가중치: 납부(40%), 사용패턴(20%), 커뮤니케이션(25%), 경쟁사(15%)
        Integer weightedScore = 
            (analysis.paymentRiskScore * 40 +
             analysis.usageRiskScore * 20 +
             analysis.communicationRiskScore * 25 +
             analysis.competitorRiskScore * 15) / 100;
        
        return weightedScore;
    }
    
    /**
     * 리스크 완화 액션 플랜 생성
     */
    private static String generateRiskMitigationPlan(CustomerRiskAnalysis analysis) {
        List<String> actions = new List<String>();
        
        // 납부 리스크 대응
        if (analysis.paymentRiskScore <= 20) {
            actions.add('✅ 납부 우수 고객: 프리미엄 서비스 제공 및 충성도 프로그램 적용');
        } else if (analysis.paymentRiskScore >= 60) {
            actions.add('⚠️ 납부 리스크: 결제 편의성 개선 및 분할납부 옵션 제시');
        }
        
        // 커뮤니케이션 리스크 대응
        if (analysis.communicationRiskScore >= 50) {
            actions.add('📞 접점 다양화: 추가 담당자 발굴 및 관계 구축');
            actions.add('📧 다채널 커뮤니케이션: 이메일, SMS, 앱 푸시 등 활용');
        }
        
        // 경쟁사 리스크 대응
        if (analysis.competitorRiskScore >= 50) {
            actions.add('🎯 차별화 전략: 경쟁사 대비 우위점 지속적 어필');
            actions.add('🤝 관계 강화: 정기 방문 및 만족도 조사 실시');
        }
        
        // 종합 대응
        if (analysis.overallRiskScore <= 30) {
            actions.add('⭐ 저리스크 고객: 레퍼런스 활용 및 추천 고객 요청');
        } else if (analysis.overallRiskScore >= 60) {
            actions.add('🚨 고리스크 고객: 즉시 고객 미팅 및 이슈 해결');
        }
        
        return String.join(actions, '\n');
    }
    
    /**
     * 고객 만족도 예측
     */
    private static Integer predictCustomerSatisfaction(List<Asset> assets) {
        Integer satisfactionScore = 70; // 기본값
        
        // 완납 이력이 있으면 만족도 상승
        for (Asset asset : assets) {
            if (asset.Description != null && asset.Description.contains('완납 완료')) {
                satisfactionScore = 85;
            }
            
            // 빠른 설치는 적극적 도입 의지 = 높은 만족도
            if (asset.PurchaseDate != null && asset.InstallDate != null) {
                Integer installDays = asset.PurchaseDate.daysBetween(asset.InstallDate);
                if (installDays <= 3) {
                    satisfactionScore += 10;
                }
            }
        }
        
        return Math.min(satisfactionScore, 100);
    }
    
    /**
     * Wrapper Class for Customer Risk Analysis
     */
    public class CustomerRiskAnalysis {
        @AuraEnabled public Integer paymentRiskScore { get; set; }
        @AuraEnabled public Integer usageRiskScore { get; set; }
        @AuraEnabled public Integer communicationRiskScore { get; set; }
        @AuraEnabled public Integer competitorRiskScore { get; set; }
        @AuraEnabled public Integer overallRiskScore { get; set; }
        @AuraEnabled public String riskMitigationActions { get; set; }
        @AuraEnabled public Integer satisfactionPrediction { get; set; }
        
        @AuraEnabled public String riskLevel { 
            get {
                if (overallRiskScore <= 30) return 'LOW';
                else if (overallRiskScore <= 60) return 'MEDIUM';
                else return 'HIGH';
            }
        }
        
        @AuraEnabled public String satisfactionLevel {
            get {
                if (satisfactionPrediction >= 80) return 'HIGH';
                else if (satisfactionPrediction >= 60) return 'MEDIUM';
                else return 'LOW';
            }
        }
    }
}
