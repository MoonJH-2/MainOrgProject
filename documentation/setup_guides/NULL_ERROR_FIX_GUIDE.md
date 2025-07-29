# 🚨 "Argument cannot be null" 오류 해결 가이드

## 🔍 문제 분석 결과

### 확인된 문제점:
1. **부분적 데이터 로딩**: Assets 우선순위는 작동하지만 성과 추적 대시보드는 실패
2. **Null 참조 오류**: JavaScript에서 undefined 객체를 참조하려 시도
3. **불완전한 테스트 데이터**: 일부 필수 필드 누락

## 🛠️ 해결 단계 (순서대로 실행)

### 1단계: 오류 진단 실행
```
Developer Console > Execute Anonymous
파일: error_diagnosis.apex 실행
목적: 정확한 오류 원인 파악
```

### 2단계: 데이터 정리 및 재생성
```
Developer Console > Execute Anonymous  
파일: fix_null_error.apex 실행
목적: 안전한 완전 데이터 생성
```

### 3단계: 컴포넌트 배포
```
VS Code > Salesforce CLI
명령어: sfdx force:source:deploy -p force-app/main/default/lwc/performanceTrackingSimple
목적: 강화된 null 처리 로직 배포
```

### 4단계: 대시보드 새로고침
```
Salesforce > Apps > Sales > Assets Performance
새로고침 버튼 클릭 또는 페이지 리로드
```

## 🎯 예상 해결 결과

### 해결 후 화면:
✅ **성과 추적 대시보드**: 정상 로딩  
✅ **오늘의 예상 매출**: 4,050만원 표시  
✅ **월간 갱신 현황**: 완료 1건, 진행 1건  
✅ **고객 건강도**: 실제 퍼센트 표시  
✅ **원클릭 갱신**: "갱신 가능한 Asset" 1건 표시  
✅ **레벨 시스템**: 실버 달성 표시  

### 핵심 개선사항:
- **Null 안전성**: 모든 데이터 필드에 기본값 설정
- **오류 처리**: 친화적인 에러 메시지 표시
- **데이터 검증**: 필수 필드 완전성 확인
- **실시간 복구**: 오류 발생 시 기본값으로 fallback

## 🚨 만약 여전히 오류가 발생한다면

### A. 권한 문제
```apex
// 권한 확인 스크립트
System.debug('현재 사용자: ' + UserInfo.getName());
System.debug('Profile: ' + [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name);
System.debug('Asset CRUD: ' + Schema.sObjectType.Asset.isCreateable());
System.debug('Opportunity CRUD: ' + Schema.sObjectType.Opportunity.isCreateable());
```

### B. 브라우저 캐시 문제
1. 하드 새로고침: `Ctrl+Shift+R` (Windows) 또는 `Cmd+Shift+R` (Mac)
2. 브라우저 캐시 전체 삭제
3. 시크릿/incognito 모드에서 접속

### C. Salesforce 환경 문제
1. Setup > Deployment Status 확인
2. Lightning Experience 모드 확인
3. 다른 브라우저에서 테스트

## 📞 추가 디버깅

오류가 지속되면 다음 정보를 수집:

```apex
// 상세 디버깅 정보
try {
    PerformanceTrackingServiceSimple.getDashboardData();
} catch(Exception e) {
    System.debug('Apex Error: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
    System.debug('Line Number: ' + e.getLineNumber());
    System.debug('Type: ' + e.getTypeName());
}
```

## ✅ 성공 확인 체크리스트

해결이 완료되면 다음을 확인:
- [ ] 성과 추적 대시보드 정상 로딩
- [ ] 모든 메트릭에 숫자 값 표시  
- [ ] 새로고침 버튼 정상 작동
- [ ] 오류 메시지 없음
- [ ] 우선순위 고객 목록 표시
- [ ] 원클릭 갱신 버튼 활성화

이제 **fix_null_error.apex** 스크립트를 실행하여 문제를 해결해보세요! 🚀
