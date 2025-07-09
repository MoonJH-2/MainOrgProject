/**
 * @description 리드(Lead) 객체에서 발생하는 이벤트를 감지하고,
 * LeadTriggerHandler를 호출하여 실제 로직 처리를 위임합니다.
 */
trigger LeadTrigger on Lead (before insert) {

    // 스위치(Switch) 문을 사용하여 어떤 이벤트가 발생했는지 확인합니다.
    // 이렇게 하면 나중에 'before update', 'after insert' 등 다른 이벤트를 추가하기 편리합니다.
    switch on Trigger.operationType {
        // 리드가 데이터베이스에 저장되기 직전(before insert)에
        when BEFORE_INSERT {
            // LeadTriggerHandler 클래스의 assignLeadOwnerOnInsert 메소드를 호출합니다.
            // Trigger.new는 방금 생성 시도 중인 리드들의 목록입니다.
            LeadTriggerHandler.assignLeadOwnerOnInsert(Trigger.new);
        }

        // when BEFORE_UPDATE {
        //     // 나중에 업데이트 시 로직을 추가할 수 있는 공간입니다.
        // }
    }
}