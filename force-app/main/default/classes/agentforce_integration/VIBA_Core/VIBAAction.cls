/**
 * @description VIBA 액션 정보
 */
global class VIBAAction {
    @InvocableVariable(label='액션 제목')
    global String title;
    
    @InvocableVariable(label='액션 설명')
    global String description;
    
    @InvocableVariable(label='우선순위')
    global String priority;
    
    @InvocableVariable(label='예상 소요시간')
    global String estimatedTime;
    
    @InvocableVariable(label='성공 확률')
    global Decimal successProbability;
}
