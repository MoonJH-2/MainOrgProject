# 🏢 Account Domain

## 🎯 목적
Account(고객사) 관련 모든 기능들을 관리하는 도메인입니다. 고객 정보 관리, 뉴스 피드, 영업 인사이트, 사업자번호 검증, 주소 검색 등의 기능을 포함합니다.

## 📁 폴더 구조

### 🎮 controllers/
Account 관련 Lightning Web Component 컨트롤러들
- `AccountNewsController.cls`: 고객사 뉴스 피드 컨트롤러

### ⚙️ services/
Account 비즈니스 로직 및 서비스들
- `AccountSalesInsightService.cls`: 고객사 영업 인사이트 분석 서비스

### 🔧 triggers/
Account 관련 트리거 핸들러들
- `AccountTriggerHandler.cls`: Account 트리거 핸들러

### 🎭 modals/
Account 관련 모달 컨트롤러들
- `BusinessNumberCheckModalController.cls`: 사업자번호 확인 모달
- `SearchAddressModalController.cls`: 주소 검색 모달

## 🔄 주요 기능

### 📰 고객사 뉴스 피드
- 고객사 관련 뉴스 자동 수집
- 영업팀에게 관련 뉴스 제공
- 고객 미팅 시 화제 제공

### 📊 영업 인사이트 분석
- 고객사 매출 분석
- 업계 동향 분석
- 영업 기회 발굴 지원

### 🔍 사업자번호 검증
- 사업자번호 유효성 검증
- 국세청 API 연동
- 실시간 사업자 정보 조회

### 📍 주소 검색
- 다음/카카오 주소 API 연동
- 정확한 주소 입력 지원
- 지도 연동 기능

## 🤝 연관 도메인
- **Order Management**: Account에서 Order 생성
- **Payment Management**: Account별 납부 현황 관리
- **Asset Management**: Account별 Asset 포트폴리오
- **Lead Domain**: Lead에서 Account 전환

## 📞 담당자
- **Lead Developer**: Moon JeongHyeon
- **Domain Expert**: Account Management Team
