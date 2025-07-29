/**
 * @description 세금계산서 PDF 생성 컨트롤러
 * @author JH Moon
 * @created 2025-07-27
 */
public with sharing class TaxInvoicePDFController {
    public Order orderInfo { get; set; }
    public String orderNumber { get; set; }
    public String accountName { get; set; }
    public String accountOwner { get; set; }
    public String accountBusinessNumber { get; set; }
    public String accountAddress { get; set; }
    public String accountIndustry { get; set; }
    public String accountPhone { get; set; }
    public String accountWebsite { get; set; }
    public List<OrderItem> orderItems { get; set; }
    public Decimal supplyAmount { get; set; }
    public Decimal vatAmount { get; set; }
    public Decimal totalAmount { get; set; }
    
    public TaxInvoicePDFController() {
        String orderId = ApexPages.currentPage().getParameters().get('orderId');
        
        if (String.isNotBlank(orderId)) {
            loadTaxData(orderId);
        }
    }
    
    private void loadTaxData(String orderId) {
        try {
            // Order 정보 조회 (OrderItem 포함)
            orderInfo = [
                SELECT Id, OrderNumber, TotalAmount, EffectiveDate, Account.Name,
                       Account.Owner.Name, Account.BusinessNumber__c, Account.ShippingAddress,
                       Account.BillingAddress, Account.Industry, Account.Phone, Account.Website,
                       (SELECT Id, Product2Id, Product2.Name, Quantity, UnitPrice, TotalPrice 
                        FROM OrderItems)
                FROM Order 
                WHERE Id = :orderId 
                LIMIT 1
            ];
            
            this.orderNumber = orderInfo.OrderNumber;
            this.accountName = orderInfo.Account.Name;
            this.accountOwner = orderInfo.Account.Owner.Name;
            this.accountBusinessNumber = orderInfo.Account.BusinessNumber__c;
            this.accountIndustry = orderInfo.Account.Industry;
            this.accountPhone = orderInfo.Account.Phone;
            this.accountWebsite = orderInfo.Account.Website;
            this.orderItems = orderInfo.OrderItems;
            
            // 주소 처리 (ShippingAddress 우선, 없으면 BillingAddress)
            if (orderInfo.Account.ShippingAddress != null) {
                this.accountAddress = formatAddress(orderInfo.Account.ShippingAddress);
            } else if (orderInfo.Account.BillingAddress != null) {
                this.accountAddress = formatAddress(orderInfo.Account.BillingAddress);
            } else {
                this.accountAddress = '주소 정보 없음';
            }
            
            // 세금 계산
            calculateTax();
            
        } catch (Exception e) {
            System.debug('세금계산서 데이터 로딩 오류: ' + e.getMessage());
            // 기본값 설정
            this.orderNumber = 'N/A';
            this.accountName = 'N/A';
            this.supplyAmount = 0;
            this.vatAmount = 0;
            this.totalAmount = 0;
        }
    }
    
    private String formatAddress(Address addr) {
        if (addr == null) return '';
        
        String formattedAddress = '';
        if (String.isNotBlank(addr.getStreet())) {
            formattedAddress += addr.getStreet();
        }
        if (String.isNotBlank(addr.getCity())) {
            formattedAddress += (String.isNotBlank(formattedAddress) ? ', ' : '') + addr.getCity();
        }
        if (String.isNotBlank(addr.getState())) {
            formattedAddress += (String.isNotBlank(formattedAddress) ? ', ' : '') + addr.getState();
        }
        if (String.isNotBlank(addr.getPostalCode())) {
            formattedAddress += (String.isNotBlank(formattedAddress) ? ' ' : '') + addr.getPostalCode();
        }
        
        return formattedAddress;
    }
    
    private void calculateTax() {
        totalAmount = 0;
        
        // OrderItem 기반 계산
        if (!orderInfo.OrderItems.isEmpty()) {
            for (OrderItem item : orderInfo.OrderItems) {
                totalAmount += item.TotalPrice;
            }
        } else {
            // OrderItem이 없는 경우 Order.TotalAmount 사용
            totalAmount = orderInfo.TotalAmount != null ? orderInfo.TotalAmount : 0;
        }
        
        // 부가세 10% 계산
        supplyAmount = totalAmount / 1.1;
        vatAmount = totalAmount - supplyAmount;
        
        // 소수점 처리
        supplyAmount = supplyAmount.setScale(0);
        vatAmount = vatAmount.setScale(0);
        totalAmount = totalAmount.setScale(0);
    }
}
