/**
 * 로직 2: 원클릭 갱신 워크플로우 서비스
 * 영업사원이 버튼 하나로 갱신 프로세스를 완료할 수 있도록 지원
 * 
 * 목적: "복잡한 갱신 업무를 5초 만에" → 20분 → 5초로 단축
 * 방식: Asset 기반 Opportunity + Task 자동 생성
 */

public class OneClickRenewalService {
    
    // 갱신 결과 래퍼 클래스
    public class RenewalResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Id opportunityId { get; set; }
        @AuraEnabled public Id taskId { get; set; }
        @AuraEnabled public String opportunityName { get; set; }
        @AuraEnabled public Decimal expectedRevenue { get; set; }
        @AuraEnabled public Date closeDate { get; set; }
        
        public RenewalResult() {
            this.success = false;
        }
    }
    
    /**
     * 메인 메서드: 원클릭 갱신 프로세스 시작
     * @param assetId Asset ID
     * @return RenewalResult 갱신 처리 결과
     */
    @AuraEnabled
    public static RenewalResult startRenewalProcess(Id assetId) {
        RenewalResult result = new RenewalResult();
        
        try {
            System.debug('=== 원클릭 갱신 프로세스 시작 ===');
            System.debug('Asset ID: ' + assetId);
            
            // 1. Asset 정보 검증 및 조회
            Asset assetInfo = validateAndGetAsset(assetId);
            if (assetInfo == null) {
                result.message = 'Asset 정보를 찾을 수 없습니다.';
                return result;
            }
            
            // 2. 중복 갱신 Opportunity 확인
            if (hasDuplicateRenewalOpportunity(assetInfo)) {
                result.message = '이미 진행 중인 갱신 기회가 있습니다.';
                return result;
            }
            
            // 3. Opportunity 자동 생성
            Opportunity renewalOpp = createRenewalOpportunity(assetInfo);
            if (renewalOpp == null) {
                result.message = 'Opportunity 생성에 실패했습니다.';
                return result;
            }
            
            // 4. Follow-up Task 자동 생성
            Task followupTask = createFollowupTask(assetInfo, renewalOpp);
            if (followupTask == null) {
                result.message = 'Task 생성에 실패했습니다.';
                return result;
            }
            
            // 5. 성공 결과 설정
            result.success = true;
            result.message = '갱신 프로세스가 성공적으로 시작되었습니다.';
            result.opportunityId = renewalOpp.Id;
            result.taskId = followupTask.Id;
            result.opportunityName = renewalOpp.Name;
            result.expectedRevenue = renewalOpp.Amount;
            result.closeDate = renewalOpp.CloseDate;
            
            System.debug('✅ 원클릭 갱신 완료');
            System.debug('생성된 Opportunity: ' + renewalOpp.Name);
            System.debug('생성된 Task: ' + followupTask.Subject);
            
            return result;
            
        } catch (Exception e) {
            System.debug('❌ 원클릭 갱신 오류: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            
            result.message = '갱신 프로세스 중 오류가 발생했습니다: ' + e.getMessage();
            return result;
        }
    }
    
    /**
     * Asset 정보 검증 및 조회
     * @param assetId Asset ID
     * @return Asset Asset 정보 (null이면 오류)
     */
    private static Asset validateAndGetAsset(Id assetId) {
        try {
            List<Asset> assets = [
                SELECT Id, Name, AccountId, Account.Name, Account.Phone, Account.OwnerId,
                       ContactId, Contact.Name, Contact.Email, 
                       Product2Id, Product2.Name, Product2.Family,
                       SerialNumber, Status, PurchaseDate, InstallDate, Price,
                       LifecycleStartDate, LifecycleEndDate
                FROM Asset 
                WHERE Id = :assetId 
                AND Status IN ('Installed', 'Registered', 'Purchased')
                LIMIT 1
            ];
            
            if (assets.isEmpty()) {
                System.debug('Asset not found or invalid status: ' + assetId);
                return null;
            }
            
            Asset asset = assets[0];
            System.debug('Asset 검증 완료: ' + asset.Name);
            
            // 필수 정보 확인
            if (asset.AccountId == null) {
                System.debug('Asset has no Account: ' + assetId);
                return null;
            }
            
            if (asset.Price == null || asset.Price <= 0) {
                System.debug('Asset has no valid price: ' + assetId);
                return null;
            }
            
            return asset;
            
        } catch (Exception e) {
            System.debug('Asset 조회 오류: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * 중복 갱신 Opportunity 확인
     * @param assetInfo Asset 정보
     * @return Boolean 중복 여부 (true이면 중복 존재)
     */
    private static Boolean hasDuplicateRenewalOpportunity(Asset assetInfo) {
        try {
            // 최근 6개월 내 같은 Asset에 대한 갱신 Opportunity 확인
            String renewalName = '%갱신%';
            Date sixMonthsAgo = Date.today().addMonths(-6);
            
            List<Opportunity> existingRenewals = [
                SELECT Id, Name, StageName, CloseDate
                FROM Opportunity 
                WHERE AccountId = :assetInfo.AccountId
                AND (Name LIKE :renewalName OR Name LIKE '%Renewal%')
                AND (Name LIKE :('%' + assetInfo.Name + '%') OR 
                     Name LIKE :('%' + assetInfo.SerialNumber + '%'))
                AND StageName NOT IN ('Closed Won', 'Closed Lost')
                AND CreatedDate >= :sixMonthsAgo
                LIMIT 5
            ];
            
            if (!existingRenewals.isEmpty()) {
                System.debug('중복 갱신 Opportunity 발견: ' + existingRenewals.size() + '개');
                for (Opportunity opp : existingRenewals) {
                    System.debug('- ' + opp.Name + ' (' + opp.StageName + ')');
                }
                return true;
            }
            
            return false;
            
        } catch (Exception e) {
            System.debug('중복 확인 오류: ' + e.getMessage());
            return false; // 오류 시 진행 허용
        }
    }
    
    /**
     * 갱신 Opportunity 자동 생성
     * @param assetInfo Asset 정보
     * @return Opportunity 생성된 Opportunity
     */
    private static Opportunity createRenewalOpportunity(Asset assetInfo) {
        try {
            Opportunity renewalOpp = new Opportunity();
            
            // 기본 정보 설정
            renewalOpp.Name = assetInfo.Account.Name + ' - ' + assetInfo.Name + ' 갱신';
            renewalOpp.AccountId = assetInfo.AccountId;
            renewalOpp.Amount = assetInfo.Price; // Asset 가격과 동일
            renewalOpp.CloseDate = Date.today().addDays(90); // 90일 후 마감
            renewalOpp.StageName = 'Prospecting'; // 초기 단계
            renewalOpp.Type = 'Existing Customer - Renewal';
            
            // 추가 정보 설정
            if (assetInfo.ContactId != null) {
                // Primary Contact는 표준 필드가 아니므로 주석 처리
                // renewalOpp.Primary_Contact__c = assetInfo.ContactId;
            }
            
            // Description 설정
            List<String> descParts = new List<String>();
            descParts.add('🔄 자동 생성된 갱신 기회');
            descParts.add('');
            descParts.add('📋 Asset 정보:');
            descParts.add('- Asset명: ' + assetInfo.Name);
            descParts.add('- Serial Number: ' + assetInfo.SerialNumber);
            descParts.add('- 현재 가격: ₩' + String.valueOf(assetInfo.Price));
            descParts.add('- 설치일: ' + (assetInfo.InstallDate != null ? assetInfo.InstallDate.format() : '미확인'));
            
            if (assetInfo.Contact.Name != null) {
                descParts.add('- 담당자: ' + assetInfo.Contact.Name);
            }
            
            descParts.add('');
            descParts.add('🎯 갱신 목표:');
            descParts.add('- 기존 서비스 연장');
            descParts.add('- 고객 만족도 유지');
            descParts.add('- 장기 파트너십 강화');
            
            renewalOpp.Description = String.join(descParts, '\n');
            
            // Opportunity 저장
            insert renewalOpp;
            
            System.debug('✅ Opportunity 생성 완료: ' + renewalOpp.Name);
            
            // 생성된 Opportunity 정보 반환 (ID 포함)
            return [SELECT Id, Name, Amount, CloseDate, StageName FROM Opportunity WHERE Id = :renewalOpp.Id];
            
        } catch (Exception e) {
            System.debug('❌ Opportunity 생성 오류: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Follow-up Task 자동 생성
     * @param assetInfo Asset 정보
     * @param opportunity 생성된 Opportunity
     * @return Task 생성된 Task
     */
    private static Task createFollowupTask(Asset assetInfo, Opportunity opportunity) {
        try {
            Task followupTask = new Task();
            
            // 기본 정보 설정
            followupTask.Subject = '🔄 갱신 논의: ' + assetInfo.Account.Name;
            followupTask.Status = 'Not Started';
            followupTask.Priority = 'High';
            followupTask.ActivityDate = Date.today().addDays(1); // 내일
            followupTask.OwnerId = UserInfo.getUserId(); // 현재 사용자
            
            // 연결 정보 설정
            followupTask.WhatId = opportunity.Id; // Opportunity와 연결
            followupTask.WhoId = assetInfo.ContactId; // Contact와 연결 (있는 경우)
            
            // Description 설정
            List<String> taskDescParts = new List<String>();
            taskDescParts.add('🎯 갱신 논의 진행');
            taskDescParts.add('');
            taskDescParts.add('📞 연락 정보:');
            taskDescParts.add('- 고객: ' + assetInfo.Account.Name);
            
            if (assetInfo.Contact.Name != null) {
                taskDescParts.add('- 담당자: ' + assetInfo.Contact.Name);
            }
            
            if (assetInfo.Account.Phone != null) {
                taskDescParts.add('- 전화: ' + assetInfo.Account.Phone);
            }
            
            if (assetInfo.Contact.Email != null) {
                taskDescParts.add('- 이메일: ' + assetInfo.Contact.Email);
            }
            
            taskDescParts.add('');
            taskDescParts.add('💼 논의 내용:');
            taskDescParts.add('1. 현재 서비스 만족도 확인');
            taskDescParts.add('2. 갱신 조건 및 가격 협의');
            taskDescParts.add('3. 추가 서비스 필요성 논의');
            taskDescParts.add('4. 계약 일정 조율');
            
            taskDescParts.add('');
            taskDescParts.add('🔗 관련 Opportunity: ' + opportunity.Name);
            taskDescParts.add('💰 예상 금액: ₩' + String.valueOf(opportunity.Amount));
            
            followupTask.Description = String.join(taskDescParts, '\n');
            
            // Task 저장
            insert followupTask;
            
            System.debug('✅ Task 생성 완료: ' + followupTask.Subject);
            
            // 생성된 Task 정보 반환 (ID 포함)
            return [SELECT Id, Subject, Status, Priority, ActivityDate FROM Task WHERE Id = :followupTask.Id];
            
        } catch (Exception e) {
            System.debug('❌ Task 생성 오류: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * 대량 갱신 처리 (배치용)
     * @param assetIds Asset ID 목록
     * @return List<RenewalResult> 처리 결과 목록
     */
    @AuraEnabled
    public static List<RenewalResult> processBulkRenewals(List<Id> assetIds) {
        List<RenewalResult> results = new List<RenewalResult>();
        
        System.debug('=== 대량 갱신 처리 시작 ===');
        System.debug('대상 Asset 수: ' + assetIds.size());
        
        for (Id assetId : assetIds) {
            try {
                RenewalResult result = startRenewalProcess(assetId);
                results.add(result);
                
                // Governor Limit 고려하여 잠시 대기
                if (Math.mod(results.size(), 50) == 0) {
                    System.debug('중간 체크포인트: ' + results.size() + '개 처리 완료');
                }
                
            } catch (Exception e) {
                RenewalResult errorResult = new RenewalResult();
                errorResult.success = false;
                errorResult.message = 'Asset ' + assetId + ' 처리 오류: ' + e.getMessage();
                results.add(errorResult);
            }
        }
        
        System.debug('=== 대량 갱신 처리 완료 ===');
        System.debug('총 처리: ' + results.size() + '개');
        
        return results;
    }
    
    /**
     * 갱신 가능한 Asset 목록 조회
     * @param ownerId 소유자 ID (null이면 현재 사용자)
     * @return List<Asset> 갱신 가능한 Asset 목록
     */
    @AuraEnabled(cacheable=true)
    public static List<Asset> getRenewableAssets(Id ownerId) {
        try {
            if (ownerId == null) {
                ownerId = UserInfo.getUserId();
            }
            
            // 갱신 가능한 조건: 설치 후 1일 이상, 활성 상태 (즉시 갱신 가능)
            Date renewalThreshold = Date.today().addDays(-1);
            
            return [
                SELECT Id, Name, AccountId, Account.Name, Account.Phone,
                       ContactId, Contact.Name, Contact.Email,
                       SerialNumber, Status, PurchaseDate, InstallDate, Price,
                       LifecycleEndDate
                FROM Asset 
                WHERE Account.OwnerId = :ownerId
                AND Status IN ('Installed', 'Registered', 'Purchased')
                AND InstallDate <= :renewalThreshold
                AND Price > 0
                ORDER BY InstallDate ASC, Price DESC
                LIMIT 100
            ];
            
        } catch (Exception e) {
            System.debug('갱신 가능 Asset 조회 오류: ' + e.getMessage());
            return new List<Asset>();
        }
    }
}
