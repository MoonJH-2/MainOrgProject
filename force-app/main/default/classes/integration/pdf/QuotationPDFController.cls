/**
 * @description       : 
 * @author            : Hyowon Hong
 * @last modified on  : 07-14-2025
 * @last modified by  : Hyowon Hong
**/
public with sharing class QuotationPDFController {
    public Quote quote { get; set; }
    public List<QuoteLineItem> lineItems { get; set; }
    public Map<String, Object> result { get; set; } // Visualforce에서 참조할 Map
    
    public QuotationPDFController(ApexPages.StandardController stdController) {
        Id quoteId = stdController.getId(); // Id 추출
        
        // Quote 재쿼리: 필요한 필드 명시적으로 포함 (에러 방지)
        this.quote = [
            SELECT  Id
                    , Name
                    , QuoteNumber
                    , ExpirationDate
                    , CreatedDate
                    , GrandTotal
                    , AccountId
                    , Account.Name 
            FROM Quote 
            WHERE Id = :quoteId
            LIMIT 1
        ];
        System.debug('quote ::: ' + this.quote); // 필드 포함 확인
        
        // QuoteLineItem 쿼리
        this.lineItems = [
            SELECT  Id
                    , Product2.Name
                    , Quantity
                    , UnitPrice
                    , Subtotal
                    , Description 
            FROM QuoteLineItem 
            WHERE QuoteId = :quoteId
        ];
        
        // result Map 초기화: 페이지에서 사용되는 모든 키 추가
        this.result = new Map<String, Object>();
        this.result.put('QuoteName', this.quote.Name);
        this.result.put('QuoteNumber', this.quote.QuoteNumber);
        this.result.put('AccountName', this.quote.Account.Name);
        this.result.put('ExpDate', this.quote.ExpirationDate); // 키 'ExpDate' 명시적 추가
        this.result.put('CreatedDate', this.quote.CreatedDate);
        this.result.put('ModelName', 'Demo Model'); // 데모용
        this.result.put('ModelDescription', 'Demo Description'); // 데모용
        this.result.put('AllExtPrice', this.quote.GrandTotal);
        this.result.put('ProductCode', 'DEMO-001'); // 데모용
        this.result.put('RDD', 'Demo RDD'); // 데모용
        this.result.put('Quantity', 1); // 데모용
        this.result.put('TotalPrice', 100000); // 데모용
        this.result.put('PrdAllPrice', 100000); // 데모용
        this.result.put('quotesalesoffice', 'Demo Sales Office'); // 데모용
        this.result.put('mainphone', '010-1234-5678'); // 데모용
        
        // lineItems 연동 예시 (실제 사용 시)
        // if (!lineItems.isEmpty()) {
        //     result.put('ModelName', lineItems[0].Product2.Name);
        // }
    }
}