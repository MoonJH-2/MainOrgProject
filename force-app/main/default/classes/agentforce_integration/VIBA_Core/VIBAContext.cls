/**
 * @description VIBA 컨텍스트 정보 클래스들
 */

/**
 * @description VIBA 컨텍스트 정보
 */
public class VIBAContext {
    public String requestType { get; set; }
    public Id recordId { get; set; }
    public DateTime timestamp { get; set; }
    public VIBAOrderContext orderContext { get; set; }
    public VIBAPaymentContext paymentContext { get; set; }
    public VIBAAssetContext assetContext { get; set; }
}
