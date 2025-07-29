/**
 * @description       : 자정 연체 전환 체크 스케줄러
 * @author            : JH Moon
 * @last modified on  : 07-17-2025
 * @last modified by  : JH Moon
**/
public class PaymentMidnightOverdueScheduler implements Schedulable {
    
    // 매일 자정에 실행하도록 스케줄링
    // System.schedule('PaymentMidnightOverdueCheck', '0 0 0 * * ?', new PaymentMidnightOverdueScheduler());
    
    public void execute(SchedulableContext context) {
        // 자정에 연체 전환 체크
        PaymentOverdueService.dailyOverdueCheck();
    }
    
    /**
     * 자정 스케줄러 등록 메서드
     */
    public static void scheduleMidnightCheck() {
        // 기존 스케줄 삭제
        List<CronTrigger> existingJobs = [
            SELECT Id FROM CronTrigger 
            WHERE CronJobDetail.Name = 'PaymentMidnightOverdueCheck' 
            AND State IN ('WAITING', 'ACQUIRED')
        ];
        
        for (CronTrigger job : existingJobs) {
            System.abortJob(job.Id);
        }
        
        // 새 스케줄 등록 (매일 자정)
        String cronExp = '0 0 0 * * ?';
        System.schedule('PaymentMidnightOverdueCheck', cronExp, new PaymentMidnightOverdueScheduler());
        
        System.debug('PaymentMidnightOverdueCheck 스케줄러가 등록되었습니다. (매일 자정 실행)');
    }
}
