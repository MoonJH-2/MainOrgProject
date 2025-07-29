public class OpportunityCloseNotificationService {

    @InvocableMethod(label='Send Close Notification to Manager' description='Sends an email to the Opportunity Owner\'s Manager when an Opportunity is closed.')
    public static void notifyManagerOnOpportunityClose(List<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }

        // 단일 Opportunity 처리 (Flow에서 단건 호출 기준)
        Opportunity opp = [
            SELECT Id, Name, OwnerId, Owner.Name, Owner.ManagerId, Owner.Manager.Email, Owner.Manager.Name
            FROM Opportunity
            WHERE Id = :opportunityIds[0]
            LIMIT 1
        ];

        // 매니저 정보가 존재하지 않으면 중단
        if (opp == null || opp.OwnerId == null || opp.Owner.ManagerId == null || opp.Owner.Manager.Email == null) {
            System.debug('필수 정보가 누락되어 이메일을 보낼 수 없습니다.');
            return;
        }

        User manager = opp.Owner.Manager;
        String opportunityLink = System.URL.getOrgDomainUrl().toExternalForm() + '/' + opp.Id;

        // 이메일 알림 생성
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { manager.Email });
        email.setSubject('[Salesforce 알림] Opportunity 종결 알림: ' + opp.Name);

        String emailBody = '안녕하세요, ' + manager.Name + ' 매니저님.<br/><br/>' +
            '귀하의 팀원 ' + opp.Owner.Name + ' 님께서 Opportunity를 종결하였습니다.<br/><br/>' +
            'Opportunity 이름: ' + opp.Name + '<br/>' +
            'Opportunity 링크: <a href="' + opportunityLink + '">' + opp.Name + ' 바로가기</a><br/><br/>' +
            '확인 부탁드립니다.<br/><br/>감사합니다.';

        email.setHtmlBody(emailBody);
        email.setSaveAsActivity(false);

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('이메일 전송 완료: ' + manager.Email);
        } catch (Exception e) {
            System.debug('이메일 전송 실패: ' + e.getMessage());
        }
    }
}