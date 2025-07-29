import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Apex 메서드 import
import analyzeRenewalOpportunities from '@salesforce/apex/AssetRenewalOpportunityEngine.analyzeRenewalOpportunities';
import analyzeSalesOpportunities from '@salesforce/apex/AssetBasedSalesOpportunityEngine.analyzeSalesOpportunities';
import analyzeCustomerRisk from '@salesforce/apex/AssetCustomerRiskAnalyzer.analyzeCustomerRisk';

// Asset 필드들
const ASSET_FIELDS = [
    'Asset.Id',
    'Asset.Name',
    'Asset.AccountId',
    'Asset.Price',
    'Asset.Status',
    'Asset.PurchaseDate',
    'Asset.InstallDate',
    'Asset.UsageEndDate'
];

export default class AssetSalesInsightDashboard extends NavigationMixin(LightningElement) {
    @api recordId;
    
    @track asset = {};
    @track renewalOpportunities = [];
    @track salesOpportunities = [];
    @track riskAnalysis = {};
    @track activeTab = 'renewal';
    @track isLoading = true;

    // Wire Asset 데이터
    @wire(getRecord, { recordId: '$recordId', fields: ASSET_FIELDS })
    wiredAsset({ error, data }) {
        if (data) {
            this.asset = data;
            this.loadAllAnalytics();
        } else if (error) {
            console.error('Asset 데이터 로드 오류:', error);
            this.showToast('오류', 'Asset 정보를 불러올 수 없습니다.', 'error');
        }
    }
    
    // Asset 필드 getter들
    get assetName() {
        return this.asset?.fields?.Name?.value || '';
    }
    
    get accountId() {
        return this.asset?.fields?.AccountId?.value;
    }
    
    get assetPrice() {
        const price = this.asset?.fields?.Price?.value;
        return price ? '₩' + price.toLocaleString() : '₩0';
    }
    
    get assetStatus() {
        return this.asset?.fields?.Status?.value || '';
    }
    
    // 탭 관리
    get isRenewalTab() { return this.activeTab === 'renewal'; }
    get isSalesTab() { return this.activeTab === 'sales'; }
    get isRiskTab() { return this.activeTab === 'risk'; }
    
    get renewalTabClass() {
        return this.activeTab === 'renewal' ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item';
    }
    
    get salesTabClass() {
        return this.activeTab === 'sales' ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item';
    }
    
    get riskTabClass() {
        return this.activeTab === 'risk' ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item';
    }
    
    // 종합 분석 데이터 로드
    async loadAllAnalytics() {
        if (!this.accountId) return;
        
        this.isLoading = true;
        try {
            // 모든 분석을 병렬로 실행
            const [renewals, sales, risk] = await Promise.all([
                analyzeRenewalOpportunities({ assetId: this.recordId }),
                analyzeSalesOpportunities({ accountId: this.accountId }),
                analyzeCustomerRisk({ accountId: this.accountId })
            ]);
            
            // Priority variant 미리 계산
            this.renewalOpportunities = (renewals || []).map(renewal => ({
                ...renewal,
                priorityVariant: this.getPriorityVariant(renewal.priorityScore)
            }));
            
            this.salesOpportunities = sales || [];
            
            // Risk variant 미리 계산
            this.riskAnalysis = {
                ...(risk || {}),
                riskVariant: this.getRiskVariant(risk?.riskLevel)
            };
            
        } catch (error) {
            console.error('분석 데이터 로드 오류:', error);
            this.showToast('오류', '분석 데이터를 불러오는 중 문제가 발생했습니다.', 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    // 갱신 기회 요약 정보
    get renewalSummary() {
        if (!this.renewalOpportunities.length) {
            return {
                totalOpportunities: 0,
                highPriorityCount: 0,
                totalValue: '₩0'
            };
        }
        
        const highPriority = this.renewalOpportunities.filter(opp => opp.priorityScore >= 70).length;
        const totalValue = this.renewalOpportunities.reduce((sum, opp) => sum + (opp.estimatedRenewalValue || 0), 0);
        
        return {
            totalOpportunities: this.renewalOpportunities.length,
            highPriorityCount: highPriority,
            totalValue: '₩' + totalValue.toLocaleString()
        };
    }
    
    // 영업 기회 요약 정보
    get salesSummary() {
        if (!this.salesOpportunities.length) {
            return {
                totalValue: '₩0',
                upgradeCount: 0,
                crossSellCount: 0
            };
        }
        
        const totalValue = this.salesOpportunities.reduce((sum, opp) => sum + (opp.estimatedValue || 0), 0);
        const upgradeCount = this.salesOpportunities.filter(opp => opp.opportunityType === '업그레이드').length;
        const crossSellCount = this.salesOpportunities.filter(opp => opp.opportunityType === '크로스셀').length;
        
        return {
            totalValue: '₩' + totalValue.toLocaleString(),
            upgradeCount: upgradeCount,
            crossSellCount: crossSellCount
        };
    }
    
    // 리스크 요약 정보
    get riskSummary() {
        if (!this.riskAnalysis) {
            return {
                overallRisk: '정보 없음',
                riskVariant: 'neutral',
                satisfactionScore: 0
            };
        }
        
        return {
            overallRisk: this.riskAnalysis.riskLevel || '정보 없음',
            riskVariant: this.riskAnalysis.riskVariant || 'neutral',
            satisfactionScore: this.riskAnalysis.satisfactionPrediction || 0
        };
    }
    
    // Variant 헬퍼 메서드들
    getPriorityVariant(score) {
        if (score >= 80) return 'error';   // 빨간색 - 높은 우선순위
        if (score >= 60) return 'warning'; // 주황색 - 중간 우선순위
        return 'success';                  // 녹색 - 낮은 우선순위
    }
    
    getRiskVariant(riskLevel) {
        if (riskLevel === '높음') return 'error';
        if (riskLevel === '보통') return 'warning';
        if (riskLevel === '낮음') return 'success';
        return 'neutral';
    }
    
    // 이벤트 핸들러들
    handleTabSelect(event) {
        this.activeTab = event.target.dataset.tab;
    }
    
    handleRefresh() {
        this.loadAllAnalytics();
        this.showToast('성공', '데이터가 새로고침되었습니다.', 'success');
    }
    
    handleCreateOpportunity(event) {
        const assetName = event.target.dataset.name;
        const value = event.target.dataset.value;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `Name=${encodeURIComponent(assetName + ' 갱신')},Amount=${value},AccountId=${this.accountId}`
            }
        });
    }
    
    handleCreateTask(event) {
        const subject = event.target.dataset.subject;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Task',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `Subject=${encodeURIComponent(subject + ' 갱신 협의')},WhatId=${this.recordId}`
            }
        });
    }
    
    // Toast 메시지 표시
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}
