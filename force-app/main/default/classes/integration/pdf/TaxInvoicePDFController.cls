public with sharing class TaxInvoicePDFController {
    public String orderNumber { get; set; }
    public String accountName { get; set; }
    public String accountOwner { get; set; }
    public String accountIndustry { get; set; }
    public String accountAddress { get; set; }
    public String accountPhone { get; set; }
    public String accountWebsite { get; set; }
    public String accountBusinessNumber { get; set; }
    public List<OrderItem> orderItems { get; set; }
    public Decimal supplyAmount { get; set; }
    public Decimal vatAmount { get; set; }
    public Decimal totalAmount { get; set; }
    
    public TaxInvoicePDFController() {
        String orderId = ApexPages.currentPage().getParameters().get('orderId');
        if (String.isNotBlank(orderId)) {
            loadOrderData(orderId);
        }
    }
    
    private void loadOrderData(String orderId) {
        try {
            // Order 및 관련 정보 조회 (Account의 실제 필드 사용, BusinessNumber__c 포함)
            Order orderRecord = [
                SELECT Id, OrderNumber, TotalAmount, AccountId,
                       Account.Name, Account.BillingAddress, Account.ShippingAddress, 
                       Account.Phone, Account.Website, Account.Industry, Account.Owner.Name,
                       Account.BusinessNumber__c,
                       (SELECT Id, Product2.Name, Quantity, UnitPrice, TotalPrice 
                        FROM OrderItems)
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            this.orderNumber = orderRecord.OrderNumber;
            this.accountName = orderRecord.Account.Name;
            this.accountOwner = orderRecord.Account.Owner.Name;
            this.accountIndustry = orderRecord.Account.Industry;
            this.accountPhone = orderRecord.Account.Phone;
            this.accountWebsite = orderRecord.Account.Website;
            this.accountBusinessNumber = orderRecord.Account.BusinessNumber__c;
            this.orderItems = orderRecord.OrderItems;
            
            // 주소 정보 처리 (Shipping Address 우선, 없으면 Billing Address)
            Address addressToUse = orderRecord.Account.ShippingAddress != null ? 
                                  orderRecord.Account.ShippingAddress : orderRecord.Account.BillingAddress;
                                  
            if (addressToUse != null) {
                this.accountAddress = '';
                if (String.isNotBlank(addressToUse.getStreet())) {
                    this.accountAddress += addressToUse.getStreet() + ' ';
                }
                if (String.isNotBlank(addressToUse.getCity())) {
                    this.accountAddress += addressToUse.getCity() + ' ';
                }
                if (String.isNotBlank(addressToUse.getState())) {
                    this.accountAddress += addressToUse.getState() + ' ';
                }
                if (String.isNotBlank(addressToUse.getPostalCode())) {
                    this.accountAddress += addressToUse.getPostalCode() + ' ';
                }
                if (String.isNotBlank(addressToUse.getCountry())) {
                    this.accountAddress += addressToUse.getCountry();
                }
                this.accountAddress = this.accountAddress.trim();
            } else {
                this.accountAddress = '사업장 주소';
            }
            
            // 세금 계산
            calculateTaxAmounts();
            
        } catch (Exception e) {
            System.debug('Order 데이터 로드 오류: ' + e.getMessage());
            // 기본값 설정
            this.orderNumber = 'N/A';
            this.accountName = '고객사';
            this.accountOwner = '회사 대표';
            this.accountIndustry = '일반 기업';
            this.accountAddress = '사업장 주소';
            this.accountPhone = '02-0000-0000';
            this.accountWebsite = 'www.example.com';
            this.accountBusinessNumber = '000-00-00000';
            this.orderItems = new List<OrderItem>();
            this.supplyAmount = 0;
            this.vatAmount = 0;
            this.totalAmount = 0;
        }
    }
    
    private void calculateTaxAmounts() {
        this.totalAmount = 0;
        
        if (orderItems != null && !orderItems.isEmpty()) {
            for (OrderItem item : orderItems) {
                this.totalAmount += item.TotalPrice;
            }
        }
        
        // 부가세 10% 계산 (역계산)
        this.supplyAmount = totalAmount / 1.1;
        this.vatAmount = totalAmount - supplyAmount;
    }
}
