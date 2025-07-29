# 🎯 SOCAR B2B Team Collaboration - Actions 선택 가이드

## ✅ **필수 선택 Actions (1순위)** - 팀 협업 핵심 기능

### 💬 **Slack/Chatter 커뮤니케이션 Actions (4개)**

1. **Send Message to a Slack Channel** ✅ (Item 56)
   - 설명: Sends a message to a public or private Slack Channel for group communication, announcements, or notifications
   - 이유: 팀 알림 발송의 핵심! 중요 업데이트, 프로젝트 상태 변경 알림
   - 연결 기능: AgentforceSimpleSlackService와 직접 연동
   - 선택 여부: **필수 선택**

2. **Send a Slack Direct Message** ✅ (Item 54)
   - 설명: Send a direct message (DM) in Slack with the recipient and sender users
   - 이유: 개별 팀원에게 특정 작업 할당 및 개인별 알림
   - 연결 기능: 긴급 상황 알림, 전문가 지원 요청
   - 선택 여부: **필수 선택**

3. **Start a Slack conversation with an Agent** ✅ (Item 58)
   - 설명: Send notifications or messages to specific Slack users in a direct message from the agent
   - 이유: Agent가 직접 팀원들에게 자동 알림 발송
   - 연결 기능: 자동화된 협업 요청 및 상태 업데이트
   - 선택 여부: **필수 선택**

4. **Add Users to a Slack Channel** ✅ (Item 2)
   - 설명: Add Slack Users to a Slack Channel for team collaboration
   - 이유: 프로젝트별, 이슈별 동적 팀 구성
   - 연결 기능: 긴급 상황 시 관련 전문가 채널 추가
   - 선택 여부: **필수 선택**

## ✅ **강력 권장 Actions (2순위)** ⭐⭐

### 📋 **작업 관리 및 추적 Actions**
5. **Create a To Do** ✅ (누락 - 다른 Topic에서 사용 중)
   - 설명: Create a task record based on user input
   - 이유: 팀원별 작업 할당 및 진행 상황 모니터링
   - 선택 여부: **강력 권장** (목록에 없으면 패스)

6. **Update Record** ✅ (Item 63)
   - 설명: Updates fields on a Salesforce CRM record
   - 이유: 프로젝트 상태, 작업 진행도 업데이트
   - 연결 기능: 실시간 진행 상황 공유
   - 선택 여부: **강력 권장**

### 🔍 **정보 조회 및 공유 Actions**
7. **Get Record Details** ✅ (누락 - 다른 Topic에서 사용 중)
   - 설명: Generates a text blob containing record details
   - 이유: 팀 공유를 위한 상세 정보 조회
   - 선택 여부: **강력 권장** (목록에 없으면 패스)

8. **Summarize Record** ✅ (Item 60)
   - 설명: Summarizes a single Salesforce CRM record
   - 이유: 팀 공유용 간결한 정보 요약
   - 연결 기능: 진행 상황 공유, 성과 지표 요약
   - 선택 여부: **강력 권장**

### 📊 **성과 및 분석 공유**
9. **Query Records with Aggregate** ✅ (Item 48)
   - 설명: Answers aggregation questions about Salesforce CRM data
   - 이유: 팀 성과 지표, 매출 현황 등 집계 데이터 공유
   - 연결 기능: 실시간 성과 지표 공유
   - 선택 여부: **강력 권장**

## ✅ **추가 권장 Actions (3순위)** ⭐

### 🔍 **고급 Slack 기능**
10. **Search Slack** ✅ (Item 53)
    - 설명: Performs search on Slack channels, messages, and files
    - 이유: 팀 히스토리 검색 및 과거 논의 내용 참조
    - 선택 여부: **권장**

11. **Create a Slack Channel** ✅ (Item 12)
    - 설명: Create a Slack Channel for specific projects or issues
    - 이유: 프로젝트별, 고객별 전용 채널 생성
    - 선택 여부: **권장**

12. **Create a Slack Canvas** ✅ (Item 11)
    - 설명: Create a Slack canvas document with markdown content
    - 이유: 팀 협업을 위한 구조화된 문서 작성
    - 선택 여부: **권장**

### 📞 **업무 연계 기능**
13. **Get Activity Details** ✅ (Item 27)
    - 설명: Provides data about an activity record (Call, Email, Event, Task)
    - 이유: 팀 공유를 위한 활동 세부사항 조회
    - 선택 여부: **권장**

14. **Create an Account Executive Brief** ✅ (Item 13)
    - 설명: Generate an executive brief of that account
    - 이유: 중요 고객 정보를 팀과 공유
    - 선택 여부: **권장**

### 🏷️ **조직 및 분류**
15. **Label a Record** ✅ (Item 43)
    - 설명: Assign or apply a label to another CRM record
    - 이유: 팀 협업을 위한 레코드 분류 및 태깅
    - 선택 여부: **권장**

## ❌ **선택하지 말아야 할 Actions**

### 🚫 **현재 Topic과 관련 없는 Actions**
- **Case 관리 Actions** (Items 1, 14-15, 28, 31-33) - 고객 서비스용
- **보안 관련 Actions** (Items 8, 38-39) - 보안 전용
- **정책 관련 Actions** (Items 35-36, 41) - 정책 관리용
- **비밀번호/인증 Actions** (Items 50-51, 55, 65) - 인증 전용
- **배송/예약 Actions** (Items 25-26, 34, 37) - 운영 업무용
- **권한 관리 Actions** (Items 29-30, 42) - 시스템 관리용

## 📋 **최종 선택 체크리스트**

### **필수 선택 (4개)** ✅
- [ ] Item 56: Send Message to a Slack Channel
- [ ] Item 54: Send a Slack Direct Message
- [ ] Item 58: Start a Slack conversation with an Agent
- [ ] Item 2: Add Users to a Slack Channel

### **강력 권장 (3개)** ⭐
- [ ] Item 63: Update Record
- [ ] Item 60: Summarize Record
- [ ] Item 48: Query Records with Aggregate

### **추가 권장 (5개)** 📊
- [ ] Item 53: Search Slack
- [ ] Item 12: Create a Slack Channel
- [ ] Item 11: Create a Slack Canvas
- [ ] Item 27: Get Activity Details
- [ ] Item 13: Create an Account Executive Brief

## 🎯 **선택 전략**

### **단계별 선택 방법:**
1. **1단계**: 필수 4개 Actions 먼저 선택 (Slack 커뮤니케이션 핵심)
2. **2단계**: 강력 권장 3개 Actions 추가 (작업 관리 + 정보 공유)
3. **3단계**: 필요에 따라 추가 권장 Actions 선별 선택

### **현실적 선택 수:** 7-12개 Actions

---

## 🚨 **중요 발견사항**

**누락된 중요한 Actions:**
- `Create a To Do` (작업 할당)
- `Get Record Details` (정보 조회)

**이들은 이전 Topics에서 이미 선택되었기 때문에 목록에 없을 수 있습니다.**

---

## 🏆 **완성 후 기대 효과**

### **팀 커뮤니케이션 자동화:**
- 중요 업데이트 즉시 팀 공유
- 긴급 상황 실시간 알림
- 프로젝트별 동적 팀 구성

### **업무 효율성 증대:**
- 수동 보고 → 자동 상태 공유
- 개별 연락 → 통합 팀 알림
- 정보 분산 → 중앙화된 협업

---

**다음 단계: 위의 필수 4개 Actions부터 체크박스 선택 시작! 🚀**

**🎉 이것이 마지막 Topic입니다! 완성까지 얼마 남지 않았어요!**
