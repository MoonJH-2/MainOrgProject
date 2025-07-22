/**
 * @description Order 완납 시 Asset 자동 생성 서비스
 * @author Copilot  
 * @date 2024
 */
public class OrderAssetCreationService {
    
    /**
     * @description Order의 모든 PaymentStatus가 완납 상태인지 확인
     * @param orderId Order ID
     * @return Boolean 완납 여부
     */
    public static Boolean isOrderFullyPaid(Id orderId) {
        try {
            // 전체 PaymentStatus 개수 조회
            Integer totalPayments = [
                SELECT COUNT() 
                FROM PaymentStatus__c 
                WHERE Order__c = :orderId
            ];
            
            if (totalPayments == 0) {
                System.debug('OrderAssetCreationService: 해당 Order에 PaymentStatus 레코드가 없습니다. OrderId: ' + orderId);
                return false;
            }
            
            // 완납 상태 PaymentStatus 개수 조회
            Integer completedPayments = [
                SELECT COUNT() 
                FROM PaymentStatus__c 
                WHERE Order__c = :orderId 
                AND Status__c = '완납'
            ];
            
            System.debug('OrderAssetCreationService: 납부 현황 - 전체: ' + totalPayments + ', 완납: ' + completedPayments);
            
            return totalPayments > 0 && totalPayments == completedPayments;
            
        } catch (Exception e) {
            System.debug('OrderAssetCreationService.isOrderFullyPaid Error: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description 완납된 Order에서 Asset 생성
     * @param orderId Order ID
     * @return Asset 생성된 Asset 레코드
     */
    public static Asset createAssetFromCompletedOrder(Id orderId) {
        try {
            // Order 정보 조회
            Order orderInfo = [
                SELECT Id, OrderNumber, AccountId, TotalAmount, Status,
                       EffectiveDate, EndDate, CreatedDate, OwnerId,
                       Contact__c, Account.Name, Owner.Name
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
                System.debug('OrderAssetCreationService: Asset이 이미 존재합니다. OrderNumber: ' + orderInfo.OrderNumber);
                return existingAssets[0];
            }
            
            // Asset 생성
            Asset newAsset = new Asset();
            
            // 표준 필드 매핑
            newAsset.Name = orderInfo.Account.Name + ' - Order ' + orderInfo.OrderNumber;
            newAsset.AccountId = orderInfo.AccountId;
            newAsset.ContactId = orderInfo.Contact__c; // Order의 Contact 연결
            newAsset.SerialNumber = orderInfo.OrderNumber; // 역추적용
            newAsset.PurchaseDate = orderInfo.EffectiveDate; // Order Start Date
            newAsset.InstallDate = Date.today(); // 완납 완료일
            newAsset.Status = 'Purchased';
            newAsset.Price = orderInfo.TotalAmount;
            newAsset.Quantity = 1;
            
            // Lifecycle 관리 (Order End Date가 있는 경우)
            if (orderInfo.EndDate != null) {
                newAsset.LifecycleEndDate = DateTime.newInstance(orderInfo.EndDate, Time.newInstance(23, 59, 59, 0));
            }
            
            // Description에 상세 정보 포함
            newAsset.Description = buildAssetDescription(orderInfo);
            
            insert newAsset;
            
            System.debug('OrderAssetCreationService: Asset 생성 완료. AssetId: ' + newAsset.Id);
            
            // Salesforce Channel에 Asset 생성 알림
            postAssetCreationNotification(orderInfo, newAsset);
            
            return newAsset;
            
        } catch (Exception e) {
            System.debug('OrderAssetCreationService.createAssetFromCompletedOrder Error: ' + e.getMessage());
            throw new OrderAssetCreationException('Asset 생성 중 오류가 발생했습니다: ' + e.getMessage());
        }
    }
    
    /**
     * @description Asset Description 구성
     * @param orderInfo Order 정보
     * @return String Asset Description
     */
    private static String buildAssetDescription(Order orderInfo) {
        List<String> descriptionParts = new List<String>();
        
        descriptionParts.add('=== Order Asset 정보 ===');
        descriptionParts.add('Order Number: ' + orderInfo.OrderNumber);
        descriptionParts.add('고객: ' + orderInfo.Account.Name);
        descriptionParts.add('총 금액: ' + (orderInfo.TotalAmount != null ? orderInfo.TotalAmount.format() : '0') + '원');
        descriptionParts.add('주문 시작일: ' + (orderInfo.EffectiveDate != null ? orderInfo.EffectiveDate.format() : '미확인'));
        descriptionParts.add('주문 종료일: ' + (orderInfo.EndDate != null ? orderInfo.EndDate.format() : '무기한'));
        descriptionParts.add('완납 완료일: ' + Date.today().format());
        descriptionParts.add('담당자: ' + orderInfo.Owner.Name);
        descriptionParts.add('');
        
        // PaymentStatus 요약 정보 추가
        try {
            List<PaymentStatus__c> paymentSummary = [
                SELECT InstallmentNumber__c, Amount__c, DueDate__c, PaidDate__c, Status__c
                FROM PaymentStatus__c 
                WHERE Order__c = :orderInfo.Id
                ORDER BY InstallmentNumber__c
                LIMIT 10
            ];
            
            if (!paymentSummary.isEmpty()) {
                descriptionParts.add('=== 납부 내역 ===');
                for (PaymentStatus__c ps : paymentSummary) {
                    String installmentInfo = ps.InstallmentNumber__c + '차: ';
                    installmentInfo += (ps.Amount__c != null ? ps.Amount__c.format() : '0') + '원';
                    installmentInfo += ' (' + ps.Status__c + ')';
                    if (ps.PaidDate__c != null) {
                        installmentInfo += ' - 납부일: ' + ps.PaidDate__c.format();
                    }
                    descriptionParts.add(installmentInfo);
                }
                descriptionParts.add('');
            }
        } catch (Exception e) {
            System.debug('PaymentStatus 정보 조회 오류: ' + e.getMessage());
        }
        
        descriptionParts.add('📈 이 Asset은 완납 완료된 Order에서 자동 생성되었습니다.');
        descriptionParts.add('고객 관리 및 갱신 영업을 위해 활용하세요.');
        
        return String.join(descriptionParts, '\n');
    }
    
    /**
     * @description Asset 생성 알림을 Salesforce Channel에 게시
     * @param orderInfo Order 정보
     * @param createdAsset 생성된 Asset
     */
    private static void postAssetCreationNotification(Order orderInfo, Asset createdAsset) {
        try {
            // SimpleSalesforceChannelService를 사용하여 알림 게시
            String message = '🎉 **Asset 자동 생성 완료**\n\n';
            message += '**고객:** ' + orderInfo.Account.Name + '\n';
            message += '**Order:** ' + orderInfo.OrderNumber + '\n';
            message += '**Asset:** ' + createdAsset.Name + '\n';
            message += '**완납 금액:** ' + (orderInfo.TotalAmount != null ? orderInfo.TotalAmount.format() : '0') + '원\n\n';
            message += '완납이 완료되어 고객 Asset이 자동으로 생성되었습니다. ';
            message += '이제 고객 관리 및 갱신 영업 기회로 활용하세요!';
            
            // Order Channel에 알림 게시 (채널이 있는 경우)
            SimpleSalesforceChannelService.postMessageToOrderChannel(orderInfo.Id, message);
            
            // 담당자에게 Task 생성
            createAssetCreationTask(orderInfo, createdAsset);
            
        } catch (Exception e) {
            System.debug('OrderAssetCreationService.postAssetCreationNotification Error: ' + e.getMessage());
            // 알림 실패해도 Asset 생성은 성공으로 처리
        }
    }
    
    /**
     * @description Asset 생성 완료 Task 생성
     * @param orderInfo Order 정보
     * @param createdAsset 생성된 Asset
     */
    private static void createAssetCreationTask(Order orderInfo, Asset createdAsset) {
        try {
            Task assetTask = new Task();
            assetTask.Subject = '[Asset 생성 완료] ' + orderInfo.Account.Name + ' - Order ' + orderInfo.OrderNumber;
            assetTask.Description = '완납 완료로 인한 Asset 자동 생성이 완료되었습니다.\n\n';
            assetTask.Description += '고객: ' + orderInfo.Account.Name + '\n';
            assetTask.Description += 'Order: ' + orderInfo.OrderNumber + '\n';
            assetTask.Description += 'Asset: ' + createdAsset.Name + '\n';
            assetTask.Description += '완납 금액: ' + (orderInfo.TotalAmount != null ? orderInfo.TotalAmount.format() : '0') + '원\n\n';
            assetTask.Description += '다음 액션:\n';
            assetTask.Description += '□ 고객 만족도 조사\n';
            assetTask.Description += '□ 추가 서비스 제안\n';
            assetTask.Description += '□ 갱신 일정 확인\n';
            assetTask.Description += '□ 레퍼런스 고객 등록 검토';
            
            assetTask.Priority = 'Normal';
            assetTask.Status = 'Not Started';
            assetTask.ActivityDate = Date.today().addDays(7); // 1주일 후
            assetTask.OwnerId = orderInfo.OwnerId;
            assetTask.WhatId = createdAsset.Id; // Asset과 연결
            
            insert assetTask;
            
        } catch (Exception e) {
            System.debug('OrderAssetCreationService.createAssetCreationTask Error: ' + e.getMessage());
        }
    }
    
    /**
     * @description 여러 Order의 완납 상태 일괄 확인 및 Asset 생성
     * @param orderIds Order ID 목록
     * @return Map<Id, Asset> Order ID와 생성된 Asset 매핑
     */
    public static Map<Id, Asset> processMultipleOrdersForAssetCreation(List<Id> orderIds) {
        Map<Id, Asset> createdAssets = new Map<Id, Asset>();
        
        for (Id orderId : orderIds) {
            try {
                if (isOrderFullyPaid(orderId)) {
                    Asset newAsset = createAssetFromCompletedOrder(orderId);
                    if (newAsset != null) {
                        createdAssets.put(orderId, newAsset);
                    }
                }
            } catch (Exception e) {
                System.debug('OrderAssetCreationService.processMultipleOrdersForAssetCreation Error for OrderId ' + orderId + ': ' + e.getMessage());
                continue; // 개별 Order 오류 시 다음 Order 계속 처리
            }
        }
        
        return createdAssets;
    }
    
    /**
     * @description 커스텀 예외 클래스
     */
    public class OrderAssetCreationException extends Exception {}
}
