# 🔐 GitHub Secrets 설정 가이드

이 문서는 SOCAR B2B Salesforce 프로젝트의 CI/CD를 위한 GitHub Secrets 설정 방법을 안내합니다.

## 필수 Secrets

### 1. Salesforce 인증 정보

#### `SALESFORCE_AUTH_URL`
- **설명**: 개발/스테이징 조직의 인증 URL
- **획득 방법**:
  ```bash
  sf org display --target-org your-dev-org --verbose
  ```
- **형식**: `force://PlatformCLI::CLIENT_ID::CLIENT_SECRET::USERNAME@INSTANCE_URL`

#### `SALESFORCE_PROD_AUTH_URL`
- **설명**: 프로덕션 조직의 인증 URL
- **획득 방법**:
  ```bash
  sf org display --target-org your-prod-org --verbose
  ```

### 2. 알림 설정

#### `SLACK_WEBHOOK_URL`
- **설명**: 배포 성공/실패 알림을 위한 Slack Webhook URL
- **설정 방법**:
  1. Slack 워크스페이스에서 Incoming Webhooks 앱 설치
  2. 채널 선택 후 Webhook URL 복사

## Secrets 설정 방법

1. GitHub 저장소로 이동
2. **Settings** → **Secrets and variables** → **Actions** 클릭
3. **New repository secret** 버튼 클릭
4. 위 목록의 각 Secret을 추가

## 보안 주의사항

⚠️ **절대 다음과 같은 정보를 코드에 포함하지 마세요:**
- Salesforce 사용자명/비밀번호
- API 키
- 인증 토큰

✅ **모든 민감한 정보는 GitHub Secrets를 통해서만 관리하세요.**

## 테스트 방법

Secrets 설정 후 다음 명령어로 테스트할 수 있습니다:

```bash
# 로컬에서 인증 테스트
sf org login sfdx-url --sfdx-url-file ./auth-url.txt

# 배포 검증 테스트
sf project deploy validate --source-dir force-app --test-level RunLocalTests
```
