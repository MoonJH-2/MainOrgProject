import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getAccountOrderDashboard from '@salesforce/apex/AccountOrderDashboardController.getAccountOrderDashboard';

/**
 * Account Order Dashboard 컴포넌트
 * Account 360도 뷰: 연결된 Order, Opportunity, Asset 정보를 종합적으로 표시
 */
export default class AccountOrderDashboard extends NavigationMixin(LightningElement) {
    @api recordId; // Account Id
    @track dashboardData;
    @track isLoading = true;
    @track error;
    @track activeTab = 'orders';

    wiredResult;

    // Order 컬럼 정의
    orderColumns = [
        { 
            label: 'Order 번호', 
            fieldName: 'orderUrl', 
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'OrderNumber' },
                target: '_blank'
            }
        },
        { label: '상태', fieldName: 'Status', type: 'text' },
        { label: '계약 금액', fieldName: 'TotalAmount', type: 'currency', 
          typeAttributes: { currencyCode: 'KRW', minimumFractionDigits: 0 } },
        { label: '시작일', fieldName: 'EffectiveDate', type: 'date' },
        { label: '납부 방법', fieldName: 'Payment_Method__c', type: 'text' }
    ];

    // Opportunity 컬럼 정의
    opportunityColumns = [
        { 
            label: '기회명', 
            fieldName: 'opportunityUrl', 
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            }
        },
        { label: '단계', fieldName: 'StageName', type: 'text' },
        { label: '금액', fieldName: 'Amount', type: 'currency', 
          typeAttributes: { currencyCode: 'KRW', minimumFractionDigits: 0 } },
        { label: '예상 완료일', fieldName: 'CloseDate', type: 'date' }
    ];

    // Asset 컬럼 정의
    assetColumns = [
        { 
            label: 'Asset 이름', 
            fieldName: 'assetUrl', 
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            }
        },
        { label: '상태', fieldName: 'Status', type: 'text' },
        { label: '시리얼 번호', fieldName: 'SerialNumber', type: 'text' },
        { label: '구매일', fieldName: 'PurchaseDate', type: 'date' },
        { label: '계약 금액', fieldName: 'Price', type: 'currency', 
          typeAttributes: { currencyCode: 'KRW', minimumFractionDigits: 0 } }
    ];

    @wire(getAccountOrderDashboard, { accountId: '$recordId' })
    wiredAccountDashboard(result) {
        this.wiredResult = result;
        this.isLoading = true;
        
        if (result.data) {
            // 데이터를 깊은 복사하여 수정 가능하게 만들기
            this.dashboardData = JSON.parse(JSON.stringify(result.data));
            this.processUrls();
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.dashboardData = undefined;
            console.error('Account Dashboard 로드 실패:', this.error);
        }
        this.isLoading = false;
    }

    // URL 처리 (데이터 변형을 안전하게 처리)
    processUrls() {
        if (!this.dashboardData) return;
        
        try {
            // Order URLs - 배열이 존재할 때만 처리
            if (this.dashboardData.orders && Array.isArray(this.dashboardData.orders)) {
                this.dashboardData.orders = this.dashboardData.orders.map(order => ({
                    ...order,
                    orderUrl: `/lightning/r/Order/${order.Id}/view`
                }));
            }
            
            // Opportunity URLs - 배열이 존재할 때만 처리
            if (this.dashboardData.opportunities && Array.isArray(this.dashboardData.opportunities)) {
                this.dashboardData.opportunities = this.dashboardData.opportunities.map(opp => ({
                    ...opp,
                    opportunityUrl: `/lightning/r/Opportunity/${opp.Id}/view`
                }));
            }
            
            // Asset URLs - 배열이 존재할 때만 처리
            if (this.dashboardData.assets && Array.isArray(this.dashboardData.assets)) {
                this.dashboardData.assets = this.dashboardData.assets.map(asset => ({
                    ...asset,
                    assetUrl: `/lightning/r/Asset/${asset.Id}/view`
                }));
            }
        } catch (error) {
            console.error('URL 처리 중 오류:', error);
        }
    }

    // Account 정보 존재 여부 확인
    get hasAccountInfo() {
        return this.dashboardData?.accountInfo;
    }

    // Order 존재 여부 확인
    get hasOrders() {
        return this.dashboardData?.orders && Array.isArray(this.dashboardData.orders) && this.dashboardData.orders.length > 0;
    }

    // Opportunity 존재 여부 확인
    get hasOpportunities() {
        return this.dashboardData?.opportunities && Array.isArray(this.dashboardData.opportunities) && this.dashboardData.opportunities.length > 0;
    }

    // Asset 존재 여부 확인
    get hasAssets() {
        return this.dashboardData?.assets && Array.isArray(this.dashboardData.assets) && this.dashboardData.assets.length > 0;
    }

    // 총 계약 금액 계산
    get totalOrderAmount() {
        if (!this.hasOrders) return 0;
        return this.dashboardData.orders.reduce((total, order) => total + (order.TotalAmount || 0), 0);
    }

    // 총 계약 금액 포맷팅
    get formattedTotalOrderAmount() {
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(this.totalOrderAmount);
    }

    // 총 Opportunity 금액 계산
    get totalOpportunityAmount() {
        if (!this.hasOpportunities) return 0;
        return this.dashboardData.opportunities.reduce((total, opp) => total + (opp.Amount || 0), 0);
    }

    // 총 Opportunity 금액 포맷팅
    get formattedTotalOpportunityAmount() {
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(this.totalOpportunityAmount);
    }

    // 활성 Order 수 계산
    get activeOrderCount() {
        if (!this.hasOrders) return 0;
        return this.dashboardData.orders.filter(order => order.Status === 'Activated').length;
    }

    // 성사된 Opportunity 수 계산
    get wonOpportunityCount() {
        if (!this.hasOpportunities) return 0;
        return this.dashboardData.opportunities.filter(opp => opp.StageName === '계약 성사').length;
    }

    // 탭 변경 핸들러
    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    // Account로 이동
    navigateToAccount() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    // 새로고침
    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredResult)
            .then(() => {
                this.showToast('성공', 'Account 정보가 새로고침되었습니다.', 'success');
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
