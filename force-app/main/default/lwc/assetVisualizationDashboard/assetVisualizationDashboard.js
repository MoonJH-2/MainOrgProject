import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getAssetDetails from '@salesforce/apex/AssetManagementController.getAssetDetails';
import getCustomerAssets from '@salesforce/apex/AssetManagementController.getCustomerAssets';

/**
 * 차트와 표를 활용한 Asset 시각화 컴포넌트
 */
export default class AssetVisualizationDashboard extends NavigationMixin(LightningElement) {
    @api recordId; // Asset ID
    @track assetData;
    @track customerAssets = [];
    @track isLoading = true;
    @track error;
    @track activeTab = 'overview';

    wiredAssetResult;

    @wire(getAssetDetails, { assetId: '$recordId' })
    wiredAsset(result) {
        this.wiredAssetResult = result;
        if (result.data) {
            this.assetData = result.data;
            this.error = undefined;
            this.loadCustomerAssets();
            this.processAssetData();
        } else if (result.error) {
            this.error = result.error;
            this.assetData = undefined;
            console.error('Asset 정보 로드 실패:', this.error);
        }
        this.isLoading = false;
    }

    // 고객의 모든 Assets 로드
    loadCustomerAssets() {
        if (this.assetData?.AccountId) {
            getCustomerAssets({ accountId: this.assetData.AccountId })
                .then(result => {
                    this.customerAssets = result;
                    this.generateChartData();
                })
                .catch(error => {
                    console.error('고객 Assets 로드 실패:', error);
                });
        }
    }

    // Asset Description 데이터 처리
    processAssetData() {
        if (!this.assetData?.Description) return;
        
        const description = this.assetData.Description;
        
        // 납부 내역 추출
        const paymentPattern = /(\w+)차: ([\d,]+)원 \((\w+)\) - 납부일: (\d{1,2}\/\d{1,2}\/\d{4})/g;
        this.paymentHistory = [];
        let match;
        
        while ((match = paymentPattern.exec(description)) !== null) {
            this.paymentHistory.push({
                installment: match[1],
                amount: match[2].replace(/,/g, ''),
                status: match[3],
                paidDate: match[4]
            });
        }
        
        // Account 정보 추출
        const orderMatch = description.match(/Order Number: (\d+)/);
        this.orderNumber = orderMatch ? orderMatch[1] : null;
        
        const totalMatch = description.match(/총 금액: ([\d,]+)원/);
        this.totalAmount = totalMatch ? totalMatch[1].replace(/,/g, '') : 0;
        
        const paymentSummaryMatch = description.match(/납부 완료: (\d+)\/(\d+)차/);
        if (paymentSummaryMatch) {
            this.completedPayments = parseInt(paymentSummaryMatch[1]);
            this.totalPayments = parseInt(paymentSummaryMatch[2]);
        }
    }

    // 차트 데이터 생성
    generateChartData() {
        // 납부 상태 파이 차트 데이터
        this.paymentStatusChartData = {
            labels: ['완납', '미납'],
            datasets: [{
                data: [this.completedPayments || 0, (this.totalPayments || 0) - (this.completedPayments || 0)],
                backgroundColor: ['#4bca81', '#ea001e'],
                borderWidth: 2,
                borderColor: '#ffffff'
            }]
        };

        // 고객 Assets 가치 차트 데이터
        if (this.customerAssets.length > 0) {
            this.assetValueChartData = {
                labels: this.customerAssets.map(asset => asset.Name.substring(0, 20) + '...'),
                datasets: [{
                    label: 'Asset 가치 (₩)',
                    data: this.customerAssets.map(asset => asset.Price || 0),
                    backgroundColor: ['#1b96ff', '#667eea', '#764ba2', '#f093fb', '#f5576c'],
                    borderWidth: 2,
                    borderColor: '#ffffff'
                }]
            };
        }

        // 월별 납부 트렌드 (가상 데이터 - 실제로는 PaymentStatus에서 가져와야 함)
        this.paymentTrendData = {
            labels: ['1월', '2월', '3월', '4월', '5월', '6월'],
            datasets: [{
                label: '월별 납부액 (₩)',
                data: this.generateTrendData(),
                borderColor: '#1b96ff',
                backgroundColor: 'rgba(27, 150, 255, 0.1)',
                borderWidth: 3,
                fill: true,
                tension: 0.4
            }]
        };
    }

    // 트렌드 데이터 생성 (실제로는 PaymentStatus 기반으로 계산)
    generateTrendData() {
        if (!this.paymentHistory || this.paymentHistory.length === 0) {
            return [0, 0, 0, 0, 0, 0];
        }
        
        // 월별로 납부액 집계
        const monthlyData = new Array(6).fill(0);
        this.paymentHistory.forEach(payment => {
            const month = new Date(payment.paidDate).getMonth();
            if (month < 6) {
                monthlyData[month] += parseInt(payment.amount);
            }
        });
        
        return monthlyData;
    }

    // 데이터 존재 여부 확인
    get hasAssetData() {
        return this.assetData != null;
    }

    get hasPaymentHistory() {
        return this.paymentHistory && this.paymentHistory.length > 0;
    }

    get hasCustomerAssets() {
        return this.customerAssets.length > 1; // 현재 Asset 포함하여 2개 이상
    }

    // 납부 완료율
    get paymentCompletionRate() {
        if (!this.totalPayments) return 0;
        return Math.round((this.completedPayments / this.totalPayments) * 100);
    }

    // 미납 건수
    get pendingPayments() {
        return (this.totalPayments || 0) - (this.completedPayments || 0);
    }

    // 미납 비율
    get pendingPaymentRate() {
        return 100 - this.paymentCompletionRate;
    }

    // 포맷팅된 총액
    get formattedTotalAmount() {
        if (!this.totalAmount) return '₩0';
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(parseInt(this.totalAmount));
    }

    // 완납된 총액
    get formattedPaidAmount() {
        if (!this.hasPaymentHistory) return '₩0';
        
        const paidAmount = this.paymentHistory
            .filter(payment => payment.status === '완납')
            .reduce((sum, payment) => sum + parseInt(payment.amount), 0);
            
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(paidAmount);
    }

    // 납부 내역 테이블 데이터
    get paymentTableData() {
        if (!this.hasPaymentHistory) return [];
        
        return this.paymentHistory.map(payment => ({
            ...payment,
            formattedAmount: new Intl.NumberFormat('ko-KR', {
                style: 'currency',
                currency: 'KRW',
                minimumFractionDigits: 0
            }).format(parseInt(payment.amount)),
            statusVariant: payment.status === '완납' ? 'success' : 'error'
        }));
    }

    // 고객 Assets 테이블 데이터
    get assetTableData() {
        return this.customerAssets.map(asset => ({
            ...asset,
            formattedPrice: new Intl.NumberFormat('ko-KR', {
                style: 'currency',
                currency: 'KRW',
                minimumFractionDigits: 0
            }).format(asset.Price || 0),
            formattedInstallDate: asset.InstallDate ? 
                new Date(asset.InstallDate).toLocaleDateString('ko-KR') : 'N/A',
            statusVariant: this.getAssetStatusVariant(asset.Status),
            isCurrentAsset: asset.Id === this.recordId
        }));
    }

    // Asset 상태 뱃지 변형
    getAssetStatusVariant(status) {
        if (!status) return 'inverse';
        
        switch (status.toLowerCase()) {
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

    // 탭 변경 핸들러
    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    // Asset으로 네비게이션
    navigateToAsset(event) {
        const assetId = event.target.dataset.assetId;
        if (assetId && assetId !== this.recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: assetId,
                    objectApiName: 'Asset',
                    actionName: 'view'
                }
            });
        }
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

    // 새로고침
    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredAssetResult)
            .then(() => {
                this.loadCustomerAssets();
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
