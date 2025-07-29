/**
 * @description       : 
 * @author            : Hyowon Hong
 * @last modified on  : 07-07-2025
 * @last modified by  : Hyowon Hong
**/
public with sharing class BusinessNumberCheckModalController {

    /**
    * @Description
    * - Modal Init시,국세청 API를 이용한 사업자등록번호 진위 확인
    * @author Hyowon Hong | 07-06-2025
    * @Parameter
    * - recordId    : Account Record Id
    **/
    @AuraEnabled
    public static WrapperUtils.resultWrapper checkBusinessNumber(String recordId) {
        WrapperUtils.resultWrapper result = new WrapperUtils.resultWrapper();
        try {
            Account acc = [
                SELECT Id
                        , BusinessNumber__c
                        , BusinessNumberVerified__c
                        , BusinessNumberDuplication__c
                FROM Account
                WHERE Id = :recordId
                LIMIT 1
            ];
    
            if(acc.BusinessNumberDuplication__c != null && !acc.BusinessNumberVerified__c) {
                String resultIF = getBusinessNumberInfo(acc.BusinessNumberDuplication__c);
                if(resultIF == 'Error'){
                    result.isSuccess = false;
                    result.errorMessage = 'BusinessNumber API Error';
                    return result;
                }
                GetBusinessNumberRes res = (GetBusinessNumberRes) JSON.deserialize(resultIF, GetBusinessNumberRes.class);
                result.resultMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(res.data[0]));

            } else if(acc.BusinessNumberDuplication__c == null) {
                result.isSuccess = false;
                result.errorMessage = '사업자등록번호를 입력해주세요.';
                return result;
            } else if(acc.BusinessNumberVerified__c) {
                result.isSuccess = false;
                result.errorMessage = 'BusinessNumber is already check';
                return result;
            }
            
        } catch (Exception e) {
            System.debug('Error : '         + e.getMessage());
            System.debug('Line Numeber : '  + e.getLineNumber());
            
            result.isSuccess = false;
            result.errorMessage = e.getMessage();
        }
        return result;
    }

    /**
    * @Description
    * - 국세청 API를 이용하여 진위 여부가 확인된 사업자등록번호를 필드에 업데이트 
    * @author Hyowon Hong | 07-06-2025
    * @Parameter
    * - recordId    : Account Record Id
    **/
    @AuraEnabled
    public static WrapperUtils.resultWrapper updateBusinessNumberVerified(String recordId){
        WrapperUtils.resultWrapper result = new WrapperUtils.resultWrapper();
        try {
            Account acc =[
                SELECT  Id
                        , BusinessNumberVerified__c
                FROM Account
                WHERE Id =: recordId
                LIMIT 1
            ];
            if(!acc.BusinessNumberVerified__c){
                acc.BusinessNumberVerified__c = true;
                update acc;
            }            
        } catch (Exception e) {
            System.debug('Error : '         + e.getMessage());
            System.debug('Line Number : '   + e.getLineNumber());

            result.isSuccess = false;
            result.errorMessage = e.getMessage();
        }
        return result;
    }
    

    /**
    * @Description
    * - 국세청 API를 이용하여 사업자등록번호 정보 가져오기
    * @author Hyowon Hong | 07-06-2025
    * @Parameter
    * - businessNumber    : Account 사업자등록번호
    **/
    private static String getBusinessNumberInfo(String businessNumber){
        String result = '';
        List<Interface_Authentication_Info__mdt> ifAuthNTS = [
            SELECT  Id
                    , SecretKey__c
                    , EndPoint__c
            FROM Interface_Authentication_Info__mdt
            WHERE DeveloperName = 'NTS_BusinessNumber_Info'
            AND isActive__c = true
            LIMIT 1
        ];


        // isActive 체크되어있지 않는 경우
        if(ifAuthNTS.isEmpty()){
            System.debug('No active Interface_Authentication_Info__mdt found for NTS_BusinessNumber_Info');
            return 'Error';
        }

        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('b_no', new List<String>{businessNumber});
        String requestBody = JSON.serialize(requestBodyMap);

        String queryStringParam = '&serviceKey=' + ifAuthNTS[0].SecretKey__c
                                    + '&returnType=json';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(ifAuthNTS[0].EndPoint__c + '?' + queryStringParam);
        request.setMethod('GET');
        request.setHeader('COntent-Type', 'application/json');
        request.setBody(requestBody);
        request.setTimeout(120000);

        HttpResponse response = http.send(request);
        Integer statusCode = response.getStatusCode();

        if(statusCode == 200){
            result = response.getBody();
            System.debug('API Response: ' + result);

        }else{
            System.debug('API Error - Status: ' + statusCode + ', Body: ' + response.getBody());
            return 'Error';
        }
        return result;
    }

    public class GetBusinessNumberRes{
        @AuraEnabled public String status_code {get;set;} // API 상태 코드
        @AuraEnabled public String match_cnt   {get;set;} // 매칭 수
        @AuraEnabled public String request_cnt {get;set;} // 요청 수
        @AuraEnabled public List<Data> data    {get;set;} // 결과
    }

    public class Data{
        @AuraEnabled public String b_no                  {get;set;} // 사업자등록번호
        @AuraEnabled public String b_stt                 {get;set;} // 납세자상태(명칭): 01: 계속사업자, 02: 휴업자, 03: 폐업자
        @AuraEnabled public String b_stt_cd              {get;set;} // 납세자상태(코드): 01: 계속사업자, 02: 휴업자, 03: 폐업자
        @AuraEnabled public String tax_type              {get;set;} // 과세유형메세지(명칭): 01:부가가치세 일반과세자, 02:부가가치세 간이과세자, 03:부가가치세 과세특례자, 04:부가가치세 면세사업자, 05:수익사업을 영위하지 않는 비영리법인이거나 고유번호가 부여된 단체,국가기관 등, 06:고유번호가 부여된 단체, 07:부가가치세 간이과세자(세금계산서 발급사업자), * 등록되지 않았거나 삭제된 경우: "국세청에 등록되지 않은 사업자등록번호입니다"
        @AuraEnabled public String tax_type_cd           {get;set;} // 과세유형메세지(코드): 01:부가가치세 일반과세자, 02:부가가치세 간이과세자, 03:부가가치세 과세특례자, 04:부가가치세 면세사업자, 05:수익사업을 영위하지 않는 비영리법인이거나 고유번호가 부여된 단체,국가기관 등, 06:고유번호가 부여된 단체, 07:부가가치세 간이과세자(세금계산서 발급사업자), * 등록되지 않았거나 삭제된 경우: "국세청에 등록되지 않은 사업자등록번호입니다"
        @AuraEnabled public String end_dt                {get;set;} // 폐업일
        @AuraEnabled public String utcc_yn               {get;set;} // 단위과세전환폐업여부
        @AuraEnabled public String tax_type_change_dt    {get;set;} // 최근과세유형전환일자
        @AuraEnabled public String invoice_apply_dt      {get;set;} // 세금계산서적용일자
        @AuraEnabled public String rbf_tax_type          {get;set;} // 직전과세유형메세지(명칭): 01:부가가치세 일반과세자, 02:부가가치세 간이과세자, 07:부가가치세 간이과세자(세금계산서 발급사업자), 99:해당없음
    }

    
}