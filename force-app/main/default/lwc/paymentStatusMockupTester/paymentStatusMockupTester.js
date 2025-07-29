import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMockupPaymentStatus from '@salesforce/apex/PaymentStatusMockupController.getMockupPaymentStatus';

/**
 * PaymentStatus 테스트를 위한 Mockup 컨트롤 컴포넌트
 * 다양한 납부 상태 시나리오를 실시간으로 테스트할 수 있음
 */
export default class PaymentStatusMockupTester extends LightningElement {
    @api recordId; // Order Id
    @track currentScenario = 'completed';
    @track mockupData;
    @track isLoading = false;

    // 시나리오 옵션
    scenarioOptions = [
        { label: '✅ 완납 (4/4)', value: 'completed' },
        { label: '🔄 부분납부 (2/4)', value: 'partial' },
        { label: '⚠️ 연체 있음 (1완납+2연체+1미납)', value: 'overdue' },
        { label: '🔀 혼합 상태 (2완납+1연체+1미납)', value: 'mixed' },
        { label: '📋 진행 중 (1/4)', value: 'progress' }
    ];

    // 시나리오 변경 핸들러
    handleScenarioChange(event) {
        this.currentScenario = event.detail.value;
        this.loadMockupData();
    }

    // Mockup 데이터 로드
    async loadMockupData() {
        this.isLoading = true;
        try {
            const result = await getMockupPaymentStatus({
                orderId: this.recordId,
                scenario: this.currentScenario
            });
            
            this.mockupData = result;
            this.showToast('성공', `${this.getScenarioLabel()} 시나리오가 적용되었습니다.`, 'success');
            
            // 부모 컴포넌트에 이벤트 발송 (실제 컴포넌트 업데이트)
            this.dispatchEvent(new CustomEvent('mockupdatachange', {
                detail: {
                    scenario: this.currentScenario,
                    mockupData: result
                }
            }));
            
        } catch (error) {
            this.showToast('오류', error.body?.message || 'Mockup 데이터 로드 중 오류가 발생했습니다.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // 현재 시나리오 라벨 가져오기
    getScenarioLabel() {
        const option = this.scenarioOptions.find(opt => opt.value === this.currentScenario);
        return option ? option.label : this.currentScenario;
    }

    // 컴포넌트 초기화
    connectedCallback() {
        if (this.recordId) {
            this.loadMockupData();
        }
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

    // 실제 데이터로 복원
    handleRestoreRealData() {
        this.dispatchEvent(new CustomEvent('restorerealdata'));
        this.showToast('복원', '실제 PaymentStatus 데이터로 복원되었습니다.', 'info');
    }

    // Mockup 데이터 새로고침
    handleRefreshMockup() {
        this.loadMockupData();
    }
}
