# 🎯 Lead Domain

## 🎯 목적
Lead(잠재고객) 관련 모든 기능들을 관리하는 도메인입니다. Lead 할당, 관리, 전환 프로세스 등을 담당합니다.

## 📁 폴더 구조

### 🔧 handlers/
Lead 할당 및 관리 핸들러들
- `LeadAssignRepHandler.cls`: Lead 영업 담당자 자동 할당 핸들러

### ⚡ triggers/
Lead 관련 트리거 핸들러들
- `LeadTriggerHandler.cls`: Lead 트리거 핸들러

## 🔄 주요 기능

### 👥 자동 Lead 할당
- 지역별 영업 담당자 자동 할당
- 업종별 전문 담당자 배정
- 워크로드 균등 분배

### 📈 Lead 관리 프로세스
- Lead 생성 시 자동 검증
- 중복 Lead 방지
- 자동 스코어링 시스템

### 🔄 Lead 전환 프로세스
- Account, Contact, Opportunity 자동 생성
- 데이터 품질 검증
- 전환 추적 및 분석

## 🤝 연관 도메인
- **Account Domain**: Lead → Account 전환
- **Opportunity Domain**: Lead → Opportunity 생성
- **Order Management**: Opportunity → Order 연결

## 📞 담당자
- **Lead Developer**: Moon JeongHyeon
- **Domain Expert**: Lead Management Team
