# 📝 Quote Pages

## 🎯 목적
Quote(견적) 관련 Visualforce Pages를 관리하는 영역입니다.

## 📄 포함된 페이지들

### 📋 **Quotation_PDF.page**
- **목적**: 견적서 PDF 생성
- **컨트롤러**: QuotationPDFController
- **표준 컨트롤러**: Quote
- **주요 기능**:
  - 정식 견적서 문서 생성
  - PDF 포맷으로 출력
  - 회사 브랜딩 포함
  - 견적 항목 상세 표시

### 📊 **페이지 설정**
```xml
- standardController="Quote"
- extensions="QuotationPDFController"
- renderAs="pdf"
- showHeader="false"
- sidebar="false"
- standardStylesheets="false"
```

## 🔗 연관 컴포넌트
- **Controller**: QuotationPDFController (classes/quote_domain/)
- **Standard Controller**: Quote (Salesforce 표준 객체)
- **Related Objects**: QuoteLineItem, Opportunity

## 📞 담당자
- **Lead Developer**: Hyowon Hong
- **Sales Team**: Quote Management Team

## 📝 사용 가이드
이 페이지는 고객에게 제공할 공식 견적서 생성에 사용됩니다. 견적서 포맷 변경이나 새로운 견적 관련 페이지 추가 시 이 폴더를 활용하세요.
