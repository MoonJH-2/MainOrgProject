/**
 * @description Agentforce Asset Renewal Email Action
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceAssetEmailAction {
    
    /**
     * Asset 갱신 이메일 초안 생성
     */
    @InvocableMethod(label='Draft Asset Renewal Email' description='Asset 갱신 및 관련 이메일 초안을 생성합니다')
    public static List<EmailDraftResult> draftAssetRenewalEmail(List<AssetEmailRequest> requests) {
        List<EmailDraftResult> results = new List<EmailDraftResult>();
        
        for(AssetEmailRequest request : requests) {
            EmailDraftResult result = new EmailDraftResult();
            
            try {
                // Asset 정보 조회
                List<Asset> assets = [
                    SELECT Id, Name, Account.Name, Account.Id, Product2.Name,
                           SerialNumber, InstallDate, UsageEndDate, Status,
                           ContactId, Contact.Email, Contact.Name,
                           AccountId, CreatedBy.Name, CreatedBy.Email
                    FROM Asset 
                    WHERE Id = :request.assetId 
                    LIMIT 1
                ];
                
                if(assets.isEmpty()) {
                    result.success = false;
                    result.errorMessage = 'Asset을 찾을 수 없습니다.';
                    results.add(result);
                    continue;
                }
                
                Asset assetRecord = assets[0];
                
                // 이메일 템플릿 생성
                String emailSubject = generateAssetEmailSubject(assetRecord, request.emailType);
                String emailBody = generateAssetEmailBody(assetRecord, request.emailType);
                
                result.emailSubject = emailSubject;
                result.emailBody = emailBody;
                result.recipientEmail = getAssetRecipientEmail(assetRecord);
                result.emailType = request.emailType;
                result.assetName = assetRecord.Name;
                result.success = true;
                
            } catch(Exception e) {
                result.success = false;
                result.errorMessage = 'Asset 이메일 생성 중 오류: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Helper Methods
    private static String generateAssetEmailSubject(Asset assetRecord, String emailType) {
        String assetName = assetRecord.Name;
        String productName = assetRecord.Product2.Name;
        String subject = '';
        
        switch on emailType {
            when 'Renewal_Reminder' {
                subject = '[갱신 안내] ' + productName + ' (' + assetName + ') 갱신 시기 안내';
            }
            when 'Maintenance_Schedule' {
                subject = '[정비 일정] ' + productName + ' (' + assetName + ') 정기 정비 안내';
            }
            when 'Usage_Report' {
                subject = '[사용 현황] ' + productName + ' (' + assetName + ') 월간 사용 리포트';
            }
            when 'Contract_Expiry' {
                subject = '[계약 만료] ' + productName + ' (' + assetName + ') 계약 만료 임박 안내';
            }
            when else {
                subject = '[Asset 안내] ' + productName + ' (' + assetName + ') 관련 안내';
            }
        }
        
        return subject;
    }
    
    private static String generateAssetEmailBody(Asset assetRecord, String emailType) {
        String body = '';
        String accountName = assetRecord.Account.Name;
        String assetName = assetRecord.Name;
        String productName = assetRecord.Product2.Name;
        String ownerName = assetRecord.CreatedBy.Name;
        
        body += '안녕하세요, ' + accountName + ' 담당자님\n\n';
        body += '담당 영업사원 ' + ownerName + '입니다.\n\n';
        
        switch on emailType {
            when 'Renewal_Reminder' {
                Date expiryDate = assetRecord.UsageEndDate;
                
                body += '🔄 Asset 갱신 시기가 다가와 안내드립니다.\n\n';
                body += 'Asset 정보:\n';
                body += '• 제품명: ' + productName + '\n';
                body += '• Asset명: ' + assetName + '\n';
                body += '• 시리얼: ' + assetRecord.SerialNumber + '\n';
                if(expiryDate != null) {
                    body += '• 만료예정일: ' + expiryDate.format() + '\n';
                }
                body += '\n갱신 절차 및 조건에 대해 상담을 진행하겠습니다.\n';
                body += '편리한 시간에 연락 부탁드립니다.\n';
            }
            when 'Maintenance_Schedule' {
                Date installDate = assetRecord.InstallDate;
                
                body += '🔧 정기 정비 일정을 안내드립니다.\n\n';
                body += '정비 대상:\n';
                body += '• 제품명: ' + productName + '\n';
                body += '• Asset명: ' + assetName + '\n';
                if(installDate != null) {
                    body += '• 설치일: ' + installDate.format() + '\n';
                }
                body += '\n최적의 성능 유지를 위해 정기 정비가 필요합니다.\n';
                body += '정비 일정 조율을 위해 연락드리겠습니다.\n';
            }
            when 'Usage_Report' {
                body += '📊 월간 사용 현황을 리포트해 드립니다.\n\n';
                body += '사용 현황:\n';
                body += '• 제품명: ' + productName + '\n';
                body += '• Asset명: ' + assetName + '\n';
                body += '• 상태: ' + assetRecord.Status + '\n';
                body += '\n자세한 사용 데이터는 첨부 파일을 확인해 주세요.\n';
                body += '추가 분석이나 최적화 상담이 필요하시면 연락주세요.\n';
            }
            when 'Contract_Expiry' {
                body += '⚠️ 계약 만료가 임박하여 안내드립니다.\n\n';
                body += '만료 예정 Asset:\n';
                body += '• 제품명: ' + productName + '\n';
                body += '• Asset명: ' + assetName + '\n';
                body += '\n서비스 연속성을 위해 계약 연장 또는 신규 도입을 검토해 주세요.\n';
                body += '맞춤형 제안을 준비하여 연락드리겠습니다.\n';
            }
        }
        
        body += '\n감사합니다.\n';
        body += ownerName + '\n';
        body += '문의: ' + assetRecord.CreatedBy.Email;
        
        return body;
    }
    
    private static String getAssetRecipientEmail(Asset assetRecord) {
        if(assetRecord.Contact != null && assetRecord.Contact.Email != null) {
            return assetRecord.Contact.Email;
        }
        // Fallback to Account 담당자 이메일 (실제로는 Contact에서 조회)
        return 'assets@example.com'; // placeholder
    }
    
    // Input/Output Classes
    public class AssetEmailRequest {
        @InvocableVariable(required=true)
        public String assetId;
        @InvocableVariable(required=true)
        public String emailType; // Renewal_Reminder, Maintenance_Schedule, Usage_Report, Contract_Expiry
    }
    
    public class EmailDraftResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String errorMessage;
        @InvocableVariable
        public String emailSubject;
        @InvocableVariable
        public String emailBody;
        @InvocableVariable
        public String recipientEmail;
        @InvocableVariable
        public String emailType;
        @InvocableVariable
        public String assetName;
    }
}
