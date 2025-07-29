/**
 * @description VIBA Asset 컨텍스트
 */
public class VIBAAssetContext {
    public Boolean hasUsageData { get; set; }
    public Boolean hasPerformanceData { get; set; }
    public Boolean hasHighUsage { get; set; }
    public Boolean hasLowUsage { get; set; }
    public Boolean isNearingExpiry { get; set; }
    
    public VIBAAssetContext() {
        this.hasUsageData = false;
        this.hasPerformanceData = false;
        this.hasHighUsage = false;
        this.hasLowUsage = false;
        this.isNearingExpiry = false;
    }
}
