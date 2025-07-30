# 🏢 SOCAR B2B Innovation Team Organization 설정 가이드

## 📋 Organization 정보
- **이름**: SOCAR-B2B-Innovation-Team
- **목적**: SOCAR B2B 혁신 프로젝트 통합 관리
- **플랫폼**: Salesforce Low Code/Vibe Coding

## 🚀 Organization 생성 단계

### 1단계: GitHub Organization 생성

1. **GitHub 프로필 → Your organizations → New organization**
2. **Organization 정보 입력:**
   ```
   Organization account name: SOCAR-B2B-Innovation-Team
   Contact email: team-leader@socar.kr
   Plan: Free (시작용) → Team (필요시 업그레이드)
   ```

### 2단계: 기본 설정

**Member privileges 권장 설정:**
```yaml
Base permissions: Read
Repository creation: Private repositories only
Repository forking: Allow forking of private repositories
Repository deletion: Only organization owners
Team creation: Allow members to create teams
```

### 3단계: Teams 구성

**개발팀 구조:**
```
🏢 SOCAR-B2B-Innovation-Team
├── 📁 Core Developers (Admin 권한)
│   ├── @MoonJH-2 (Team Lead)
│   ├── @enigmapark (Senior Developer)
│   └── @honghyowon (Developer)
├── 📁 QA Team (Write 권한)
│   └── (QA 엔지니어들)
└── 📁 Stakeholders (Read 권한)
    └── (기획자, PM들)
```

## 🔧 저장소 이전 프로세스

### 방법 1: 기존 저장소 Transfer (권장)

1. **기존 개인 저장소 Settings로 이동**
2. **"Transfer ownership" 섹션에서:**
   ```
   New owner: SOCAR-B2B-Innovation-Team
   Repository name: MainOrgProject
   ```

### 방법 2: 새 저장소 생성 후 코드 이전

1. **Organization에서 "New repository" 생성**
2. **로컬에서 원격 저장소 변경:**
   ```bash
   # 자동화 스크립트 사용
   ./scripts/change-remote-to-new-org.sh SOCAR-B2B-Innovation-Team
   
   # 또는 수동으로
   git remote set-url origin git@github.com:SOCAR-B2B-Innovation-Team/MainOrgProject.git
   git push -u origin main
   ```

## 🛡️ 보안 설정

### 브랜치 보호 규칙

**main 브랜치 보호:**
```yaml
Branch name pattern: main
Settings:
  ✅ Require a pull request before merging (1 reviewer)
  ✅ Require status checks to pass before merging
  ✅ Require conversation resolution before merging
  ✅ Require linear history
  ✅ Do not allow bypassing the above settings
  ❌ Allow force pushes
  ❌ Allow deletions
```

### 필수 상태 검사

```yaml
Required status checks:
  ✅ security-scan
  ✅ salesforce-validation
  ✅ code-quality
  ✅ unit-tests
  ✅ documentation-check
```

## 📊 Organization 관리

### 정기 검토 항목

**월간 Organization 리뷰:**
- [ ] 멤버 권한 검토
- [ ] 저장소 접근 권한 확인
- [ ] 보안 정책 업데이트
- [ ] 팀 구조 최적화

**분기별 Organization 감사:**
- [ ] 보안 취약점 스캔
- [ ] 사용하지 않는 저장소 정리
- [ ] 권한 남용 여부 검토
- [ ] 비용 최적화 검토

### 멤버 온보딩 프로세스

**새 멤버 추가 시:**
1. Organization 초대 발송
2. 적절한 Team에 배정
3. 저장소별 권한 부여
4. 개발 환경 설정 가이드 제공
5. 브랜치 보호 규칙 교육

## 🎯 성공 지표

### Organization 운영 KPI

```yaml
목표 지표:
  📈 코드 리뷰율: 100%
  🔒 보안 스캔 통과율: 100%
  🚀 배포 성공률: 95%+
  👥 멤버 만족도: 4.5/5.0
  📚 문서 최신화율: 90%+
```

### 프로젝트 성과 추적

```yaml
개발 효율성:
  ⏱️ 평균 PR 리뷰 시간: 24시간 이내
  🐛 버그 발견율: 배포 전 95%
  📦 배포 빈도: 주 2회
  🔄 핫픽스 비율: 5% 이하
```

## 🔗 관련 링크

- **Organization**: https://github.com/SOCAR-B2B-Innovation-Team
- **MainOrgProject**: https://github.com/SOCAR-B2B-Innovation-Team/MainOrgProject
- **브랜치 보호 가이드**: [BRANCH_PROTECTION_GUIDE.md](./BRANCH_PROTECTION_GUIDE.md)
- **팀 협업 가이드**: [TEAM_COLLABORATION_GUIDE.md](../TEAM_COLLABORATION_GUIDE.md)

## 📞 지원 및 문의

**Technical Lead**: @MoonJH-2  
**Organization Admin**: team-leader@socar.kr  
**개발 문의**: Slack #socar-b2b-dev  
**긴급 이슈**: GitHub Issues 또는 Slack DM
