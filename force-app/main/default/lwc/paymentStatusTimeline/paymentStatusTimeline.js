import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPaymentTimeline from '@salesforce/apex/PaymentStatusTimelineController.getPaymentTimeline';
import updatePaymentStatus from '@salesforce/apex/PaymentStatusTimelineController.updatePaymentStatus';
import generatePaymentSchedulePDF from '@salesforce/apex/PaymentStatusTimelineController.generatePaymentSchedulePDF';

export default class PaymentStatusTimeline extends LightningElement {
    @api recordId; // Order Id
    @track filterStatus = 'all';
    @track isLoading = false;

    wiredTimelineResult;
    timelineData;

    @wire(getPaymentTimeline, { orderId: '$recordId' })
    wiredTimeline(result) {
        this.wiredTimelineResult = result;
        if (result.data) {
            this.timelineData = this.processTimelineData(result.data);
        } else if (result.error) {
            this.showToast('오류', result.error.body.message, 'error');
        }
    }

    processTimelineData(data) {
        const today = new Date();
        const processedPayments = data.paymentStatuses.map((payment, index) => {
            const dueDate = new Date(payment.DueDate__c);
            const isOverdue = payment.Status__c === '미납' && dueDate < today;
            const isLast = index === data.paymentStatuses.length - 1;
            
            return {
                ...payment,
                isOverdue,
                isLast,
                formattedAmount: this.formatCurrency(payment.Amount__c),
                formattedDueDate: this.formatDate(payment.DueDate__c),
                statusVariant: this.getStatusVariant(payment.Status__c, isOverdue),
                statusLabel: this.getStatusLabel(payment.Status__c, isOverdue),
                cardClass: `payment-card ${this.getCardClass(payment.Status__c, isOverdue)}`,
                markerClass: this.getMarkerClass(payment.Status__c, isOverdue),
                toggleButtonLabel: payment.Status__c === '미납' ? '완납 처리' : '미납으로 변경',
                toggleButtonVariant: payment.Status__c === '미납' ? 'success' : 'neutral'
            };
        });

        return {
            ...data,
            paymentStatuses: processedPayments,
            filteredPayments: this.applyFilter(processedPayments, this.filterStatus)
        };
    }

    get filteredPayments() {
        if (!this.timelineData) return [];
        return this.applyFilter(this.timelineData.paymentStatuses, this.filterStatus);
    }

    applyFilter(payments, filter) {
        const today = new Date();
        switch (filter) {
            case 'unpaid':
                return payments.filter(p => p.Status__c === '미납');
            case 'paid':
                return payments.filter(p => p.Status__c === '완납');
            case 'overdue':
                return payments.filter(p => 
                    p.Status__c === '미납' && new Date(p.DueDate__c) < today
                );
            default:
                return payments;
        }
    }

    getStatusVariant(status, isOverdue) {
        if (status === '완납') return 'success';
        if (isOverdue) return 'warning';
        return 'inverse';
    }

    getStatusLabel(status, isOverdue) {
        if (status === '완납') return '완납';
        if (isOverdue) return '연체';
        return '미납';
    }

    formatCurrency(amount) {
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW'
        }).format(amount);
    }

    formatDate(dateString) {
        return new Date(dateString).toLocaleDateString('ko-KR');
    }

    handleFilterChange(event) {
        this.filterStatus = event.target.value;
    }

    async handleStatusToggle(event) {
        const paymentId = event.target.dataset.id;
        const currentStatus = event.target.dataset.status;
        const newStatus = currentStatus === '미납' ? '완납' : '미납';
        
        this.isLoading = true;
        try {
            await updatePaymentStatus({ paymentStatusId: paymentId, newStatus });
            await refreshApex(this.wiredTimelineResult);
            this.showToast('성공', '납부 상태가 업데이트되었습니다.', 'success');
        } catch (error) {
            this.showToast('오류', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleDownloadPDF() {
        this.isLoading = true;
        try {
            await generatePaymentSchedulePDF({ orderId: this.recordId });
            this.showToast('성공', 'PDF 다운로드가 준비되었습니다.', 'success');
        } catch (error) {
            this.showToast('오류', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get progressBarClass() {
        if (!this.timelineData) return '';
        const percentage = this.timelineData.progressPercentage;
        if (percentage === 100) return 'progress-complete';
        if (percentage >= 50) return 'progress-good';
        return 'progress-low';
    }

    get filterOptions() {
        return [
            { label: '전체', value: 'all' },
            { label: '미납', value: 'unpaid' },
            { label: '완납', value: 'paid' },
            { label: '연체', value: 'overdue' }
        ];
    }

    getCardClass(status, isOverdue) {
        if (status === '완납') return 'payment-card-paid';
        if (isOverdue) return 'payment-card-overdue';
        return 'payment-card-unpaid';
    }

    getMarkerClass(status, isOverdue) {
        if (status === '완납') return 'marker-paid';
        if (isOverdue) return 'marker-overdue';
        return 'marker-unpaid';
    }
}
