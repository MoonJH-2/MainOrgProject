import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getOrderAssetInfo from '@salesforce/apex/OrderAssetNavigatorController.getOrderAssetInfo';
import createAssetFromOrder from '@salesforce/apex/OrderAssetNavigatorController.createAssetFromOrder';

/**
 * Order 화면에서 연결된 Asset으로 네비게이션하는 컴포넌트
 * 모든 납부가 완료된 Order에 대해 생성된 Asset 정보를 표시하고 이동 기능 제공
 */
export default class OrderAssetNavigator extends NavigationMixin(LightningElement) {
    @api recordId; // Order Id
    @track assetInfo;
    @track orderInfo;
    @track paymentSummary;
    @track isLoading = true;
    @track error;

    wiredResult;

    @wire(getOrderAssetInfo, { orderId: '$recordId' })
    wiredOrderAsset(result) {
        this.wiredResult = result;
        this.isLoading = true;
        
        if (result.data) {
            try {
                // 데이터 유효성 검증
                const data = result.data;
                this.assetInfo = data.assetInfo || null;
                this.orderInfo = data.orderInfo || null;
                this.paymentSummary = data.paymentSummary || {
                    completedPayments: 0,
                    remainingPayments: 0,
                    totalPayments: 0,
                    totalAmount: 0,
                    isFullyPaid: false
                };
                this.error = undefined;
                console.log('Asset 데이터 로드:', { 
                    assetInfo: this.assetInfo, 
                    orderInfo: this.orderInfo,
                    paymentSummary: this.paymentSummary 
                });
            } catch (dataError) {
                console.error('데이터 처리 오류:', dataError);
                this.error = { message: '데이터 처리 중 오류가 발생했습니다.' };
                this.assetInfo = null;
                this.orderInfo = null;
                this.paymentSummary = null;
            }
        } else if (result.error) {
            console.error('API 호출 오류:', result.error);
            this.error = result.error;
            this.assetInfo = null;
            this.orderInfo = null;
            this.paymentSummary = null;
        }
        this.isLoading = false;
    }

    // Asset이 존재하는지 확인
    get hasAsset() {
        return this.assetInfo?.Id;
    }

    // 모든 납부가 완료되었는지 확인
    get isFullyPaid() {
        return this.paymentSummary?.isFullyPaid || false;
    }

    // Asset 생성 가능 상태인지 확인 (완납했지만 Asset이 없는 경우)
    get canCreateAsset() {
        return this.isFullyPaid && !this.hasAsset;
    }

    // 안전한 납부 통계 접근
    get safeCompletedPayments() {
        return this.paymentSummary?.completedPayments || 0;
    }

    get safeRemainingPayments() {
        return this.paymentSummary?.remainingPayments || 0;
    }

    get safeTotalPayments() {
        return this.paymentSummary?.totalPayments || 0;
    }

    // 납부 완료율 계산
    get paymentProgress() {
        if (!this.paymentSummary) return 0;
        const total = this.paymentSummary.totalPayments || 0;
        const completed = this.paymentSummary.completedPayments || 0;
        return total > 0 ? Math.round((completed / total) * 100) : 0;
    }

    // 진행률에 따른 스타일 클래스
    get progressBarClass() {
        const progress = this.paymentProgress;
        if (progress === 100) return 'progress-complete';
        if (progress >= 75) return 'progress-good';
        if (progress >= 50) return 'progress-medium';
        return 'progress-low';
    }

    // Asset 상태 뱃지 스타일
    get assetStatusVariant() {
        if (!this.hasAsset) return 'warning';
        return this.assetInfo?.Status__c === 'Active' ? 'success' : 'inverse';
    }

    // Asset 카드 표시 여부
    get showAssetCard() {
        return this.hasAsset || this.canCreateAsset;
    }

    // 완납 상태 메시지
    get paymentStatusMessage() {
        if (this.isFullyPaid) {
            return this.hasAsset ? 
                '✅ 모든 납부가 완료되어 Asset이 생성되었습니다.' : 
                '⏳ 모든 납부가 완료되었습니다. Asset 생성 중...';
        } else {
            const remaining = this.safeRemainingPayments;
            return `📋 ${remaining}개의 납부가 남아있습니다.`;
        }
    }

    // Asset으로 네비게이션
    handleNavigateToAsset() {
        if (!this.hasAsset) {
            this.showToast('알림', 'Asset이 아직 생성되지 않았습니다.', 'warning');
            return;
        }

        console.log('Asset 네비게이션:', this.assetInfo.Id);
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.assetInfo.Id,
                objectApiName: 'Asset',
                actionName: 'view'
            }
        }).catch(error => {
            console.error('Asset 네비게이션 오류:', error);
            this.showToast('오류', 'Asset 페이지로 이동할 수 없습니다.', 'error');
        });
    }

    // Asset 목록 페이지로 이동 (Account의 모든 Asset 보기)
    handleViewAllAssets() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Asset',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }

    // Asset 관련 Task 보기
    handleViewAssetTasks() {
        if (!this.hasAsset) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Task',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }

    // 수동 Asset 생성 요청
    async handleCreateAsset() {
        if (!this.canCreateAsset) return;

        this.isLoading = true;
        try {
            // AccountBasedAssetService를 통한 Asset 생성 호출
            const result = await createAssetFromOrder({ orderId: this.recordId });
            
            if (result.success) {
                this.showToast('성공', 'Asset이 성공적으로 생성되었습니다.', 'success');
                
                // 데이터 새로고침
                await refreshApex(this.wiredResult);
                
                // 생성된 Asset으로 이동
                if (result.assetId) {
                    this.navigateToAsset(result.assetId);
                }
            } else {
                this.showToast('오류', result.message || 'Asset 생성 중 오류가 발생했습니다.', 'error');
            }
        } catch (error) {
            this.showToast('오류', error.body?.message || 'Asset 생성 중 오류가 발생했습니다.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // 특정 Asset ID로 네비게이션
    navigateToAsset(assetId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: assetId,
                objectApiName: 'Asset',
                actionName: 'view'
            }
        });
    }

    // 데이터 새로고침
    async handleRefresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredResult);
            this.showToast('성공', '데이터가 새로고침되었습니다.', 'success');
        } catch (error) {
            console.error('데이터 새로고침 오류:', error);
            this.showToast('오류', `데이터 새로고침 중 오류가 발생했습니다: ${error.message || '알 수 없는 오류'}`, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // 통화 포맷
    formatCurrency(amount) {
        if (!amount) return '₩0';
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW'
        }).format(amount);
    }

    // 날짜 포맷
    formatDate(dateString) {
        if (!dateString) return '';
        return new Date(dateString).toLocaleDateString('ko-KR');
    }

    // 포맷된 총 금액 getter
    get formattedTotalAmount() {
        const amount = this.paymentSummary?.totalAmount;
        if (amount === null || amount === undefined || isNaN(amount)) {
            return '₩0';
        }
        return this.formatCurrency(amount);
    }

    // 포맷된 구매일 getter
    get formattedPurchaseDate() {
        return this.assetInfo?.PurchaseDate ? this.formatDate(this.assetInfo.PurchaseDate) : '미정';
    }

    // 포맷된 설치일 getter
    get formattedInstallDate() {
        return this.assetInfo?.InstallDate ? this.formatDate(this.assetInfo.InstallDate) : '미정';
    }

    // OrderItem 정보 getter
    get orderItem() {
        return this.orderInfo?.OrderItems?.length > 0 ? this.orderInfo.OrderItems[0] : null;
    }

    // 제품명 getter
    get productName() {
        return this.orderItem?.Product2?.Name || '제품 정보 없음';
    }

    // 포맷된 제품 단가 getter
    get formattedUnitPrice() {
        const unitPrice = this.orderItem?.UnitPrice;
        return unitPrice ? this.formatCurrency(unitPrice) : '₩0';
    }

    // 포맷된 제품 총액 getter
    get formattedProductTotalPrice() {
        const totalPrice = this.orderItem?.TotalPrice;
        return totalPrice ? this.formatCurrency(totalPrice) : '₩0';
    }

    // 수량 getter
    get productQuantity() {
        return this.orderItem?.Quantity || 0;
    }

    // 토스트 메시지
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}
