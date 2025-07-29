/**
 * @description VIBA 데이터 모델 클래스들
 * @author VIBA AI Assistant
 * @date 2025-01-27
 */

/**
 * @description VIBA 요청 데이터 구조
 */
global class VIBARequest {
    @InvocableVariable(label='요청 ID' description='고유 요청 식별자')
    global String requestId;
    
    @InvocableVariable(label='분석 타입' description='Order/PaymentStatus/Asset')
    global String type;
    
    @InvocableVariable(label='레코드 ID' description='분석할 레코드 ID')
    global Id recordId;
    
    @InvocableVariable(label='추가 컨텍스트' description='추가 분석 정보')
    global String additionalContext;
}
