# 🚀 Agentforce Studio 핵심 서비스 연결 가이드

## 현재 상황
- Agent 이름: SOCAR Sales Agent (Version 2)
- 기존 Topics: B2B Email Communication, General FAQ  
- **필요한 작업**: 배포된 핵심 서비스들을 Actions로 연결

## 📍 단계별 설정 방법

### 1단계: Actions 탭으로 이동
```
현재 위치: Topics 탭
이동할 위치: Actions 탭 (Topics 옆에 있음)
```

### 2단계: New Action 생성 (5개 필요)
각각의 배포된 서비스를 Action으로 등록:

#### Action 1: 마스터 오케스트레이션
```yaml
Name: Process_Agentforce_Request
Type: Apex
Class: AgentforceSimpleMasterService
Method: processAgentforceRequest
Description: 통합 Agentforce 요청 처리
Input Parameters:
  - userId (String): 사용자 ID
  - userMessage (String): 사용자 메시지  
  - recordId (String, optional): 관련 레코드 ID
  - additionalContext (String, optional): 추가 컨텍스트
```

#### Action 2: 일일 브리핑
```yaml
Name: Generate_Daily_Briefing
Type: Apex
Class: AgentforceSalesAssistantService
Method: getDailyBriefing
Description: 영업담당자 일일 브리핑 생성
Input Parameters:
  - userId (String): 영업담당자 ID
```

#### Action 3: 이메일 생성
```yaml
Name: Generate_Email_Draft
Type: Apex
Class: AgentforceSimpleEmailActions
Method: generateEmailDraft
Description: 고객/파트너 이메일 초안 생성
Input Parameters:
  - recordId (String): 관련 레코드 ID
  - emailType (String): 이메일 유형 (order/payment/asset/general)
  - additionalContext (String, optional): 추가 정보
```

#### Action 4: 고객 분석
```yaml
Name: Predict_Customer_Churn
Type: Apex
Class: AgentforceSimpleAnalyticsService
Method: predictCustomerChurnRisk
Description: 고객 이탈 위험도 예측 및 분석
Input Parameters:
  - customerId (String): 고객 ID
```

#### Action 5: 팀 알림
```yaml
Name: Send_Team_Notification
Type: Apex
Class: AgentforceSimpleSlackService
Method: sendTeamNotification
Description: Chatter 기반 팀 알림 발송
Input Parameters:
  - recordId (String): 관련 레코드 ID
  - notificationType (String): 알림 유형 (ORDER_UPDATE/PAYMENT_ALERT/GENERAL)
  - message (String): 알림 메시지
```

### 3단계: Topics 업데이트 (기존 + 신규)
기존 Topics을 확장하고 새로운 Topics 추가:

#### 기존 Topic 확장: B2B Email Communication  
**Actions 연결:**
- Generate_Email_Draft
- Process_Agentforce_Request

**예시 문구 추가:**
- "고객에게 주문 확인 이메일 보내줘"
- "결제 안내 메일 작성해줘"
- "Asset 관련 이메일 만들어줘"

#### 기존 Topic 확장: General FAQ
**Actions 연결:**
- Process_Agentforce_Request

#### 신규 Topic 1: Sales Management
```yaml
Name: Sales Management
Intent: 영업 업무, 일일 브리핑, 스케줄 관리
Actions: 
  - Generate_Daily_Briefing
  - Process_Agentforce_Request
Examples:
  - "오늘 할 일 정리해줘"
  - "일일 브리핑 보여줘"
  - "오늘 미팅 일정 확인해줘"
  - "우선순위 업무 알려줘"
```

#### 신규 Topic 2: Customer Analysis
```yaml
Name: Customer Analysis  
Intent: 고객 위험도 분석, 갱신 기회
Actions:
  - Predict_Customer_Churn
  - Process_Agentforce_Request
Examples:
  - "고객 이탈 위험도 분석해줘"
  - "갱신 기회 찾아줘"
  - "고객 360도 뷰 보여줘"
  - "위험한 고객 있나?"
```

#### 신규 Topic 3: Team Collaboration
```yaml
Name: Team Collaboration
Intent: 팀 알림, 정보 공유
Actions:
  - Send_Team_Notification
  - Process_Agentforce_Request
Examples:
  - "팀에 알림 보내줘"
  - "중요한 업데이트 공유해줘"
  - "프로젝트 상태 알려줘"
  - "팀원들에게 공지해줘"
```

### 4단계: 실행 순서
1. **Actions 탭 클릭** → New Action 버튼
2. **5개 Action 순차적 생성** (위 YAML 참고)
3. **Topics 탭으로 돌아가서** 기존 Topics 편집
4. **New Topic 3개 추가** 생성
5. **Agent 활성화** 및 테스트

## 🎯 즉시 실행할 명령

Agentforce Studio에서:
1. **Actions 탭으로 이동**
2. **"New Action" 클릭**
3. **첫 번째 Action부터 설정 시작**

## 📝 설정 완료 후 테스트 명령어
```
"오늘 할 일 정리해줘"
"고객 이탈 위험도 분석해줘" 
"주문 확인 이메일 작성해줘"
"팀에 업데이트 공유해줘"
```

---
**다음 단계: Actions 탭으로 이동 → New Action 생성 시작! 🚀**
