# 🛡️ SOCAR B2B 프로젝트 SARIF 보안 분석 가이드

## 🎯 목적
SOCAR B2B Salesforce 프로젝트에 SARIF (Static Analysis Results Interchange Format) 기반 보안 분석을 통합하여 코드 품질과 보안을 향상시킵니다.

## 📋 목차
1. [사전 준비](#사전-준비)
2. [SARIF 도구 설치](#sarif-도구-설치)
3. [Salesforce 스캐너 설정](#salesforce-스캐너-설정)
4. [JavaScript/LWC 보안 스캔](#javascriptlwc-보안-스캔)
5. [GitHub Actions 통합](#github-actions-통합)
6. [결과 분석 및 해결](#결과-분석-및-해결)

## 🔧 사전 준비

### 1. 필요한 도구 설치
```bash
# Salesforce CLI 및 스캐너 플러그인
npm install -g @salesforce/cli
sfdx plugins:install @salesforce/sfdx-scanner

# ESLint Security Plugin
npm install --save-dev eslint-plugin-security
npm install --save-dev @microsoft/eslint-formatter-sarif

# SARIF 뷰어 (선택사항)
npm install -g @microsoft/sarif-multitool
```

### 2. 프로젝트 구조 확인
```
MainOrgProject/
├── force-app/main/default/
│   ├── classes/           # Apex 클래스
│   ├── lwc/              # Lightning Web Components
│   ├── triggers/         # Apex 트리거
│   └── pages/            # Visualforce 페이지
├── .sarif/              # SARIF 결과 저장소
└── security-config/     # 보안 설정 파일
```

## 🔍 Salesforce 스캐너 설정

### 1. PMD 규칙 설정 파일 생성
```xml
<!-- security-config/pmd-ruleset.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<ruleset name="SOCAR Security Rules"
         xmlns="http://pmd.sourceforge.net/ruleset/2.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 
                            https://pmd.sourceforge.io/ruleset_2_0_0.xsd">
    <description>SOCAR B2B 프로젝트 보안 규칙</description>
    
    <!-- Security Rules -->
    <rule ref="category/apex/security.xml"/>
    <rule ref="category/apex/errorprone.xml"/>
    <rule ref="category/apex/performance.xml"/>
    <rule ref="category/apex/design.xml"/>
    
    <!-- Custom Rules for SOCAR -->
    <rule ref="category/apex/security.xml/ApexSOQLInjection"/>
    <rule ref="category/apex/security.xml/ApexXSSFromURLParam"/>
    <rule ref="category/apex/security.xml/ApexOpenRedirect"/>
</ruleset>
```

### 2. Apex 보안 스캔 실행
```bash
# 전체 Apex 코드 스캔
sfdx scanner:run \
  --target "force-app/main/default/classes,force-app/main/default/triggers" \
  --format sarif \
  --outfile .sarif/apex-security-scan.sarif \
  --severity-threshold 3

# 특정 도메인별 스캔
sfdx scanner:run \
  --target "force-app/main/default/classes/order_domain" \
  --format sarif \
  --outfile .sarif/order-domain-scan.sarif
```

## ⚡ JavaScript/LWC 보안 스캔

### 1. ESLint 보안 설정
```json
// .eslintrc-security.json
{
  "extends": ["@salesforce/eslint-config-lwc/recommended"],
  "plugins": ["security"],
  "rules": {
    "security/detect-object-injection": "error",
    "security/detect-non-literal-regexp": "error",
    "security/detect-unsafe-regex": "error",
    "security/detect-eval-with-expression": "error",
    "security/detect-pseudoRandomBytes": "error",
    "security/detect-possible-timing-attacks": "error"
  },
  "env": {
    "browser": true,
    "es2020": true
  }
}
```

### 2. LWC 보안 스캔 실행
```bash
# LWC 보안 스캔
eslint force-app/main/default/lwc \
  --config .eslintrc-security.json \
  --format @microsoft/eslint-formatter-sarif \
  --output-file .sarif/lwc-security-scan.sarif

# 특정 컴포넌트 스캔
eslint force-app/main/default/lwc/account_components \
  --config .eslintrc-security.json \
  --format @microsoft/eslint-formatter-sarif \
  --output-file .sarif/account-components-scan.sarif
```

## 🚀 GitHub Actions 통합

### 1. Workflow 파일 생성
```yaml
# .github/workflows/security-scan.yml
name: Security Scan with SARIF

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        
    - name: Install Salesforce CLI
      run: |
        npm install -g @salesforce/cli
        sfdx plugins:install @salesforce/sfdx-scanner
        
    - name: Install dependencies
      run: |
        npm install
        npm install --save-dev eslint-plugin-security
        npm install --save-dev @microsoft/eslint-formatter-sarif
        
    - name: Run Apex Security Scan
      run: |
        mkdir -p .sarif
        sfdx scanner:run \
          --target "force-app/main/default/classes,force-app/main/default/triggers" \
          --format sarif \
          --outfile .sarif/apex-security-scan.sarif \
          --severity-threshold 2
          
    - name: Run LWC Security Scan  
      run: |
        eslint force-app/main/default/lwc \
          --config .eslintrc-security.json \
          --format @microsoft/eslint-formatter-sarif \
          --output-file .sarif/lwc-security-scan.sarif || true
          
    - name: Upload SARIF to GitHub
      uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: .sarif/
        category: socar-security-scan
        
    - name: Archive SARIF results
      uses: actions/upload-artifact@v4
      with:
        name: sarif-results
        path: .sarif/
```

## 📊 결과 분석 및 해결

### 1. SARIF 결과 확인 스크립트
```bash
#!/bin/bash
# scripts/analyze-sarif.sh

echo "🔍 SOCAR B2B 보안 스캔 결과 분석"
echo "=================================="

# SARIF 파일 존재 확인
if [ ! -d ".sarif" ]; then
    echo "❌ .sarif 디렉토리가 없습니다. 먼저 보안 스캔을 실행하세요."
    exit 1
fi

# Apex 스캔 결과 요약
if [ -f ".sarif/apex-security-scan.sarif" ]; then
    echo "📋 Apex 보안 스캔 결과:"
    jq '.runs[0].results | length' .sarif/apex-security-scan.sarif
    echo "발견된 이슈 개수"
fi

# LWC 스캔 결과 요약  
if [ -f ".sarif/lwc-security-scan.sarif" ]; then
    echo "⚡ LWC 보안 스캔 결과:"
    jq '.runs[0].results | length' .sarif/lwc-security-scan.sarif
    echo "발견된 이슈 개수"
fi

# 심각도별 분류
echo "🎯 심각도별 이슈 분류:"
find .sarif -name "*.sarif" -exec jq -r '.runs[0].results[] | .level' {} \; | sort | uniq -c
```

### 2. 일반적인 Salesforce 보안 이슈 해결

#### SOQL Injection 방지
```apex
// ❌ 취약한 코드
public List<Account> searchAccounts(String searchTerm) {
    String query = 'SELECT Id, Name FROM Account WHERE Name LIKE \'%' + searchTerm + '%\'';
    return Database.query(query);
}

// ✅ 안전한 코드
public List<Account> searchAccounts(String searchTerm) {
    String query = 'SELECT Id, Name FROM Account WHERE Name LIKE :searchPattern';
    String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
    return Database.query(query);
}
```

#### Cross-Site Scripting (XSS) 방지
```javascript
// ❌ 취약한 LWC 코드
@track htmlContent = this.userInput;

// ✅ 안전한 LWC 코드
@track sanitizedContent = this.sanitizeInput(this.userInput);

sanitizeInput(input) {
    return input.replace(/[<>]/g, '');
}
```

## 📈 주기적 보안 스캔 설정

### 1. 일일 보안 스캔 cron 작업
```yaml
# .github/workflows/daily-security-scan.yml
name: Daily Security Scan

on:
  schedule:
    - cron: '0 2 * * *'  # 매일 오전 2시 실행

jobs:
  security-scan:
    # ... (위와 동일한 작업)
```

### 2. 보안 메트릭 대시보드
```bash
# 주간 보안 리포트 생성
scripts/weekly-security-report.sh
```

## 🎯 SOCAR 프로젝트 특화 보안 체크리스트

### 결제 관련 보안
- [ ] PaymentStatus 클래스의 민감한 데이터 암호화
- [ ] 결제 정보 로깅 방지
- [ ] API 호출 시 인증 토큰 검증

### 고객 데이터 보호
- [ ] 개인정보 필드 접근 권한 검증
- [ ] 데이터 마스킹 적용
- [ ] 감사 로그 기록

### Agentforce 보안
- [ ] AI 모델 입력 데이터 검증
- [ ] 외부 API 호출 보안
- [ ] 권한 에스컬레이션 방지

## 📞 문의 및 지원
- **보안팀**: security@socar.kr
- **개발팀**: dev@socar.kr
- **Lead Developer**: Moon JeongHyeon

---
*마지막 업데이트: 2025년 7월 29일*
*SOCAR B2B 프로젝트 보안 가이드 v1.0*
