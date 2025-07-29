/**
 * @description VIBA Risk Prediction Response 클래스
 * @author VIBA AI Assistant
 * @date 2025-01-27
 */
public with sharing class VIBARiskPrediction {
    public Id accountId { get; set; }
    public Boolean success { get; set; }
    public String riskLevel { get; set; }
    public Decimal riskScore { get; set; }
    public Decimal confidence { get; set; }
    public String message { get; set; }
    public List<String> recommendations { get; set; }
    
    public VIBARiskPrediction() {
        this.success = false;
        this.riskScore = 0.0;
        this.confidence = 0.0;
        this.recommendations = new List<String>();
    }
}
