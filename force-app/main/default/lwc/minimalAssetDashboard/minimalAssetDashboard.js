import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getAssetDetails from '@salesforce/apex/AssetManagementController.getAssetDetails';

/**
 * 미니멀하고 사용자 친화적인 Asset 관리 대시보드
 */
export default class MinimalAssetDashboard extends NavigationMixin(LightningElement) {
    @api recordId; // Asset ID
    @track assetData;
    @track isLoading = true;
    @track error;

    wiredAssetResult;

    @wire(getAssetDetails, { assetId: '$recordId' })
    wiredAsset(result) {
        this.wiredAssetResult = result;
        if (result.data) {
            this.assetData = result.data;
            this.error = undefined;
            this.processAssetInsights();
        } else if (result.error) {
            this.error = result.error;
            this.assetData = undefined;
            console.error('Asset 정보 로드 실패:', this.error);
        }
        this.isLoading = false;
    }

    // Asset Description에서 비즈니스 인사이트 추출 및 처리
    processAssetInsights() {
        if (!this.assetData?.Description) return;
        
        const description = this.assetData.Description;
        
        // Order Number 추출
        const orderMatch = description.match(/Order Number: (\d+)/);
        this.orderNumber = orderMatch ? orderMatch[1] : null;
        
        // 고객명 추출
        const customerMatch = description.match(/고객명: (.+)/);
        this.customerName = customerMatch ? customerMatch[1].trim() : this.assetData.Account?.Name;
        
        // 총 금액 추출
        const amountMatch = description.match(/총 금액: ([\d,]+)원/);
        this.totalAmount = amountMatch ? amountMatch[1] : null;
        
        // 납부 완료 정보 추출
        const paymentMatch = description.match(/납부 완료: (\d+)\/(\d+)차/);
        if (paymentMatch) {
            this.completedPayments = parseInt(paymentMatch[1]);
            this.totalPayments = parseInt(paymentMatch[2]);
            this.paymentProgress = `${this.completedPayments}/${this.totalPayments}`;
        }
        
        // 완납 금액 추출
        const paidMatch = description.match(/완납 금액: ([\d,]+)원/);
        this.paidAmount = paidMatch ? paidMatch[1] : null;
    }

    // Asset 정보 존재 여부
    get hasAssetData() {
        return this.assetData != null;
    }

    // 납부 현황 존재 여부
    get hasPaymentInfo() {
        return this.completedPayments != null && this.totalPayments != null;
    }

    // 납부 완료율 계산
    get paymentCompletionRate() {
        if (!this.hasPaymentInfo) return 0;
        return Math.round((this.completedPayments / this.totalPayments) * 100);
    }

    // 납부 상태 라벨
    get paymentStatusLabel() {
        if (!this.hasPaymentInfo) return '정보 없음';
        if (this.paymentCompletionRate === 100) return '완납';
        if (this.paymentCompletionRate >= 50) return '진행 중';
        return '시작 단계';
    }

    // 납부 상태 뱃지 변형
    get paymentStatusVariant() {
        if (this.paymentCompletionRate === 100) return 'success';
        if (this.paymentCompletionRate >= 50) return 'warning';
        return 'inverse';
    }

    // Asset 상태 한글 변환
    get assetStatusLabel() {
        if (!this.assetData?.Status) return '알 수 없음';
        
        const statusMap = {
            'Purchased': '구매됨',
            'Shipped': '배송됨',
            'Installed': '설치됨',
            'Registered': '등록됨',
            'Obsolete': '사용종료'
        };
        
        return statusMap[this.assetData.Status] || this.assetData.Status;
    }

    // Asset 상태 뱃지 변형
    get assetStatusVariant() {
        if (!this.assetData?.Status) return 'inverse';
        
        switch (this.assetData.Status.toLowerCase()) {
            case 'purchased':
                return 'success';
            case 'shipped':
                return 'warning';
            case 'installed':
                return 'success';
            case 'registered':
                return 'brand';
            case 'obsolete':
                return 'error';
            default:
                return 'inverse';
        }
    }

    // 현재 계약 금액 포맷팅
    get formattedPrice() {
        if (!this.assetData?.Price) return '₩0';
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(this.assetData.Price);
    }

    // 총 금액 포맷팅
    get formattedTotalAmount() {
        if (!this.totalAmount) return null;
        const amount = this.totalAmount.replace(/,/g, '');
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(parseInt(amount));
    }

    // 완납 금액 포맷팅
    get formattedPaidAmount() {
        if (!this.paidAmount) return null;
        const amount = this.paidAmount.replace(/,/g, '');
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(parseInt(amount));
    }

    // 구매일 포맷팅
    get formattedPurchaseDate() {
        if (!this.assetData?.PurchaseDate) return 'N/A';
        return new Date(this.assetData.PurchaseDate).toLocaleDateString('ko-KR');
    }

    // 설치일 포맷팅
    get formattedInstallDate() {
        if (!this.assetData?.InstallDate) return 'N/A';
        return new Date(this.assetData.InstallDate).toLocaleDateString('ko-KR');
    }

    // 라이프사이클 관리 상태
    get lifecycleStatus() {
        return this.assetData?.HasLifecycleManagement ? '활성' : '비활성';
    }

    // 제품 유형
    get productType() {
        return this.assetData?.IsCompetitorProduct ? '경쟁사 제품' : 'Tiger B2B 제품';
    }

    // Account 산업군
    get industryInfo() {
        return this.assetData?.Account?.Industry || '미분류';
    }

    // Account로 네비게이션
    navigateToAccount() {
        if (this.assetData?.AccountId) {
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

    // Order로 네비게이션 (Description에서 추출한 OrderNumber 사용)
    navigateToOrder() {
        if (this.assetData?.Order__c) {
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

    // 새로고침
    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredAssetResult)
            .then(() => {
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
