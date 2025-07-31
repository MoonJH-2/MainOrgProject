# 🚀 SOCAR B2B 혁신 프로젝트 Wiki

> **"타인의 닭을 빌려 나의 알을 낳는다"** - Vibe Coding으로 구현한 차세대 B2B 플랫폼

[![Salesforce](https://img.shields.io/badge/Salesforce-Lightning-00A1E0?style=flat-square&logo=salesforce)](https://salesforce.com)
[![Agentforce](https://img.shields.io/badge/Agentforce-AI%20Assistant-7057FF?style=flat-square)](https://www.salesforce.com/products/einstein/agentforce/)
[![Low Code](https://img.shields.io/badge/Low%20Code-80%25-4CAF50?style=flat-square)](https://github.com)

---

## 🎯 프로젝트 개요

SOCAR B2B 혁신 프로젝트는 Salesforce 플랫폼을 기반으로 한 차세대 B2B 비즈니스 관리 시스템입니다. Low Code/Vibe Coding 철학을 바탕으로, 기존 플랫폼의 강력함을 창의적으로 활용하여 새로운 가치를 창출합니다.

### 🌟 핵심 특징
- 🤖 **Agentforce 통합**: AI 기반 고객 서비스 자동화
- ⚡ **Lightning Web Components**: 모던하고 반응형 사용자 인터페이스
- 🔄 **Flow 자동화**: 복잡한 비즈니스 프로세스 자동화
- 📊 **360도 고객 뷰**: 통합된 고객 데이터 관리
- 🚗 **SOCAR 특화**: 차량 공유 비즈니스에 최적화

---

## 📚 문서 구조

### 🚀 시작하기
- [[개발 환경 설정|Development-Setup]]
- [[프로젝트 구조|Project-Structure]]
- [[배포 가이드|Deployment-Guide]]

### 🏗️ 아키텍처
- [[시스템 아키텍처|System-Architecture]]
- [[데이터 모델|Data-Model]]
- [[보안 가이드|Security-Guide]]

### 🤖 Agentforce
- [[Agentforce 개요|Agentforce-Overview]]
- [[Action 개발 가이드|Agentforce-Actions]]
- [[Topic 설정 가이드|Agentforce-Topics]]
- [[Knowledge Base 관리|Agentforce-Knowledge-Base]]

### 💻 개발 가이드
- [[Apex 개발 가이드|Apex-Development]]
- [[LWC 개발 가이드|LWC-Development]]
- [[Flow 개발 가이드|Flow-Development]]
- [[테스트 가이드|Testing-Guide]]

### 🔗 API 문서
- [[REST API 가이드|REST-API]]
- [[GraphQL API|GraphQL-API]]
- [[외부 시스템 연동|External-Integration]]

### 🚗 SOCAR 비즈니스
- [[주문 관리 시스템|Order-Management]]
- [[결제 시스템|Payment-System]]
- [[고객 관리|Customer-Management]]
- [[분석 및 리포팅|Analytics-Reporting]]

### 🛠️ 운영 가이드
- [[모니터링|Monitoring]]
- [[트러블슈팅|Troubleshooting]]
- [[성능 최적화|Performance-Optimization]]
- [[백업 및 복구|Backup-Recovery]]

---

## 🎵 Vibe Coding 철학

> **"코드는 언어이고, 감정은 문법이다. 둘 다 완벽해야 진짜 소통이 시작된다."**

이 프로젝트는 단순한 기술 구현이 아닙니다. 사용자의 감정과 경험을 최우선으로 하는 **Vibe Coding** 철학을 바탕으로 만들어졌습니다.

### 💡 핵심 원칙
1. **사람 중심**: 기술보다 사람의 문제 해결에 집중
2. **감정 전달**: 코드를 통해 긍정적인 사용자 경험을 창조
3. **창의적 활용**: 기존 플랫폼을 혁신적으로 활용
4. **지속 가능성**: 장기적으로 유지보수 가능한 설계

---

## 🚀 빠른 시작

### 1. 개발 환경 준비
```bash
# Salesforce CLI 설치
npm install -g @salesforce/cli

# 프로젝트 클론
git clone https://github.com/Salesforce-Sales-B2B-Socar/MainOrgProject.git
cd MainOrgProject

# 의존성 설치
npm install
```

### 2. Scratch Org 생성
```bash
# Scratch Org 생성
sf org create scratch -f config/project-scratch-def.json -a socar-scratch

# 소스 배포
sf project deploy start -o socar-scratch

# Org 열기
sf org open -o socar-scratch
```

### 3. Agentforce 설정
Agentforce 기능을 사용하려면 [[Agentforce 설정 가이드|Agentforce-Setup]]를 참조하세요.

---

## 📊 프로젝트 현황

### 🏆 주요 성과
- ✅ Salesforce Lightning Platform 완전 활용
- ✅ Agentforce AI Assistant 통합 완료
- ✅ 80% Low Code / 20% Custom Code 비율 달성
- ✅ 자동화된 CI/CD 파이프라인 구축

### 📈 기술 스택
| 영역 | 기술 |
|------|------|
| **Platform** | Salesforce Lightning Platform |
| **Frontend** | Lightning Web Components (LWC) |
| **Backend** | Apex, Salesforce APIs |
| **AI** | Agentforce, Einstein |
| **Automation** | Salesforce Flow, Process Builder |
| **Integration** | REST/SOAP APIs, MuleSoft |
| **Testing** | Jest, Apex Test Classes |
| **CI/CD** | GitHub Actions, Salesforce CLI |

---

## 👥 팀 및 기여

### 🎭 역할
- **Product Owner**: SOCAR 비즈니스 요구사항 정의
- **Salesforce Developer**: Platform 개발 및 커스터마이징
- **Agentforce Specialist**: AI Assistant 설계 및 구현
- **QA Engineer**: 품질 보증 및 테스트

### 🤝 기여 방법
1. [[개발 가이드|Development-Guide]] 읽기
2. [[이슈 생성|https://github.com/Salesforce-Sales-B2B-Socar/MainOrgProject/issues/new/choose]]
3. [[Pull Request 생성|https://github.com/Salesforce-Sales-B2B-Socar/MainOrgProject/compare]]
4. [[코드 리뷰 가이드|Code-Review-Guide]] 준수

---

## 📞 지원 및 연락

### 🚨 긴급 지원
- **Slack**: `#socar-b2b-dev`
- **Email**: socar-b2b-dev@example.com
- **On-call**: +82-10-XXXX-XXXX

### 💬 커뮤니티
- [[GitHub Discussions|https://github.com/Salesforce-Sales-B2B-Socar/MainOrgProject/discussions]]
- [[Trailblazer Community|https://trailblazers.salesforce.com/]]

---

## 📝 최신 업데이트

### 🎉 v1.2.0 (2025-07-30)
- 🤖 Agentforce 완전 통합
- ⚡ 성능 최적화 (30% 향상)
- 🔒 보안 강화 (OWASP 준수)
- 📱 모바일 반응형 개선

### 🎯 다음 릴리스 (v1.3.0)
- 🌍 다국어 지원
- 📊 고급 분석 대시보드
- 🔄 실시간 동기화
- 🤖 AI 예측 기능 확장

---

**🎵 "Every great platform starts with understanding the human behind the screen."** - Vibe Coding Team 💫
