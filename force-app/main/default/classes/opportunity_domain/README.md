# 💼 Opportunity Domain

## 🎯 목적
Opportunity(영업 기회) 관련 모든 기능들을 관리하는 도메인입니다. 영업 기회 분석, 성사/실패 알림, 후속 프로세스 등을 담당합니다.

## 📁 폴더 구조

### ⚙️ services/
Opportunity 비즈니스 로직 및 서비스들
- `OpportunityCloseNotificationService.cls`: 영업 기회 성사/실패 알림 서비스

## 🔄 주요 기능

### 📢 성사/실패 알림 시스템
- Opportunity 성사 시 자동 축하 알림
- 실패 시 후속 조치 안내
- 영업팀 성과 공유

### 📊 영업 기회 분석
- 성사율 분석
- 영업 사이클 추적
- 예상 매출 예측

### 🔄 후속 프로세스 자동화
- 성사 시 Order 생성 프로세스 시작
- 실패 시 재영업 스케줄링
- 고객 관계 유지 활동 설정

## 🤝 연관 도메인
- **Lead Domain**: Lead → Opportunity 전환
- **Account Domain**: Account 기반 Opportunity 생성
- **Order Management**: Opportunity → Order 연결
- **Quote Domain**: Opportunity → Quote 생성

## 📞 담당자
- **Lead Developer**: Moon JeongHyeon
- **Domain Expert**: Sales Opportunity Team
