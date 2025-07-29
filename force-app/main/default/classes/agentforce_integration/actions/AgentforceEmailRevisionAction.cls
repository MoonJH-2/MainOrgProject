/**
 * @description Agentforce Email Revision Action
 * @author AI Assistant
 * @created 2025-07-24
 */
public with sharing class AgentforceEmailRevisionAction {
    
    /**
     * 이메일 초안 수정 및 개선
     */
    @InvocableMethod(label='Revise Email Draft' description='기존 이메일 초안을 수정하고 개선합니다')
    public static List<EmailRevisionResult> reviseEmailDraft(List<EmailRevisionRequest> requests) {
        List<EmailRevisionResult> results = new List<EmailRevisionResult>();
        
        for(EmailRevisionRequest request : requests) {
            EmailRevisionResult result = new EmailRevisionResult();
            
            try {
                // 수정 요청에 따른 이메일 개선
                String revisedSubject = reviseEmailSubject(request);
                String revisedBody = reviseEmailBody(request);
                
                result.revisedSubject = revisedSubject;
                result.revisedBody = revisedBody;
                result.revisionType = request.revisionType;
                result.originalSubject = request.originalSubject;
                result.originalBody = request.originalBody;
                result.success = true;
                
            } catch(Exception e) {
                result.success = false;
                result.errorMessage = '이메일 수정 중 오류: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    // Helper Methods
    private static String reviseEmailSubject(EmailRevisionRequest request) {
        String revisedSubject = request.originalSubject;
        
        switch on request.revisionType {
            when 'Make_Urgent' {
                if(!revisedSubject.contains('[긴급]')) {
                    revisedSubject = '[긴급] ' + revisedSubject;
                }
            }
            when 'Make_Formal' {
                revisedSubject = revisedSubject.replace('[안내]', '[공식 안내]');
                if(!revisedSubject.contains('귀하')) {
                    revisedSubject = revisedSubject.replace('님', '귀하');
                }
            }
            when 'Make_Friendly' {
                revisedSubject = revisedSubject.replace('[공식 안내]', '[안내]');
                revisedSubject = revisedSubject.replace('귀하', '님');
                if(!revisedSubject.contains('😊')) {
                    revisedSubject = revisedSubject + ' 😊';
                }
            }
            when 'Add_Action_Required' {
                if(!revisedSubject.contains('[조치 필요]')) {
                    revisedSubject = '[조치 필요] ' + revisedSubject;
                }
            }
            when 'Shorten' {
                // 제목 간소화
                revisedSubject = revisedSubject.replace('안내드립니다', '안내');
                revisedSubject = revisedSubject.replace('알려드립니다', '알림');
            }
        }
        
        return revisedSubject;
    }
    
    private static String reviseEmailBody(EmailRevisionRequest request) {
        String revisedBody = request.originalBody;
        
        switch on request.revisionType {
            when 'Make_Urgent' {
                revisedBody = addUrgentTone(revisedBody, request.revisionInstructions);
            }
            when 'Make_Formal' {
                revisedBody = makeFormalTone(revisedBody, request.revisionInstructions);
            }
            when 'Make_Friendly' {
                revisedBody = makeFriendlyTone(revisedBody, request.revisionInstructions);
            }
            when 'Add_Details' {
                revisedBody = addMoreDetails(revisedBody, request.revisionInstructions);
            }
            when 'Shorten' {
                revisedBody = shortenContent(revisedBody, request.revisionInstructions);
            }
            when 'Add_Action_Required' {
                revisedBody = addActionItems(revisedBody, request.revisionInstructions);
            }
            when 'Custom' {
                revisedBody = applyCustomRevisions(revisedBody, request.revisionInstructions);
            }
        }
        
        return revisedBody;
    }
    
    private static String addUrgentTone(String originalBody, String instructions) {
        String urgentBody = originalBody;
        
        // 긴급성 표현 추가
        urgentBody = urgentBody.replace('안내드립니다', '긴급히 안내드립니다');
        urgentBody = urgentBody.replace('연락주세요', '즉시 연락주세요');
        
        // 긴급 아이콘 추가
        if(!urgentBody.contains('🚨')) {
            urgentBody = '🚨 긴급 안내 🚨\n\n' + urgentBody;
        }
        
        // 마감일 강조
        if(instructions != null && instructions.contains('마감일')) {
            urgentBody = urgentBody + '\n\n⏰ 마감일이 임박했습니다. 빠른 조치 부탁드립니다.';
        }
        
        return urgentBody;
    }
    
    private static String makeFormalTone(String originalBody, String instructions) {
        String formalBody = originalBody;
        
        // 정중한 표현으로 변경
        formalBody = formalBody.replace('안녕하세요', '안녕하십니까');
        formalBody = formalBody.replace('감사합니다', '감사드립니다');
        formalBody = formalBody.replace('연락주세요', '연락주시기 바랍니다');
        formalBody = formalBody.replace('부탁드립니다', '부탁드리겠습니다');
        
        // 존댓말 강화
        formalBody = formalBody.replace('해 주세요', '해 주시기 바랍니다');
        formalBody = formalBody.replace('확인해', '확인하여 주시기');
        
        return formalBody;
    }
    
    private static String makeFriendlyTone(String originalBody, String instructions) {
        String friendlyBody = originalBody;
        
        // 친근한 표현 추가
        if(!friendlyBody.contains('😊')) {
            friendlyBody = friendlyBody.replace('안녕하세요', '안녕하세요 😊');
        }
        
        // 감정 표현 추가
        friendlyBody = friendlyBody.replace('감사합니다', '감사합니다! 🙏');
        friendlyBody = friendlyBody.replace('연락주세요', '언제든 편하게 연락주세요');
        
        // 이모지 적절히 추가
        if(friendlyBody.contains('완료')) {
            friendlyBody = friendlyBody.replace('완료', '완료 ✅');
        }
        
        return friendlyBody;
    }
    
    private static String addMoreDetails(String originalBody, String instructions) {
        String detailedBody = originalBody;
        
        // 상세 정보 섹션 추가
        if(instructions != null) {
            String additionalInfo = '\n\n📋 추가 상세 정보:\n';
            additionalInfo += '• ' + instructions + '\n';
            additionalInfo += '• 문의사항이 있으시면 언제든 연락주세요\n';
            additionalInfo += '• 관련 문서나 자료가 필요하시면 제공해 드리겠습니다\n';
            
            detailedBody = detailedBody + additionalInfo;
        }
        
        return detailedBody;
    }
    
    private static String shortenContent(String originalBody, String instructions) {
        String shortenedBody = originalBody;
        
        // 불필요한 문구 제거
        shortenedBody = shortenedBody.replace('안내드립니다.', '안내.');
        shortenedBody = shortenedBody.replace('부탁드립니다.', '부탁드림.');
        shortenedBody = shortenedBody.replace('감사합니다.', '감사.');
        
        // 중복 표현 제거
        shortenedBody = shortenedBody.replaceAll('\\n\\n\\n+', '\n\n');
        
        return shortenedBody;
    }
    
    private static String addActionItems(String originalBody, String instructions) {
        String actionBody = originalBody;
        
        // 액션 아이템 섹션 추가
        String actionSection = '\n\n✅ 필요한 조치사항:\n';
        
        if(instructions != null && instructions.length() > 0) {
            actionSection += '• ' + instructions + '\n';
        }
        
        actionSection += '• 회신 기한: 영업일 기준 2일 이내\n';
        actionSection += '• 담당자 연락처로 진행상황 공유 부탁드립니다\n';
        
        actionBody = actionBody + actionSection;
        
        return actionBody;
    }
    
    private static String applyCustomRevisions(String originalBody, String instructions) {
        String customBody = originalBody;
        
        if(instructions != null && instructions.length() > 0) {
            // 맞춤 수정 지시사항 적용
            customBody = customBody + '\n\n📝 맞춤 수정사항:\n';
            customBody = customBody + instructions + '\n';
        }
        
        return customBody;
    }
    
    // Input/Output Classes
    public class EmailRevisionRequest {
        @InvocableVariable(required=true)
        public String originalSubject;
        @InvocableVariable(required=true)
        public String originalBody;
        @InvocableVariable(required=true)
        public String revisionType; // Make_Urgent, Make_Formal, Make_Friendly, Add_Details, Shorten, Add_Action_Required, Custom
        @InvocableVariable
        public String revisionInstructions; // 구체적인 수정 지시사항
    }
    
    public class EmailRevisionResult {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String errorMessage;
        @InvocableVariable
        public String revisedSubject;
        @InvocableVariable
        public String revisedBody;
        @InvocableVariable
        public String revisionType;
        @InvocableVariable
        public String originalSubject;
        @InvocableVariable
        public String originalBody;
    }
}
