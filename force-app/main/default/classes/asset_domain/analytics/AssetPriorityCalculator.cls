/**
 * 로직 1: Assets 우선순위 계산 시스템
 * 영업사원을 위한 스마트한 고객 우선순위 자동 분류
 * 
 * 목적: "오늘 누구에게 먼저 연락할까?" → 5초 내 답변
 * 방식: 3개 핵심 요소로 단순한 점수 합산 (총 100점)
 */

public class AssetPriorityCalculator {
    
    // 우선순위 래퍼 클래스
    public class AssetPriority implements Comparable {
        @AuraEnabled public Asset asset { get; set; }
        @AuraEnabled public Decimal score { get; set; }
        @AuraEnabled public String urgencyLevel { get; set; }
        @AuraEnabled public String urgencyColor { get; set; }
        @AuraEnabled public String actionRecommendation { get; set; }
        @AuraEnabled public Decimal expectedRevenue { get; set; }
        @AuraEnabled public Integer daysFromInstall { get; set; }
        @AuraEnabled public String renewalStatus { get; set; }
        
        public AssetPriority() {
            this.score = 0;
        }
        
        // 정렬을 위한 compareTo 구현 (높은 점수 우선)
        public Integer compareTo(Object compareTo) {
            AssetPriority other = (AssetPriority) compareTo;
            if (this.score > other.score) return -1;
            if (this.score < other.score) return 1;
            return 0;
        }
    }
    
    // 결과 래퍼 클래스
    public class PriorityResult {
        @AuraEnabled public List<AssetPriority> priorities { get; set; }
        @AuraEnabled public Decimal totalExpectedRevenue { get; set; }
        @AuraEnabled public Integer urgentCount { get; set; }
        @AuraEnabled public Integer importantCount { get; set; }
        @AuraEnabled public Integer normalCount { get; set; }
        @AuraEnabled public String summary { get; set; }
        
        public PriorityResult() {
            this.priorities = new List<AssetPriority>();
            this.totalExpectedRevenue = 0;
            this.urgentCount = 0;
            this.importantCount = 0;
            this.normalCount = 0;
        }
    }
    
    /**
     * 메인 메서드: 영업사원별 우선순위 계산
     * @param salesRepId 영업사원 ID (null이면 현재 사용자)
     * @param topN 상위 N개 결과 (기본값: 10)
     * @return PriorityResult 우선순위 결과
     */
    @AuraEnabled(cacheable=true)
    public static PriorityResult calculatePriorities(Id salesRepId, Integer topN) {
        try {
            // 기본값 설정
            if (salesRepId == null) {
                salesRepId = UserInfo.getUserId();
            }
            if (topN == null || topN <= 0) {
                topN = 10;
            }
            
            System.debug('=== Assets 우선순위 계산 시작 ===');
            System.debug('영업사원 ID: ' + salesRepId);
            System.debug('상위 ' + topN + '개 결과 요청');
            
            PriorityResult result = new PriorityResult();
            
            // 1. 기본 Assets 데이터 조회 (필수 정보만)
            List<Asset> assets = getEligibleAssets(salesRepId);
            System.debug('분석 대상 Assets: ' + assets.size() + '개');
            
            if (assets.isEmpty()) {
                result.summary = '분석 가능한 Assets이 없습니다.';
                return result;
            }
            
            // 2. 각 Asset별 우선순위 계산
            List<AssetPriority> priorities = new List<AssetPriority>();
            for (Asset asset : assets) {
                AssetPriority priority = calculateAssetPriority(asset);
                priorities.add(priority);
                
                // 전체 통계 집계
                result.totalExpectedRevenue += priority.expectedRevenue;
                
                if (priority.score >= 80) {
                    result.urgentCount++;
                } else if (priority.score >= 60) {
                    result.importantCount++;
                } else {
                    result.normalCount++;
                }
            }
            
            // 3. 점수별 정렬 및 상위 N개 선택
            priorities.sort();
            
            // 상위 N개만 선택
            List<AssetPriority> topPriorities = new List<AssetPriority>();
            for (Integer i = 0; i < Math.min(topN, priorities.size()); i++) {
                topPriorities.add(priorities[i]);
            }
            
            result.priorities = topPriorities;
            
            // 4. 요약 메시지 생성
            result.summary = generateSummary(result);
            
            System.debug('=== 우선순위 계산 완료 ===');
            System.debug('긴급: ' + result.urgentCount + '건, 중요: ' + result.importantCount + '건, 일반: ' + result.normalCount + '건');
            System.debug('총 예상 매출: ₩' + result.totalExpectedRevenue?.format());
            
            return result;
            
        } catch (Exception e) {
            System.debug('우선순위 계산 오류: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            
            PriorityResult errorResult = new PriorityResult();
            errorResult.summary = '우선순위 계산 중 오류가 발생했습니다: ' + e.getMessage();
            return errorResult;
        }
    }
    
    /**
     * 분석 대상 Assets 조회
     * @param salesRepId 영업사원 ID
     * @return List<Asset> 분석 가능한 Assets
     */
    private static List<Asset> getEligibleAssets(Id salesRepId) {
        try {
            return [
                SELECT Id, Name, AccountId, Account.Name, Account.Phone, Account.Industry,
                       Status, InstallDate, PurchaseDate, Price, SerialNumber, 
                       Product2Id, Product2.Name, Product2.Family,
                       ContactId, Contact.Name, Contact.Email
                FROM Asset 
                WHERE Account.OwnerId = :salesRepId
                AND Status IN ('Installed', 'Registered', 'Shipped')
                AND InstallDate != null
                ORDER BY InstallDate DESC
                LIMIT 200 // Governor Limit 고려
            ];
        } catch (Exception e) {
            System.debug('Assets 조회 오류: ' + e.getMessage());
            return new List<Asset>();
        }
    }
    
    /**
     * 개별 Asset 우선순위 계산
     * @param asset Asset 레코드
     * @return AssetPriority 우선순위 정보
     */
    private static AssetPriority calculateAssetPriority(Asset asset) {
        AssetPriority priority = new AssetPriority();
        priority.asset = asset;
        
        Decimal score = 0;
        
        // 1. 갱신 임박도 계산 (50점) - 가장 중요한 요소
        Integer daysFromInstall = asset.InstallDate.daysBetween(Date.today());
        priority.daysFromInstall = daysFromInstall;
        
        if (daysFromInstall >= 1 && daysFromInstall <= 365) {
            // 갱신 적기 (1일 이상)
            score += 50;
            priority.renewalStatus = '갱신 적기';
            priority.actionRecommendation = '🔥 즉시 갱신 논의 시작';
        } else if (daysFromInstall >= 1 && daysFromInstall < 30) {
            // 갱신 예정 (1일-1개월)
            score += 30;
            priority.renewalStatus = '갱신 예정';
            priority.actionRecommendation = '⏰ 2주 내 갱신 준비';
        } else if (daysFromInstall >= 1 && daysFromInstall < 7) {
            // 갱신 대기 (1일-1주)
            score += 15;
            priority.renewalStatus = '갱신 대기';
            priority.actionRecommendation = '📅 관계 강화 필요';
        } else {
            priority.renewalStatus = '갱신 시기 아님';
            priority.actionRecommendation = '📋 정기 점검';
        }
        
        // 2. 매출 규모 계산 (30점) - 수익성 고려
        if (asset.Price != null) {
            if (asset.Price >= 5000000) {
                // 고액 (500만원 이상)
                score += 30;
            } else if (asset.Price >= 1000000) {
                // 중액 (100만원 이상)
                score += 15;
            }
            // 소액은 0점
        }
        
        // 3. 고객 안정성 계산 (20점) - 관계 건강도
        Integer caseCount = getCaseCount(asset.AccountId);
        
        if (caseCount == 0) {
            // 문제 없음
            score += 20;
        } else if (caseCount <= 2) {
            // 경미한 문제
            score += 10;
        }
        // 많은 문제는 0점
        
        // 최종 점수 및 등급 설정
        priority.score = score;
        priority.urgencyLevel = getUrgencyLevel(score);
        priority.urgencyColor = getUrgencyColor(score);
        
        // 예상 매출 계산 (갱신 확률 적용)
        if (asset.Price != null) {
            Decimal renewalProbability = calculateRenewalProbability(score);
            priority.expectedRevenue = asset.Price * (renewalProbability / 100);
        } else {
            priority.expectedRevenue = 0;
        }
        
        return priority;
    }
    
    /**
     * 긴급도 레벨 계산
     * @param score 우선순위 점수
     * @return String 긴급도 레벨
     */
    private static String getUrgencyLevel(Decimal score) {
        if (score >= 80) {
            return '긴급';
        } else if (score >= 60) {
            return '중요';
        } else if (score >= 40) {
            return '일반';
        } else {
            return '낮음';
        }
    }
    
    /**
     * 긴급도 색상 계산
     * @param score 우선순위 점수
     * @return String 색상 코드
     */
    private static String getUrgencyColor(Decimal score) {
        if (score >= 80) {
            return 'slds-theme_error'; // 빨간색
        } else if (score >= 60) {
            return 'slds-theme_warning'; // 주황색
        } else if (score >= 40) {
            return 'slds-theme_success'; // 녹색
        } else {
            return 'slds-theme_neutral'; // 회색
        }
    }
    
    /**
     * 갱신 확률 계산
     * @param score 우선순위 점수
     * @return Decimal 갱신 확률 (0-100)
     */
    private static Decimal calculateRenewalProbability(Decimal score) {
        if (score >= 90) {
            return 90; // 매우 높음
        } else if (score >= 80) {
            return 80; // 높음
        } else if (score >= 60) {
            return 65; // 보통
        } else if (score >= 40) {
            return 45; // 낮음
        } else {
            return 25; // 매우 낮음
        }
    }
    
    /**
     * 요약 메시지 생성
     * @param result 우선순위 결과
     * @return String 요약 메시지
     */
    private static String generateSummary(PriorityResult result) {
        String summary = '';
        
        if (result.urgentCount > 0) {
            summary += '🔥 긴급: ' + result.urgentCount + '건 ';
        }
        if (result.importantCount > 0) {
            summary += '⚠️ 중요: ' + result.importantCount + '건 ';
        }
        if (result.normalCount > 0) {
            summary += '📋 일반: ' + result.normalCount + '건';
        }
        
        if (result.totalExpectedRevenue > 0) {
            summary += ' | 예상 매출: ₩' + result.totalExpectedRevenue.format();
        }
        
        if (String.isBlank(summary)) {
            summary = '분석 결과가 없습니다.';
        }
        
        return summary.trim();
    }
    
    /**
     * 빠른 TOP 5 조회 (캐시 가능)
     * @return PriorityResult TOP 5 우선순위
     */
    @AuraEnabled(cacheable=true)
    public static PriorityResult getTop5Priorities() {
        return calculatePriorities(null, 5);
    }
    
    /**
     * 특정 Account의 Assets 우선순위 조회
     * @param accountId Account ID
     * @return PriorityResult Account Assets 우선순위
     */
    @AuraEnabled(cacheable=true)
    public static PriorityResult getAccountAssetPriorities(Id accountId) {
        try {
            List<Asset> assets = [
                SELECT Id, Name, AccountId, Account.Name, Account.Phone,
                       Status, InstallDate, Price, SerialNumber, 
                       Product2.Name, Contact.Name
                FROM Asset 
                WHERE AccountId = :accountId
                AND Status IN ('Installed', 'Registered')
                AND InstallDate != null
                ORDER BY InstallDate DESC
            ];
            
            PriorityResult result = new PriorityResult();
            
            for (Asset asset : assets) {
                AssetPriority priority = calculateAssetPriority(asset);
                result.priorities.add(priority);
                result.totalExpectedRevenue += priority.expectedRevenue;
            }
            
            result.priorities.sort();
            result.summary = 'Account Assets: ' + assets.size() + '개';
            
            return result;
            
        } catch (Exception e) {
            PriorityResult errorResult = new PriorityResult();
            errorResult.summary = 'Account Assets 조회 오류: ' + e.getMessage();
            return errorResult;
        }
    }
    
    /**
     * Account의 최근 90일 Case 수 조회
     * @param accountId Account ID
     * @return Integer Case 수
     */
    private static Integer getCaseCount(Id accountId) {
        try {
            if (accountId == null) return 0;
            
            List<AggregateResult> results = [
                SELECT COUNT(Id) caseCount
                FROM Case 
                WHERE AccountId = :accountId 
                AND CreatedDate = LAST_N_DAYS:90
            ];
            
            if (results.isEmpty()) return 0;
            return (Integer) results[0].get('caseCount');
            
        } catch (Exception e) {
            System.debug('Case 수 조회 오류: ' + e.getMessage());
            return 0; // 오류 시 안전한 기본값
        }
    }
}
