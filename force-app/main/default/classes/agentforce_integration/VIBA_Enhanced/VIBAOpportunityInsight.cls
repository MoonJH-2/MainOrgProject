/**
 * @description VIBA Opportunity Insight Response 클래스
 * @author VIBA AI Assistant
 * @date 2025-01-27
 */
public with sharing class VIBAOpportunityInsight {
    public Id assetId { get; set; }
    public Boolean success { get; set; }
    public Decimal opportunityScore { get; set; }
    public String opportunityType { get; set; }
    public Decimal estimatedRevenue { get; set; }
    public String message { get; set; }
    public List<String> insights { get; set; }
    
    public VIBAOpportunityInsight() {
        this.success = false;
        this.opportunityScore = 0.0;
        this.estimatedRevenue = 0.0;
        this.insights = new List<String>();
    }
}
