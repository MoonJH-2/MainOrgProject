/**
 * @description VIBA 인사이트 정보
 */
global class VIBAInsight {
    @InvocableVariable(label='VIBA 점수')
    global Decimal vibaScore;
    
    @InvocableVariable(label='개인화 메시지')
    global String personalizedMessage;
    
    @InvocableVariable(label='데이터 품질')
    global Decimal dataQuality;
    
    @InvocableVariable(label='분석 복잡도')
    global Decimal analysisComplexity;
    
    @InvocableVariable(label='고객 등급')
    global String customerTier;
    
    @InvocableVariable(label='위험 레벨')
    global String riskLevel;
    
    @InvocableVariable(label='기회 점수')
    global Decimal opportunityScore;
}
