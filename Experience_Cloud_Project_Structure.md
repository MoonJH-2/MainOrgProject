# 🏗️ Salesforce 프로젝트 구조 권장사항

## 📁 권장 디렉토리 구조

```
SalesforceProjects/
├── MainOrgProject/                 # 현재 프로젝트 (내부 시스템)
│   ├── force-app/
│   │   └── main/default/
│   │       ├── classes/            # Payment, Order 관리
│   │       ├── objects/            # PaymentStatus__c, etc.
│   │       ├── triggers/           # 비즈니스 로직 트리거
│   │       └── lwc/               # 내부 사용자용 컴포넌트
│   └── sfdx-project.json
│
├── ExperienceCloudProject/         # 새로운 Experience Cloud 프로젝트
│   ├── force-app/
│   │   └── main/default/
│   │       ├── digitalExperiences/ # Experience Site 설정
│   │       ├── experiences/        # Community 설정
│   │       ├── networkBranding/    # 브랜딩
│   │       ├── lwc/               # 고객용 컴포넌트
│   │       ├── classes/           # Experience 전용 Controller
│   │       └── staticresources/   # 고객 포털 리소스
│   ├── config/
│   │   └── project-scratch-def.json
│   └── sfdx-project.json
│
└── SharedComponents/               # 공통 컴포넌트 (선택사항)
    ├── force-app/
    │   └── main/default/
    │       ├── lwc/               # 재사용 가능한 컴포넌트
    │       └── classes/           # 공통 유틸리티
    └── sfdx-project.json
```

## 🔄 **프로젝트 간 연동 방식**

### 1️⃣ **패키지 기반 연동**
```yaml
MainOrgProject: # 소스 패키지
  - PaymentStatus__c 객체
  - Order 객체
  - 공개 API 컨트롤러

ExperienceCloudProject: # 의존 패키지
  - MainOrgProject 패키지 의존성
  - Experience Cloud 전용 컴포넌트
  - 고객 포털 UI/UX
```

### 2️⃣ **API 기반 연동**
```apex
// MainOrgProject - 공개 API
@RestResource(urlMapping='/api/payment/status/*')
global class PaymentStatusAPI {
    @HttpGet
    global static PaymentInfo getPaymentStatus() {
        // 결제 상태 조회 (보안 필터링)
    }
}

// ExperienceCloudProject - API 호출
public class ExperiencePaymentController {
    @AuraEnabled(cacheable=true)
    public static PaymentInfo getCustomerPaymentStatus(Id customerId) {
        // REST API 호출로 데이터 조회
        return PaymentStatusAPI.getPaymentStatus();
    }
}
```

## 🚀 **Experience Cloud 프로젝트 생성 가이드**

### 1단계: 새 프로젝트 생성
```bash
# 새 디렉토리 생성
mkdir ExperienceCloudProject
cd ExperienceCloudProject

# SFDX 프로젝트 초기화
sfdx project generate --name ExperienceCloudProject

# Experience Cloud용 디렉토리 구조 생성
mkdir -p force-app/main/default/digitalExperiences
mkdir -p force-app/main/default/experiences  
mkdir -p force-app/main/default/networkBranding
mkdir -p force-app/main/default/lwc
mkdir -p force-app/main/default/classes
```

### 2단계: 프로젝트 설정
```json
// sfdx-project.json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true,
      "package": "ExperienceCloudProject",
      "versionName": "ver 1.0",
      "versionNumber": "1.0.0.NEXT"
    }
  ],
  "name": "ExperienceCloudProject",
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "60.0",
  "packageAliases": {
    "MainOrgProject": "04t..." // MainOrgProject 패키지 의존성
  }
}
```

### 3단계: 스크래치 조직 설정
```json
// config/project-scratch-def.json
{
  "orgName": "Experience Cloud Dev",
  "edition": "Developer", 
  "features": [
    "Communities",
    "ExperienceBundle",
    "LightningExperienceEnabled"
  ],
  "settings": {
    "communitiesSettings": {
      "enableNetworksEnabled": true
    },
    "experienceBundle": {
      "enableExperienceBundle": true
    }
  },
  "packageVersions": [
    "MainOrgProject@1.0.0-1" // 의존성 패키지
  ]
}
```

## 🔐 **보안 및 권한 분리**

### MainOrgProject (내부)
```apex
// 높은 권한, 민감한 데이터 접근
public with sharing class PaymentStatusTimelineController {
    @AuraEnabled
    public static PaymentTimelineWrapper getPaymentTimeline(Id orderId) {
        // 모든 결제 정보 접근 가능
        return fullPaymentData;
    }
}
```

### ExperienceCloudProject (외부)
```apex
// 제한된 권한, 필터링된 데이터 접근
public with sharing class CustomerPaymentController {
    @AuraEnabled(cacheable=true)
    public static CustomerPaymentInfo getCustomerPayments() {
        // 현재 로그인 고객의 데이터만 접근
        Id currentCustomerId = getCurrentCustomerId();
        return getFilteredPaymentData(currentCustomerId);
    }
    
    private static CustomerPaymentInfo getFilteredPaymentData(Id customerId) {
        // 민감한 정보 제외하고 반환
        return sanitizedData;
    }
}
```

## 📋 **마이그레이션 체크리스트**

### ✅ Experience Cloud로 이동할 컴포넌트
- [ ] 고객 대면 LWC 컴포넌트
- [ ] 공개 API 컨트롤러
- [ ] 고객 포털 정적 리소스
- [ ] 브랜딩 및 테마 설정

### ✅ MainOrgProject에 유지할 컴포넌트  
- [ ] PaymentStatusTimelineController (내부용)
- [ ] PaymentStatus__c 객체 정의
- [ ] Order 관리 트리거
- [ ] 내부 사용자 권한 설정

### ✅ 새로 개발할 컴포넌트
- [ ] CustomerPaymentPortal (고객용)
- [ ] GuestUserPaymentInquiry (게스트용)
- [ ] ExperienceNavigation (포털 네비게이션)
- [ ] CustomerSupportChat (고객 지원)

## 🎯 **결론**

**MainOrgProject는 내부 시스템용으로 유지**하고, **Experience Cloud는 별도 프로젝트로 개발**하는 것이 권장됩니다:

✅ **보안 분리**: 내부/외부 권한 명확히 구분
✅ **유지보수**: 각 프로젝트 독립적 관리
✅ **배포 안정성**: 내부 시스템 변경이 고객 포털에 영향 없음
✅ **확장성**: 각각 독립적으로 확장 가능
✅ **팀 협업**: 백엔드/프론트엔드 팀 분리 개발

Experience Cloud 개발 시에는 새로운 프로젝트를 생성하여 전용 환경에서 개발하시기 바랍니다! 🚀
