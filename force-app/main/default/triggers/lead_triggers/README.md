# 👥 Lead Triggers

## 🎯 목적
Lead(리드) 관련 모든 Triggers를 관리하는 영역입니다.

## ⚡ 포함된 트리거들

### 🔄 **LeadTrigger.trigger**
- **대상 객체**: Lead
- **트리거 이벤트**: before insert
- **핸들러**: LeadTriggerHandler
- **주요 기능**:
  - Lead 생성 시 소유자 자동 할당
  - 신규 리드 처리 로직

### 👤 **LeadAssignRepTrigger.trigger**
- **대상 객체**: Lead
- **트리거 이벤트**: before insert, before update
- **주요 기능**:
  - Lead 담당자 자동 배정
  - 지역별/조건별 담당자 할당 로직

### 📊 **트리거 설정**
```apex
// LeadTrigger - 기본 Lead 처리
trigger LeadTrigger on Lead (before insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            LeadTriggerHandler.assignLeadOwnerOnInsert(Trigger.new);
        }
    }
}

// LeadAssignRepTrigger - 담당자 배정
trigger LeadAssignRepTrigger on Lead (before insert, before update) {
    // 담당자 배정 로직
}
```

## 🔗 연관 컴포넌트
- **Handler**: LeadTriggerHandler (classes/lead_domain/)
- **Related Objects**: Lead (Salesforce 표준 객체)
- **User Assignment**: User 객체와 연동

## 📈 비즈니스 로직
- 신규 리드 생성 시 담당자 자동 배정
- 지역별 담당자 할당 규칙 적용
- 리드 상태 변경에 따른 후속 처리

## 📞 담당자
- **Lead Developer**: Moon JeongHyeon
- **Sales Team**: Lead Management Team

## 📝 사용 가이드
리드 할당 규칙 변경이나 새로운 리드 처리 로직 추가 시 해당 핸들러 클래스를 수정하세요.
