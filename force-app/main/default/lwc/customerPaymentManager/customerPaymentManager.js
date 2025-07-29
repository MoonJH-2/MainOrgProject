import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrdersWithPayments from '@salesforce/apex/CustomerPaymentManagerController.getOrdersWithPayments';
import getPaymentStatusDetails from '@salesforce/apex/CustomerPaymentManagerController.getPaymentStatusDetails';
import updatePaymentMethod from '@salesforce/apex/CustomerPaymentManagerController.updatePaymentMethod';
import updatePaymentStatus from '@salesforce/apex/CustomerPaymentManagerController.updatePaymentStatus';
import markAllPaymentsAsCompleted from '@salesforce/apex/CustomerPaymentManagerController.markAllPaymentsAsCompleted';

export default class CustomerPaymentManager extends LightningElement {
    @track orderList = [];
    @track selectedOrderId = null;
    @track selectedOrder = null;
    @track paymentDetails = null;
    @track isLoading = false;
    @track showPaymentDetails = false;
    @track isUpdatingPayment = false;
    @track showEditModal = false;
    @track selectedPayment = null;
    @track newStatus = '';
    @track newPaidDate = '';
    @track showPaymentMethodModal = false;
    @track selectedPaymentMethod = '';

    // Wire된 Order 목록
    wiredOrdersResult;
    @wire(getOrdersWithPayments)
    wiredOrders(result) {
        this.wiredOrdersResult = result;
        if (result.data) {
            this.orderList = result.data;
        } else if (result.error) {
            this.showToast('오류', 'Order 목록을 불러오는 중 오류가 발생했습니다.', 'error');
        }
    }

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

    // 포맷된 납부 목록 getter
    get enrichedPaymentList() {
        if (!this.paymentDetails || !this.paymentDetails.paymentList) {
            return [];
        }
        
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

    // 선택된 납부 포맷된 정보
    get selectedPaymentFormatted() {
        if (!this.selectedPayment) return null;
        
        return {
            ...this.selectedPayment,
            formattedAmount: this.formatCurrency(this.selectedPayment.Amount__c),
            formattedDueDate: this.formatDate(this.selectedPayment.DueDate__c),
            formattedPaidDate: this.formatDate(this.selectedPayment.PaidDate__c)
        };
    }

    // 완납일 입력 필드 표시 여부
    get showPaidDateInput() {
        return this.newStatus === '완납';
    }

    // 총 금액 포맷
    get formattedTotalAmount() {
        if (!this.paymentDetails || !this.paymentDetails.orderInfo) return '';
        return this.formatCurrency(this.paymentDetails.orderInfo.TotalAmount);
    }

    // Order 선택 처리
    handleOrderSelect(event) {
        const orderId = event.currentTarget.dataset.orderId;
        this.selectedOrderId = orderId;
        this.selectedOrder = this.orderList.find(order => order.orderRecord.Id === orderId);
        this.loadPaymentDetails();
    }

    // 납부 상세 정보 로드
    async loadPaymentDetails() {
        this.isLoading = true;
        try {
            const result = await getPaymentStatusDetails({ orderId: this.selectedOrderId });
            this.paymentDetails = result;
            this.selectedPaymentMethod = result.orderInfo?.Payment_Method__c || '분기별';
            this.showPaymentDetails = true;
        } catch (error) {
            this.showToast('오류', '납부 상세 정보 로드 실패: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // 납부 편집 모달 열기
    handleEditPayment(event) {
        const paymentId = event.currentTarget.dataset.paymentId;
        this.selectedPayment = this.paymentDetails.paymentList.find(p => p.Id === paymentId);
        this.newStatus = this.selectedPayment.Status__c;
        this.newPaidDate = this.selectedPayment.Paid_Date__c || '';
        this.showEditModal = true;
    }

    // 납부 편집 모달 닫기
    closeEditModal() {
        this.showEditModal = false;
        this.selectedPayment = null;
        this.newStatus = '';
        this.newPaidDate = '';
    }

    // 상태 변경 처리
    handleStatusChange(event) {
        this.newStatus = event.detail.value;
        if (this.newStatus === '완납' && !this.newPaidDate) {
            this.newPaidDate = new Date().toISOString().split('T')[0];
        }
    }

    // 납부 완료일 변경 처리
    handlePaidDateChange(event) {
        this.newPaidDate = event.detail.value;
    }

    // 납부 상태 업데이트
    async handleUpdatePaymentStatus() {
        this.isLoading = true;
        
        try {
            await updatePaymentStatus({
                paymentId: this.selectedPayment.Id,
                newStatus: this.newStatus,
                paidDate: this.newPaidDate || null,
                notes: null
            });
            
            this.showToast('성공', '납부 상태가 업데이트되었습니다.', 'success');
            this.closeEditModal();
            await this.loadPaymentDetails();
            
        } catch (error) {
            this.showToast('오류', '납부 상태 업데이트 실패: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Payment Method 모달 열기
    openPaymentMethodModal() {
        this.showPaymentMethodModal = true;
    }

    // Payment Method 모달 닫기
    closePaymentMethodModal() {
        this.showPaymentMethodModal = false;
    }

    // Payment Method 변경 처리
    handlePaymentMethodChange(event) {
        this.selectedPaymentMethod = event.detail.value;
    }

    // Payment Method 업데이트
    async handleUpdatePaymentMethod() {
        this.isLoading = true;
        
        try {
            await updatePaymentMethod({
                orderId: this.selectedOrderId,
                newPaymentMethod: this.selectedPaymentMethod
            });
            
            this.showToast('성공', 'Payment Method가 변경되고 납부 일정이 재생성되었습니다.', 'success');
            this.closePaymentMethodModal();
            await this.refreshData();
            
        } catch (error) {
            this.showToast('오류', 'Payment Method 변경 실패: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // 전체 완납 처리
    async handleMarkAllCompleted() {
        this.isLoading = true;
        
        try {
            await markAllPaymentsAsCompleted({ orderId: this.selectedOrderId });
            this.showToast('성공', '모든 납부가 완납 처리되었습니다.', 'success');
            await this.refreshData();
            
        } catch (error) {
            this.showToast('오류', '전체 완납 처리 실패: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // 뒤로가기
    handleGoBack() {
        this.showPaymentDetails = false;
        this.selectedOrderId = null;
        this.selectedOrder = null;
        this.paymentDetails = null;
    }

    // 데이터 새로고침
    async refreshData() {
        await refreshApex(this.wiredOrdersResult);
        if (this.selectedOrderId) {
            await this.loadPaymentDetails();
        }
    }

    // 통화 포맷팅
    formatCurrency(amount) {
        if (!amount) return '₩0';
        return '₩' + Number(amount).toLocaleString();
    }

    // 날짜 포맷팅
    formatDate(dateString) {
        if (!dateString) return '-';
        const date = new Date(dateString);
        return date.toLocaleDateString('ko-KR');
    }

    // 상태 CSS 클래스
    getStatusClass(status) {
        switch(status) {
            case '완납': return 'status-completed';
            case '연체': return 'status-overdue';
            case '미납': return 'status-pending';
            default: return 'status-pending';
        }
    }

    // Toast 메시지
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        }));
    }
}
