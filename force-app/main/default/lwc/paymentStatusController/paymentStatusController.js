import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPaymentStatusDetails from '@salesforce/apex/CustomerPaymentManagerController.getPaymentStatusDetails';
import updatePaymentStatus from '@salesforce/apex/CustomerPaymentManagerController.updatePaymentStatus';
import updatePaymentMethod from '@salesforce/apex/CustomerPaymentManagerController.updatePaymentMethod';
import markAllPaymentsAsCompleted from '@salesforce/apex/CustomerPaymentManagerController.markAllPaymentsAsCompleted';
import createPaymentStatusManually from '@salesforce/apex/PaymentScheduleService.createPaymentStatusManually';

export default class PaymentStatusController extends LightningElement {
    @api recordId; // Order ID
    @track paymentDetails = null;
    @track isLoading = false;
    @track showEditModal = false;
    @track selectedPayment = null;
    @track newStatus = '';
    @track newPaidDate = '';
    @track showPaymentMethodModal = false;
    @track selectedPaymentMethod = '';

    // Payment Method 옵션
    get paymentMethodOptions() {
        return [
            { label: '월별 (12회)', value: '월별' },
            { label: '분기별 (4회)', value: '분기별' },
            { label: '반기별 (2회)', value: '반기별' },
            { label: '년별 (1회)', value: '년별' }
        ];
    }

    // 납부 상태 옵션
    get statusOptions() {
        return [
            { label: '미납', value: '미납' },
            { label: '완납', value: '완납' },
            { label: '연체', value: '연체' }
        ];
    }

    connectedCallback() {
        this.loadPaymentDetails();
    }

    // PaymentStatus 상세 정보 로드
    async loadPaymentDetails() {
        this.isLoading = true;
        try {
            const result = await getPaymentStatusDetails({ orderId: this.recordId });
            this.paymentDetails = result;
            
            // 현재 Payment Method 설정
            this.selectedPaymentMethod = result.orderInfo?.Payment_Method__c || '분기별';
            
        } catch (error) {
            console.error('Error loading payment details:', error);
            this.showToast('오류', 'PaymentStatus 정보를 불러오는 중 오류가 발생했습니다.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // 개별 납부 상태 편집
    handleEditPayment(event) {
        const paymentId = event.currentTarget.dataset.paymentId;
        this.selectedPayment = this.paymentDetails.paymentList.find(p => p.Id === paymentId);
        this.newStatus = this.selectedPayment.Status__c || '미납';
        this.newPaidDate = this.selectedPayment.PaidDate__c || '';
        this.showEditModal = true;
    }

    // 납부 상태 업데이트
    async handleUpdatePaymentStatus() {
        this.isLoading = true;
        try {
            const result = await updatePaymentStatus({
                paymentId: this.selectedPayment.Id,
                newStatus: this.newStatus,
                paidDate: this.newStatus === '완납' ? (this.newPaidDate || new Date().toISOString().split('T')[0]) : null,
                notes: ''
            });

            this.showToast('성공', result, 'success');
            this.closeEditModal();
            await this.loadPaymentDetails(); // 데이터 새로고침
            
        } catch (error) {
            console.error('Error updating payment status:', error);
            this.showToast('오류', error.body?.message || '납부 상태 업데이트에 실패했습니다.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Payment Method 변경
    async handleUpdatePaymentMethod() {
        this.isLoading = true;
        try {
            const result = await updatePaymentMethod({
                orderId: this.recordId,
                newPaymentMethod: this.selectedPaymentMethod
            });

            this.showToast('성공', result, 'success');
            this.closePaymentMethodModal();
            await this.loadPaymentDetails(); // 데이터 새로고침
            
        } catch (error) {
            console.error('Error updating payment method:', error);
            this.showToast('오류', error.body?.message || 'Payment Method 변경에 실패했습니다.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // 전체 완납 처리
    async handleMarkAllCompleted() {
        this.isLoading = true;
        try {
            const result = await markAllPaymentsAsCompleted({ orderId: this.recordId });
            this.showToast('성공', result, 'success');
            await this.loadPaymentDetails(); // 데이터 새로고침
            
        } catch (error) {
            console.error('Error marking all payments as completed:', error);
            this.showToast('오류', error.body?.message || '전체 완납 처리에 실패했습니다.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // 수동으로 PaymentStatus 생성
    async handleCreatePaymentStatus() {
        this.isLoading = true;
        try {
            const result = await createPaymentStatusManually({ orderId: this.recordId });
            this.showToast('성공', result, 'success');
            await this.loadPaymentDetails(); // 데이터 새로고침
            
        } catch (error) {
            console.error('PaymentStatus 생성 오류:', error);
            this.showToast('오류', error.body?.message || 'PaymentStatus 생성에 실패했습니다.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // 이벤트 핸들러들
    handleStatusChange(event) {
        this.newStatus = event.detail.value;
    }

    handlePaidDateChange(event) {
        this.newPaidDate = event.detail.value;
    }

    handlePaymentMethodChange(event) {
        this.selectedPaymentMethod = event.detail.value;
    }

    // 모달 제어
    openPaymentMethodModal() {
        this.showPaymentMethodModal = true;
    }

    closePaymentMethodModal() {
        this.showPaymentMethodModal = false;
    }

    closeEditModal() {
        this.showEditModal = false;
        this.selectedPayment = null;
    }

    // 계산된 속성들
    get formattedTotalAmount() {
        return this.paymentDetails?.orderInfo?.TotalAmount ? 
            this.formatCurrency(this.paymentDetails.orderInfo.TotalAmount) : '₩0';
    }

    get showPaidDateInput() {
        return this.newStatus === '완납';
    }

    get enrichedPaymentList() {
        if (!this.paymentDetails?.paymentList) return [];
        
        const today = new Date();
        today.setHours(0, 0, 0, 0); // 시간 부분 제거
        
        return this.paymentDetails.paymentList.map(payment => {
            // 연체 상태 동적 계산
            let effectiveStatus = payment.Status__c;
            if (payment.Status__c === '미납' && payment.DueDate__c) {
                const dueDate = new Date(payment.DueDate__c);
                if (dueDate < today) {
                    effectiveStatus = '연체';
                }
            }
            
            return {
                ...payment,
                effectiveStatus: effectiveStatus,
                formattedAmount: this.formatCurrency(payment.Amount__c),
                formattedDueDate: this.formatDate(payment.DueDate__c),
                formattedPaidDate: this.formatDate(payment.PaidDate__c),
                statusClass: this.getStatusClass(effectiveStatus)
            };
        });
    }

    get selectedPaymentFormatted() {
        if (!this.selectedPayment) return null;
        
        return {
            ...this.selectedPayment,
            formattedAmount: this.formatCurrency(this.selectedPayment.Amount__c),
            formattedDueDate: this.formatDate(this.selectedPayment.DueDate__c)
        };
    }
    // 날짜 포맷팅
    formatDate(dateValue) {
        if (!dateValue) return '';
        const date = new Date(dateValue);
        return date.toLocaleDateString('ko-KR');
    }

    // 통화 포맷팅
    formatCurrency(amount) {
        if (!amount) return '₩0';
        return '₩' + amount.toLocaleString('ko-KR');
    }

    // 상태별 CSS 클래스
    getStatusClass(status) {
        switch (status) {
            case '완납': return 'payment-status completed';
            case '연체': return 'payment-status overdue';
            case '미납': return 'payment-status pending';
            default: return 'payment-status pending';
        }
    }

    // 토스트 메시지
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        }));
    }
}
