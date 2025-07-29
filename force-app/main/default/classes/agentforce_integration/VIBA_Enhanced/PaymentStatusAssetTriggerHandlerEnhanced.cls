/**
 * @description Enhanced PaymentStatus Asset Trigger Handler with VIBA Integration
 * @author VIBA AI Assistant
 * @date 2025-01-27
 * @version 2.0 - AI 통합 버전
 */
public class PaymentStatusAssetTriggerHandlerEnhanced {
    
    // VIBA 로깅 상수
    private static final String VIBA_LOG_PREFIX = '🤖 VIBA-Enhanced: ';
    
    /**
     * @description PaymentStatus 업데이트 후 AI 기반 통합 처리
     * @param updatedPaymentStatuses 업데이트된 PaymentStatus 목록
     * @param oldPaymentStatusMap 이전 PaymentStatus 맵
     */
    public static void handleAfterUpdateWithVIBA(List<PaymentStatus__c> updatedPaymentStatuses, Map<Id, PaymentStatus__c> oldPaymentStatusMap) {
        System.debug(VIBA_LOG_PREFIX + '업데이트 후 처리 시작. 레코드 수: ' + updatedPaymentStatuses.size());
        
        // 1. 완납 감지 및 Asset 생성
        Set<Id> orderIdsForAssetCreation = detectPaymentCompletions(updatedPaymentStatuses, oldPaymentStatusMap);
        
        // 2. 위험도 변화 감지
        Set<Id> accountIdsForRiskAnalysis = detectRiskChanges(updatedPaymentStatuses, oldPaymentStatusMap);
        
        // 3. 기회 발굴 대상 감지
        Set<Id> accountIdsForOpportunityAnalysis = detectOpportunityChanges(updatedPaymentStatuses, oldPaymentStatusMap);
        
        // 4. 비동기 처리로 성능 최적화
        if (!orderIdsForAssetCreation.isEmpty()) {
            processAssetCreationWithVIBA(orderIdsForAssetCreation);
        }
        
        if (!accountIdsForRiskAnalysis.isEmpty()) {
            processRiskAnalysisWithVIBA(accountIdsForRiskAnalysis);
        }
        
        if (!accountIdsForOpportunityAnalysis.isEmpty()) {
            processOpportunityAnalysisWithVIBA(accountIdsForOpportunityAnalysis);
        }
        
        System.debug(VIBA_LOG_PREFIX + '업데이트 후 처리 완료');
    }
    
    /**
     * @description PaymentStatus 삽입 후 AI 기반 통합 처리
     */
    public static void handleAfterInsertWithVIBA(List<PaymentStatus__c> newPaymentStatuses) {
        System.debug(VIBA_LOG_PREFIX + '삽입 후 처리 시작. 레코드 수: ' + newPaymentStatuses.size());
        
        // 신규 생성된 완납 상태 처리
        Set<Id> orderIdsToCheck = new Set<Id>();
        Set<Id> accountIdsForWelcomeAnalysis = new Set<Id>();
        
        for (PaymentStatus__c paymentStatus : newPaymentStatuses) {
            if (paymentStatus.Status__c == '완납') {
                orderIdsToCheck.add(paymentStatus.Order__c);
                
                // 신규 고객 환영 분석 준비
                accountIdsForWelcomeAnalysis.add(getAccountIdFromOrder(paymentStatus.Order__c));
                
                System.debug(VIBA_LOG_PREFIX + '완납 상태로 생성 감지. PaymentStatusId: ' + paymentStatus.Id);
            }
        }
        
        if (!orderIdsToCheck.isEmpty()) {
            processAssetCreationWithVIBA(orderIdsToCheck);
        }
        
        if (!accountIdsForWelcomeAnalysis.isEmpty()) {
            processWelcomeAnalysisWithVIBA(accountIdsForWelcomeAnalysis);
        }
        
        System.debug(VIBA_LOG_PREFIX + '삽입 후 처리 완료');
    }
    
    /**
     * @description PaymentStatus 업데이트 전 AI 기반 전처리
     */
    public static void handleBeforeUpdateWithVIBA(List<PaymentStatus__c> updatedPaymentStatuses, Map<Id, PaymentStatus__c> oldPaymentStatusMap) {
        System.debug(VIBA_LOG_PREFIX + '업데이트 전 처리 시작');
        
        for (PaymentStatus__c paymentStatus : updatedPaymentStatuses) {
            PaymentStatus__c oldPaymentStatus = oldPaymentStatusMap.get(paymentStatus.Id);
            
            // AI 기반 위험도 점수 계산
            if (paymentStatus.Status__c != oldPaymentStatus.Status__c) {
                paymentStatus.AI_Risk_Score__c = VIBARiskCalculator.calculatePaymentRisk(paymentStatus);
                paymentStatus.Next_Contact_Date__c = VIBAScheduler.calculateOptimalContactTime(paymentStatus);
            }
            
            // VIBA 권장 액션 설정
            if (paymentStatus.Status__c == '연체') {
                paymentStatus.Recommended_Action__c = VIBAActionGenerator.generateOverdueAction(paymentStatus);
            } else if (paymentStatus.Status__c == '완납') {
                paymentStatus.Recommended_Action__c = 'Asset 생성 및 고객 감사 연락';
            }
        }
        
        System.debug(VIBA_LOG_PREFIX + '업데이트 전 처리 완료');
    }
    
    // ============================================================================
    // Private Helper Methods - Enhanced with VIBA
    // ============================================================================
    
    /**
     * @description 완납 완료 감지 (VIBA 향상)
     */
    private static Set<Id> detectPaymentCompletions(List<PaymentStatus__c> updatedPayments, Map<Id, PaymentStatus__c> oldMap) {
        Set<Id> orderIdsToCheck = new Set<Id>();
        
        for (PaymentStatus__c payment : updatedPayments) {
            PaymentStatus__c oldPayment = oldMap.get(payment.Id);
            
            // 완납으로 변경된 경우
            if (payment.Status__c == '완납' && oldPayment.Status__c != '완납') {
                orderIdsToCheck.add(payment.Order__c);
                
                // VIBA 로그
                System.debug(VIBA_LOG_PREFIX + '완납 감지 - PaymentStatusId: ' + payment.Id + ', OrderId: ' + payment.Order__c);
                
                // 실시간 알림 발송
                VIBANotificationService.sendPaymentCompletionAlert(payment.Id);
            }
        }
        
        return orderIdsToCheck;
    }
    
    /**
     * @description 위험도 변화 감지 (VIBA 신규)
     */
    private static Set<Id> detectRiskChanges(List<PaymentStatus__c> updatedPayments, Map<Id, PaymentStatus__c> oldMap) {
        Set<Id> accountIdsForAnalysis = new Set<Id>();
        
        for (PaymentStatus__c payment : updatedPayments) {
            PaymentStatus__c oldPayment = oldMap.get(payment.Id);
            
            // 위험 상태로 변경 감지
            if (isRiskStatusChange(payment, oldPayment)) {
                Id accountId = getAccountIdFromOrder(payment.Order__c);
                if (accountId != null) {
                    accountIdsForAnalysis.add(accountId);
                    System.debug(VIBA_LOG_PREFIX + '위험도 변화 감지 - AccountId: ' + accountId);
                }
            }
        }
        
        return accountIdsForAnalysis;
    }
    
    /**
     * @description 기회 변화 감지 (VIBA 신규)
     */
    private static Set<Id> detectOpportunityChanges(List<PaymentStatus__c> updatedPayments, Map<Id, PaymentStatus__c> oldMap) {
        Set<Id> accountIdsForAnalysis = new Set<Id>();
        
        for (PaymentStatus__c payment : updatedPayments) {
            PaymentStatus__c oldPayment = oldMap.get(payment.Id);
            
            // 긍정적 변화 감지 (연체 → 완납, 미납 → 완납)
            if (isPositiveStatusChange(payment, oldPayment)) {
                Id accountId = getAccountIdFromOrder(payment.Order__c);
                if (accountId != null) {
                    accountIdsForAnalysis.add(accountId);
                    System.debug(VIBA_LOG_PREFIX + '기회 발굴 대상 감지 - AccountId: ' + accountId);
                }
            }
        }
        
        return accountIdsForAnalysis;
    }
    
    /**
     * @description VIBA 기반 Asset 생성 처리
     */
    private static void processAssetCreationWithVIBA(Set<Id> orderIds) {
        System.debug(VIBA_LOG_PREFIX + 'Asset 생성 프로세스 시작. Order 수: ' + orderIds.size());
        
        for (Id orderId : orderIds) {
            try {
                // 1. 기존 완납 확인 로직
                if (OrderAssetCreationService.isOrderFullyPaid(orderId)) {
                    
                    // 2. VIBA 분석 수행
                    VIBARequest request = new VIBARequest();
                    request.requestId = 'ASSET_CREATION_' + orderId;
                    request.type = 'Order';
                    request.recordId = orderId;
                    
                    List<VIBAResponse> responses = VIBAFrameworkController.performComprehensiveAnalysis(new List<VIBARequest>{request});
                    
                    // 3. Asset 생성 (기존 로직 활용)
                    Asset newAsset = AccountBasedAssetService.createAssetWithAccountAnalysis(orderId);
                    
                    if (newAsset != null) {
                        // 4. VIBA 기반 후속 액션
                        processPostAssetCreationWithVIBA(newAsset, responses[0]);
                        
                        System.debug(VIBA_LOG_PREFIX + 'Asset 생성 성공 - AssetId: ' + newAsset.Id);
                    }
                }
                
            } catch (Exception e) {
                System.debug(VIBA_LOG_PREFIX + 'Asset 생성 오류 - OrderId: ' + orderId + ', Error: ' + e.getMessage());
                createVIBAErrorTask(orderId, e.getMessage());
            }
        }
    }
    
    /**
     * @description VIBA 기반 위험도 분석 처리
     */
    private static void processRiskAnalysisWithVIBA(Set<Id> accountIds) {
        System.debug(VIBA_LOG_PREFIX + '위험도 분석 시작. Account 수: ' + accountIds.size());
        
        List<Id> accountIdsList = new List<Id>(accountIds);
        
        // 비동기 위험도 분석
        if (!System.isBatch() && !System.isFuture()) {
            processRiskAnalysisAsync(accountIdsList);
        } else {
            // 동기 처리 (배치나 Future 컨텍스트에서)
            List<VIBARiskPrediction> predictions = VIBAFrameworkController.predictCustomerRisk(accountIdsList);
            
            for (VIBARiskPrediction prediction : predictions) {
                if (prediction.success && prediction.riskLevel == 'High') {
                    createUrgentRiskTask(prediction);
                }
            }
        }
    }
    
    /**
     * @description VIBA 기반 기회 분석 처리
     */
    private static void processOpportunityAnalysisWithVIBA(Set<Id> accountIds) {
        System.debug(VIBA_LOG_PREFIX + '기회 분석 시작. Account 수: ' + accountIds.size());
        
        for (Id accountId : accountIds) {
            try {
                // 해당 Account의 Assets 조회
                List<Asset> assets = [SELECT Id FROM Asset WHERE AccountId = :accountId LIMIT 5];
                
                if (!assets.isEmpty()) {
                    List<Id> assetIds = new List<Id>();
                    for (Asset asset : assets) {
                        assetIds.add(asset.Id);
                    }
                    
                    // VIBA 기회 분석
                    List<VIBAOpportunityInsight> opportunities = VIBAFrameworkController.identifyOpportunities(assetIds);
                    
                    for (VIBAOpportunityInsight opportunity : opportunities) {
                        if (opportunity.success && opportunity.opportunityScore > 70) {
                            createOpportunityTask(opportunity);
                        }
                    }
                }
                
            } catch (Exception e) {
                System.debug(VIBA_LOG_PREFIX + '기회 분석 오류 - AccountId: ' + accountId + ', Error: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description 신규 고객 환영 분석
     */
    private static void processWelcomeAnalysisWithVIBA(Set<Id> accountIds) {
        System.debug(VIBA_LOG_PREFIX + '신규 고객 환영 분석 시작. Account 수: ' + accountIds.size());
        
        for (Id accountId : accountIds) {
            // 첫 완납 고객인지 확인
            if (isFirstTimeCompletedCustomer(accountId)) {
                createWelcomeTask(accountId);
            }
        }
    }
    
    /**
     * @description Asset 생성 후 VIBA 기반 후속 처리
     */
    private static void processPostAssetCreationWithVIBA(Asset newAsset, VIBAResponse vibaResponse) {
        try {
            // 1. VIBA 축하 메시지 발송
            VIBANotificationService.sendAssetCreationCelebration(newAsset, vibaResponse);
            
            // 2. 고객 만족도 조사 스케줄링
            VIBAScheduler.scheduleCustomerSatisfactionSurvey(newAsset);
            
            // 3. 갱신 기회 분석 및 예약
            VIBAScheduler.scheduleRenewalAnalysis(newAsset);
            
            System.debug(VIBA_LOG_PREFIX + 'Asset 생성 후 처리 완료 - AssetId: ' + newAsset.Id);
            
        } catch (Exception e) {
            System.debug(VIBA_LOG_PREFIX + 'Asset 생성 후 처리 오류: ' + e.getMessage());
        }
    }
    
    // ============================================================================
    // Utility Methods
    // ============================================================================
    
    /**
     * @description Order로부터 Account ID 조회
     */
    private static Id getAccountIdFromOrder(Id orderId) {
        try {
            List<Order> orders = [SELECT AccountId FROM Order WHERE Id = :orderId LIMIT 1];
            return orders.isEmpty() ? null : orders[0].AccountId;
        } catch (Exception e) {
            System.debug(VIBA_LOG_PREFIX + 'Account ID 조회 오류: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description 위험 상태 변화 확인
     */
    private static Boolean isRiskStatusChange(PaymentStatus__c newPayment, PaymentStatus__c oldPayment) {
        return (newPayment.Status__c == '연체' && oldPayment.Status__c != '연체') ||
               (newPayment.Status__c == '미납' && oldPayment.Status__c == '완납');
    }
    
    /**
     * @description 긍정적 상태 변화 확인
     */
    private static Boolean isPositiveStatusChange(PaymentStatus__c newPayment, PaymentStatus__c oldPayment) {
        return (newPayment.Status__c == '완납' && 
                (oldPayment.Status__c == '연체' || oldPayment.Status__c == '미납'));
    }
    
    /**
     * @description 첫 완납 고객 확인
     */
    private static Boolean isFirstTimeCompletedCustomer(Id accountId) {
        Integer completedPaymentCount = [
            SELECT COUNT() 
            FROM PaymentStatus__c 
            WHERE Order__r.AccountId = :accountId 
            AND Status__c = '완납'
        ];
        
        return completedPaymentCount == 1; // 첫 번째 완납
    }
    
    /**
     * @description VIBA 오류 Task 생성
     */
    private static void createVIBAErrorTask(Id orderId, String errorMessage) {
        try {
            Task errorTask = new Task(
                Subject = '🤖 VIBA Asset 생성 오류 처리 필요',
                Description = 'OrderId: ' + orderId + '\n오류 내용: ' + errorMessage + '\n\n수동 Asset 생성을 검토해주세요.',
                Priority = 'High',
                Status = 'Not Started',
                WhatId = orderId,
                ActivityDate = Date.today()
            );
            
            insert errorTask;
            
        } catch (Exception e) {
            System.debug(VIBA_LOG_PREFIX + '오류 Task 생성 실패: ' + e.getMessage());
        }
    }
    
    /**
     * @description 긴급 위험 Task 생성
     */
    private static void createUrgentRiskTask(VIBARiskPrediction prediction) {
        try {
            Task riskTask = new Task(
                Subject = '🚨 VIBA 고위험 고객 즉시 대응 필요',
                Description = prediction.message + '\n\n즉시 고객 접촉 및 리스크 관리 필요',
                Priority = 'High',
                Status = 'Not Started',
                ActivityDate = Date.today()
            );
            
            // Account Owner에게 할당
            List<Account> accounts = [SELECT OwnerId FROM Account WHERE Id = :prediction.accountId LIMIT 1];
            if (!accounts.isEmpty()) {
                riskTask.OwnerId = accounts[0].OwnerId;
            }
            
            insert riskTask;
            
        } catch (Exception e) {
            System.debug(VIBA_LOG_PREFIX + '위험 Task 생성 실패: ' + e.getMessage());
        }
    }
    
    /**
     * @description 기회 Task 생성
     */
    private static void createOpportunityTask(VIBAOpportunityInsight opportunity) {
        try {
            Task opportunityTask = new Task(
                Subject = '🚀 VIBA 기회 발굴 - 즉시 액션',
                Description = opportunity.message + '\n\n예상 매출: ' + opportunity.estimatedRevenue + '원',
                Priority = 'Normal',
                Status = 'Not Started',
                WhatId = opportunity.assetId,
                ActivityDate = Date.today().addDays(1)
            );
            
            insert opportunityTask;
            
        } catch (Exception e) {
            System.debug(VIBA_LOG_PREFIX + '기회 Task 생성 실패: ' + e.getMessage());
        }
    }
    
    /**
     * @description 환영 Task 생성
     */
    private static void createWelcomeTask(Id accountId) {
        try {
            Task welcomeTask = new Task(
                Subject = '🎉 VIBA 신규 완납 고객 환영 안내',
                Description = '첫 완납을 달성한 소중한 고객입니다!\n\n' +
                            '1. 완납 축하 연락\n' +
                            '2. 서비스 만족도 확인\n' +
                            '3. 추가 서비스 니즈 파악\n' +
                            '4. 장기 관계 구축 계획 수립',
                Priority = 'Normal',
                Status = 'Not Started',
                ActivityDate = Date.today().addDays(1)
            );
            
            // Account Owner에게 할당
            List<Account> accounts = [SELECT OwnerId FROM Account WHERE Id = :accountId LIMIT 1];
            if (!accounts.isEmpty()) {
                welcomeTask.OwnerId = accounts[0].OwnerId;
            }
            
            insert welcomeTask;
            
        } catch (Exception e) {
            System.debug(VIBA_LOG_PREFIX + '환영 Task 생성 실패: ' + e.getMessage());
        }
    }
    
    // ============================================================================
    // Async Processing Methods
    // ============================================================================
    
    /**
     * @description 비동기 위험도 분석
     */
    @future
    private static void processRiskAnalysisAsync(List<Id> accountIds) {
        try {
            List<VIBARiskPrediction> predictions = VIBAFrameworkController.predictCustomerRisk(accountIds);
            
            for (VIBARiskPrediction prediction : predictions) {
                if (prediction.success && prediction.riskLevel == 'High') {
                    createUrgentRiskTask(prediction);
                }
            }
            
            System.debug(VIBA_LOG_PREFIX + '비동기 위험도 분석 완료. 처리된 Account 수: ' + accountIds.size());
            
        } catch (Exception e) {
            System.debug(VIBA_LOG_PREFIX + '비동기 위험도 분석 오류: ' + e.getMessage());
        }
    }
}
