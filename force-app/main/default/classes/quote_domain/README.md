# 📋 Quote Domain

## 🎯 목적
Quote(견적서) 관련 모든 기능들을 관리하는 도메인입니다. 견적서 생성, 복제, 관리 등의 기능을 담당합니다.

## 📁 폴더 구조

### 🎭 modals/
Quote 관련 모달 컨트롤러들
- `QuoteCloneModalController.cls`: 견적서 복제 모달 컨트롤러

## 🔄 주요 기능

### 📄 견적서 복제
- 기존 견적서 기반 신규 견적서 생성
- 상품 정보 자동 복사
- 가격 조정 기능

### 📝 견적서 관리
- 견적서 버전 관리
- 승인 프로세스 연동
- 고객 발송 추적

### 💰 가격 계산
- 할인율 자동 적용
- 세금 계산
- 총액 계산

## 🤝 연관 도메인
- **Opportunity Domain**: Opportunity → Quote 생성
- **Order Management**: Quote → Order 전환
- **Integration Services**: Quote PDF 생성
- **Account Domain**: Account 정보 연동

## 📞 담당자
- **Lead Developer**: Moon JeongHyeon
- **Domain Expert**: Quote Management Team
