/**
 * @description       : 
 * @author            : Hyowon Hong
 * @last modified on  : 07-07-2025
 * @last modified by  : Hyowon Hong
**/
public with sharing class WrapperUtils {
    public class resultWrapper {
        @AuraEnabled public Boolean             isSuccess       { get; set;}
        @AuraEnabled public String              errorMessage    { get; set;}
        @AuraEnabled public Map<String, Object> resultMap       {get; set;}

        public resultWrapper() {
            this.isSuccess = true;
            this.resultMap = new Map<String, Object>();
        }
        
    }
}