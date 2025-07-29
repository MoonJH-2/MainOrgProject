import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAssetDetails from '@salesforce/apex/AssetManagementController.getAssetDetails';
import getPaymentHistory from '@salesforce/apex/PaymentStatusTimelineController.getPaymentHistory';

export default class ModernAssetDashboard extends NavigationMixin(LightningElement) {
    @api recordId;
    @track assetData = {};
    @track paymentHistory = [];
    @track isLoading = true;
    @track error;
    
    wiredAssetResult;
    wiredPaymentResult;

    // Asset 정보 가져오기
    @wire(getAssetDetails, { assetId: '$recordId' })
    wiredAssetDetails(result) {
        this.wiredAssetResult = result;
        const { error, data } = result;
        if (data) {
            this.assetData = data;
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.isLoading = false;
            this.showToast('Error', 'Asset 정보를 불러오는 중 오류가 발생했습니다.', 'error');
        }
    }

    // Payment 히스토리 가져오기
    @wire(getPaymentHistory, { assetId: '$recordId' })
    wiredPaymentHistory(result) {
        this.wiredPaymentResult = result;
        const { error, data } = result;
        if (data) {
            this.paymentHistory = data;
        } else if (error) {
            this.showToast('Warning', 'Payment 히스토리를 불러올 수 없습니다.', 'warning');
        }
    }

    // Computed Properties
    get assetName() {
        return this.assetData.Name || 'Asset 정보 없음';
    }

    get serialNumber() {
        return this.assetData.SerialNumber || 'N/A';
    }

    get assetStatus() {
        return this.assetData.Status || 'Unknown';
    }

    get formattedTotalValue() {
        if (this.assetData.Price) {
            return new Intl.NumberFormat('ko-KR', {
                style: 'currency',
                currency: 'KRW'
            }).format(this.assetData.Price);
        }
        return '₩0';
    }

    get formattedPurchaseDate() {
        if (this.assetData.PurchaseDate) {
            return new Date(this.assetData.PurchaseDate).toLocaleDateString('ko-KR', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });
        }
        return 'N/A';
    }

    get accountName() {
        return this.assetData.Account?.Name || 'N/A';
    }

    get accountType() {
        return this.assetData.Account?.Type || 'N/A';
    }

    get accountPhone() {
        return this.assetData.Account?.Phone || 'N/A';
    }

    get orderNumber() {
        return this.assetData.Order__r?.OrderNumber || 'N/A';
    }

    get orderStatus() {
        return this.assetData.Order__r?.Status || 'N/A';
    }

    get contractNumber() {
        return this.assetData.Order__r?.ContractNumber || 'N/A';
    }

    get productName() {
        return this.assetData.Product2?.Name || 'N/A';
    }

    get unitPrice() {
        if (this.assetData.Product2?.UnitPrice) {
            return new Intl.NumberFormat('ko-KR', {
                style: 'currency',
                currency: 'KRW'
            }).format(this.assetData.Product2.UnitPrice);
        }
        return '₩0';
    }

    get quantity() {
        return this.assetData.Quantity || 1;
    }

    get paymentCompletionRate() {
        if (!this.paymentHistory.length) return 0;
        const completedPayments = this.paymentHistory.filter(payment => 
            payment.Status__c === 'Paid'
        ).length;
        return Math.round((completedPayments / this.paymentHistory.length) * 100);
    }

    get isPaymentComplete() {
        return this.paymentCompletionRate === 100;
    }

    // Event Handlers
    handleRefresh() {
        this.isLoading = true;
        // Force refresh by re-evaluating wired methods
        return refreshApex(this.wiredAssetResult)
            .then(() => refreshApex(this.wiredPaymentResult))
            .then(() => {
                this.isLoading = false;
                this.showToast('Success', 'Asset 정보가 새로고침되었습니다.', 'success');
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', '새로고침 중 오류가 발생했습니다.', 'error');
            });
    }

    navigateToAccount() {
        if (this.assetData.AccountId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.assetData.AccountId,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            });
        }
    }

    navigateToOrder() {
        if (this.assetData.Order__c) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.assetData.Order__c,
                    objectApiName: 'Order',
                    actionName: 'view'
                }
            });
        }
    }

    downloadPaymentConfirmation() {
        // Payment 확인서 다운로드 로직
        this.showToast('Info', '납부확인서 다운로드 기능을 준비 중입니다.', 'info');
    }

    downloadTaxInvoice() {
        // 세금계산서 다운로드 로직
        this.showToast('Info', '세금계산서 다운로드 기능을 준비 중입니다.', 'info');
    }

    reviewRenewal() {
        // 갱신 검토 페이지로 이동
        this.showToast('Info', '갱신 검토 프로세스를 시작합니다.', 'info');
    }

    contactCustomer() {
        // 고객 연락 기능
        if (this.assetData.Account?.Phone) {
            // 전화 걸기 기능 또는 태스크 생성
            this.showToast('Info', `${this.accountName}에게 연락합니다: ${this.accountPhone}`, 'info');
        } else {
            this.showToast('Warning', '고객 연락처 정보가 없습니다.', 'warning');
        }
    }

    // Utility Methods
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    // Lifecycle Hooks
    connectedCallback() {
        console.log('Modern Asset Dashboard initialized with recordId:', this.recordId);
    }

    disconnectedCallback() {
        // Cleanup if needed
    }

    renderedCallback() {
        // DOM 렌더링 완료 후 실행할 로직
        if (!this.isLoading && this.template.querySelector('.modern-asset-container')) {
            // 애니메이션이나 추가 초기화 로직
            this.initializeInteractions();
        }
    }

    initializeInteractions() {
        // 카드 호버 효과나 기타 인터랙션 초기화
        const cards = this.template.querySelectorAll('.status-card, .detail-card');
        cards.forEach(card => {
            card.addEventListener('mouseenter', this.handleCardHover);
            card.addEventListener('mouseleave', this.handleCardLeave);
        });
    }

    handleCardHover = (event) => {
        event.currentTarget.style.transform = 'translateY(-4px)';
    }

    handleCardLeave = (event) => {
        event.currentTarget.style.transform = 'translateY(0)';
    }
}
