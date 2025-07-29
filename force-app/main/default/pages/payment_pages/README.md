# 💳 Payment Pages

## 🎯 목적
Payment(납부) 관련 Visualforce Pages를 관리하는 영역입니다.

## 📄 포함된 페이지들

### 📋 **PaymentSchedule_PDF.page**
- **목적**: 납부 일정표 PDF 생성
- **컨트롤러**: PaymentStatusPDFController
- **주요 기능**:
  - 납부 일정 상세 정보 표시
  - PDF 포맷으로 출력
  - 인쇄 최적화된 레이아웃
  - 한국어 인코딩 지원 (UTF-8)

### 📊 **페이지 설정**
```xml
- renderAs="pdf"
- contentType="text/html;charset=UTF-8"
- showHeader="false"
- sidebar="false"
- standardStylesheets="false"
```

## 🔗 연관 컴포넌트
- **Controller**: PaymentStatusPDFController (classes/payment_domain/)
- **Related Objects**: PaymentStatus__c, Order__c

## 📞 담당자
- **Lead Developer**: Moon JeongHyeon  
- **Finance Team**: Payment Management Team

## 📝 사용 가이드
이 페이지는 납부 관련 PDF 문서 생성에 사용됩니다. 새로운 납부 관련 페이지 추가 시 이 폴더에 위치시키세요.
