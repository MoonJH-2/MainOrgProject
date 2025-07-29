# 🚀 Agentforce Studio 다음 단계 가이드

## 📍 현재 상황
- ✅ **B2B Sales Daily Management** Topic 생성 완료
- ✅ 핵심 Actions 8개 선택 완료
- ⏳ **다음 단계 진행 필요**

---

## 🎯 **다음 단계 로드맵**

### **1단계: Topic 활성화 및 테스트** 🔧
```
목표: 방금 생성한 Topic이 정상 작동하는지 확인
소요시간: 5-10분
```

**실행 단계:**
1. **Agent 활성화**
   - Topics 목록에서 Agent 상태 확인
   - 비활성화 상태라면 "Activate" 버튼 클릭

2. **Conversation Preview 테스트**
   - 우측 "Let's chat!" 창에서 테스트
   - 테스트 명령어: `"오늘 할 일 정리해줘"`
   - 예상 결과: B2B Sales Daily Management Topic이 활성화되어 응답

3. **Actions 연결 확인**
   - Draft Order Email 기능 테스트
   - 테스트 명령어: `"고객에게 주문 확인 이메일 작성해줘"`

---

### **2단계: 두 번째 Topic 생성 - Enhanced Email Communication** ✉️
```
목표: 이메일 커뮤니케이션 전용 Topic 생성
우선순위: 높음 (기존 B2B Email Communication 확장)
```

**Topic 설정 정보:**
```yaml
Name: Enhanced Email Communication
API Name: Enhanced_Email_Communication
Description: SOCAR B2B 고객과의 모든 이메일 커뮤니케이션을 자동화하고 개인화하는 Topic

What do you want this topic to do?:
이 Topic은 SOCAR B2B 고객과의 모든 이메일 커뮤니케이션을 자동화하고 개인화합니다.

주요 기능:
1. 주문 관련 이메일 - 주문 확인, 배송 안내, 완료 알림
2. 결제 관련 이메일 - 결제 요청, 연체 알림, 완료 확인
3. Asset 관리 이메일 - 갱신 안내, 만료 알림, 업그레이드 제안
4. 맞춤형 영업 이메일 - 고객별 상황에 맞는 개인화된 메시지

사용자가 "고객에게 주문 확인 이메일 보내줘", "결제 안내 메일 작성해줘", "Asset 갱신 이메일 만들어줘" 같은 요청을 할 때 AgentforceSimpleEmailActions를 통해 전문적이고 개인화된 이메일 초안을 생성합니다.
```

**선택할 Actions:**
- ✅ Draft Order Email
- ✅ Draft Payment Email
- ✅ Draft Asset Renewal Email
- ✅ Send Generated Email
- ✅ Revise Email Draft
- ✅ Draft or Revise Email

---

### **3단계: 세 번째 Topic 생성 - Customer Analysis** 📊
```
목표: AI 기반 고객 분석 및 예측 Topic 생성
우선순위: 높음 (배포된 Analytics 서비스 활용)
```

**Topic 설정 정보:**
```yaml
Name: Customer Analysis
API Name: Customer_Analysis
Description: AI 기반 고객 분석을 통해 영업팀의 전략적 의사결정을 지원하는 Topic

What do you want this topic to do?:
이 Topic은 AI 기반 고객 분석을 통해 영업팀의 전략적 의사결정을 지원합니다.

주요 기능:
1. 고객 이탈 위험도 예측 - 과거 행동 패턴과 결제 이력 분석
2. 갱신 기회 분석 - Asset 만료일 및 갱신 가능성 평가
3. 고객 360도 뷰 - 종합적인 고객 정보 및 관계 현황
4. 최적 연락 타이밍 추천 - 고객별 맞춤 컨택 시점 제안

사용자가 "고객 이탈 위험도 분석해줘", "갱신 기회 찾아줘", "이 고객 언제 연락하면 좋을까?" 같은 요청을 할 때 AgentforceSimpleAnalyticsService를 활용하여 데이터 기반 인사이트를 제공합니다.
```

**선택할 Actions:**
- ✅ Get Record Details
- ✅ Query Records
- ✅ Query Records with Aggregate
- ✅ Summarize Record
- ✅ Get Activities Timeline

---

### **4단계: 네 번째 Topic 생성 - Team Collaboration** 👥
```
목표: 팀 협업 및 내부 커뮤니케이션 Topic 생성
우선순위: 중간 (Slack/Chatter 서비스 활용)
```

**Topic 설정 정보:**
```yaml
Name: Team Collaboration
API Name: Team_Collaboration
Description: SOCAR B2B 영업팀의 효율적인 협업과 정보 공유를 지원하는 Topic

What do you want this topic to do?:
이 Topic은 SOCAR B2B 영업팀의 효율적인 협업과 정보 공유를 지원합니다.

주요 기능:
1. 팀 알림 발송 - 중요 업데이트, 프로젝트 상태 변경 알림
2. 진행 상황 공유 - 거래 진척도, 성과 지표 공유
3. 긴급 상황 알림 - 고위험 고객, 결제 문제 등 즉시 대응 필요 사항
4. 협업 요청 - 전문가 지원, 리소스 공유 요청

사용자가 "팀에 알림 보내줘", "중요한 업데이트 공유해줘", "프로젝트 상태 알려줘" 같은 요청을 할 때 AgentforceSimpleSlackService를 통해 Salesforce Chatter에 적절한 알림을 발송합니다.
```

**선택할 Actions:**
- ✅ Send Message to a Slack Channel
- ✅ Send a Slack Direct Message
- ✅ Create a To Do
- ✅ Update Record

---

### **5단계: Agent 통합 테스트** 🧪
```
목표: 모든 Topics이 연동되어 작동하는지 종합 테스트
소요시간: 15-20분
```

**테스트 시나리오:**
1. **일일 브리핑 테스트**
   - 명령어: `"오늘 할 일 정리해줘"`
   - 예상: B2B Sales Daily Management Topic 활성화

2. **이메일 생성 테스트**
   - 명령어: `"고객에게 주문 확인 이메일 보내줘"`
   - 예상: Enhanced Email Communication Topic 활성화

3. **고객 분석 테스트**
   - 명령어: `"고객 이탈 위험도 분석해줘"`
   - 예상: Customer Analysis Topic 활성화

4. **팀 협업 테스트**
   - 명령어: `"팀에 중요한 업데이트 공유해줘"`
   - 예상: Team Collaboration Topic 활성화

---

### **6단계: 사용자 교육 및 배포** 📚
```
목표: 실제 영업팀이 Agent를 사용할 수 있도록 교육
소요시간: 30분
```

**교육 내용:**
1. **기본 사용법**
   - Agent 접근 방법
   - 기본 명령어 교육

2. **실무 활용 시나리오**
   - 일일 브리핑 받기
   - 고객 이메일 작성
   - 데이터 분석 요청
   - 팀 협업 활용

3. **주의사항 및 제한사항**
   - 개인정보 보호
   - 이메일 전송 전 검토 필요

---

## 🎯 **즉시 실행할 다음 단계**

### **지금 바로 할 일:**
1. **현재 화면에서 "Save" 또는 "Next" 클릭**
2. **Agent 활성화 상태 확인**
3. **Conversation Preview에서 테스트**
   - 입력: `"오늘 할 일 정리해줘"`
   - 결과 확인

### **오늘 완료 목표:**
- [ ] B2B Sales Daily Management Topic 테스트 완료
- [ ] Enhanced Email Communication Topic 생성 완료
- [ ] Customer Analysis Topic 생성 완료
- [ ] 기본 기능 통합 테스트 완료

---

**다음 실행: 현재 Topic 저장 → Agent 활성화 → 테스트 시작! 🚀**
