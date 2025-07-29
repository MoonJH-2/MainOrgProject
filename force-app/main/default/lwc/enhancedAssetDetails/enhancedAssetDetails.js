import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getAssetDetails from '@salesforce/apex/AssetManagementController.getAssetDetails';
import getCustomerAssets from '@salesforce/apex/AssetManagementController.getCustomerAssets';

/**
 * 향상된 Asset 상세 정보 컴포넌트
 * Assets에서 제품, 제품코드, 연락처->Account 필드를 참조하여 모든 데이터를 채움
 */
export default class EnhancedAssetDetails extends NavigationMixin(LightningElement) {
    @api recordId; // Asset ID
    @track assetDetails;
    @track relatedAssets = [];
    @track isLoading = true;
    @track error;
    @track activeTab = 'overview';

    wiredAssetResult;

    @wire(getAssetDetails, { assetId: '$recordId' })
    wiredAsset(result) {
        this.wiredAssetResult = result;
        if (result.data) {
            this.assetDetails = result.data;
            this.error = undefined;
            this.loadRelatedAssets();
        } else if (result.error) {
            this.error = result.error;
            this.assetDetails = undefined;
            console.error('Asset 정보 로드 실패:', this.error);
        }
        this.isLoading = false;
    }

    // 관련 Assets 로드 (같은 Account)
    loadRelatedAssets() {
        if (this.assetDetails?.AccountId) {
            getCustomerAssets({ accountId: this.assetDetails.AccountId })
                .then(result => {
                    // 현재 Asset 제외
                    this.relatedAssets = result.filter(asset => asset.Id !== this.recordId);
                })
                .catch(error => {
                    console.error('관련 Assets 로드 실패:', error);
                });
        }
    }

    // Asset 정보 존재 여부
    get hasAssetDetails() {
        return this.assetDetails != null;
    }

    // Product 정보 존재 여부
    get hasProductInfo() {
        return this.assetDetails?.Product2?.Name;
    }

    // Contact 정보 존재 여부  
    get hasContactInfo() {
        return this.assetDetails?.Contact?.Name;
    }

    // Account 정보 존재 여부
    get hasAccountInfo() {
        return this.assetDetails?.Account?.Name;
    }

    // Order 정보 존재 여부
    get hasOrderInfo() {
        return this.assetDetails?.Order__r?.OrderNumber;
    }

    // 관련 Assets 존재 여부
    get hasRelatedAssets() {
        return this.relatedAssets.length > 0;
    }

    // Asset 가격 포맷팅
    get formattedPrice() {
        if (!this.assetDetails?.Price) return '₩0';
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(this.assetDetails.Price);
    }

    // Product 단가 포맷팅
    get formattedProductPrice() {
        if (!this.assetDetails?.Product2?.UnitPrice) return '₩0';
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(this.assetDetails.Product2.UnitPrice);
    }

    // 구매일 포맷팅
    get formattedPurchaseDate() {
        if (!this.assetDetails?.PurchaseDate) return 'N/A';
        return new Date(this.assetDetails.PurchaseDate).toLocaleDateString('ko-KR');
    }

    // 설치일 포맷팅
    get formattedInstallDate() {
        if (!this.assetDetails?.InstallDate) return 'N/A';
        return new Date(this.assetDetails.InstallDate).toLocaleDateString('ko-KR');
    }

    // 라이프사이클 종료일 포맷팅
    get formattedLifecycleEndDate() {
        if (!this.assetDetails?.LifecycleEndDate) return 'N/A';
        return new Date(this.assetDetails.LifecycleEndDate).toLocaleDateString('ko-KR');
    }

    // Asset 상태 뱃지 변형
    get assetStatusVariant() {
        if (!this.assetDetails?.Status) return 'inverse';
        
        switch (this.assetDetails.Status.toLowerCase()) {
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

    // Asset 상태 한글 변환
    get assetStatusLabel() {
        if (!this.assetDetails?.Status) return '알 수 없음';
        
        const statusMap = {
            'Purchased': '구매됨',
            'Shipped': '배송됨',
            'Installed': '설치됨',  
            'Registered': '등록됨',
            'Obsolete': '사용종료'
        };
        
        return statusMap[this.assetDetails.Status] || this.assetDetails.Status;
    }

    // Product 코드 표시
    get productCode() {
        return this.assetDetails?.ProductCode || 'N/A';
    }

    // 제품 패밀리 표시
    get productFamily() {
        return this.assetDetails?.Product2?.Family || 'N/A';
    }

    // 총 수량 정보
    get quantityInfo() {
        const quantity = this.assetDetails?.Quantity || 0;
        const currentQuantity = this.assetDetails?.CurrentQuantity || 0;
        return `${currentQuantity} / ${quantity}`;
    }

    // Account 소유자 정보
    get accountOwnerInfo() {
        return this.assetDetails?.Account?.Owner?.Name || 'N/A';
    }

    // Contact 연락처 정보 배열
    get contactInfoList() {
        if (!this.hasContactInfo) return [];
        
        const contact = this.assetDetails.Contact;
        const info = [];
        
        if (contact.Email) {
            info.push({ label: '이메일', value: contact.Email, type: 'email' });
        }
        if (contact.Phone) {
            info.push({ label: '전화번호', value: contact.Phone, type: 'phone' });
        }
        if (contact.MobilePhone) {
            info.push({ label: '휴대전화', value: contact.MobilePhone, type: 'phone' });
        }
        if (contact.Department) {
            info.push({ label: '부서', value: contact.Department, type: 'text' });
        }
        
        return info;
    }

    // 탭 변경 핸들러
    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    // Product로 네비게이션
    navigateToProduct() {
        if (this.assetDetails?.Product2Id) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.assetDetails.Product2Id,
                    objectApiName: 'Product2',
                    actionName: 'view'
                }
            });
        }
    }

    // Contact로 네비게이션
    navigateToContact() {
        if (this.assetDetails?.ContactId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.assetDetails.ContactId,
                    objectApiName: 'Contact',
                    actionName: 'view'
                }
            });
        }
    }

    // Account로 네비게이션
    navigateToAccount() {
        if (this.assetDetails?.AccountId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.assetDetails.AccountId,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            });
        }
    }

    // Order로 네비게이션
    navigateToOrder() {
        if (this.assetDetails?.Order__c) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.assetDetails.Order__c,
                    objectApiName: 'Order',
                    actionName: 'view'
                }
            });
        }
    }

    // 관련 Asset으로 네비게이션
    navigateToAsset(event) {
        const assetId = event.target.dataset.assetId;
        if (assetId) {
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

    // 새로고침
    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredAssetResult)
            .then(() => {
                this.loadRelatedAssets();
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
