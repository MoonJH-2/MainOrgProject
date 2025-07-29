# 🏢 Account Triggers

## 🎯 목적
Account(고객사) 관련 모든 Triggers를 관리하는 영역입니다.

## ⚡ 포함된 트리거들

### 🔄 **AccountTrigger.trigger**
- **대상 객체**: Account
- **트리거 이벤트**: before insert, before update, after insert, after update
- **핸들러**: AccountTriggerHandler
- **주요 기능**:
  - Account 생성/수정 시 데이터 검증
  - 비즈니스 로직 실행
  - TriggerManager 패턴 사용

### 📊 **트리거 설정**
```apex
trigger AccountTrigger on Account (
    before insert, before update, 
    after insert, after update
) {
    TriggerManager.prepare()
        .bind(new AccountTriggerHandler())
        .execute();
}
```

## 🔗 연관 컴포넌트
- **Handler**: AccountTriggerHandler (classes/account_domain/)
- **Manager**: TriggerManager (shared framework)
- **Related Objects**: Account (Salesforce 표준 객체)

## 📈 비즈니스 로직
- Account 생성 시 기본값 설정
- Account 수정 시 유효성 검사
- 하위 객체들과의 연관관계 관리

## 📞 담당자
- **Lead Developer**: Hyowon Hong
- **Business Team**: Account Management Team

## 📝 사용 가이드
Account 관련 새로운 트리거 로직 추가 시 AccountTriggerHandler 클래스를 수정하여 기능을 확장하세요.
