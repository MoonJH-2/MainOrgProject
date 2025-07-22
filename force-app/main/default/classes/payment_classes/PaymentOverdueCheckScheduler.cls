/**
 * @description       : 연체 체크 보완 배치 스케줄러 (즉시 처리는 트리거에서 수행)
 * @author            : JH Moon
 * @last modified on  : 07-17-2025
 * @last modified by  : JH Moon
**/
public class PaymentOverdueCheckScheduler implements Schedulable {
    
    // 매일 오전 9시에 실행하도록 스케줄링 (보완적 체크용)
    // System.schedule('PaymentOverdueCheck', '0 0 9 * * ?', new PaymentOverdueCheckScheduler());
    
    public void execute(SchedulableContext context) {
        // 연체 체크 배치 실행 (놓친 연체 건들 보완 처리)
        PaymentOverdueCheckBatch batch = new PaymentOverdueCheckBatch();
        Database.executeBatch(batch, 50); // 50개씩 처리
    }
    
    /**
     * 스케줄러 등록 메서드 (Developer Console에서 실행)
     * 오전 9시 배치는 놓친 연체 건들을 보완적으로 처리
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
        
        // 새 스케줄 등록 (매일 오전 9시 - 보완적 체크)
        String cronExp = '0 0 9 * * ?';
        System.schedule('PaymentOverdueCheck', cronExp, new PaymentOverdueCheckScheduler());
        
        System.debug('PaymentOverdueCheck 스케줄러가 등록되었습니다. (매일 오전 9시 보완 체크)');
    }
    
    /**
     * 즉시 연체 처리를 위한 자정 스케줄러 및 오전 9시 보완 스케줄러를 함께 등록
     */
    public static void setupComprehensiveScheduling() {
        // 자정 스케줄러 등록 (즉시 연체 처리)
        PaymentMidnightOverdueScheduler.scheduleMidnightCheck();
        
        // 오전 9시 보완 스케줄러 등록
        scheduleDaily();
        
        System.debug('연체 처리 시스템이 완전히 설정되었습니다:');
        System.debug('- 자정: 즉시 연체 전환 처리');
        System.debug('- 오전 9시: 놓친 연체 건들 보완 처리');
        System.debug('- 실시간: 트리거를 통한 즉시 처리');
    }
}
