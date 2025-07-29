/**
 * @description       : 
 * @author            : Hyowon Hong
 * @last modified on  : 07-09-2025
 * @last modified by  : Hyowon Hong
**/
public with sharing class SearchAddressModalController {

    /**
    * @Description
    * - 행안부 주소 검색 API를 이용하여 주소 검색 
    * @author Hyowon Hong | 07-08-2025
    * @Parameter
    * - searchText    : 검색어
    * - pagingNumber  : 페이지넘버
    **/
    @AuraEnabled
    public static WrapperUtils.resultWrapper getAddress(String searchText, Integer pagingNumber){
        WrapperUtils.resultWrapper result = new WrapperUtils.resultWrapper();
        try {
            String resultIF = getAddressInfo(searchText, String.valueOf(pagingNumber));
            
            if(resultIF == 'Error'){
                result.isSuccess = false;
                result.errorMessage = 'Address API Error';
                return result;
            }

            Map<String, Object> resultIFMap = (Map<String, Object>) JSON.deserializeUntyped(resultIF);
            Map<String, Object> resultsMap = (Map<String, Object>) resultIFMap.get('results');
            Map<String, Object> commonMap = (Map<String, Object>) resultsMap.get('common');
            List<Object> jusoList = (List<Object>) resultsMap.get('juso');

            System.debug('resultIFMap ::: ' + resultIFMap);
            System.debug('resultsMap ::: ' + resultsMap);
            System.debug('commonMap ::: ' + commonMap);

            result.resultMap.put('totalResultCount', commonMap.get('totalCount'));
            result.resultMap.put('jusoList', jusoList);

        } catch (Exception e) {
            System.debug('Error : ' + e.getMessage());
            System.debug('Line Number : ' + e.getLineNumber());

            result.isSuccess = false;
            result.errorMessage = e.getMessage();
        }
        return result;
    }

    /**
    * @Description
    * - 행안부 주소 검색 API 호출
    * @author Hyowon Hong | 07-08-2025
    * @Parameter
    * - keyword     : 검색어
    * - pageNo      : 페이지넘버
    **/
    private static String getAddressInfo(String keyword, String pageNo){
        String result = '';
        if(pageNo == null || pageNo == '') pageNo = '1';

        List<Interface_Authentication_Info__mdt> ifAuthMOIS = [
            SELECT Id
                    , SecretKey__c
                    , EndPoint__c
            FROM Interface_Authentication_Info__mdt
            WHERE DeveloperName = 'MOIS_Address_Info'
            AND isActive__c = true
            LIMIT 1
        ];

        if(ifAuthMOIS.isEmpty()){
            System.debug('No active Interface_Authentication_Info__mdt found for MOIS_Address_Info');
            return 'Error'; 
        }
        System.debug('ifAuthMOIS :::' + ifAuthMOIS);
        keyword = EncodingUtil.urlEncode(keyword, 'UTF-8');
        System.debug('keyword ::: ' + keyword);
        String queryStringParam =   'currentPage=' + pageNo +
                                    '&countPerPage=15' + 
                                    '&keyword=' + keyword +
                                    '&confmKey=' + ifAuthMOIS[0].SecretKey__c +
                                    '&hstryYn=Y' +
                                    '&resultType=json';
        System.debug('queryStringParam ::: '+ queryStringParam);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(ifAuthMOIS[0].EndPoint__c + '?' + queryStringParam);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);
        
        HttpResponse response = http.send(request);
        Integer statusCode = response.getStatusCode();

        if(statusCode == 200) {
            result = response.getBody();
            System.debug('API Response: ' + result);
        }else{
            System.debug('API Error - Status: ' + statusCode + ', Body: ' + response.getBody());
            return 'Error';
        }
        return result;
    }

    /**
    * @Description
    * - 행안부 주소 검색 API로 받아온 주소를 필드에 업데이트(저장)
    * @author Hyowon Hong | 07-08-2025
    * @Parameter
    * - recordId    : Account recordId
    * - address     : 선택된 주소 정보
    * - detailInfo  : 상세 주소 정보
    **/
    @AuraEnabled
    public static WrapperUtils.resultWrapper setShippingAddress(String recordId, Map<String, Object> address, Object detailInfo){
        WrapperUtils.resultWrapper result = new WrapperUtils.resultWrapper();
        try {
            Account acc = [
                SELECT  id
                        , ShippingStreet
                        , ShippingPostalCode
                        , ShippingCity
                        , ShippingCountry
                        , ShippingState
                FROM Account
                WHERE Id =: recordId
                LIMIT 1
            ];

            acc.ShippingStreet = (String) address.get('roadAddr') + '\n' + detailInfo;
            acc.ShippingPostalCode = (String) address.get('zipNo');
            acc.ShippingCountry = 'Korea, Republic of';
            acc.ShippingState = '';
            update acc;
            
        } catch (Exception e) {
            System.debug('Error : ' + e.getMessage());
            System.debug('Line Number : ' + e.getLineNumber());

            result.isSuccess = false;
            result.errorMessage = e.getMessage();
        }
        return result;
    }

    // 주소 지도 API 인증 키 반환 메서드
    public String getAddressMapKey() {
        // 지도 API 인증 정보 조회
        Interface_Authentication_Info__mdt ifAuthMOIS = [
            SELECT Id, SecretKey__c 
            FROM Interface_Authentication_Info__mdt 
            WHERE DeveloperName = 'MOIS_Map_Info' 
            LIMIT 1
        ];
        return ifAuthMOIS.SecretKey__c;
        // 설명: Visualforce 페이지에서 사용할 지도 API의 인증 키를 반환
    }
}