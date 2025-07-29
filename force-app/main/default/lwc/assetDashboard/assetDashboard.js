import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getAssetDashboard from '@salesforce/apex/SalesAssetSupportController.getAssetDashboard';
import generateSalesInsights from '@salesforce/apex/SalesAssetSupportController.generateSalesInsights';

/**
 * Asset Dashboard 컴포넌트
 * SalesAssetSupportController와 연동하여 Tiger B2B Asset 관리 기능 제공
 */
export default class AssetDashboard extends NavigationMixin(LightningElement) {
    @api recordId; // Asset Id
    @track dashboardData;
    @track salesInsights;
    @track isLoading = true;
    @track error;
    @track activeTab = 'overview';

    wiredResult;

    // Payment History 컬럼 정의 (실제 필드명 기반)
    paymentColumns = [
        { label: '분할 차수', fieldName: 'Installment_Number__c', type: 'number' },
        { label: '납부 금액', fieldName: 'Amount__c', type: 'currency', 
          typeAttributes: { currencyCode: 'KRW', minimumFractionDigits: 0 } },
        { label: '납부 예정일', fieldName: 'DueDate__c', type: 'date' },
        { label: '실납부일', fieldName: 'PaidDate__c', type: 'date' },
        { label: '상태', fieldName: 'Status__c', type: 'text' }
    ];

    // Opportunity 컬럼 정의
    opportunityColumns = [
        { label: '기회명', fieldName: 'Name', type: 'text' },
        { label: '단계', fieldName: 'StageName', type: 'text' },
        { label: '금액', fieldName: 'Amount', type: 'currency', 
          typeAttributes: { currencyCode: 'KRW' } },
        { label: '예상 완료일', fieldName: 'CloseDate', type: 'date' },
        { label: '확률', fieldName: 'Probability', type: 'percent' }
    ];

    @wire(getAssetDashboard, { assetId: '$recordId' })
    wiredAssetDashboard(result) {
        this.wiredResult = result;
        this.isLoading = true;
        
        if (result.data) {
            this.dashboardData = result.data;
            this.error = undefined;
            this.loadSalesInsights();
        } else if (result.error) {
            this.error = result.error;
            this.dashboardData = undefined;
            console.error('Asset Dashboard 로드 실패:', this.error);
        }
        this.isLoading = false;
    }

    // Sales Insights 로드
    loadSalesInsights() {
        if (this.recordId) {
            generateSalesInsights({ assetId: this.recordId })
                .then(result => {
                    this.salesInsights = result;
                })
                .catch(error => {
                    console.error('Sales Insights 로드 실패:', error);
                });
        }
    }

    // Asset 정보 존재 여부 확인
    get hasAssetInfo() {
        return this.dashboardData?.assetInfo;
    }

    // Order 정보 존재 여부 확인
    get hasOrderInfo() {
        return this.dashboardData?.assetInfo?.Order__r;
    }

    // Payment History 존재 여부 확인
    get hasPaymentHistory() {
        return this.dashboardData?.paymentHistory?.length > 0;
    }

    // Opportunities 존재 여부 확인
    get hasOpportunities() {
        return this.dashboardData?.opportunities?.length > 0;
    }

    // Asset 상태별 스타일 클래스
    get assetStatusClass() {
        if (!this.hasAssetInfo) return 'status-unknown';
        
        const status = this.dashboardData.assetInfo.Status;
        return `status-${status ? status.toLowerCase().replace(/\s+/g, '-') : 'unknown'}`;
    }

    // 현재 MRR 포맷팅 (표준 필드 CurrentMrr 사용)
    get formattedMrr() {
        if (!this.hasAssetInfo || !this.dashboardData.assetInfo.CurrentMrr) {
            return '₩0';
        }
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(this.dashboardData.assetInfo.CurrentMrr);
    }

    // 현재 계약 금액 포맷팅 (Price 필드 사용)
    get formattedTotalValue() {
        if (!this.hasAssetInfo || !this.dashboardData.assetInfo.Price) {
            return '₩0';
        }
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(this.dashboardData.assetInfo.Price);
    }

    // 라이프사이클 관리 여부 표시 (표준 필드명)
    get lifecycleManagementStatus() {
        if (!this.hasAssetInfo) return '알 수 없음';
        return this.dashboardData.assetInfo.HasLifecycleManagement ? '활성' : '비활성';
    }

    // 경쟁사 제품 여부 표시 (표준 필드명)
    get competitorProductStatus() {
        if (!this.hasAssetInfo) return '알 수 없음';
        return this.dashboardData.assetInfo.IsCompetitorProduct ? '경쟁사 제품' : 'Tiger B2B 제품';
    }

    // 시리얼 번호 표시
    get serialNumber() {
        return this.hasAssetInfo ? this.dashboardData.assetInfo.SerialNumber : 'N/A';
    }

    // 설치일 포맷팅
    get formattedInstallDate() {
        if (!this.hasAssetInfo || !this.dashboardData.assetInfo.InstallDate) {
            return 'N/A';
        }
        return new Date(this.dashboardData.assetInfo.InstallDate).toLocaleDateString('ko-KR');
    }

    // Asset 설명에서 비즈니스 인사이트 추출
    get assetBusinessInsights() {
        if (!this.hasAssetInfo || !this.dashboardData.assetInfo.Description) {
            return null;
        }
        
        const description = this.dashboardData.assetInfo.Description;
        const insights = {};
        
        // Order Number 추출
        const orderMatch = description.match(/Order Number: (\d+)/);
        insights.orderNumber = orderMatch ? orderMatch[1] : 'N/A';
        
        // 총 금액 추출
        const amountMatch = description.match(/총 금액: ([\d,]+)원/);
        insights.totalAmount = amountMatch ? amountMatch[1] : 'N/A';
        
        // 납부 완료 정보 추출
        const paymentMatch = description.match(/납부 완료: (\d+)\/(\d+)차/);
        insights.paymentProgress = paymentMatch ? `${paymentMatch[1]}/${paymentMatch[2]}차` : 'N/A';
        
        // 완납 금액 추출
        const paidMatch = description.match(/완납 금액: ([\d,]+)원/);
        insights.paidAmount = paidMatch ? paidMatch[1] : 'N/A';
        
        return insights;
    }

    // 납부 완료율 계산
    get paymentCompletionRate() {
        const insights = this.assetBusinessInsights;
        if (!insights || insights.paymentProgress === 'N/A') {
            return 0;
        }
        
        const [completed, total] = insights.paymentProgress.split('/').map(num => parseInt(num.replace('차', '')));
        return total > 0 ? Math.round((completed / total) * 100) : 0;
    }

    // 납부 상태에 따른 색상 클래스
    get paymentStatusClass() {
        const rate = this.paymentCompletionRate;
        if (rate === 100) return 'payment-complete';
        if (rate >= 75) return 'payment-good';
        if (rate >= 50) return 'payment-warning';
        return 'payment-danger';
    }

    // 프로그레스 바 스타일
    get progressBarStyle() {
        return `width: ${this.paymentCompletionRate}%`;
    }

    // 탭 변경 핸들러
    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    // Order로 이동
    navigateToOrder() {
        if (this.hasOrderInfo) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.dashboardData.assetInfo.Order__r.Id,
                    objectApiName: 'Order__c',
                    actionName: 'view'
                }
            });
        }
    }

    // Account로 이동
    navigateToAccount() {
        if (this.hasAssetInfo && this.dashboardData.assetInfo.AccountId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.dashboardData.assetInfo.AccountId,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            });
        }
    }

    // 새로고침
    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredResult)
            .then(() => {
                this.loadSalesInsights();
                this.showToast('성공', 'Asset 정보가 새로고침되었습니다.', 'success');
            })
            .catch(error => {
                console.error('새로고침 실패:', error);
                this.showToast('오류', '새로고침 중 오류가 발생했습니다.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
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
