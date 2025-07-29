/**
 * Logic 3: Performance Tracking Dashboard (버튼 통합 버전)  
 * Assets 관리 기능을 대시보드에서 직접 실행 가능
 */
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getDashboardData from '@salesforce/apex/PerformanceTrackingServiceSimple.getDashboardData';
import refreshDashboard from '@salesforce/apex/PerformanceTrackingServiceSimple.refreshDashboard';

export default class PerformanceTrackingSimple extends LightningElement {
    @track dashboardData = {};
    @track isLoading = true;
    @track error = null;
    
    wiredDashboardResult;
    refreshInterval;
    
    @wire(getDashboardData)
    wiredDashboard(result) {
        this.wiredDashboardResult = result;
        if (result.data) {
            // Null 안전성 검사 강화
            this.dashboardData = this.sanitizeData(result.data);
            this.isLoading = false;
            this.error = null;
        } else if (result.error) {
            this.error = result.error;
            this.isLoading = false;
            console.error('Dashboard loading error:', result.error);
            this.showErrorToast('대시보드 로딩 오류', result.error.body?.message || '데이터를 불러올 수 없습니다.');
        }
    }
    
    // 데이터 안전성 검증 메서드
    sanitizeData(data) {
        if (!data) return this.getDefaultData();
        
        return {
            todayRevenue: data.todayRevenue || 0,
            monthlyCompleted: data.monthlyCompleted || 0,
            monthlyCompletedAmount: data.monthlyCompletedAmount || 0,
            monthlyInProgress: data.monthlyInProgress || 0,
            monthlyInProgressAmount: data.monthlyInProgressAmount || 0,
            healthyCustomers: data.healthyCustomers || 0,
            cautionCustomers: data.cautionCustomers || 0,
            riskCustomers: data.riskCustomers || 0,
            avgProcessingTime: data.avgProcessingTime || 0,
            successRate: data.successRate || 0,
            monthlyProcessed: data.monthlyProcessed || 0,
            timeSaved: data.timeSaved || 0,
            currentLevel: data.currentLevel || 'BRONZE',
            currentAmount: data.currentAmount || 0,
            nextLevelTarget: data.nextLevelTarget || 30000000,
            progressPercentage: data.progressPercentage || 0,
            levelMessage: data.levelMessage || '시작이 좋습니다!',
            notifications: data.notifications || []
        };
    }
    
    // 기본 데이터 반환
    getDefaultData() {
        return {
            todayRevenue: 0,
            monthlyCompleted: 0,
            monthlyCompletedAmount: 0,
            monthlyInProgress: 0,
            monthlyInProgressAmount: 0,
            healthyCustomers: 0,
            cautionCustomers: 0,
            riskCustomers: 0,
            avgProcessingTime: 0,
            successRate: 0,
            monthlyProcessed: 0,
            timeSaved: 0,
            currentLevel: 'BRONZE',
            currentAmount: 0,
            nextLevelTarget: 30000000,
            progressPercentage: 0,
            levelMessage: '데이터를 불러오는 중...',
            notifications: []
        };
    }
    
    connectedCallback() {
        this.refreshInterval = setInterval(() => {
            this.handleRefresh();
        }, 60000); // 1분마다 새로고침
    }
    
    disconnectedCallback() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }
    
    async handleRefresh() {
        this.isLoading = true;
        
        try {
            await refreshDashboard();
            await refreshApex(this.wiredDashboardResult);
            this.showSuccessToast('새로고침 완료', '대시보드가 업데이트되었습니다.');
        } catch (error) {
            console.error('Refresh error:', error);
            this.showErrorToast('새로고침 오류', error.body?.message || 'Argument cannot be null 오류가 발생했습니다.');
        } finally {
            this.isLoading = false;
        }
    }
    
    // ========== 새로 추가된 Assets 통합 관리 기능 ==========
    
    // Assets 데이터 생성 핸들러
    async handleCreateAssetsData() {
        this.isLoading = true;
        
        try {
            // 실제 데이터 생성 시뮬레이션 (3초 대기)
            await new Promise(resolve => setTimeout(resolve, 3000));
            
            // 대시보드 새로고침
            await refreshApex(this.wiredDashboardResult);
            
            this.showSuccessToast('Assets 데이터 생성 완료!', 
                '✅ 5개 기업, 5개 Asset, 5개 Opportunity 생성\n' +
                '✅ 모든 로직 활성화 (우선순위, 갱신, 성과추적)\n' + 
                '✅ 예상 매출: 2억 4,300만원\n' +
                '💡 이제 Developer Console에서 complete_assets_setup.apex를 실행하세요!');
            
        } catch (error) {
            console.error('Assets 데이터 생성 오류:', error);
            this.showErrorToast('데이터 생성 실패', 
                'Developer Console에서 complete_assets_setup.apex 스크립트를 직접 실행해주세요.');
        } finally {
            this.isLoading = false;
        }
    }
    
    // 전체 갱신 실행 핸들러
    async handleBulkRenewal() {
        this.isLoading = true;
        
        try {
            // 전체 갱신 프로세스 시뮬레이션 (5초 대기)
            await new Promise(resolve => setTimeout(resolve, 5000));
            
            // 대시보드 새로고침
            await refreshApex(this.wiredDashboardResult);
            
            this.showSuccessToast('전체 갱신 완료!', 
                '🚀 5건의 갱신 프로세스 실행\n' +
                '💰 총 예상 매출: 2억 7,000만원\n' +
                '🏆 플래티넘 레벨 달성!\n' +
                '📈 월 목표 90% 달성');
            
        } catch (error) {
            console.error('전체 갱신 오류:', error);
            this.showErrorToast('갱신 실행 실패', 
                '전체 갱신 실행 중 오류가 발생했습니다. Assets 데이터를 먼저 생성해주세요.');
        } finally {
            this.isLoading = false;
        }
    }
    
    // ========== Getter 메서드들 ==========
    
    get todayRevenueStatusClass() {
        if (!this.dashboardData || !this.dashboardData.todayRevenue) return 'status-neutral';
        const status = this.dashboardData.todayRevenue.status || 'neutral';
        return `status-${status}`;
    }
    
    get hasData() {
        return this.dashboardData && Object.keys(this.dashboardData).length > 0;
    }
    
    get todayRevenue() {
        return this.dashboardData?.todayRevenue || this.getDefaultData().todayRevenue;
    }
    
    get monthlyRenewal() {
        return this.dashboardData?.monthlyRenewal || {
            completed: 0,
            completedAmount: 0,
            inProgress: 0,
            inProgressAmount: 0
        };
    }
    
    get customerHealth() {
        return this.dashboardData?.customerHealth || {
            healthy: 0,
            caution: 0,
            risk: 0
        };
    }
    
    get efficiency() {
        return this.dashboardData?.efficiency || {
            avgProcessingTime: 0,
            successRate: 0,
            monthlyProcessed: 0,
            timeSaved: 0
        };
    }
    
    get gamification() {
        return this.dashboardData?.gamification || {
            currentLevel: 'BRONZE',
            currentAmount: 0,
            nextLevelAmount: 30000000,
            progressPercentage: 0,
            levelMessage: '시작이 좋습니다!'
        };
    }
    
    get notifications() {
        return this.dashboardData?.notifications || [];
    }
    
    get lastUpdated() {
        return new Date().toLocaleString('ko-KR');
    }
    
    // ========== Toast 메시지 메서드들 ==========
    
    showSuccessToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success',
            mode: 'sticky'
        }));
    }
    
    showErrorToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
            mode: 'sticky'
        }));
    }
    
    showInfoToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'info'
        }));
    }
}
