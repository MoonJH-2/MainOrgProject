/**
 * @description Account 필드 기반 Asset 비즈니스 로직 서비스
 * @author Copilot
 * @date 2024
 */
public with sharing class AccountBasedAssetService {
    
    /**
     * @description Account 정보를 포함한 Asset 생성 (OrderAssetCreationService 확장)
     * @param orderId Order ID
     * @return Asset 생성된 Asset 레코드
     */
    public static Asset createAssetWithAccountAnalysis(Id orderId) {
        try {
            // Order와 Account 상세 정보 조회
            Order orderInfo = [
                SELECT Id, OrderNumber, AccountId, TotalAmount, Status,
                       EffectiveDate, EndDate, CreatedDate, OwnerId,
                       Contact__c, Account.Name, Account.AccountNumber, Account.Industry,
                       Account.AnnualRevenue, Account.NumberOfEmployees,
                       Account.CustomerPriority__c, Account.Key_Account__c, Account.Active__c,
                       Account.AccountSource, Account.Ownership, Account.Site,
                       Account.Manager__c, Account.Manager__r.Name, Owner.Name
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            // 이미 Asset이 생성되었는지 확인
            List<Asset> existingAssets = [
                SELECT Id FROM Asset 
                WHERE SerialNumber = :orderInfo.OrderNumber
                LIMIT 1
            ];
            
            if (!existingAssets.isEmpty()) {
                System.debug('AccountBasedAssetService: Asset이 이미 존재합니다. OrderNumber: ' + orderInfo.OrderNumber);
                return existingAssets[0];
            }
            
            // Asset 생성
            Asset newAsset = new Asset();
            
            // 기본 Asset 정보
            newAsset.Name = buildAssetName(orderInfo);
            newAsset.AccountId = orderInfo.AccountId;
            newAsset.ContactId = orderInfo.Contact__c;
            newAsset.SerialNumber = orderInfo.OrderNumber;
            newAsset.PurchaseDate = orderInfo.EffectiveDate;
            newAsset.InstallDate = Date.today();
            newAsset.Status = 'Purchased';
            newAsset.Price = orderInfo.TotalAmount;
            newAsset.Quantity = 1;
            
            // Account 정보 기반 Asset 분류 및 Lifecycle 설정
            setAssetCategoryAndLifecycle(newAsset, orderInfo);
            
            // Asset Description with Account Analysis
            newAsset.Description = buildAccountBasedDescription(orderInfo);
            
            insert newAsset;
            
            System.debug('AccountBasedAssetService: Asset 생성 완료. AssetId: ' + newAsset.Id);
            
            // Account 기반 후속 액션 수행
            performAccountBasedActions(orderInfo, newAsset);
            
            return newAsset;
            
        } catch (Exception e) {
            System.debug('AccountBasedAssetService.createAssetWithAccountAnalysis Error: ' + e.getMessage());
            throw new AccountBasedAssetException('Account 기반 Asset 생성 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * @description Account 정보 기반 Asset 이름 생성
     * @param orderInfo Order 정보
     * @return String Asset 이름
     */
    private static String buildAssetName(Order orderInfo) {
        List<String> nameParts = new List<String>();
        
        nameParts.add(orderInfo.Account.Name);
        
        // Key Account 표시
        if (orderInfo.Account.Key_Account__c) {
            nameParts.add('(Key Account)');
        }
        
        // Einstein Tier 표시 (필드 존재 시)
        // if (String.isNotBlank(orderInfo.Account.Tier__c)) {
        //     nameParts.add('Tier:' + orderInfo.Account.Tier__c);
        // }
        
        // Industry 표시
        if (String.isNotBlank(orderInfo.Account.Industry)) {
            nameParts.add('[' + orderInfo.Account.Industry + ']');
        }
        
        nameParts.add('Order ' + orderInfo.OrderNumber);
        
        return String.join(nameParts, ' ');
    }
    
    /**
     * @description Account 정보 기반 Asset 카테고리 및 Lifecycle 설정
     * @param newAsset Asset 레코드
     * @param orderInfo Order 정보
     */
    private static void setAssetCategoryAndLifecycle(Asset newAsset, Order orderInfo) {
        // Account Size 기반 Lifecycle 기간 설정
        Integer lifecycleMonths = 12; // 기본 12개월
        
        if (orderInfo.Account.NumberOfEmployees != null) {
            if (orderInfo.Account.NumberOfEmployees >= 1000) {
                lifecycleMonths = 36; // 대기업: 3년
            } else if (orderInfo.Account.NumberOfEmployees >= 100) {
                lifecycleMonths = 24; // 중견기업: 2년
            } else {
                lifecycleMonths = 12; // 중소기업: 1년
            }
        }
        
        // Key Account는 추가 연장
        if (orderInfo.Account.Key_Account__c) {
            lifecycleMonths += 12;
        }
        
        // Annual Revenue 기반 조정
        if (orderInfo.Account.AnnualRevenue != null) {
            if (orderInfo.Account.AnnualRevenue >= 100000000) { // 1억 이상
                lifecycleMonths += 6;
            }
        }
        
        // InstallDate 설정 (Asset 설치일로 사용)
        newAsset.InstallDate = Date.today();
        
        // PurchaseDate 설정 (Order EffectiveDate 또는 오늘 날짜)
        if (orderInfo.EffectiveDate != null) {
            newAsset.PurchaseDate = orderInfo.EffectiveDate;
        } else {
            newAsset.PurchaseDate = Date.today();
        }
    }
    
    /**
     * @description Account 분석이 포함된 Asset Description 생성
     * @param orderInfo Order 정보
     * @return String Asset Description
     */
    private static String buildAccountBasedDescription(Order orderInfo) {
        List<String> descriptionParts = new List<String>();
        
        descriptionParts.add('=== Account 기반 Asset 정보 ===');
        descriptionParts.add('Order Number: ' + orderInfo.OrderNumber);
        descriptionParts.add('고객명: ' + orderInfo.Account.Name);
        descriptionParts.add('계정번호: ' + (orderInfo.Account.AccountNumber ?? '미설정'));
        descriptionParts.add('총 금액: ' + (orderInfo.TotalAmount != null ? orderInfo.TotalAmount.format() : '0') + '원');
        descriptionParts.add('');
        
        // Account 상세 분석
        descriptionParts.add('=== Account 분석 ===');
        descriptionParts.add('산업군: ' + (orderInfo.Account.Industry ?? '미분류'));
        descriptionParts.add('직원수: ' + (orderInfo.Account.NumberOfEmployees != null ? orderInfo.Account.NumberOfEmployees.format() : '미확인') + '명');
        descriptionParts.add('연매출: ' + (orderInfo.Account.AnnualRevenue != null ? orderInfo.Account.AnnualRevenue.format() : '미확인') + '원');
        // descriptionParts.add('Einstein Tier: ' + (orderInfo.Account.Tier__c ?? '미분류'));
        descriptionParts.add('고객 우선순위: ' + (orderInfo.Account.CustomerPriority__c ?? '일반'));
        descriptionParts.add('Key Account: ' + (orderInfo.Account.Key_Account__c ? 'Yes' : 'No'));
        descriptionParts.add('Account 활성 상태: ' + (orderInfo.Account.Active__c ?? '미확인'));
        descriptionParts.add('Account Source: ' + (orderInfo.Account.AccountSource ?? '미확인'));
        descriptionParts.add('소유 형태: ' + (orderInfo.Account.Ownership ?? '미확인'));
        
        if (orderInfo.Account.Manager__r?.Name != null) {
            descriptionParts.add('Account Manager: ' + orderInfo.Account.Manager__r.Name);
        }
        
        descriptionParts.add('');
        
        // PaymentStatus 요약 정보
        try {
            List<PaymentStatus__c> paymentSummary = [
                SELECT Installment_Number__c, Amount__c, DueDate__c, PaidDate__c, Status__c
                FROM PaymentStatus__c 
                WHERE Order__c = :orderInfo.Id
                ORDER BY Installment_Number__c
                LIMIT 10
            ];
            
            if (!paymentSummary.isEmpty()) {
                descriptionParts.add('=== 납부 내역 ===');
                Decimal totalPaid = 0;
                Integer completedCount = 0;
                
                for (PaymentStatus__c ps : paymentSummary) {
                    String installmentInfo = ps.Installment_Number__c + '차: ';
                    installmentInfo += (ps.Amount__c != null ? ps.Amount__c.format() : '0') + '원';
                    installmentInfo += ' (' + ps.Status__c + ')';
                    if (ps.PaidDate__c != null) {
                        installmentInfo += ' - 납부일: ' + ps.PaidDate__c.format();
                    }
                    descriptionParts.add(installmentInfo);
                    
                    if (ps.Status__c == '완납' && ps.Amount__c != null) {
                        totalPaid += ps.Amount__c;
                        completedCount++;
                    }
                }
                
                descriptionParts.add('');
                descriptionParts.add('납부 완료: ' + completedCount + '/' + paymentSummary.size() + '차');
                descriptionParts.add('완납 금액: ' + totalPaid.format() + '원');
                descriptionParts.add('');
            }
        } catch (Exception e) {
            System.debug('PaymentStatus 정보 조회 오류: ' + e.getMessage());
        }
        
        // Account 기반 비즈니스 인사이트
        descriptionParts.add('=== Account 기반 비즈니스 인사이트 ===');
        descriptionParts.addAll(generateAccountInsights(orderInfo));
        
        descriptionParts.add('');
        descriptionParts.add('📈 이 Asset은 Account 분석 기반으로 완납 완료된 Order에서 자동 생성되었습니다.');
        descriptionParts.add('Account 특성을 고려한 맞춤형 고객 관리 및 갱신 영업을 진행하세요.');
        
        return String.join(descriptionParts, '\n');
    }
    
    /**
     * @description Account 정보 기반 비즈니스 인사이트 생성
     * @param orderInfo Order 정보
     * @return List<String> 인사이트 목록
     */
    private static List<String> generateAccountInsights(Order orderInfo) {
        List<String> insights = new List<String>();
        
        // 기업 규모 분석
        if (orderInfo.Account.NumberOfEmployees != null) {
            if (orderInfo.Account.NumberOfEmployees >= 1000) {
                insights.add('• 대기업 고객: 장기 파트너십 및 확장 기회 검토 필요');
                insights.add('• 조직 내 추가 부서 확산 가능성 높음');
            } else if (orderInfo.Account.NumberOfEmployees >= 100) {
                insights.add('• 중견기업 고객: 성장 단계별 솔루션 확장 제안');
                insights.add('• 경영진 직접 접촉을 통한 의사결정 가속화');
            } else {
                insights.add('• 중소기업 고객: 효율성 및 ROI 중심의 제안 필요');
                insights.add('• 간단하고 명확한 갱신 프로세스 제공');
            }
        }
        
        // 매출 규모 분석
        if (orderInfo.Account.AnnualRevenue != null) {
            if (orderInfo.Account.AnnualRevenue >= 100000000) { // 1억 이상
                insights.add('• 고매출 기업: Premium 서비스 및 컨설팅 제안 가능');
                insights.add('• 투자 여력 충분, 추가 솔루션 확대 기회');
            }
        }
        
        // Industry 기반 인사이트
        if (String.isNotBlank(orderInfo.Account.Industry)) {
            switch on orderInfo.Account.Industry.toLowerCase() {
                when 'technology' {
                    insights.add('• IT 기업: 최신 기술 트렌드 및 혁신 솔루션 제안');
                    insights.add('• 빠른 기술 도입 성향, 조기 갱신 가능성');
                }
                when 'manufacturing' {
                    insights.add('• 제조업: 생산성 향상 및 비용 절감 효과 강조');
                    insights.add('• 장기 계약 선호, 안정적인 갱신 패턴');
                }
                when 'healthcare' {
                    insights.add('• 의료업: 규제 준수 및 보안 강화 솔루션 필요');
                    insights.add('• 신뢰성과 안정성 중시, 장기 파트너십 구축');
                }
                when 'financial services' {
                    insights.add('• 금융업: 보안, 규제, 리스크 관리 솔루션 우선');
                    insights.add('• 엄격한 검증 과정, 고가치 장기 계약 가능');
                }
                when else {
                    insights.add('• ' + orderInfo.Account.Industry + ' 업계 특성 고려한 맞춤 솔루션 제안');
                }
            }
        }
        
        // Key Account 인사이트
        if (orderInfo.Account.Key_Account__c) {
            insights.add('• Key Account: 최우선 관리 대상, 전담 팀 배정 고려');
            insights.add('• 레퍼런스 고객 활용 및 성공 사례 개발 기회');
            insights.add('• 경영진 레벨 관계 구축 및 전략적 파트너십 추진');
        }
        
        // Customer Priority 인사이트
        if (String.isNotBlank(orderInfo.Account.CustomerPriority__c)) {
            switch on orderInfo.Account.CustomerPriority__c.toLowerCase() {
                when 'high' {
                    insights.add('• 고우선순위 고객: 신속한 대응 및 프리미엄 서비스 제공');
                    insights.add('• 갱신 6개월 전 사전 접촉 및 맞춤 제안서 준비');
                }
                when 'medium' {
                    insights.add('• 중우선순위 고객: 정기적 관계 유지 및 가치 제안');
                }
                when 'low' {
                    insights.add('• 일반 고객: 효율적 관리 및 자동화된 갱신 프로세스');
                }
            }
        }
        
        // Einstein Tier 기반 인사이트 (필드 존재 시)
        // if (String.isNotBlank(orderInfo.Account.Tier__c)) {
        //     insights.add('• Einstein AI Tier ' + orderInfo.Account.Tier__c + ': AI 기반 고객 행동 예측 활용');
        //     insights.add('• 데이터 기반 개인화된 갱신 전략 수립 가능');
        // }
        
        return insights;
    }
    
    /**
     * @description Account 기반 후속 액션 수행
     * @param orderInfo Order 정보
     * @param createdAsset 생성된 Asset
     */
    private static void performAccountBasedActions(Order orderInfo, Asset createdAsset) {
        // Account Manager가 있는 경우 별도 알림
        if (orderInfo.Account.Manager__c != null) {
            createAccountManagerTask(orderInfo, createdAsset);
        }
        
        // Key Account인 경우 특별 처리
        if (orderInfo.Account.Key_Account__c) {
            createKeyAccountNotification(orderInfo, createdAsset);
        }
        
        // 고우선순위 고객인 경우 즉시 알림
        if (orderInfo.Account.CustomerPriority__c == 'High') {
            createHighPriorityCustomerAlert(orderInfo, createdAsset);
        }
    }
    
    /**
     * @description Account Manager용 Task 생성
     * @param orderInfo Order 정보
     * @param createdAsset 생성된 Asset
     */
    private static void createAccountManagerTask(Order orderInfo, Asset createdAsset) {
        try {
            Task managerTask = new Task();
            managerTask.Subject = '[Account Manager] Asset 생성 알림 - ' + orderInfo.Account.Name;
            managerTask.Description = 'Account Manager님께 알려드립니다.\n\n';
            managerTask.Description += '고객: ' + orderInfo.Account.Name + '\n';
            managerTask.Description += 'Order: ' + orderInfo.OrderNumber + '\n';
            managerTask.Description += 'Asset: ' + createdAsset.Name + '\n';
            managerTask.Description += '완납 금액: ' + (orderInfo.TotalAmount != null ? orderInfo.TotalAmount.format() : '0') + '원\n\n';
            managerTask.Description += 'Account 특성:\n';
            managerTask.Description += '- 산업군: ' + (orderInfo.Account.Industry ?? '미분류') + '\n';
            managerTask.Description += '- 직원수: ' + (orderInfo.Account.NumberOfEmployees != null ? orderInfo.Account.NumberOfEmployees.format() : '미확인') + '명\n';
            managerTask.Description += '- Key Account: ' + (orderInfo.Account.Key_Account__c ? 'Yes' : 'No') + '\n\n';
            managerTask.Description += 'Account 전략 수립 및 추가 기회 발굴을 진행해주세요.';
            
            managerTask.Priority = 'Normal';
            managerTask.Status = 'Not Started';
            managerTask.ActivityDate = Date.today().addDays(3);
            managerTask.OwnerId = orderInfo.Account.Manager__c;
            managerTask.WhatId = createdAsset.Id;
            
            insert managerTask;
            
        } catch (Exception e) {
            System.debug('AccountBasedAssetService.createAccountManagerTask Error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Key Account 알림 생성
     * @param orderInfo Order 정보
     * @param createdAsset 생성된 Asset
     */
    private static void createKeyAccountNotification(Order orderInfo, Asset createdAsset) {
        try {
            Task keyAccountTask = new Task();
            keyAccountTask.Subject = '[Key Account] 전략적 Asset 생성 완료 - ' + orderInfo.Account.Name;
            keyAccountTask.Description = '🌟 Key Account Asset 생성이 완료되었습니다.\n\n';
            keyAccountTask.Description += '고객: ' + orderInfo.Account.Name + '\n';
            keyAccountTask.Description += 'Asset 가치: ' + (orderInfo.TotalAmount != null ? orderInfo.TotalAmount.format() : '0') + '원\n\n';
            keyAccountTask.Description += '권장 액션:\n';
            keyAccountTask.Description += '□ 경영진 레벨 감사 인사\n';
            keyAccountTask.Description += '□ 성공 사례 인터뷰 요청\n';
            keyAccountTask.Description += '□ 추가 사업 기회 논의 일정 수립\n';
            keyAccountTask.Description += '□ 레퍼런스 고객 등록 검토\n';
            keyAccountTask.Description += '□ 전략적 파트너십 확대 방안 수립';
            
            keyAccountTask.Priority = 'High';
            keyAccountTask.Status = 'Not Started';
            keyAccountTask.ActivityDate = Date.today().addDays(1);
            keyAccountTask.OwnerId = orderInfo.OwnerId;
            keyAccountTask.WhatId = createdAsset.Id;
            
            insert keyAccountTask;
            
        } catch (Exception e) {
            System.debug('AccountBasedAssetService.createKeyAccountNotification Error: ' + e.getMessage());
        }
    }
    
    /**
     * @description 고우선순위 고객 알림 생성
     * @param orderInfo Order 정보
     * @param createdAsset 생성된 Asset
     */
    private static void createHighPriorityCustomerAlert(Order orderInfo, Asset createdAsset) {
        try {
            Task priorityTask = new Task();
            priorityTask.Subject = '[우선순위 高] Asset 생성 즉시 대응 필요 - ' + orderInfo.Account.Name;
            priorityTask.Description = '⚡ 고우선순위 고객의 Asset이 생성되었습니다. 즉시 대응이 필요합니다.\n\n';
            priorityTask.Description += '고객: ' + orderInfo.Account.Name + '\n';
            priorityTask.Description += 'Priority Level: ' + orderInfo.Account.CustomerPriority__c + '\n';
            priorityTask.Description += 'Asset 가치: ' + (orderInfo.TotalAmount != null ? orderInfo.TotalAmount.format() : '0') + '원\n\n';
            priorityTask.Description += '즉시 액션:\n';
            priorityTask.Description += '□ 24시간 내 완납 감사 연락\n';
            priorityTask.Description += '□ 서비스 만족도 확인\n';
            priorityTask.Description += '□ 추가 요구사항 파악\n';
            priorityTask.Description += '□ 갱신 일정 사전 협의';
            
            priorityTask.Priority = 'High';
            priorityTask.Status = 'Not Started';
            priorityTask.ActivityDate = Date.today();
            priorityTask.OwnerId = orderInfo.OwnerId;
            priorityTask.WhatId = createdAsset.Id;
            
            insert priorityTask;
            
        } catch (Exception e) {
            System.debug('AccountBasedAssetService.createHighPriorityCustomerAlert Error: ' + e.getMessage());
        }
    }
    
    /**
     * @description 커스텀 예외 클래스
     */
    public class AccountBasedAssetException extends Exception {}
}
