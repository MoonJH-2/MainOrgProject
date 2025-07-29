/**
 * @description VIBA Order 컨텍스트
 */
public class VIBAOrderContext {
    public Boolean hasCompleteData { get; set; }
    public Boolean hasPaymentHistory { get; set; }
    public Boolean hasCustomerHistory { get; set; }
    public Boolean hasComplexPaymentTerms { get; set; }
    
    public VIBAOrderContext() {
        this.hasCompleteData = false;
        this.hasPaymentHistory = false;
        this.hasCustomerHistory = false;
        this.hasComplexPaymentTerms = false;
    }
}
