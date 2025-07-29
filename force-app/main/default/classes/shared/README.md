# 🔧 Shared Components Domain

## 🎯 목적
프로젝트 전반에서 공통으로 사용되는 기본 클래스들, 유틸리티, 공통 기능들을 관리하는 도메인입니다.

## 📁 폴더 구조

### 🏗️ base/
기본 추상 클래스 및 인터페이스들
- `TriggerHandler.cls`: 모든 트리거 핸들러의 기본 클래스
- `TriggerManager.cls`: 트리거 관리 및 실행 제어

### 🛠️ utils/
공통 유틸리티 클래스들
- `WrapperUtils.cls`: 공통 래퍼 및 응답 객체들
- `SearchAddressModalController.cls`: 주소 검색 모달
- `BusinessNumberCheckModalController.cls`: 사업자번호 확인 모달
- `QuoteCloneModalController.cls`: 견적서 복제 모달
- `PerformanceTrackingService.cls`: 성능 추적 서비스

### 📊 wrappers/
공통 데이터 래퍼 클래스들
- 응답 객체 표준화
- API 호출 결과 래핑
- 에러 처리 표준화

### ⚠️ exceptions/
커스텀 예외 클래스들
- 비즈니스 로직 예외
- 데이터 검증 예외
- 외부 연동 예외

## 🎯 설계 원칙

### 📋 Trigger Handler Pattern
```apex
public abstract class TriggerHandler {
    // 모든 트리거의 표준 라이프사이클 관리
    protected abstract void beforeInsert(List<SObject> newRecords);
    protected abstract void afterInsert(List<SObject> newRecords);
    protected abstract void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords);
    protected abstract void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords);
}
```

### 🔄 Response Wrapper Pattern
```apex
public class ResponseWrapper {
    @AuraEnabled public Boolean isSuccess { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public Object data { get; set; }
    @AuraEnabled public String errorCode { get; set; }
}
```

### 📊 Performance Tracking
```apex
public class PerformanceTracker {
    public static void startTracking(String operationName);
    public static void endTracking(String operationName);
    public static PerformanceResult getResults();
}
```

## 🔧 공통 기능

### 1️⃣ 에러 처리 표준화
- 일관된 에러 메시지 포맷
- 로깅 표준화
- 사용자 친화적 에러 응답

### 2️⃣ 데이터 검증
- 입력값 검증 유틸리티
- 비즈니스 규칙 검증
- 보안 검증

### 3️⃣ 성능 모니터링
- 실행 시간 측정
- 메모리 사용량 추적
- Governor Limits 모니터링

### 4️⃣ 로깅 & 디버깅
- 구조화된 로그 포맷
- 디버그 레벨 관리
- 운영 환경 모니터링

## 🤝 사용 가이드라인

### ✅ 사용해야 하는 경우
- 여러 도메인에서 공통으로 사용되는 기능
- 플랫폼 표준을 확장하는 기능
- 성능 및 보안 관련 공통 요구사항

### ❌ 사용하지 말아야 하는 경우
- 특정 도메인에만 국한된 기능
- 비즈니스 로직이 포함된 기능
- 자주 변경될 가능성이 있는 기능

## 📞 담당자
- **Lead Architect**: Moon JeongHyeon
- **Platform Team**: Shared Components Team
