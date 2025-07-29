/**
 * @description VIBA 응답 데이터 구조
 */
global class VIBAResponse {
    @InvocableVariable(label='요청 ID')
    global String requestId;
    
    @InvocableVariable(label='성공 여부')
    global Boolean success;
    
    @InvocableVariable(label='VIBA 메시지')
    global String message;
    
    @InvocableVariable(label='신뢰도')
    global Decimal confidence;
    
    @InvocableVariable(label='인사이트')
    global VIBAInsight insights;
    
    @InvocableVariable(label='권장 액션')
    global List<VIBAAction> recommendedActions;
}
