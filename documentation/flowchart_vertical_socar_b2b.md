# SOCAR B2B 비즈니스 프로세스 - 세로형 플로우차트

```mermaid
---
config:
  layout: dagre
---
flowchart TD
    A["💼 기회<br><small>영업 기회 발생</small>"] --> B["📦 기회제품<br><small>제품 정보 확인</small>"]
    B --> C["🚀 주문시작<br><small>정식 주문 개시</small>"]
    C --> D["📋 주문제품<br><small>기회제품→주문제품</small>"]
    C --> E{"💳 납부방법<br>월/분기/반기/년<br><small>고객 맞춤 선택</small>"}
    
    D --> F["📅 납부일정생성<br><small>자동 일정 생성</small>"]
    E --> F
    
    F --> G["📱 고객납부앱<br><small>Slack 앱 연동</small>"]
    G --> H["💰 납부진행<br><small>고객 직접 납부</small>"]
    H --> I["📈 납부현황<br><small>실시간 모니터링</small>"]
    
    I --> J["⚠️ 연체알림Task<br><small>지연시 자동 알림</small>"]
    I --> K["✅ 완료알림Task<br><small>납부완료 확인</small>"]
    I --> L["📄 PDF생성Task<br><small>증빙서류 요청</small>"]
    
    J --> M["👥 영업지원팀<br><small>Task 자동 할당</small>"]
    K --> M
    L --> M
    
    L --> O["🖨️ PDF생성<br><small>버튼 클릭 생성</small>"]
    
    O --> P["📄 납부확인서<br><small>납부 완료 증명</small>"]
    O --> Q["📄 세금계산서<br><small>세무 신고용</small>"]
    
    P --> R["👤 영업사원<br><small>고객 관리 정보</small>"]
    P --> S["🏢 고객<br><small>회계 처리용</small>"]
    P --> AssetDoc["💾 Asset 증빙저장<br><small>납부확인서 저장</small>"]
    
    Q --> R
    Q --> S
    Q --> AssetDoc
    
    I --> |전체완료시| N["🏢 자산생성<br><small>Asset 자동 생성</small>"]
    AssetDoc --> N
    
    N --> AccountB2B["📊 Account B2B 뷰"]
    
    AccountB2B --> OrderStatus["📈 Order 현황"]
    AccountB2B --> OpportunityStatus["🎯 Opportunity 현황"]
    AccountB2B --> AssetStatus["🏢 Asset 현황"]
    
    OrderStatus --> OrderList["📋 Order 목록"]
    OrderList --> Insight360["🔍 360도 인사이트<br><small>완전한 고객 뷰 실현</small>"]
    
    OpportunityStatus --> Insight360
    AssetStatus --> Insight360
    
    R --> T["🎉 고객 360도 리사이클 실현"]
    S --> T
    Insight360 --> T
    
    %% 스타일 정의
    A:::main
    B:::main
    C:::main
    D:::main
    E:::main
    F:::main
    G:::customer
    H:::customer
    I:::main
    J:::task
    K:::task
    L:::task
    M:::task
    O:::pdf
    N:::main
    P:::pdf
    Q:::pdf
    R:::people
    S:::people
    AssetDoc:::pdf
    AccountB2B:::b2b
    OrderStatus:::b2b
    OpportunityStatus:::b2b
    AssetStatus:::b2b
    OrderList:::b2b
    Insight360:::insight
    T:::people
    
    %% 클래스 스타일 정의
    classDef main fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef customer fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef task fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef pdf fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef people fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    classDef b2b fill:#f1f8e9,stroke:#558b2f,stroke-width:2px
    classDef insight fill:#e1f5fe,stroke:#0277bd,stroke-width:3px
```

## 주요 변경사항

1. **방향 변경**: `flowchart LR` → `flowchart TD` (세로 방향)
2. **연결 구조 최적화**: 세로 흐름에 맞게 노드 간 연결 재배치
3. **가독성 향상**: 병렬 프로세스를 명확하게 구분
4. **레이아웃 개선**: Dagre 레이아웃을 활용한 자동 정렬

## 프로세스 흐름 요약

1. **영업 단계**: 기회 → 기회제품 → 주문시작
2. **주문 처리**: 주문제품 + 납부방법 선택 → 납부일정생성
3. **고객 납부**: 고객납부앱 → 납부진행 → 납부현황
4. **Task 관리**: 연체/완료/PDF생성 알림 → 영업지원팀
5. **문서 생성**: PDF생성 → 납부확인서/세금계산서
6. **자산 관리**: Asset 증빙저장 → 자산생성
7. **B2B 뷰**: Account B2B → Order/Opportunity/Asset 현황
8. **최종 목표**: 360도 인사이트 → 고객 리사이클 실현
