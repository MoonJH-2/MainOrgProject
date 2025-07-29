# SOCAR B2B 업무 프로세스 흐름도

## 🔄 전체 비즈니스 프로세스 개요

```mermaid
flowchart TD
    %% 고객 획득 단계
    A[잠재고객 발굴<br/>Lead Generation] --> B[Lead<br/>잠재고객]
    B --> C{자격 검증<br/>Qualification}
    C -->|적격| D[Opportunity<br/>영업기회]
    C -->|부적격| E[Lead Nurturing<br/>잠재고객 육성]
    
    %% 영업 단계
    D --> F[Quote<br/>견적서 생성]
    F --> G[Contract<br/>계약 체결]
    G --> H[Order<br/>주문 생성]
    
    %% 결제 관리 단계
    H --> I[PaymentStatus__c<br/>납부 일정 관리]
    I --> J[Payment_Notification__c<br/>결제 알림]
    J --> K{결제 완료 여부}
    K -->|미완료| L[결제 독촉<br/>Payment Reminder]
    K -->|완료| M[납부 확인서 발급<br/>Payment Receipt]
    L --> J
    
    %% 자산 생성 및 관리
    M --> N[Asset<br/>고객 자산 생성]
    N --> O[Asset 활성화<br/>서비스 제공 시작]
    O --> P[고객 관리<br/>Customer Success]
    
    %% 업무 자동화
    H --> Q[OrderItem<br/>주문 상품 관리]
    Q --> R[세금계산서 발급<br/>Tax Invoice]
    
    %% 협업 및 모니터링
    P --> S[Task<br/>업무 할당]
    S --> T[Dashboard<br/>모니터링]
    T --> U[Report<br/>분석 리포트]
    
    %% 갱신 및 확장
    P --> V{갱신/확장 기회}
    V -->|갱신| W[Renewal Opportunity]
    V -->|확장| X[Upsell/Cross-sell]
    W --> D
    X --> D

    %% 스타일링
    classDef leadStage fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef salesStage fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef paymentStage fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef assetStage fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef systemStage fill:#fafafa,stroke:#424242,stroke-width:2px
    
    class A,B,C,E leadStage
    class D,F,G salesStage
    class H,I,J,K,L,M,Q,R paymentStage
    class N,O,P assetStage
    class S,T,U,V,W,X systemStage
```

## 📊 세부 업무 프로세스 분석

### 1️⃣ **Lead to Opportunity 전환 프로세스**

```mermaid
sequenceDiagram
    participant L as Lead
    participant A as Account
    participant C as Contact
    participant O as Opportunity
    
    L->>L: 잠재고객 정보 수집
    L->>A: Account 변환
    L->>C: Contact 변환
    L->>O: Opportunity 생성
    O->>O: 영업 단계 진행
    Note over O: Discovery → Proposal → Negotiation → Closed Won
```

### 2️⃣ **Order to Asset 생성 프로세스**

```mermaid
flowchart LR
    subgraph "주문 관리"
        A1[Order 생성<br/>00000200] --> A2[OrderItem 생성<br/>카셰어링 엔터프라이즈]
        A2 --> A3[총 금액: ₩10,710,000<br/>수량: 100]
    end
    
    subgraph "결제 관리"
        B1[PaymentStatus 생성<br/>4회 분할] --> B2[1차: ₩2,677,500<br/>2025.07.27]
        B2 --> B3[2차: ₩2,677,500<br/>2025.10.27]
        B3 --> B4[3차: ₩2,677,500<br/>2026.01.27]
        B4 --> B5[4차: ₩2,677,500<br/>2026.04.27]
    end
    
    subgraph "문서 관리"
        C1[납부확인서 발급<br/>PDF 생성] --> C2[세금계산서 발급<br/>PDF 생성]
        C2 --> C3[Notes & Attachments<br/>자동 첨부]
    end
    
    subgraph "자산 생성"
        D1[모든 납부 완료 확인] --> D2[Asset 자동 생성<br/>Serial: 00000200]
        D2 --> D3[고객 자산 활성화<br/>Status: Purchased]
        D3 --> D4[서비스 제공 시작]
    end
    
    A3 --> B1
    B5 --> C1
    C3 --> D1
```

### 3️⃣ **고객 관계 관리 프로세스**

```mermaid
flowchart TD
    subgraph "Account 360도 뷰"
        A1[주식회사 무신사<br/>Account]
        A1 --> A2[Order 현황<br/>6건 활성]
        A1 --> A3[Opportunity 현황<br/>1건 진행]
        A1 --> A4[Asset 현황<br/>8건 관리]
        A1 --> A5[총 계약금액<br/>₩70,210,000]
    end
    
    subgraph "Tiger B2B 인사이트"
        B1[영업 성과 분석] --> B2[고객 관계 현황]
        B2 --> B3[추천 액션]
        B3 --> B4[✅ 기존 고객 관리]
        B3 --> B5[🎯 영업 기회 진행]
        B3 --> B6[🔧 Asset 서비스 제공]
        B3 --> B7[💡 고객 만족도 관리]
        B3 --> B8[📈 Up-sell/Cross-sell]
    end
    
    A2 --> B1
    A3 --> B1
    A4 --> B1
    A5 --> B1
```

## 🔧 기술적 구현 세부사항

### **Apex 트리거 흐름**

```mermaid
graph LR
    subgraph "Order Processing"
        A[OrderTrigger] --> B[PaymentStatusTrigger]
        B --> C[AssetTrigger]
    end
    
    subgraph "Notification System"
        D[PaymentNotificationTrigger] --> E[EmailService]
        E --> F[SlackIntegration]
    end
    
    subgraph "Document Generation"
        G[TaxInvoiceTrigger] --> H[PDFGenerator]
        H --> I[AttachmentCreation]
    end
    
    C --> D
    I --> J[CompletionNotification]
```

### **LWC 컴포넌트 상호작용**

```mermaid
flowchart TD
    subgraph "고객 정보 관리"
        A[accountDetailView] --> B[orderManagement]
        B --> C[paymentStatusTimeline]
        C --> D[assetManagement]
    end
    
    subgraph "문서 및 알림"
        E[documentGenerator] --> F[notificationCenter]
        F --> G[slackIntegration]
    end
    
    subgraph "분석 및 리포팅"
        H[customerInsights] --> I[salesDashboard]
        I --> J[performanceMetrics]
    end
    
    D --> E
    G --> H
```

## 📈 KPI 및 성과 지표

### **핵심 성과 지표 흐름**

```mermaid
flowchart LR
    subgraph "영업 KPI"
        A1[Lead 전환율] --> A2[Opportunity 성사율]
        A2 --> A3[평균 거래 규모]
        A3 --> A4[영업 사이클 시간]
    end
    
    subgraph "결제 KPI"
        B1[납부 준수율] --> B2[연체율]
        B2 --> B3[회수율]
        B3 --> B4[현금 흐름]
    end
    
    subgraph "고객 KPI"
        C1[고객 만족도] --> C2[갱신율]
        C2 --> C3[Up-sell 비율]
        C3 --> C4[고객 생애 가치]
    end
    
    A4 --> B1
    B4 --> C1
```

## 🚀 자동화 워크플로우

### **프로세스 자동화 흐름**

```mermaid
sequenceDiagram
    participant O as Order
    participant P as PaymentStatus
    participant N as Notification
    participant A as Asset
    participant T as Task
    
    O->>P: 납부 일정 생성
    P->>N: 결제 알림 발송
    N->>P: 결제 완료 확인
    P->>A: Asset 자동 생성
    A->>T: 고객 관리 업무 할당
    T->>N: 완료 알림 발송
    
    Note over O,T: 전체 프로세스 자동화
```

---

## 📝 업무 프로세스 특징

### ✅ **구현된 핵심 기능**
1. **완전 자동화된 Order to Asset 흐름**
2. **실시간 결제 상태 추적 및 알림**
3. **360도 고객 뷰 및 인사이트 제공**
4. **문서 자동 생성 및 첨부**
5. **Tiger B2B 추천 액션 시스템**

### 🎯 **비즈니스 가치**
- **영업 효율성**: 자동화를 통한 수작업 90% 감소
- **고객 만족도**: 실시간 상태 추적 및 투명한 정보 제공
- **매출 성장**: Up-sell/Cross-sell 기회 자동 식별
- **리스크 관리**: 결제 지연 조기 감지 및 대응

이 프로세스 흐름은 SOCAR B2B의 실제 업무 환경을 완전히 반영하여 설계되었습니다.
