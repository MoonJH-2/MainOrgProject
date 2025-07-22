/**
 * @description 알림 대시보드 컨트롤러
 * @author JH Moon
 * @date 2025-07-15
 */
public with sharing class PaymentNotificationDashboardController {
    
    /**
     * 알림 통계 조회
     */
    @AuraEnabled(cacheable=true)
    public static NotificationStats getNotificationStats(String timeFrame) {
        Date fromDate = calculateFromDate(timeFrame);
        
        // 전체 알림 통계
        List<AggregateResult> totalStats = [
            SELECT COUNT(Id) totalCount, NotificationStatus__c status
            FROM Payment_Notification__c 
            WHERE CreatedDate >= :fromDate
            GROUP BY NotificationStatus__c
        ];
        
        // 채널별 통계
        List<AggregateResult> channelStats = [
            SELECT COUNT(Id) totalCount, NotificationChannel__c channel
            FROM Payment_Notification__c 
            WHERE CreatedDate >= :fromDate
            AND NotificationStatus__c = 'Sent'
            GROUP BY NotificationChannel__c
        ];
        
        // 알림 유형별 통계
        List<AggregateResult> typeStats = [
            SELECT COUNT(Id) totalCount, NotificationType__c notificationType
            FROM Payment_Notification__c 
            WHERE CreatedDate >= :fromDate
            AND NotificationStatus__c = 'Sent'
            GROUP BY NotificationType__c
        ];
        
        NotificationStats stats = new NotificationStats();
        stats.totalNotifications = 0;
        stats.sentNotifications = 0;
        stats.failedNotifications = 0;
        stats.pendingNotifications = 0;
        
        // 상태별 통계 집계
        for (AggregateResult ar : totalStats) {
            Integer count = (Integer)ar.get('totalCount');
            String status = (String)ar.get('status');
            
            stats.totalNotifications += count;
            
            switch on status {
                when 'Sent' {
                    stats.sentNotifications = count;
                }
                when 'Failed' {
                    stats.failedNotifications = count;
                }
                when 'Pending' {
                    stats.pendingNotifications = count;
                }
            }
        }
        
        // 성공률 계산
        if (stats.totalNotifications > 0) {
            stats.successRate = (Decimal.valueOf(stats.sentNotifications) / 
                               Decimal.valueOf(stats.totalNotifications) * 100).setScale(1);
        } else {
            stats.successRate = 0;
        }
        
        // 채널별 통계 설정
        stats.salesforceCount = 0;
        stats.salesforceChannelCount = 0;
        stats.emailCount = 0;
        stats.slackCount = 0;
        
        for (AggregateResult ar : channelStats) {
            Integer count = (Integer)ar.get('totalCount');
            String channel = (String)ar.get('channel');
            
            switch on channel {
                when 'Salesforce' {
                    stats.salesforceCount = count;
                }
                when 'SalesforceChannel' {
                    stats.salesforceChannelCount = count;
                }
                when 'Email' {
                    stats.emailCount = count;
                }
                when 'Slack' {
                    stats.slackCount = count;
                }
            }
        }
        
        // 알림 유형별 통계 설정
        stats.reminderCount = 0;
        stats.overdueCount = 0;
        
        for (AggregateResult ar : typeStats) {
            Integer count = (Integer)ar.get('totalCount');
            String notificationType = (String)ar.get('notificationType');
            
            switch on notificationType {
                when '예정 알림' {
                    stats.reminderCount = count;
                }
                when '연체 알림' {
                    stats.overdueCount = count;
                }
            }
        }
        
        return stats;
    }
    
    /**
     * 최근 알림 이력 조회
     */
    @AuraEnabled(cacheable=true)
    public static List<NotificationDetail> getRecentNotifications(Integer limitCount) {
        try {
            List<NotificationDetail> notifications = new List<NotificationDetail>();
            
            List<Payment_Notification__c> records = [
                SELECT Id, NotificationType__c, NotificationChannel__c, NotificationStatus__c,
                       PaymentStatus__r.Order__r.Account.Name, PaymentStatus__r.Order__r.OrderNumber,
                       PaymentStatus__r.Amount__c, PaymentStatus__r.InstallmentNumber__c,
                       ScheduledDateTime__c, SentDateTime__c, ErrorMessage__c
                FROM Payment_Notification__c 
                ORDER BY CreatedDate DESC
                LIMIT :limitCount
            ];
            
            for (Payment_Notification__c record : records) {
                NotificationDetail detail = new NotificationDetail();
                detail.id = record.Id;
                detail.type = record.NotificationType__c;
                detail.channel = record.NotificationChannel__c;
                detail.status = record.NotificationStatus__c;
                detail.accountName = record.PaymentStatus__r.Order__r.Account.Name;
                detail.orderNumber = record.PaymentStatus__r.Order__r.OrderNumber;
                detail.amount = record.PaymentStatus__r.Amount__c;
                detail.installmentNumber = record.PaymentStatus__r.InstallmentNumber__c != null ? 
                    Integer.valueOf(record.PaymentStatus__r.InstallmentNumber__c) : 0;
                detail.scheduledTime = record.ScheduledDateTime__c;
                detail.sentTime = record.SentDateTime__c;
                detail.errorMessage = record.ErrorMessage__c;
                
                notifications.add(detail);
            }
            
            return notifications;
            
        } catch (Exception e) {
            throw new AuraHandledException('알림 목록 조회 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 실패한 알림 재발송
     */
    @AuraEnabled
    public static String retryFailedNotifications(List<String> notificationIds) {
        try {
            List<Payment_Notification__c> failedNotifications = [
                SELECT Id, NotificationStatus__c, ErrorMessage__c
                FROM Payment_Notification__c 
                WHERE Id IN :notificationIds
                AND NotificationStatus__c = 'Failed'
            ];
            
            // 상태를 Pending으로 변경하여 다음 배치에서 재처리되도록 함
            for (Payment_Notification__c notification : failedNotifications) {
                notification.NotificationStatus__c = 'Pending';
                notification.ErrorMessage__c = null;
            }
            
            update failedNotifications;
            
            return '성공: ' + failedNotifications.size() + '건의 알림이 재발송 대기열에 추가되었습니다.';
            
        } catch (Exception e) {
            return '오류: ' + e.getMessage();
        }
    }
    
    /**
     * 시간 범위 계산
     */
    private static Date calculateFromDate(String timeFrame) {
        switch on timeFrame {
            when 'today' {
                return Date.today();
            }
            when 'week' {
                return Date.today().addDays(-7);
            }
            when 'month' {
                return Date.today().addDays(-30);
            }
            when else {
                return Date.today().addDays(-7);
            }
        }
    }
    
    /**
     * 대시보드 통계 데이터 조회 (새로운 형식)
     */
    @AuraEnabled(cacheable=true)
    public static DashboardStats getDashboardStats() {
        try {
            DashboardStats stats = new DashboardStats();
            
            // 오늘 통계
            Date today = Date.today();
            List<AggregateResult> todayResults = [
                SELECT NotificationStatus__c, COUNT(Id) cnt
                FROM Payment_Notification__c 
                WHERE CreatedDate = TODAY
                GROUP BY NotificationStatus__c
            ];
            
            stats.todayTotal = 0;
            stats.todaySuccess = 0;
            stats.todayFailed = 0;
            stats.todayPending = 0;
            
            for (AggregateResult result : todayResults) {
                Integer count = (Integer) result.get('cnt');
                String status = (String) result.get('NotificationStatus__c');
                
                stats.todayTotal += count;
                if (status == 'Sent') {
                    stats.todaySuccess = count;
                } else if (status == 'Failed') {
                    stats.todayFailed = count;
                } else if (status == 'Pending') {
                    stats.todayPending = count;
                }
            }
            
            // 성공률 계산
            if (stats.todayTotal > 0) {
                stats.successRate = ((Decimal) stats.todaySuccess / stats.todayTotal * 100).setScale(1);
            } else {
                stats.successRate = 0;
            }
            
            // 주간/월간 통계
            stats.weeklyTotal = [SELECT COUNT() FROM Payment_Notification__c WHERE CreatedDate = LAST_N_DAYS:7];
            stats.monthlyTotal = [SELECT COUNT() FROM Payment_Notification__c WHERE CreatedDate = LAST_N_DAYS:30];
            
            // 채널별 통계
            stats.channelStats = getChannelStats();
            
            // 유형별 통계
            stats.typeStats = getTypeStats();
            
            // 일별 트렌드 (최근 7일)
            stats.dailyTrend = getDailyTrend();
            
            return stats;
            
        } catch (Exception e) {
            throw new AuraHandledException('대시보드 데이터 조회 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 채널별 통계
     */
    private static List<ChartData> getChannelStats() {
        List<ChartData> channelData = new List<ChartData>();
        
        List<AggregateResult> channelResults = [
            SELECT NotificationChannel__c, COUNT(Id) cnt
            FROM Payment_Notification__c 
            WHERE CreatedDate = LAST_N_DAYS:7
            GROUP BY NotificationChannel__c
        ];
        
        Map<String, String> channelColors = new Map<String, String>{
            'Salesforce' => '#1589EE',
            'SalesforceChannel' => '#00D924',
            'Email' => '#FF6B6B',
            'Slack' => '#4ECDC4'
        };
        
        for (AggregateResult result : channelResults) {
            String channel = (String) result.get('NotificationChannel__c');
            Integer count = (Integer) result.get('cnt');
            String color = channelColors.get(channel);
            
            channelData.add(new ChartData(channel, count, color));
        }
        
        return channelData;
    }
    
    /**
     * 유형별 통계
     */
    private static List<ChartData> getTypeStats() {
        List<ChartData> typeData = new List<ChartData>();
        
        List<AggregateResult> typeResults = [
            SELECT NotificationType__c, COUNT(Id) cnt
            FROM Payment_Notification__c 
            WHERE CreatedDate = LAST_N_DAYS:7
            GROUP BY NotificationType__c
        ];
        
        Map<String, String> typeColors = new Map<String, String>{
            '예정 알림' => '#FFA726',
            '연체 알림' => '#EF5350'
        };
        
        for (AggregateResult result : typeResults) {
            String type = (String) result.get('NotificationType__c');
            Integer count = (Integer) result.get('cnt');
            String color = typeColors.get(type);
            
            typeData.add(new ChartData(type, count, color));
        }
        
        return typeData;
    }
    
    /**
     * 일별 트렌드 (최근 7일)
     */
    private static List<ChartData> getDailyTrend() {
        List<ChartData> trendData = new List<ChartData>();
        
        List<AggregateResult> trendResults = [
            SELECT DAY_ONLY(CreatedDate) day, COUNT(Id) cnt
            FROM Payment_Notification__c 
            WHERE CreatedDate = LAST_N_DAYS:7
            GROUP BY DAY_ONLY(CreatedDate)
            ORDER BY DAY_ONLY(CreatedDate)
        ];
        
        for (AggregateResult result : trendResults) {
            Date day = (Date) result.get('day');
            Integer count = (Integer) result.get('cnt');
            
            trendData.add(new ChartData(day.format(), count, '#42A5F5'));
        }
        
        return trendData;
    }
    
    /**
     * 배치 작업 수동 실행
     */
    @AuraEnabled
    public static String executeBatchJob() {
        try {
            PaymentNotificationBatch batch = new PaymentNotificationBatch();
            Id jobId = Database.executeBatch(batch, 10);
            return '배치 작업이 시작되었습니다. Job ID: ' + jobId;
        } catch (Exception e) {
            throw new AuraHandledException('배치 실행 오류: ' + e.getMessage());
        }
    }
    
    /**
     * 스케줄러 상태 조회
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getSchedulerStatus() {
        try {
            List<Map<String, Object>> schedulers = new List<Map<String, Object>>();
            
            List<CronTrigger> cronJobs = [
                SELECT Id, CronJobDetail.Name, State, NextFireTime, PreviousFireTime
                FROM CronTrigger 
                WHERE CronJobDetail.Name LIKE '%Payment%'
            ];
            
            for (CronTrigger job : cronJobs) {
                Map<String, Object> scheduler = new Map<String, Object>();
                scheduler.put('name', job.CronJobDetail.Name);
                scheduler.put('state', job.State);
                scheduler.put('nextFireTime', job.NextFireTime);
                scheduler.put('previousFireTime', job.PreviousFireTime);
                
                schedulers.add(scheduler);
            }
            
            return schedulers;
            
        } catch (Exception e) {
            throw new AuraHandledException('스케줄러 상태 조회 오류: ' + e.getMessage());
        }
    }

    // Wrapper Classes
    public class NotificationStats {
        @AuraEnabled public Integer totalNotifications;
        @AuraEnabled public Integer sentNotifications;
        @AuraEnabled public Integer failedNotifications;
        @AuraEnabled public Integer pendingNotifications;
        @AuraEnabled public Decimal successRate;
        @AuraEnabled public Integer salesforceCount;
        @AuraEnabled public Integer salesforceChannelCount;
        @AuraEnabled public Integer emailCount;
        @AuraEnabled public Integer slackCount;
        @AuraEnabled public Integer reminderCount;
        @AuraEnabled public Integer overdueCount;
    }
    
    public class NotificationHistory {
        @AuraEnabled public String id;
        @AuraEnabled public String customerName;
        @AuraEnabled public String orderNumber;
        @AuraEnabled public Integer installmentNumber;
        @AuraEnabled public String notificationType;
        @AuraEnabled public String channel;
        @AuraEnabled public String status;
        @AuraEnabled public DateTime scheduledDateTime;
        @AuraEnabled public DateTime sentDateTime;
        @AuraEnabled public String errorMessage;
    }
    
    public class DashboardStats {
        @AuraEnabled public Integer todayTotal { get; set; }
        @AuraEnabled public Integer todaySuccess { get; set; }
        @AuraEnabled public Integer todayFailed { get; set; }
        @AuraEnabled public Integer todayPending { get; set; }
        @AuraEnabled public Decimal successRate { get; set; }
        @AuraEnabled public Integer weeklyTotal { get; set; }
        @AuraEnabled public Integer monthlyTotal { get; set; }
        @AuraEnabled public List<ChartData> channelStats { get; set; }
        @AuraEnabled public List<ChartData> typeStats { get; set; }
        @AuraEnabled public List<ChartData> dailyTrend { get; set; }
    }
    
    public class ChartData {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Integer value { get; set; }
        @AuraEnabled public String color { get; set; }
        
        public ChartData(String label, Integer value, String color) {
            this.label = label;
            this.value = value;
            this.color = color;
        }
    }
    
    public class NotificationDetail {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String channel { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String orderNumber { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public Integer installmentNumber { get; set; }
        @AuraEnabled public DateTime scheduledTime { get; set; }
        @AuraEnabled public DateTime sentTime { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
    }
}
