# SFDX 배포 오류 해결 가이드

## 일반적인 오류 유형 및 해결 방법

### 1. Lightning Component Bundle 오류
**오류**: `Cannot find Lightning Component Bundle [componentName]`
**원인**: 컴포넌트 파일이 누락되거나 메타데이터 파일에 문제가 있음
**해결방법**:
```bash
# 컴포넌트 구조 확인
sf project generate manifest --source-dir force-app/main/default/lwc

# 개별 컴포넌트 배포
sf project deploy start -d force-app/main/default/lwc/[componentName]
```

### 2. Apex 메서드 참조 오류
**오류**: `'[ClassName.methodName]'(으)로 지칭되는 Apex 작업 메서드를 찾을 수 없습니다`
**원인**: Apex 클래스가 배포되지 않았거나 메서드명이 틀림
**해결방법**:
```bash
# Apex 클래스 먼저 배포
sf project deploy start -d force-app/main/default/classes/[ClassName].cls

# 전체 순서대로 배포
sf project deploy start -d force-app/main/default/classes
sf project deploy start -d force-app/main/default/lwc
```

### 3. 사용자 정의 필드 오류
**오류**: `No such column '[FieldName]' on entity '[ObjectName]'`
**원인**: 사용자 정의 필드가 생성되지 않았거나 API명이 틀림
**해결방법**:
- Setup → Object Manager에서 필드 확인
- API명에 `__c` 접미사 확인
- 필드 권한 및 가시성 확인

### 4. HTML 구문 오류
**오류**: `LWC1058: Invalid HTML syntax: missing-whitespace-between-attributes`
**원인**: HTML 속성 사이에 공백이 없음
**해결방법**:
```html
<!-- 잘못된 예 -->
<div class="slds-card"data-id="123">

<!-- 올바른 예 -->
<div class="slds-card" data-id="123">
```

## 배포 순서 권장사항

1. **메타데이터 객체** (Custom Objects, Fields)
2. **Apex 클래스** (Controllers, Services)
3. **Lightning Web Components**
4. **Permission Sets & Profiles**
5. **Flows & Process Builder**

## 배포 전 체크리스트

- [ ] 모든 의존성 확인
- [ ] 코드 구문 검사
- [ ] 테스트 클래스 작성 (Apex의 경우)
- [ ] 메타데이터 파일 검증
- [ ] 권한 설정 확인

## 유용한 명령어

```bash
# 현재 org 상태 확인
sf org display

# 배포 전 검증
sf project deploy validate -d [directory]

# 특정 컴포넌트만 배포
sf project deploy start -m "LightningComponentBundle:[componentName]"

# 배포 상태 확인
sf project deploy report

# 오류 로그 확인
sf project deploy report --verbose
```

## 디버깅 팁

1. **VS Code 출력 창 확인**: View → Output → Salesforce CLI
2. **단계적 배포**: 하나씩 배포하여 문제 원인 파악
3. **메타데이터 API 버전 확인**: 프로젝트 설정과 org 버전 호환성
4. **브라우저 개발자 도구**: LWC 런타임 오류 확인
