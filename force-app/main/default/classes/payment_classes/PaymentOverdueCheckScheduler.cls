/**
 * @description       : 연체 체크 및 Task 생성을 위한 일일 배치 스케줄러
 * @author            : JH Moon
 * @last modified on  : 07-16-2025
 * @last modified by  : JH Moon
**/
public class PaymentOverdueCheckScheduler implements Schedulable {
    
    // 매일 오전 9시에 실행하도록 스케줄링
    // System.schedule('PaymentOverdueCheck', '0 0 9 * * ?', new PaymentOverdueCheckScheduler());
    
    public void execute(SchedulableContext context) {
        // 연체 체크 배치 실행
        PaymentOverdueCheckBatch batch = new PaymentOverdueCheckBatch();
        Database.executeBatch(batch, 50); // 50개씩 처리
    }
    
    /**
     * 스케줄러 등록 메서드 (Developer Console에서 실행)
     */
    public static void scheduleDaily() {
        // 기존 스케줄 삭제
        List<CronTrigger> existingJobs = [
            SELECT Id FROM CronTrigger 
            WHERE CronJobDetail.Name = 'PaymentOverdueCheck' 
            AND State IN ('WAITING', 'ACQUIRED')
        ];
        
        for (CronTrigger job : existingJobs) {
            System.abortJob(job.Id);
        }
        
        // 새 스케줄 등록 (매일 오전 9시)
        String cronExp = '0 0 9 * * ?';
        System.schedule('PaymentOverdueCheck', cronExp, new PaymentOverdueCheckScheduler());
        
        System.debug('PaymentOverdueCheck 스케줄러가 등록되었습니다. (매일 오전 9시 실행)');
    }
}
