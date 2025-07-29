/**
 * @description Asset 상태 자동 관리 서비스
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AssetStatusManagementService {
    
    /**
     * Asset 상태를 자동으로 업데이트하는 메인 메서드
     */
    public static void updateAssetStatuses() {
        try {
            // 1. 새로 생성된 Asset을 Active로 변경
            activateNewAssets();
            
            // 2. 만료된 Asset을 Obsolete로 변경
            deactivateExpiredAssets();
            
            // 3. 갱신 예정 Asset에 대한 알림 생성
            createRenewalNotifications();
            
            // 4. Asset 상태 변경 로그 생성
            logAssetStatusChanges();
            
        } catch(Exception e) {
            System.debug('AssetStatusManagementService Error: ' + e.getMessage());
        }
    }
    
    /**
     * 새로 생성된 Asset을 Active 상태로 변경
     */
    private static void activateNewAssets() {
        List<Asset> newAssets = [
            SELECT Id, Name, Status, InstallDate, UsageEndDate
            FROM Asset 
            WHERE Status = 'Purchased' 
            AND InstallDate <= :Date.today()
            AND (UsageEndDate = null OR UsageEndDate > :Date.today())
        ];
        
        if(!newAssets.isEmpty()) {
            for(Asset asset : newAssets) {
                asset.Status = 'Installed';
                
                // Usage End Date가 없으면 1년 후로 설정
                if(asset.UsageEndDate == null) {
                    asset.UsageEndDate = Date.today().addYears(1);
                }
            }
            
            update newAssets;
            System.debug('✅ ' + newAssets.size() + '개 Asset이 Active 상태로 변경되었습니다.');
        }
    }
    
    /**
     * 만료된 Asset을 Obsolete 상태로 변경
     */
    private static void deactivateExpiredAssets() {
        List<Asset> expiredAssets = [
            SELECT Id, Name, Status, UsageEndDate, Account.Name
            FROM Asset 
            WHERE Status IN ('Purchased', 'Installed')
            AND UsageEndDate < :Date.today()
        ];
        
        if(!expiredAssets.isEmpty()) {
            for(Asset asset : expiredAssets) {
                asset.Status = 'Obsolete';
            }
            
            update expiredAssets;
            
            // 만료 알림 생성
            createExpirationTasks(expiredAssets);
            System.debug('⚠️ ' + expiredAssets.size() + '개 Asset이 만료 처리되었습니다.');
        }
    }
    
    /**
     * 갱신 예정 Asset에 대한 알림 생성 (90일, 60일, 30일 전)
     */
    private static void createRenewalNotifications() {
        // 90일 전 알림
        Date date90 = Date.today().addDays(90);
        createRenewalTasksForDate(date90, '90일 전');
        
        // 60일 전 알림
        Date date60 = Date.today().addDays(60);
        createRenewalTasksForDate(date60, '60일 전');
        
        // 30일 전 알림
        Date date30 = Date.today().addDays(30);
        createRenewalTasksForDate(date30, '30일 전');
    }
    
    /**
     * 특정 날짜의 갱신 예정 Asset에 대한 Task 생성
     */
    private static void createRenewalTasksForDate(Date targetDate, String timeFrame) {
        List<Asset> renewalAssets = [
            SELECT Id, Name, Account.Name, Account.OwnerId, UsageEndDate, Price, 
                   Contact.Name, Contact.Email, Account.Key_Account__c
            FROM Asset 
            WHERE UsageEndDate = :targetDate
            AND Status IN ('Purchased', 'Installed')
        ];
        
        if(!renewalAssets.isEmpty()) {
            List<Task> renewalTasks = new List<Task>();
            
            for(Asset asset : renewalAssets) {
                Task renewalTask = new Task();
                renewalTask.Subject = '[갱신 ' + timeFrame + '] ' + asset.Name + ' - 갱신 영업 시작';
                renewalTask.Description = buildRenewalTaskDescription(asset, timeFrame);
                renewalTask.Priority = asset.Account.Key_Account__c ? 'High' : 'Normal';
                renewalTask.Status = 'Not Started';
                renewalTask.ActivityDate = Date.today().addDays(7);
                renewalTask.OwnerId = asset.Account.OwnerId;
                renewalTask.WhatId = asset.Id;
                
                renewalTasks.add(renewalTask);
            }
            
            insert renewalTasks;
            System.debug('📅 ' + timeFrame + ' 갱신 알림 ' + renewalTasks.size() + '개 생성');
        }
    }
    
    /**
     * 갱신 Task 설명 생성
     */
    private static String buildRenewalTaskDescription(Asset asset, String timeFrame) {
        String description = '🔔 Asset 갱신 예정 알림\n\n';
        description += '📋 Asset: ' + asset.Name + '\n';
        description += '🏢 고객: ' + asset.Account.Name + '\n';
        description += '📅 만료일: ' + asset.UsageEndDate.format() + '\n';
        description += '💰 기존 가격: ₩' + (asset.Price != null ? asset.Price.format() : '0') + '\n';
        description += '👤 담당자: ' + (asset.Contact?.Name ?? '미지정') + '\n\n';
        
        description += '📌 ' + timeFrame + ' 액션 아이템:\n';
        
        if(timeFrame == '90일 전') {
            description += '□ 고객 만족도 조사 실시\n';
            description += '□ 사용 현황 분석 및 ROI 계산\n';
            description += '□ 갱신 제안서 초안 작성\n';
            description += '□ 경쟁사 동향 파악';
        } else if(timeFrame == '60일 전') {
            description += '□ 정식 갱신 제안서 제출\n';
            description += '□ 업그레이드 옵션 제안\n';
            description += '□ 의사결정자 미팅 일정 조율\n';
            description += '□ 계약 조건 협상 시작';
        } else if(timeFrame == '30일 전') {
            description += '□ 최종 계약 조건 확정\n';
            description += '□ 서명 일정 조율\n';
            description += '□ 갱신 혜택 최종 확인\n';
            description += '□ 후속 서비스 계획 수립';
        }
        
        return description;
    }
    
    /**
     * 만료된 Asset에 대한 후속 조치 Task 생성
     */
    private static void createExpirationTasks(List<Asset> expiredAssets) {
        List<Task> expirationTasks = new List<Task>();
        
        for(Asset asset : expiredAssets) {
            Task expirationTask = new Task();
            expirationTask.Subject = '[Asset 만료] ' + asset.Name + ' - 후속 조치 필요';
            expirationTask.Description = '⚠️ Asset이 만료되었습니다.\n\n';
            expirationTask.Description += '📋 Asset: ' + asset.Name + '\n';
            expirationTask.Description += '🏢 고객: ' + asset.Account.Name + '\n';
            expirationTask.Description += '📅 만료일: ' + asset.UsageEndDate.format() + '\n\n';
            expirationTask.Description += '📌 후속 조치:\n';
            expirationTask.Description += '□ 고객 연락하여 만료 확인\n';
            expirationTask.Description += '□ 갱신 의향 재확인\n';
            expirationTask.Description += '□ 만료 사유 분석\n';
            expirationTask.Description += '□ 향후 영업 전략 수립';
            
            expirationTask.Priority = 'High';
            expirationTask.Status = 'Not Started';
            expirationTask.ActivityDate = Date.today().addDays(1);
            
            // Account Owner에게 할당
            List<Account> accounts = [SELECT OwnerId FROM Account WHERE Id = :asset.AccountId LIMIT 1];
            if(!accounts.isEmpty()) {
                expirationTask.OwnerId = accounts[0].OwnerId;
            }
            expirationTask.WhatId = asset.Id;
            
            expirationTasks.add(expirationTask);
        }
        
        if(!expirationTasks.isEmpty()) {
            insert expirationTasks;
        }
    }
    
    /**
     * Asset 상태 변경 로그 생성
     */
    private static void logAssetStatusChanges() {
        // 최근 24시간 동안 변경된 Asset 상태 로그
        DateTime yesterday = DateTime.now().addDays(-1);
        
        List<Asset> recentChanges = [
            SELECT Id, Name, Status, Account.Name, LastModifiedDate, LastModifiedBy.Name
            FROM Asset 
            WHERE LastModifiedDate >= :yesterday
            ORDER BY LastModifiedDate DESC
        ];
        
        if(!recentChanges.isEmpty()) {
            String logMessage = '📊 Asset 상태 변경 로그 (최근 24시간)\n\n';
            
            for(Asset asset : recentChanges) {
                logMessage += '• ' + asset.Name + ' (' + asset.Account.Name + ')\n';
                logMessage += '  상태: ' + asset.Status + ' | 수정자: ' + asset.LastModifiedBy.Name + '\n';
                logMessage += '  수정일: ' + asset.LastModifiedDate.format() + '\n\n';
            }
            
            System.debug(logMessage);
        }
    }
    
    /**
     * 스케줄링을 위한 배치 실행 메서드
     */
    public static void scheduleStatusUpdate() {
        // 매일 오전 9시에 실행되도록 스케줄링
        String cronExp = '0 0 9 * * ?';
        AssetStatusUpdateBatch batch = new AssetStatusUpdateBatch();
        System.schedule('Asset Status Daily Update', cronExp, batch);
    }
}
