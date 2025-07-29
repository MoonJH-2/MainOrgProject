/**
 * Logic 3: Performance Tracking Dashboard
 * 영업사원을 위한 실시간 성과 추적 대시보드
 */
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getDashboardData from '@salesforce/apex/PerformanceTrackingService.getDashboardData';
import refreshDashboard from '@salesforce/apex/PerformanceTrackingService.refreshDashboard';

export default class PerformanceTrackingDashboard extends LightningElement {
    @track dashboardData = {};
    @track isLoading = true;
    @track error = null;
    
    // 와이어드 데이터 저장용
    wiredDashboardResult;
    
    // 자동 새로고침을 위한 인터벌 ID
    refreshInterval;
    
    @wire(getDashboardData)
    wiredDashboard(result) {
        this.wiredDashboardResult = result;
        if (result.data) {
            this.dashboardData = result.data;
            this.isLoading = false;
            this.error = null;
        } else if (result.error) {
            this.error = result.error;
            this.isLoading = false;
            this.showErrorToast('대시보드 로딩 오류', result.error.body?.message || '데이터를 불러올 수 없습니다.');
        }
    }
    
    connectedCallback() {
        // 30초마다 자동 새로고침
        this.refreshInterval = setInterval(() => {
            this.handleRefresh();
        }, 30000);
    }
    
    disconnectedCallback() {
        // 컴포넌트 해제 시 인터벌 정리
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }
    
    // 수동 새로고침
    async handleRefresh() {
        this.isLoading = true;
        
        try {
            await refreshDashboard();
            await refreshApex(this.wiredDashboardResult);
            
            this.showSuccessToast('새로고침 완료', '대시보드가 업데이트되었습니다.');
        } catch (error) {
            this.showErrorToast('새로고침 오류', error.body?.message || '새로고침 중 오류가 발생했습니다.');
        } finally {
            this.isLoading = false;
        }
    }
    
    // 오늘의 매출 상태에 따른 CSS 클래스
    get todayRevenueStatusClass() {
        if (!this.dashboardData.todayRevenue) return 'status-neutral';
        
        const status = this.dashboardData.todayRevenue.status;
        return `status-${status}`;
    }
    
    // 달성률 진행바 스타일
    get achievementProgressStyle() {
        if (!this.dashboardData.todayRevenue) return 'width: 0%';
        
        const rate = Math.min(this.dashboardData.todayRevenue.achievementRate, 100);
        return `width: ${rate}%`;
    }
    
    // 레벨 진행률 스타일
    get levelProgressStyle() {
        if (!this.dashboardData.gamification) return 'width: 0%';
        
        const progress = Math.min(this.dashboardData.gamification.progressPercentage, 100);
        return `width: ${progress}%`;
    }
    
    // 고객 건강도 차트 데이터
    get customerHealthChartData() {
        if (!this.dashboardData.customerHealth) return [];
        
        return [
            {
                label: '건강한 고객',
                value: this.dashboardData.customerHealth.healthyCount,
                percentage: this.dashboardData.customerHealth.healthyPercentage,
                color: '#04844b',
                icon: '🟢'
            },
            {
                label: '주의 고객',
                value: this.dashboardData.customerHealth.warningCount,
                percentage: this.dashboardData.customerHealth.warningPercentage,
                color: '#ff6900',
                icon: '🟡'
            },
            {
                label: '위험 고객',
                value: this.dashboardData.customerHealth.riskCount,
                percentage: this.dashboardData.customerHealth.riskPercentage,
                color: '#c23934',
                icon: '🔴'
            }
        ];
    }
    
    // 우선순위별 알림 정렬
    get sortedNotifications() {
        if (!this.dashboardData.notifications) return [];
        
        const priorityOrder = { 'high': 3, 'medium': 2, 'low': 1 };
        
        return [...this.dashboardData.notifications].sort((a, b) => {
            return priorityOrder[b.priority] - priorityOrder[a.priority];
        });
    }
    
    // 알림 아이템 클릭 처리
    handleNotificationClick(event) {
        const notificationId = event.currentTarget.dataset.id;
        const notification = this.dashboardData.notifications.find(n => n.id === notificationId);
        
        if (notification) {
            // 알림 타입에 따른 액션 수행
            switch (notification.type) {
                case 'renewal':
                    this.handleRenewalNotification(notification);
                    break;
                case 'target':
                    this.handleTargetNotification(notification);
                    break;
                case 'opportunity':
                    this.handleOpportunityNotification(notification);
                    break;
            }
        }
    }
    
    handleRenewalNotification(notification) {
        // 갱신 관련 알림 - 관련 Asset으로 이동
        this.showInfoToast('갱신 알림', '해당 자산의 갱신 프로세스를 시작하세요.');
    }
    
    handleTargetNotification(notification) {
        // 목표 관련 알림 - 우선순위 고객 리스트로 이동
        this.showInfoToast('목표 알림', '우선순위 고객들에게 연락하여 목표를 달성하세요.');
    }
    
    handleOpportunityNotification(notification) {
        // 기회 관련 알림 - 해당 기회 상세로 이동
        this.showInfoToast('기회 알림', '고액 갱신 기회를 놓치지 마세요!');
    }
    
    // 숫자 포맷팅 유틸리티
    formatCurrency(amount) {
        if (!amount) return '₩0';
        
        if (amount >= 100000000) {
            return `₩${(amount / 100000000).toFixed(1)}억`;
        } else if (amount >= 10000) {
            return `₩${(amount / 10000).toFixed(0)}만`;
        } else {
            return `₩${amount.toLocaleString()}`;
        }
    }
    
    formatNumber(num) {
        if (!num) return '0';
        return num.toLocaleString();
    }
    
    formatPercentage(percent) {
        if (!percent) return '0%';
        return `${percent.toFixed(1)}%`;
    }
    
    formatTimeReduction(seconds) {
        if (!seconds) return '0초';
        
        if (seconds >= 3600) {
            return `${(seconds / 3600).toFixed(1)}시간`;
        } else if (seconds >= 60) {
            return `${(seconds / 60).toFixed(0)}분`;
        } else {
            return `${seconds}초`;
        }
    }
    
    // 빠른 액션 메소드들
    handleViewPriorityCustomers() {
        this.showInfoToast('우선순위 고객', 'Logic 1 우선순위 계산 결과를 확인하세요.');
    }
    
    handleStartRenewalProcess() {
        this.showInfoToast('갱신 프로세스', 'Logic 2 원클릭 갱신 기능을 사용하세요.');
    }
    
    handleViewDetailedReport() {
        this.showInfoToast('상세 리포트', '자세한 성과 분석 리포트를 준비 중입니다.');
    }
    
    // 토스트 메시지 유틸리티
    showSuccessToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success'
        }));
    }
    
    showErrorToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error'
        }));
    }
    
    showInfoToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'info'
        }));
    }
    
    // 게터 메소드들 (템플릿에서 사용)
    get hasData() {
        return this.dashboardData && Object.keys(this.dashboardData).length > 0;
    }
    
    get todayRevenue() {
        return this.dashboardData.todayRevenue;
    }
    
    get monthlyRenewal() {
        return this.dashboardData.monthlyRenewal;
    }
    
    get customerHealth() {
        return this.dashboardData.customerHealth;
    }
    
    get efficiency() {
        return this.dashboardData.efficiency;
    }
    
    get gamification() {
        return this.dashboardData.gamification;
    }
    
    get lastUpdated() {
        if (!this.dashboardData.lastUpdated) return '';
        
        const date = new Date(this.dashboardData.lastUpdated);
        return date.toLocaleString('ko-KR');
    }
}
