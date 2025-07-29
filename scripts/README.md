# 📜 Scripts 폴더 구조화 완료

## 🎯 프로젝트 개요
SOCAR B2B 플랫폼의 모든 개발 스크립트들이 용도별로 체계적으로 구조화되었습니다.

## 📁 폴더 구조

### 🔍 **scripts/soql/** - SOQL 쿼리 관리
```
soql/
├── account.soql                    # 기본 Account 쿼리 템플릿
└── notification_reports.soql      # 알림 리포트용 복합 쿼리
```

### ⚡ **scripts/apex/** - Apex 스크립트 관리
```
apex/
├── setup_scripts/                 # 시스템 설정 스크립트
├── test_scripts/                  # 테스트 및 검증 스크립트
├── order_scripts/                 # Order 관련 스크립트
├── asset_scripts/                 # Asset 관련 스크립트  
├── notification_scripts/          # 알림 관련 스크립트
├── agentforce_scripts/            # Agentforce 관련 스크립트
├── debug_scripts/                 # 디버깅 및 문제해결 스크립트
└── migration_scripts/             # 데이터 마이그레이션 스크립트
```

## 📊 구조화 통계
- **SOQL 파일**: 2개
- **Apex 스크립트**: 120개+ (8개 카테고리로 분류)
- **README 문서**: 9개 (메인 + 각 카테고리별)

## 🔧 scripts/soql 상세 분석

### 🎯 **목적 및 역할**
- **개발자 도구**: VS Code SFDX 확장과 연동한 쿼리 실행
- **리포트 개발**: 복잡한 비즈니스 인텔리전스 쿼리 개발
- **데이터 분석**: 임시 데이터 조회 및 분석
- **문서화**: 자주 사용하는 쿼리 패턴 저장소

### 📋 **주요 파일**
| 파일명 | 목적 | 특징 |
|--------|------|------|
| account.soql | 기본 Account 쿼리 | VS Code 연동, 템플릿 |
| notification_reports.soql | 알림 리포트 쿼리 | 복합 쿼리, GROUP BY, 집계 |

### 🚀 **사용 방법**
1. VS Code에서 SOQL 파일 열기
2. 실행할 쿼리 텍스트 선택
3. "SFDX: Execute SOQL Query with Currently Selected Text" 명령 실행

## ⚡ scripts/apex 카테고리별 분류

### 🛠️ **setup_scripts/** (13개 스크립트)
- **목적**: 시스템 초기 설정 및 환경 구성
- **주요 스크립트**: 
  - Agentforce 설정
  - B2B 상품 설정
  - 알림 시스템 설정
  - 테스트 데이터 생성

### 🧪 **test_scripts/** (25개+ 스크립트)
- **목적**: 기능 테스트 및 검증
- **카테고리**:
  - 기본 테스트
  - 결제 테스트
  - 시스템 통합 테스트
  - 성능 테스트

### 📦 **order_scripts/** (32개 스크립트)
- **목적**: Order 관련 모든 스크립트
- **기능**:
  - Order 생성/수정
  - Order 분석
  - Order 문제 해결
  - Order 자동화

### 🏗️ **asset_scripts/** (10개 스크립트)
- **목적**: Asset 관련 스크립트
- **기능**:
  - Asset 테스트
  - Asset 생성 시스템
  - Asset 분석
  - Asset 데모

### 🔔 **notification_scripts/** (15개 스크립트)
- **목적**: 알림 시스템 관련 스크립트
- **기능**:
  - 알림 테스트
  - 이메일 시스템
  - Slack 연동
  - 알림 모니터링

### 🤖 **agentforce_scripts/** (1개 스크립트)
- **목적**: Agentforce AI 관련 스크립트
- **기능**:
  - VIBA 통합 테스트
  - AI 기능 검증

### 🐛 **debug_scripts/** (10개 스크립트)
- **목적**: 디버깅 및 문제 해결
- **기능**:
  - 오류 분석
  - 계약 상태 검증
  - 시스템 상태 체크
  - 권한 확인

### 🔄 **migration_scripts/** (1개 스크립트)
- **목적**: 데이터 마이그레이션
- **기능**:
  - 전체 마이그레이션 실행

## 🚀 사용 가이드라인

### 1. 새 스크립트 추가 시
```
1. 목적에 맞는 카테고리 폴더 선택
2. 명명 규칙 준수: {기능}_{대상}_{목적}.apex
3. 해당 폴더의 README 업데이트
```

### 2. 스크립트 실행 순서
```
1. setup_scripts - 환경 설정
2. test_scripts - 기능 검증
3. debug_scripts - 문제 해결
4. migration_scripts - 데이터 이관
```

### 3. 보안 고려사항
- 프로덕션 실행 시 주의
- 백업 후 실행 권장
- 권한 확인 필수

## 👥 담당자
- **Lead Developer**: Moon JeongHyeon
- **DevOps Team**: Script Management Team
- **QA Team**: Test Script Team

---
*마지막 업데이트: 2025년 7월 29일*
*구조화 완료: 용도별 카테고리 분류 적용*
