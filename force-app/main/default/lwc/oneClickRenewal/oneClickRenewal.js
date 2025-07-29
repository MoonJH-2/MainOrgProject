import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import startRenewalProcess from '@salesforce/apex/OneClickRenewalService.startRenewalProcess';
import getRenewableAssets from '@salesforce/apex/OneClickRenewalService.getRenewableAssets';
import processBulkRenewals from '@salesforce/apex/OneClickRenewalService.processBulkRenewals';

/**
 * 로직 2: 원클릭 갱신 워크플로우 컴포넌트
 * 복잡한 갱신 프로세스를 버튼 하나로 완료
 */
export default class OneClickRenewal extends NavigationMixin(LightningElement) {
    @api title = '원클릭 갱신 워크플로우';
    @api maxAssets = 10;
    @api showBulkActions = false;
    
    @track renewableAssets = [];
    @track isLoading = false;
    @track error = null;
    @track selectedAssetIds = [];
    @track processingAssetId = null;
    @track bulkProcessing = false;
    
    // 와이어드 메서드로 갱신 가능한 Assets 조회
    wiredAssetsResult;
    @wire(getRenewableAssets, { ownerId: null })
    wiredRenewableAssets(result) {
        this.wiredAssetsResult = result;
        if (result.data) {
            this.renewableAssets = result.data.slice(0, this.maxAssets);
            this.error = null;
        } else if (result.error) {
            this.error = result.error;
            this.renewableAssets = [];
        }
    }
    
    // 컴포넌트 초기화
    connectedCallback() {
        console.log('OneClickRenewal 컴포넌트 초기화');
    }
    
    /**
     * 개별 Asset 갱신 처리
     */
    async handleRenewalClick(event) {
        const assetId = event.target.dataset.assetId;
        const assetName = event.target.dataset.assetName;
        
        if (!assetId) {
            this.showToast('오류', 'Asset ID를 찾을 수 없습니다.', 'error');
            return;
        }
        
        this.processingAssetId = assetId;
        this.isLoading = true;
        
        try {
            console.log('갱신 프로세스 시작:', assetName);
            
            const result = await startRenewalProcess({ assetId: assetId });
            
            if (result.success) {
                this.showToast(
                    '갱신 시작 완료!', 
                    `${result.opportunityName}이 생성되었습니다. (예상 매출: ₩${this.formatCurrency(result.expectedRevenue)})`, 
                    'success'
                );
                
                // 생성된 Opportunity로 이동
                this.navigateToOpportunity(result.opportunityId);
                
                // 데이터 새로고침
                await this.refreshData();
                
            } else {
                this.showToast('갱신 실패', result.message, 'error');
            }
            
        } catch (error) {
            console.error('갱신 프로세스 오류:', error);
            this.showToast('오류', error.body?.message || '갱신 처리 중 오류가 발생했습니다.', 'error');
        } finally {
            this.processingAssetId = null;
            this.isLoading = false;
        }
    }
    
    /**
     * 대량 갱신 처리
     */
    async handleBulkRenewal() {
        if (this.selectedAssetIds.length === 0) {
            this.showToast('선택 필요', '갱신할 Asset을 선택해주세요.', 'warning');
            return;
        }
        
        this.bulkProcessing = true;
        this.isLoading = true;
        
        try {
            console.log('대량 갱신 시작:', this.selectedAssetIds.length + '개');
            
            const results = await processBulkRenewals({ assetIds: this.selectedAssetIds });
            
            const successCount = results.filter(r => r.success).length;
            const failCount = results.length - successCount;
            
            if (successCount > 0) {
                this.showToast(
                    '대량 갱신 완료', 
                    `성공: ${successCount}건, 실패: ${failCount}건`, 
                    successCount === results.length ? 'success' : 'warning'
                );
            }
            
            // 실패한 항목들 상세 로그
            const failures = results.filter(r => !r.success);
            if (failures.length > 0) {
                failures.forEach(failure => {
                    console.error('갱신 실패:', failure.message);
                });
            }
            
            // 선택 해제 및 데이터 새로고침
            this.selectedAssetIds = [];
            await this.refreshData();
            
        } catch (error) {
            console.error('대량 갱신 오류:', error);
            this.showToast('오류', '대량 갱신 중 오류가 발생했습니다.', 'error');
        } finally {
            this.bulkProcessing = false;
            this.isLoading = false;
        }
    }
    
    /**
     * Asset 선택/해제 처리
     */
    handleAssetSelection(event) {
        const assetId = event.target.dataset.assetId;
        const isChecked = event.target.checked;
        
        if (isChecked) {
            if (!this.selectedAssetIds.includes(assetId)) {
                this.selectedAssetIds = [...this.selectedAssetIds, assetId];
            }
        } else {
            this.selectedAssetIds = this.selectedAssetIds.filter(id => id !== assetId);
        }
        
        console.log('선택된 Assets:', this.selectedAssetIds.length + '개');
    }
    
    /**
     * 전체 선택/해제
     */
    handleSelectAll(event) {
        const isChecked = event.target.checked;
        
        if (isChecked) {
            this.selectedAssetIds = this.renewableAssets.map(asset => asset.Id);
        } else {
            this.selectedAssetIds = [];
        }
        
        // 체크박스 상태 업데이트
        const checkboxes = this.template.querySelectorAll('input[type="checkbox"][data-asset-id]');
        checkboxes.forEach(checkbox => {
            checkbox.checked = isChecked;
        });
    }
    
    /**
     * 데이터 새로고침
     */
    async refreshData() {
        try {
            await refreshApex(this.wiredAssetsResult);
        } catch (error) {
            console.error('데이터 새로고침 오류:', error);
        }
    }
    
    /**
     * Opportunity로 네비게이션
     */
    navigateToOpportunity(opportunityId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: opportunityId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }
    
    /**
     * Account로 네비게이션
     */
    navigateToAccount(event) {
        const accountId = event.target.dataset.accountId;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }
    
    /**
     * Asset으로 네비게이션
     */
    navigateToAsset(event) {
        const assetId = event.target.dataset.assetId;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: assetId,
                objectApiName: 'Asset',
                actionName: 'view'
            }
        });
    }
    
    /**
     * Toast 메시지 표시
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'pester'
        });
        this.dispatchEvent(event);
    }
    
    /**
     * 통화 포맷팅
     */
    formatCurrency(amount) {
        if (!amount) return '0';
        return new Intl.NumberFormat('ko-KR').format(amount);
    }
    
    /**
     * 날짜 포맷팅
     */
    formatDate(dateString) {
        if (!dateString) return '-';
        const date = new Date(dateString);
        return date.toLocaleDateString('ko-KR');
    }
    
    /**
     * 갱신 임박도 계산 (일수)
     */
    getDaysFromInstall(installDate) {
        if (!installDate) return 0;
        const install = new Date(installDate);
        const today = new Date();
        const diffTime = today - install;
        return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    }
    
    /**
     * 갱신 긴급도 계산
     */
    getRenewalUrgency(installDate) {
        const days = this.getDaysFromInstall(installDate);
        
        if (days >= 330) {
            return { level: '갱신 적기', color: 'slds-theme_error', icon: 'utility:priority' };
        } else if (days >= 300) {
            return { level: '갱신 예정', color: 'slds-theme_warning', icon: 'utility:clock' };
        } else if (days >= 270) {
            return { level: '갱신 대기', color: 'slds-theme_info', icon: 'utility:info' };
        } else {
            return { level: '갱신 시기 아님', color: 'slds-theme_neutral', icon: 'utility:dash' };
        }
    }
    
    // Getter 메서드들
    get hasAssets() {
        return this.renewableAssets && this.renewableAssets.length > 0;
    }
    
    get hasSelectedAssets() {
        return this.selectedAssetIds.length > 0;
    }
    
    get selectedCount() {
        return this.selectedAssetIds.length;
    }
    
    get cardTitle() {
        return this.title || '원클릭 갱신 워크플로우';
    }
    
    get loadingMessage() {
        if (this.bulkProcessing) {
            return `${this.selectedCount}개 Asset 대량 갱신 처리 중...`;
        } else if (this.processingAssetId) {
            return '갱신 프로세스 실행 중...';
        } else {
            return '데이터 로딩 중...';
        }
    }
    
    get bulkActionLabel() {
        return `선택된 ${this.selectedCount}개 Asset 갱신 시작`;
    }
}
