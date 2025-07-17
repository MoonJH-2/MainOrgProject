/**
 * @description 납부 알림 배치 스케줄러
 * @author JH Moon
 * @date 2025-07-15
 */
public class PaymentNotificationSchedulable implements Schedulable {
    
    /**
     * 스케줄된 실행 메서드
     */
    public void execute(SchedulableContext ctx) {
        // 배치 잡 실행
        PaymentNotificationBatch batch = new PaymentNotificationBatch();
        Database.executeBatch(batch, 200);
    }
    
    /**
     * 스케줄 설정 헬퍼 메서드
     * 매일 오전 9시 실행
     */
    public static String scheduleDaily() {
        String cronExp = '0 0 9 * * ?'; // 매일 오전 9시
        String jobName = 'Payment Notification Daily Job';
        
        // 기존 스케줄 삭제
        List<CronTrigger> existingJobs = [
            SELECT Id 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = :jobName 
            AND State IN ('WAITING', 'ACQUIRED', 'EXECUTING')
        ];
        
        for (CronTrigger job : existingJobs) {
            System.abortJob(job.Id);
        }
        
        // 새 스케줄 등록
        PaymentNotificationSchedulable scheduler = new PaymentNotificationSchedulable();
        String jobId = System.schedule(jobName, cronExp, scheduler);
        
        System.debug('납부 알림 스케줄 등록 완료: ' + jobId);
        return jobId;
    }
    
    /**
     * 스케줄 해제
     */
    public static void unschedule() {
        String jobName = 'Payment Notification Daily Job';
        
        List<CronTrigger> jobs = [
            SELECT Id 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = :jobName 
            AND State IN ('WAITING', 'ACQUIRED', 'EXECUTING')
        ];
        
        for (CronTrigger job : jobs) {
            System.abortJob(job.Id);
        }
        
        System.debug('납부 알림 스케줄 해제 완료');
    }
}
