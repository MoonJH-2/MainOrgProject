import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getNotificationStats from '@salesforce/apex/PaymentNotificationDashboardController.getNotificationStats';
import getRecentNotifications from '@salesforce/apex/PaymentNotificationDashboardController.getRecentNotifications';

export default class SimpleDashboard extends LightningElement {
    @track stats;
    @track notifications = [];
    @track isLoading = true;
    @track error;
    
    selectedTimeFrame = 'THIS_WEEK';
    
    timeFrameOptions = [
        { label: '오늘', value: 'TODAY' },
        { label: '이번 주', value: 'THIS_WEEK' },
        { label: '이번 달', value: 'THIS_MONTH' }
    ];

    @wire(getNotificationStats, { timeFrame: '$selectedTimeFrame' })
    wiredStats({ error, data }) {
        if (data) {
            this.stats = data;
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.stats = undefined;
            this.isLoading = false;
            this.showToast('오류', '통계 조회 중 오류가 발생했습니다.', 'error');
        }
    }

    @wire(getRecentNotifications, { limitCount: 10 })
    wiredNotifications({ error, data }) {
        if (data) {
            this.notifications = data.map(notification => ({
                ...notification,
                statusVariant: this.getStatusVariant(notification.status),
                typeVariant: this.getTypeVariant(notification.type)
            }));
        } else if (error) {
            this.showToast('오류', '알림 목록 조회 중 오류가 발생했습니다.', 'error');
        }
    }

    handleTimeFrameChange(event) {
        this.selectedTimeFrame = event.detail.value;
    }

    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredStats);
    }

    getStatusVariant(status) {
        switch (status) {
            case 'Sent': return 'success';
            case 'Failed': return 'error';
            case 'Pending': return 'warning';
            default: return 'inverse';
        }
    }

    getTypeVariant(type) {
        switch (type) {
            case '연체 알림': return 'error';
            case '예정 알림': return 'warning';
            default: return 'inverse';
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    get successRate() {
        if (!this.stats || this.stats.totalNotifications === 0) return 0;
        return ((this.stats.sentNotifications / this.stats.totalNotifications) * 100).toFixed(1);
    }

    get notificationColumns() {
        return [
            {
                label: '유형',
                fieldName: 'type',
                type: 'text'
            },
            {
                label: '채널',
                fieldName: 'channel',
                type: 'text'
            },
            {
                label: '상태',
                fieldName: 'status',
                type: 'text'
            },
            {
                label: '고객명',
                fieldName: 'accountName',
                type: 'text'
            },
            {
                label: '주문번호',
                fieldName: 'orderNumber',
                type: 'text'
            },
            {
                label: '예정시간',
                fieldName: 'scheduledTime',
                type: 'date'
            }
        ];
    }
}
