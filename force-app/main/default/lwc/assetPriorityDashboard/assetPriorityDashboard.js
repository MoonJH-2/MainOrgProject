import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import calculatePriorities from '@salesforce/apex/AssetPriorityCalculator.calculatePriorities';

/**
 * 로직 1: Assets 우선순위 표시 컴포넌트
 * 영업사원을 위한 스마트한 고객 우선순위 자동 분류 UI
 */
export default class AssetPriorityDashboard extends NavigationMixin(LightningElement) {
    @api title = 'Assets 우선순위'; // 메타데이터에서 받는 제목
    @api showTopN = 5; // 메타데이터에서 받는 표시 수
    
    @track priorities = [];
    @track isLoading = false;
    @track error = null;
    @track summary = '';
    @track totalExpectedRevenue = 0;
    @track urgentCount = 0;
    @track importantCount = 0;
    @track normalCount = 0;
    @track showAll = false;

    // 컴포넌트 초기화 시 TOP 5 자동 로드
    connectedCallback() {
        this.loadTop5Priorities();
    }

    /**
     * 설정된 수만큼 우선순위 로드
     */
    loadTop5Priorities() {
        this.isLoading = true;
        this.error = null;
        
        calculatePriorities({ salesRepId: null, topN: this.showTopN })
            .then(result => {
                this.processPriorityResult(result);
                console.log('우선순위 로드 성공:', result);
            })
            .catch(error => {
                this.handleError('우선순위 조회 실패', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * 전체 우선순위 로드 (더 보기)
     */
    loadAllPriorities() {
        this.isLoading = true;
        this.error = null;
        
        calculatePriorities({ salesRepId: null, topN: 20 })
            .then(result => {
                this.processPriorityResult(result);
                this.showAll = true;
                console.log('전체 우선순위 로드 성공:', result);
            })
            .catch(error => {
                this.handleError('전체 조회 실패', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * 우선순위 결과 처리
     */
    processPriorityResult(result) {
        if (result && result.priorities) {
            this.priorities = result.priorities.map(priority => {
                return {
                    ...priority,
                    // UI 표시용 추가 필드
                    accountName: priority.asset.Account?.Name || 'Unknown',
                    assetName: priority.asset.Name || 'Unknown Asset',
                    phoneNumber: priority.asset.Account?.Phone || 'N/A',
                    formattedPrice: priority.asset.Price ? 
                        '₩' + this.formatNumber(priority.asset.Price) : 'N/A',
                    formattedExpectedRevenue: '₩' + this.formatNumber(priority.expectedRevenue),
                    scoreFormatted: priority.score.toFixed(0) + '점',
                    urgencyIcon: this.getUrgencyIcon(priority.score),
                    urgencyClass: this.getUrgencyClass(priority.score),
                    contactInfo: this.getContactInfo(priority.asset),
                    // 액션 버튼 표시용
                    showCreateOpportunity: priority.score >= 60 // 60점 이상만 갱신 버튼 표시
                };
            });

            this.summary = result.summary || '';
            this.totalExpectedRevenue = result.totalExpectedRevenue || 0;
            this.urgentCount = result.urgentCount || 0;
            this.importantCount = result.importantCount || 0;
            this.normalCount = result.normalCount || 0;
        } else {
            this.priorities = [];
            this.summary = '조회된 우선순위가 없습니다.';
        }
    }

    /**
     * 오류 처리
     */
    handleError(title, error) {
        console.error(title + ':', error);
        this.error = error.body?.message || error.message || '알 수 없는 오류가 발생했습니다.';
        
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: this.error,
            variant: 'error'
        }));
    }

    /**
     * 긴급도 아이콘 반환
     */
    getUrgencyIcon(score) {
        if (score >= 80) return '🔥';
        if (score >= 60) return '⚠️';
        if (score >= 40) return '📋';
        return '📝';
    }

    /**
     * 긴급도 CSS 클래스 반환
     */
    getUrgencyClass(score) {
        if (score >= 80) return 'slds-theme_error';
        if (score >= 60) return 'slds-theme_warning';
        if (score >= 40) return 'slds-theme_success';
        return 'slds-theme_neutral';
    }

    /**
     * 연락처 정보 포맷팅
     */
    getContactInfo(asset) {
        const contact = asset.Contact?.Name || '';
        const phone = asset.Account?.Phone || '';
        
        if (contact && phone) {
            return `${contact} (${phone})`;
        } else if (phone) {
            return phone;
        } else if (contact) {
            return contact;
        }
        return '연락처 없음';
    }

    /**
     * 숫자 포맷팅 (천 단위 콤마)
     */
    formatNumber(number) {
        if (!number) return '0';
        return new Intl.NumberFormat('ko-KR').format(number);
    }

    /**
     * Account 페이지로 이동
     */
    handleAccountClick(event) {
        const accountId = event.currentTarget.dataset.accountId;
        
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
     * Asset 페이지로 이동
     */
    handleAssetClick(event) {
        const assetId = event.currentTarget.dataset.assetId;
        
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
     * 갱신 Opportunity 생성 (로직 2에서 구현 예정)
     */
    handleCreateRenewal(event) {
        const assetId = event.currentTarget.dataset.assetId;
        const accountName = event.currentTarget.dataset.accountName;
        
        // 임시 토스트 메시지 (로직 2에서 실제 구현)
        this.dispatchEvent(new ShowToastEvent({
            title: '갱신 프로세스',
            message: `${accountName}의 갱신 프로세스를 시작합니다. (로직 2에서 구현 예정)`,
            variant: 'info'
        }));
        
        console.log('갱신 요청:', { assetId, accountName });
    }

    /**
     * 전화 걸기
     */
    handleCallCustomer(event) {
        const phoneNumber = event.currentTarget.dataset.phone;
        const accountName = event.currentTarget.dataset.accountName;
        
        if (phoneNumber && phoneNumber !== 'N/A') {
            // 전화 앱 열기 (모바일에서 동작)
            const telLink = `tel:${phoneNumber}`;
            window.open(telLink);
            
            this.dispatchEvent(new ShowToastEvent({
                title: '전화 연결',
                message: `${accountName}에게 전화를 겁니다: ${phoneNumber}`,
                variant: 'success'
            }));
        } else {
            this.dispatchEvent(new ShowToastEvent({
                title: '전화번호 없음',
                message: `${accountName}의 전화번호가 등록되지 않았습니다.`,
                variant: 'warning'
            }));
        }
    }

    /**
     * 새로고침
     */
    handleRefresh() {
        if (this.showAll) {
            this.loadAllPriorities();
        } else {
            this.loadTop5Priorities();
        }
    }

    /**
     * 더 보기/간단히 보기 토글
     */
    handleToggleView() {
        if (this.showAll) {
            this.showAll = false;
            this.loadTop5Priorities();
        } else {
            this.loadAllPriorities();
        }
    }

    // Getter 메서드들
    get hasData() {
        return this.priorities && this.priorities.length > 0;
    }

    get formattedTotalRevenue() {
        return '₩' + this.formatNumber(this.totalExpectedRevenue);
    }

    get viewButtonLabel() {
        return this.showAll ? '간단히 보기' : '더 보기';
    }

    get cardTitle() {
        return this.title || (this.showAll ? '전체 우선순위 고객' : 'TOP 5 우선순위 고객');
    }

    get statisticsClass() {
        return this.hasData ? 'statistics-visible' : 'statistics-hidden';
    }
}
