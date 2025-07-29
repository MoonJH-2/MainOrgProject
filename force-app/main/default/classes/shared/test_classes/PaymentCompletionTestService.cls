/**
 * @description 완납 시나리오 테스트 서비스
 * @author JH Moon
 * @created 2025-07-27
 */
public with sharing class PaymentCompletionTestService {
    
    /**
     * 완납 시나리오 테스트 실행
     */
    @AuraEnabled
    public static String executePaymentCompletionTest(Id orderId) {
        try {
            System.debug('🎯 =====완납 시나리오 테스트 시작=====');
            System.debug('Order ID: ' + orderId);
            
            // 1. 테스트 전 현재 상태 확인
            PaymentTestResult beforeState = analyzePaymentState(orderId, 'BEFORE');
            
            // 2. 완납 처리 실행
            String completionResult = PaymentStatusTimelineController.markAllPaymentsAsCompleted(orderId);
            System.debug('완납 처리 결과: ' + completionResult);
            
            // 3. 테스트 후 상태 확인
            PaymentTestResult afterState = analyzePaymentState(orderId, 'AFTER');
            
            // 4. 결과 비교 및 검증
            String validationResult = validatePaymentCompletion(beforeState, afterState);
            
            // 5. PDF 생성 테스트
            String pdfGenerationResult = testPDFGeneration(orderId);
            
            // 6. 최종 결과 리포트
            String finalReport = generateTestReport(beforeState, afterState, validationResult, pdfGenerationResult);
            
            System.debug('🎯 =====완납 시나리오 테스트 완료=====');
            
            return finalReport;
            
        } catch (Exception e) {
            String errorMessage = '완납 테스트 실행 중 오류: ' + e.getMessage();
            System.debug('❌ ' + errorMessage);
            throw new AuraHandledException(errorMessage);
        }
    }
    
    /**
     * 납부 상태 분석
     */
    private static PaymentTestResult analyzePaymentState(Id orderId, String phase) {
        PaymentTestResult result = new PaymentTestResult();
        result.phase = phase;
        result.timestamp = System.now();
        
        // Order 정보 조회
        List<Order> orders = [
            SELECT Id, OrderNumber, TotalAmount, Account.Name,
                   (SELECT Id, Product2.Name, Quantity, UnitPrice, TotalPrice FROM OrderItems)
            FROM Order 
            WHERE Id = :orderId 
            LIMIT 1
        ];
        
        if (!orders.isEmpty()) {
            result.orderInfo = orders[0];
        }
        
        // PaymentStatus 조회
        result.paymentStatuses = [
            SELECT Id, Status__c, Amount__c, DueDate__c, Installment_Number__c, PaidDate__c
            FROM PaymentStatus__c
            WHERE Order__c = :orderId
            ORDER BY Installment_Number__c ASC
        ];
        
        // 통계 계산
        result.totalPayments = result.paymentStatuses.size();
        result.completedPayments = 0;
        result.pendingPayments = 0;
        
        for (PaymentStatus__c payment : result.paymentStatuses) {
            if (payment.Status__c == '완납') {
                result.completedPayments++;
            } else {
                result.pendingPayments++;
            }
        }
        
        result.completionRate = result.totalPayments > 0 ? 
            (Decimal.valueOf(result.completedPayments) / result.totalPayments * 100).setScale(1) : 0;
        
        System.debug('📊 ' + phase + ' 상태 분석:');
        System.debug('   총 납부 항목: ' + result.totalPayments);
        System.debug('   완납: ' + result.completedPayments);
        System.debug('   미납: ' + result.pendingPayments);
        System.debug('   완납률: ' + result.completionRate + '%');
        
        return result;
    }
    
    /**
     * 완납 처리 검증
     */
    private static String validatePaymentCompletion(PaymentTestResult before, PaymentTestResult after) {
        List<String> validationResults = new List<String>();
        
        // 1. 완납 상태 변경 검증
        if (after.completedPayments > before.completedPayments) {
            validationResults.add('✅ 완납 상태 변경: ' + before.completedPayments + ' → ' + after.completedPayments);
        } else {
            validationResults.add('❌ 완납 상태 변경 실패');
        }
        
        // 2. 완납률 검증
        if (after.completionRate == 100) {
            validationResults.add('✅ 완납률 100% 달성');
        } else {
            validationResults.add('⚠️ 완납률: ' + after.completionRate + '%');
        }
        
        // 3. 미납 항목 검증
        if (after.pendingPayments == 0) {
            validationResults.add('✅ 모든 미납 항목 해결');
        } else {
            validationResults.add('❌ 여전히 ' + after.pendingPayments + '개 미납 항목 존재');
        }
        
        return String.join(validationResults, '\n');
    }
    
    /**
     * PDF 생성 테스트
     */
    private static String testPDFGeneration(Id orderId) {
        try {
            String pdfId = PaymentStatusTimelineController.generatePaymentSchedulePDF(orderId);
            
            // 생성된 PDF 파일 확인
            List<ContentVersion> generatedPDFs = [
                SELECT Id, Title, ContentSize, CreatedDate
                FROM ContentVersion
                WHERE FirstPublishLocationId = :orderId
                AND CreatedDate = TODAY
                ORDER BY CreatedDate DESC
                LIMIT 10
            ];
            
            List<String> pdfResults = new List<String>();
            pdfResults.add('✅ PDF 생성 성공: ' + generatedPDFs.size() + '개 파일');
            
            for (ContentVersion pdf : generatedPDFs) {
                String fileType = '';
                if (pdf.Title.contains('납부확인서')) {
                    fileType = '[납부확인서]';
                } else if (pdf.Title.contains('세금계산서')) {
                    fileType = '[세금계산서]';
                }
                pdfResults.add('  • ' + pdf.Title + ' ' + fileType + ' (' + (pdf.ContentSize/1024) + 'KB)');
            }
            
            return String.join(pdfResults, '\n');
            
        } catch (Exception e) {
            return '❌ PDF 생성 테스트 실패: ' + e.getMessage();
        }
    }
    
    /**
     * 테스트 리포트 생성
     */
    private static String generateTestReport(PaymentTestResult before, PaymentTestResult after, 
                                           String validation, String pdfTest) {
        List<String> report = new List<String>();
        
        report.add('🎯 완납 시나리오 테스트 결과 리포트');
        report.add('═══════════════════════════════════');
        report.add('');
        report.add('📋 Order 정보:');
        if (before.orderInfo != null) {
            report.add('  • Order Number: ' + before.orderInfo.OrderNumber);
            report.add('  • Customer: ' + before.orderInfo.Account.Name);
            report.add('  • Total Amount: ₩' + before.orderInfo.TotalAmount?.format());
        }
        report.add('');
        
        report.add('📊 납부 상태 변화:');
        report.add('  BEFORE → AFTER');
        report.add('  • 총 납부 항목: ' + before.totalPayments + ' → ' + after.totalPayments);
        report.add('  • 완납: ' + before.completedPayments + ' → ' + after.completedPayments);
        report.add('  • 미납: ' + before.pendingPayments + ' → ' + after.pendingPayments);
        report.add('  • 완납률: ' + before.completionRate + '% → ' + after.completionRate + '%');
        report.add('');
        
        report.add('✅ 검증 결과:');
        report.add(validation);
        report.add('');
        
        report.add('📄 PDF 생성 테스트:');
        report.add(pdfTest);
        report.add('');
        
        report.add('⏰ 테스트 완료 시간: ' + System.now().format('yyyy-MM-dd HH:mm:ss'));
        report.add('═══════════════════════════════════');
        
        return String.join(report, '\n');
    }
    
    /**
     * 테스트 결과 래퍼 클래스
     */
    public class PaymentTestResult {
        public String phase;
        public DateTime timestamp;
        public Order orderInfo;
        public List<PaymentStatus__c> paymentStatuses;
        public Integer totalPayments;
        public Integer completedPayments;
        public Integer pendingPayments;
        public Decimal completionRate;
    }
}
