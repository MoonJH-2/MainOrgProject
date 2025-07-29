// ==========================================
// 📋 Weekly Sales Report Custom Object
// ==========================================

// Weekly_Sales_Report__c Custom Object Fields
/*
API Name: Weekly_Sales_Report__c
Label: 주간 영업 활동 보고서

=== 기본 정보 ===
Week_Start_Date__c (Date, Required): 주간 시작일
Week_End_Date__c (Date, Required): 주간 종료일  
Sales_Rep__c (Lookup to User, Required): 영업사원
Manager__c (Lookup to User): 관리자
Status__c (Picklist): Draft, Submitted, Approved, Needs_Review

=== 업무 실적 ===
Calls_Made__c (Number(18,0)): 전화 통화 수
Meetings_Held__c (Number(18,0)): 고객 미팅 수
Proposals_Sent__c (Number(18,0)): 제안서 발송 수
Contracts_Closed__c (Number(18,0)): 계약 성사 수
Revenue_Generated__c (Currency(16,2)): 발생 매출
New_Leads__c (Number(18,0)): 신규 리드 수

=== 주관적 평가 ===
Energy_Level__c (Number(2,0), 1-10): 에너지 레벨
Productivity_Score__c (Number(2,0), 1-10): 생산성 점수
Customer_Satisfaction__c (Number(2,0), 1-10): 고객 만족도
Challenge_Level__c (Number(2,0), 1-10): 업무 난이도

=== 창의적 기록 ===
Weekly_Highlight__c (Long Text Area): 주간 하이라이트
Creative_Solutions__c (Long Text Area): 창의적 해결책
Learning_Points__c (Long Text Area): 배운 점
Next_Week_Goals__c (Long Text Area): 다음 주 목표
Mood_Emoji__c (Text(255)): 기분 이모지

=== 게임화 필드 ===
Total_Points__c (Number(18,0)): 총 획득 포인트
Weekly_Rank__c (Number(18,0)): 주간 순위
Achievement_Badges__c (Long Text Area): 획득한 배지들 (JSON)
*/

// ==========================================
// 🏆 Achievement Badge System
// ==========================================

// Achievement_Badge__c Custom Object
/*
Badge_Name__c (Text(80), Required): 배지 이름
Badge_Type__c (Picklist): Weekly, Monthly, Quarterly, Annual
Badge_Category__c (Picklist): Performance, Creativity, Teamwork, Customer_Focus
Description__c (Long Text Area): 배지 설명
Icon_URL__c (URL): 배지 아이콘 URL
Criteria__c (Long Text Area): 달성 조건
Points_Award__c (Number(18,0)): 획득 포인트
Active__c (Checkbox): 활성 상태
*/

// Badge Achievement 관계 Object
/*
Badge_Achievement__c
Sales_Rep__c (Lookup to User, Required): 영업사원
Badge__c (Lookup to Achievement_Badge__c, Required): 배지
Achieved_Date__c (DateTime, Required): 달성 일시
Week_Report__c (Lookup to Weekly_Sales_Report__c): 관련 주간 보고서
*/

// ==========================================
// 📊 Daily Mood Tracking
// ==========================================

// Daily_Mood__c Custom Object (Weekly Report의 Child)
/*
Weekly_Report__c (Master-Detail to Weekly_Sales_Report__c): 주간 보고서
Date__c (Date, Required): 날짜
Morning_Mood__c (Number(2,0), 1-10): 오전 기분
Afternoon_Mood__c (Number(2,0), 1-10): 오후 기분
Energy_Level__c (Number(2,0), 1-10): 에너지 수준
Stress_Level__c (Number(2,0), 1-10): 스트레스 수준
Confidence_Level__c (Number(2,0), 1-10): 자신감 수준
Notes__c (Long Text Area): 기분에 대한 메모
Location__c (Geolocation): 위치 정보
*/

// ==========================================
// 💡 Creative Ideas Tracking
// ==========================================

// Creative_Idea__c Custom Object
/*
Idea_Title__c (Text(120), Required): 아이디어 제목
Description__c (Long Text Area, Required): 상세 설명
Created_By__c (Lookup to User, Required): 작성자
Implementation_Status__c (Picklist): Not_Started, In_Progress, Implemented, Cancelled
Impact_Score__c (Number(2,0), 1-10): 예상 임팩트
Category__c (Picklist): Customer_Approach, Process_Improvement, Product_Idea, Team_Collaboration
Collaborators__c (Long Text Area): 협업자들
Implementation_Date__c (Date): 구현 예정일
Actual_Impact__c (Long Text Area): 실제 임팩트
Likes_Count__c (Number(18,0)): 좋아요 수
*/

// ==========================================
// 🤝 Social Sharing System
// ==========================================

// Weekly_Share__c Custom Object
/*
Shared_By__c (Lookup to User, Required): 공유자
Share_Type__c (Picklist): Success_Story, Lesson_Learned, Tip_Share, Question, Celebration
Title__c (Text(120), Required): 제목
Content__c (Long Text Area, Required): 공유 내용
Related_Report__c (Lookup to Weekly_Sales_Report__c): 관련 주간 보고서
Likes_Count__c (Number(18,0)): 좋아요 수
Comments_Count__c (Number(18,0)): 댓글 수
Is_Featured__c (Checkbox): 추천 게시물
Created_Date__c (DateTime): 생성일시
*/

// ==========================================
// 📈 Performance Analytics Fields
// ==========================================

// User Object에 추가할 Custom Fields
/*
=== 게임화 관련 ===
Total_Career_Points__c (Number(18,0)): 총 경력 포인트
Current_Level__c (Picklist): Bronze, Silver, Gold, Platinum, Diamond
Level_Progress__c (Percent): 레벨 진행률
Badges_Count__c (Number(18,0)): 보유 배지 수

=== 성과 분석 ===
Best_Performance_Day__c (Picklist): Monday, Tuesday, Wednesday, Thursday, Friday
Best_Performance_Time__c (Picklist): Morning, Afternoon, Evening
Preferred_Customer_Type__c (Text(255)): 선호 고객 유형
Average_Deal_Size__c (Currency): 평균 거래 규모
Conversion_Rate__c (Percent): 전환율

=== AI 분석 결과 ===
Personality_Type__c (Picklist): Hunter, Farmer, Relationship_Builder, Technical_Expert
Strength_Areas__c (Multi-Select Picklist): Cold_Calling, Relationship_Building, Presentations, Negotiations
Improvement_Areas__c (Multi-Select Picklist): Time_Management, Follow_Up, Technical_Knowledge, Communication
*/
