# 📄 Tax Pages

## 🎯 목적
Tax Invoice(세금계산서) 관련 Visualforce Pages를 관리하는 영역입니다.

## 📄 포함된 페이지들

### 📋 **TaxInvoice_PDF.page**
- **목적**: 세금계산서 PDF 생성
- **컨트롤러**: TaxInvoicePDFController
- **주요 기능**:
  - 한국 표준 세금계산서 양식
  - PDF 포맷으로 출력
  - 국세청 규정 준수
  - 사업자등록번호 및 세무 정보 표시

### 📊 **페이지 설정**
```xml
- controller="TaxInvoicePDFController"
- renderAs="pdf"
- contentType="text/html;charset=UTF-8"
- showHeader="false"
- sidebar="false"
- standardStylesheets="false"
```

## 🔗 연관 컴포넌트
- **Controller**: TaxInvoicePDFController (classes/tax_domain/)
- **Related Objects**: Order__c, Account

## ⚖️ 규정 준수
- **국세청 세금계산서 규정**: 전자세금계산서 표준 양식 준수
- **사업자등록번호**: 유효성 검증 포함
- **부가세 계산**: 한국 세법 기준 적용

## 📞 담당자
- **Lead Developer**: Moon JeongHyeon
- **Finance Team**: Tax Management Team
- **Legal Team**: Compliance Team

## 📝 사용 가이드
이 페이지는 법적 효력이 있는 세금계산서 생성에 사용됩니다. 세법 변경이나 양식 업데이트 시 신중하게 검토 후 수정하세요.
