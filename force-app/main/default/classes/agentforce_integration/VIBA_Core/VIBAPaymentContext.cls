/**
 * @description VIBA Payment 컨텍스트
 */
public class VIBAPaymentContext {
    public Boolean hasTimelineData { get; set; }
    public Boolean hasCompletionData { get; set; }
    public Boolean hasOverduePayments { get; set; }
    public Boolean hasRepeatedDelays { get; set; }
    public Boolean hasRecentCommunication { get; set; }
    public Boolean hasExcellentHistory { get; set; }
    
    public VIBAPaymentContext() {
        this.hasTimelineData = false;
        this.hasCompletionData = false;
        this.hasOverduePayments = false;
        this.hasRepeatedDelays = false;
        this.hasRecentCommunication = false;
        this.hasExcellentHistory = false;
    }
}
