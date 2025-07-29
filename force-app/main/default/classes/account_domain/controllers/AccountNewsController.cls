/**
 * @description       : 
 * @author            : Hyowon Hong
 * @last modified on  : 07-08-2025
 * @last modified by  : Hyowon Hong
**/
public with sharing class AccountNewsController {
    
    /**
    * @Description
    * - 네이버뉴스 API를 이용하여 Account 이름으로 관련 뉴스 조회하기
    * @author Hyowon Hong | 07-06-2025
    * @Parameter
    * - recordId    : Account recordId
    **/
    @AuraEnabled
    public static List<NaverNewsArticle> fetchAccountNews(String recordId){
        Account acc = [
            SELECT Id
                    , Name
            FROM Account
            WHERE Id =: recordId
            LIMIT 1
        ];
        return fetchNaverNews(acc.Name);
    }

    private static List<NaverNewsArticle> fetchNaverNews(String query){
       
        List<NaverNewsArticle> result = new List<NaverNewsArticle>();
       
        try {
            List<Interface_Authentication_Info__mdt> ifAuthNaver = [
                SELECT  Id
                        , ClientId__c
                        , SecretKey__c
                        , EndPoint__c
                FROM Interface_Authentication_Info__mdt
                WHERE DeveloperName = 'Naver_News_Info'
                AND isActive__c = true
                LIMIT 1
            ];

            if(!ifAuthNaver.isEmpty()) {
                String clientId     = ifAuthNaver[0].ClientId__c;
                String clientSecret = ifAuthNaver[0].SecretKey__c;
                String endPoint     = ifAuthNaver[0].EndPoint__c;

                System.debug('clientId ::: '        + clientId);
                System.debug('clientSecret ::: '    + clientSecret);
                System.debug('endPoint ::: '        + endPoint);

                String apiURL = endPoint + EncodingUtil.urlEncode(query, 'UTF-8') + '&display=10';

                System.debug('apiURL ::: ' + apiURL);

                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(apiURL);
                request.setMethod('GET');
                request.setHeader('Content-Type'            , 'application/json');
                request.setHeader('X-Naver-Client-Id'       , clientId);
                request.setHeader('X-Naver-Client-Secret'   , clientSecret);
                request.setTimeout(120000);

                HttpResponse response = http.send(request);
                Integer statusCode = response.getStatusCode();

                if(statusCode == 200){
                    Integer num = 1;
                    String responseBody = response.getBody();
                    System.debug('API Response: ' + result);

                    Map<String, Object> jsonResponse    = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    List<Object>        jsonItems       = (List<Object>) jsonResponse.get('items');
                    
                    
                    for (Object item : jsonItems) {
                        Map<String, Object> article     = (Map<String, Object>) item;
                        NaverNewsArticle    newsArticle = new NaverNewsArticle();

                        String formattedDate    = convertDate((String) article.get('pubDate'));
                        newsArticle.index       = num;
                        newsArticle.title       = decodeHtml(removeHtmlTags((String) article.get('title')));
                        newsArticle.description = decodeHtml(removeHtmlTags((String) article.get('description')));
                        newsArticle.url         = (String) article.get('link');
                        newsArticle.uploadDate  = formattedDate;

                        result.add(newsArticle);
                        num++;
                    }
                        return result;
                    }else{
                        System.debug('API Error - Status: ' + statusCode + ', Body: ' + response.getBody());
                        throw new AuraHandledException('API 호출 중 오류 발생');
                    }
            }else{
                return null;
            }
        } catch (Exception e) {
            System.debug('Error : '         + e.getMessage());
            System.debug('Line Number : '   + e.getLineNumber());
            
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String convertDate(String pubDate){
        String[] dateParts = pubDate.split(' ');
        return dateParts[0] + ' ' + dateParts[1] + ' ' + dateParts[2] + ' ' + dateParts[3]; 
    }

    // HTML 태그 제거 메서드
    private static String removeHtmlTags(String html){
        return html.replaceAll('<.*?>', '');
    }

    private static String decodeHtml(String text) {
        if (text == null) return null;
    
        Map<String, String> htmlEntities = new Map<String, String>{
            '&quot;'    => '"',
            '&amp;'     => '&',
            '&lt;'      => '<',
            '&gt;'      => '>',
            '&nbsp;'    => ' ',
            '&iexcl;'   => '¡',
            '&cent;'    => '¢',
            '&pound;'   => '£',
            '&curren;'  => '¤',
            '&yen;'     => '¥',
            '&brvbar;'  => '¦',
            '&sect;'    => '§',
            '&uml;'     => '¨',
            '&copy;'    => '©',
            '&ordf;'    => 'ª',
            '&laquo;'   => '«',
            '&not;'     => '¬',
            '&shy;'     => '­',
            '&reg;'     => '®',
            '&macr;'    => '¯',
            '&deg;'     => '°',
            '&plusmn;'  => '±',
            '&sup2;'    => '²',
            '&sup3;'    => '³',
            '&acute;'   => '´',
            '&micro;'   => 'µ',
            '&para;'    => '¶',
            '&middot;'  => '·',
            '&cedil;'   => '¸',
            '&sup1;'    => '¹',
            '&ordm;'    => 'º',
            '&raquo;'   => '»',
            '&frac14;'  => '¼',
            '&frac12;'  => '½',
            '&frac34;'  => '¾',
            '&iquest;'  => '¿',
            '&Agrave;'  => 'À',
            '&Aacute;'  => 'Á',
            '&Acirc;'   => 'Â',
            '&Atilde;'  => 'Ã',
            '&Auml;'    => 'Ä',
            '&Aring;'   => 'Å',
            '&AElig;'   => 'Æ',
            '&Ccedil;'  => 'Ç',
            '&Egrave;'  => 'È',
            '&Eacute;'  => 'É',
            '&Ecirc;'   => 'Ê',
            '&Euml;'    => 'Ë',
            '&Igrave;'  => 'Ì',
            '&Iacute;'  => 'Í',
            '&Icirc;'   => 'Î',
            '&Iuml;'    => 'Ï',
            '&ETH;'     => 'Ð',
            '&Ntilde;'  => 'Ñ',
            '&Ograve;'  => 'Ò',
            '&Oacute;'  => 'Ó',
            '&Ocirc;'   => 'Ô',
            '&Otilde;'  => 'Õ',
            '&Ouml;'    => 'Ö',
            '&times;'   => '×',
            '&Oslash;'  => 'Ø',
            '&Ugrave;'  => 'Ù',
            '&Uacute;'  => 'Ú',
            '&Ucirc;'   => 'Û',
            '&Uuml;'    => 'Ü',
            '&Yacute;'  => 'Ý',
            '&THORN;'   => 'Þ',
            '&szlig;'   => 'ß',
            '&agrave;'  => 'à',
            '&aacute;'  => 'á',
            '&acirc;'   => 'â',
            '&atilde;'  => 'ã',
            '&auml;'    => 'ä',
            '&aring;'   => 'å',
            '&aelig;'   => 'æ',
            '&ccedil;'  => 'ç',
            '&egrave;'  => 'è',
            '&eacute;'  => 'é',
            '&ecirc;'   => 'ê',
            '&euml;'    => 'ë',
            '&igrave;'  => 'ì',
            '&iacute;'  => 'í',
            '&icirc;'   => 'î',
            '&iuml;'    => 'ï',
            '&eth;'     => 'ð',
            '&ntilde;'  => 'ñ',
            '&ograve;'  => 'ò',
            '&oacute;'  => 'ó',
            '&ocirc;'   => 'ô',
            '&otilde;'  => 'õ',
            '&ouml;'    => 'ö',
            '&divide;'  => '÷',
            '&oslash;'  => 'ø',
            '&ugrave;'  => 'ù',
            '&uacute;'  => 'ú',
            '&ucirc;'   => 'û',
            '&uuml;'    => 'ü',
            '&yacute;'  => 'ý',
            '&thorn;'   => 'þ',
            '&yuml;'    => 'ÿ'
        };
    
        for (String key : htmlEntities.keySet()) {
            text = text.replace(key, htmlEntities.get(key));
        }
    
        return text;
    }

    public class NaverNewsArticle {
        @AuraEnabled public Integer index       { get; set; } 
        @AuraEnabled public String  title       { get; set; }  
        @AuraEnabled public String  description { get; set; } 
        @AuraEnabled public String  url         { get; set; }
        @AuraEnabled public String  uploadDate  { get; set; }
    }

}