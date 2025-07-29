# 🔧 Shared Pages

## 🎯 목적
공통으로 사용되는 Visualforce Pages를 관리하는 영역입니다.

## 📄 포함된 페이지들

### 🗺️ **SearchAddressMap.page**
- **목적**: 주소 검색 모달 페이지
- **컨트롤러**: SearchAddressModalController
- **주요 기능**:
  - 한국 주소 검색 API 연동
  - 모달 팝업 형태로 표시
  - 주소 선택 및 반환
  - 모바일 최적화

### 📊 **페이지 설정**
```xml
- controller="SearchAddressModalController"
- showHeader="false"
- sidebar="false"
- standardStylesheets="false"
```

## 🔗 연관 컴포넌트
- **Controller**: SearchAddressModalController (classes/shared_domain/)
- **사용 도메인**: Account, Lead, Opportunity (주소 입력이 필요한 모든 영역)

## 🌐 외부 연동
- **주소 검색 API**: 한국 우편번호 검색 서비스
- **지도 서비스**: 위치 표시 및 확인

## 📞 담당자
- **Lead Developer**: Hyowon Hong
- **Frontend Team**: Shared Components Team

## 📝 사용 가이드
이 페이지는 시스템 전반에서 주소 입력이 필요한 곳에서 공통으로 사용됩니다. 주소 API 변경이나 UI 개선 시 모든 도메인에 영향을 주므로 신중하게 테스트하세요.
