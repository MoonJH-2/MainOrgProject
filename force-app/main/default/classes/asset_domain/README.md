# 🏢 Asset Domain

## 🎯 목적
고객 자산(Asset) 생성, 관리, 분석, 갱신 기회 발굴 등 Asset 생애주기 전반을 관리하는 도메인입니다.

## 📁 폴더 구조

### 🎮 controllers/
Asset 관련 Lightning Web Component 컨트롤러들
- `AssetManagementController.cls`: Asset 관리 메인 컨트롤러
- `AssetManagementController_Enhanced.cls`: 향상된 Asset 관리 컨트롤러
- `SalesAssetSupportController.cls`: 영업팀 Asset 지원 컨트롤러

### ⚙️ services/
Asset 핵심 비즈니스 로직들
- `AccountBasedAssetService.cls`: Account 분석 기반 Asset 서비스
- `OrderAssetCreationService.cls`: Order 완납 시 Asset 자동 생성
- `AssetStatusManagementService.cls`: Asset 상태 관리 서비스

### 📊 analytics/
Asset 분석 및 인텔리전스 엔진들
- `AssetBasedSalesOpportunityEngine.cls`: Asset 기반 영업 기회 엔진
- `AssetCustomerRiskAnalyzer.cls`: 고객 위험도 분석기
- `AssetROIAnalysisService.cls`: Asset ROI 분석 서비스
- `AssetPriorityCalculator.cls`: Asset 우선순위 계산기

### 🔄 renewal/
Asset 갱신 관련 서비스들
- `AssetRenewalOpportunityEngine.cls`: 갱신 기회 엔진
- `OneClickRenewalService.cls`: 원클릭 갱신 서비스

## 🔄 주요 비즈니스 플로우
```
Order 완납 감지 → Asset 자동 생성 → Account 분석 연동 → 고객 인사이트 생성 → 갱신 기회 식별 → 영업팀 알림
```

## 🤖 자동화 기능
1. **자동 Asset 생성**: Order 완납 시 즉시 Asset 생성
2. **Account 분석 연동**: 고객 특성 기반 맞춤형 Asset 정보 생성
3. **갱신 알림**: Asset 만료 6개월 전 자동 갱신 기회 알림
4. **위험도 분석**: 고객 이탈 위험도 실시간 분석

## 📈 비즈니스 인사이트
- **고객 포트폴리오 분석**: Account별 Asset 현황 시각화
- **갱신 기회 예측**: AI 기반 갱신 확률 계산
- **ROI 분석**: Asset별 수익성 분석 및 최적화 제안
- **리스크 관리**: 고객 이탈 위험 조기 감지

## 🤝 연관 도메인
- **Payment Domain**: 완납 시 Asset 생성 트리거
- **Order Domain**: Order 정보 기반 Asset 생성
- **Agentforce Integration**: AI 기반 Asset 분석 및 추천

## 📞 담당자
- **Lead Developer**: Moon JeongHyeon
- **Domain Expert**: Asset Domain Team
