/**
 * @description LWC에서 Order 생성을 처리하는 컨트롤러
 */
public with sharing class OrderCreatorController {

    @AuraEnabled
    public static Id createOrder(Order orderToCreate) {
        // 필수 필드 유효성 검사 (서버 측에서도 확인)
        if (orderToCreate.AccountId == null || orderToCreate.EffectiveDate == null || orderToCreate.TotalAmount == null || orderToCreate.Payment_Method__c == null) {
            throw new AuraHandledException('Account, Order Start Date, Total Amount, and Payment Method are required.');
        }

        try {
            // LWC에서 받은 데이터로 Order 레코드 생성
            insert orderToCreate;
            // 생성된 레코드의 ID 반환
            return orderToCreate.Id;
        } catch (Exception e) {
            // 오류 발생 시 LWC에 오류 메시지 전달
            throw new AuraHandledException(e.getMessage());
        }
    }
}