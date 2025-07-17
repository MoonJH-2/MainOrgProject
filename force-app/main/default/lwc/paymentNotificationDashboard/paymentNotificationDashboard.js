import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getDashboardStats from '@salesforce/apex/PaymentNotificationDashboardController.getDashboardStats';
import getRecentNotifications from '@salesforce/apex/PaymentNotificationDashboardController.getRecentNotifications';
import executeBatchJob from '@salesforce/apex/PaymentNotificationDashboardController.executeBatchJob';
import getSchedulerStatus from '@salesforce/apex/PaymentNotificationDashboardController.getSchedulerStatus';

export default class PaymentNotificationDashboard extends LightningElement {
    @track dashboardData;
    @track recentNotifications = [];
    @track schedulerStatus = [];
    @track isLoading = true;
    @track error;
    
    // 차트 설정
    @track chartConfig = {
        type: 'doughnut',
        options: {
            responsive: true,
            plugins: {
                legend: {
                    position: 'bottom'
                }
            }
        }
    };

    // 대시보드 데이터 조회
    @wire(getDashboardStats)
    wiredDashboardStats({ error, data }) {
        if (data) {
            this.dashboardData = data;
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.dashboardData = undefined;
            this.isLoading = false;
        }
    }

    // 최근 알림 조회
    @wire(getRecentNotifications, { limitCount: 10 })
    wiredRecentNotifications({ error, data }) {
        if (data) {
            this.recentNotifications = data.map(notification => ({
                ...notification,
                statusVariant: this.getStatusVariant(notification.status),
                typeVariant: this.getTypeVariant(notification.type),
                channelIcon: this.getChannelIcon(notification.channel),
                formattedAmount: this.formatCurrency(notification.amount)
            }));
        } else if (error) {
            this.showToast('오류', '최근 알림 조회 중 오류가 발생했습니다.', 'error');
        }
    }

    // 스케줄러 상태 조회
    @wire(getSchedulerStatus)
    wiredSchedulerStatus({ error, data }) {
        if (data) {
            this.schedulerStatus = data;
        } else if (error) {
            this.showToast('오류', '스케줄러 상태 조회 중 오류가 발생했습니다.', 'error');
        }
    }

    // 새로고침
    handleRefresh() {
        this.isLoading = true;
        return refreshApex(this.wiredDashboardStats);
    }

    // 배치 작업 실행
    async handleExecuteBatch() {
        try {
            const result = await executeBatchJob();
            this.showToast('성공', result, 'success');
            // 데이터 새로고침
            setTimeout(() => {
                this.handleRefresh();
            }, 2000);
        } catch (error) {
            this.showToast('오류', '배치 실행 중 오류가 발생했습니다.', 'error');
        }
    }

    // 상태에 따른 뱃지 스타일
    getStatusVariant(status) {
        switch (status) {
            case 'Sent': return 'success';
            case 'Failed': return 'error';
            case 'Pending': return 'warning';
            case 'Cancelled': return 'inverse';
            default: return 'inverse';
        }
    }

    // 알림 유형에 따른 스타일
    getTypeVariant(type) {
        switch (type) {
            case '연체 알림': return 'error';
            case '예정 알림': return 'warning';
            default: return 'inverse';
        }
    }

    // 채널에 따른 아이콘
    getChannelIcon(channel) {
        switch (channel) {
            case 'Salesforce': return 'standard:announcement';
            case 'Email': return 'standard:email';
            case 'Slack': return 'standard:messaging_session';
            default: return 'standard:notification';
        }
    }

    // 통화 포맷
    formatCurrency(amount) {
        if (!amount) return '₩0';
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(amount);
    }

    // 토스트 메시지
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    // 성공률 색상
    get successRateColor() {
        if (!this.dashboardData) return 'gray';
        const rate = this.dashboardData.successRate;
        if (rate >= 90) return 'green';
        if (rate >= 70) return 'yellow';
        return 'red';
    }

    // 차트 데이터 - 채널별
    get channelChartData() {
        if (!this.dashboardData?.channelStats) return null;
        
        return this.dashboardData.channelStats.map(item => ({
            label: item.label,
            value: item.value,
            color: item.color
        }));
    }

    // 차트 데이터 - 유형별
    get typeChartData() {
        if (!this.dashboardData?.typeStats) return null;
        
        return this.dashboardData.typeStats.map(item => ({
            label: item.label,
            value: item.value,
            color: item.color
        }));
    }

    // 컬럼 정의
    get notificationColumns() {
        return [
            {
                label: '유형',
                fieldName: 'type',
                type: 'text',
                cellAttributes: {
                    class: { fieldName: 'typeVariant' }
                }
            },
            {
                label: '채널',
                fieldName: 'channel',
                type: 'text',
                cellAttributes: {
                    iconName: { fieldName: 'channelIcon' }
                }
            },
            {
                label: '상태',
                fieldName: 'status',
                type: 'text',
                cellAttributes: {
                    class: { fieldName: 'statusVariant' }
                }
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
                label: '금액',
                fieldName: 'formattedAmount',
                type: 'text'
            },
            {
                label: '예정시간',
                fieldName: 'scheduledTime',
                type: 'date',
                typeAttributes: {
                    year: 'numeric',
                    month: 'short',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit'
                }
            }
        ];
    }
}
