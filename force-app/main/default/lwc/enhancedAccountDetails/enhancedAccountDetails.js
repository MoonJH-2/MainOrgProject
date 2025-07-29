import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Account fields - 화면에 표시된 모든 필드 포함
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_PHONE_FIELD from '@salesforce/schema/Account.Phone';
import ACCOUNT_WEBSITE_FIELD from '@salesforce/schema/Account.Website';
import ACCOUNT_INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';
import ACCOUNT_ANNUAL_REVENUE_FIELD from '@salesforce/schema/Account.AnnualRevenue';
import ACCOUNT_EMPLOYEES_FIELD from '@salesforce/schema/Account.NumberOfEmployees';
import ACCOUNT_SHIPPING_ADDRESS_FIELD from '@salesforce/schema/Account.ShippingAddress';
import ACCOUNT_DESCRIPTION_FIELD from '@salesforce/schema/Account.Description';
import ACCOUNT_OWNER_FIELD from '@salesforce/schema/Account.OwnerId';
import ACCOUNT_PARENT_FIELD from '@salesforce/schema/Account.ParentId';
import ACCOUNT_RECORD_TYPE_FIELD from '@salesforce/schema/Account.RecordTypeId';
import ACCOUNT_SOURCE_FIELD from '@salesforce/schema/Account.AccountSource';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Account.Type';
import ACCOUNT_CREATED_BY_FIELD from '@salesforce/schema/Account.CreatedById';
import ACCOUNT_CREATED_DATE_FIELD from '@salesforce/schema/Account.CreatedDate';
import ACCOUNT_MODIFIED_BY_FIELD from '@salesforce/schema/Account.LastModifiedById';
import ACCOUNT_MODIFIED_DATE_FIELD from '@salesforce/schema/Account.LastModifiedDate';

// Custom fields
import BUSINESS_NUMBER_FIELD from '@salesforce/schema/Account.BusinessNumber__c';
import KEY_ACCOUNT_FIELD from '@salesforce/schema/Account.Key_Account__c';
import BUSINESS_NUMBER_VERIFIED_FIELD from '@salesforce/schema/Account.BusinessNumberVerified__c';

const ACCOUNT_FIELDS = [
    ACCOUNT_NAME_FIELD,
    ACCOUNT_PHONE_FIELD,
    ACCOUNT_WEBSITE_FIELD,
    ACCOUNT_INDUSTRY_FIELD,
    ACCOUNT_ANNUAL_REVENUE_FIELD,
    ACCOUNT_EMPLOYEES_FIELD,
    ACCOUNT_SHIPPING_ADDRESS_FIELD,
    ACCOUNT_DESCRIPTION_FIELD,
    ACCOUNT_OWNER_FIELD,
    ACCOUNT_PARENT_FIELD,
    ACCOUNT_RECORD_TYPE_FIELD,
    ACCOUNT_SOURCE_FIELD,
    ACCOUNT_TYPE_FIELD,
    ACCOUNT_CREATED_BY_FIELD,
    ACCOUNT_CREATED_DATE_FIELD,
    ACCOUNT_MODIFIED_BY_FIELD,
    ACCOUNT_MODIFIED_DATE_FIELD,
    BUSINESS_NUMBER_FIELD,
    KEY_ACCOUNT_FIELD,
    BUSINESS_NUMBER_VERIFIED_FIELD
];

export default class EnhancedAccountDetails extends NavigationMixin(LightningElement) {
    @api recordId;
    @track selectedTab = 'summary';
    @track isLoading = false;
    @track account;
    @track newsData = [];
    @track relatedCounts = {
        contacts: 0,
        opportunities: 0,
        cases: 0,
        attachments: 0
    };

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.account = data;
            this.loadRelatedCounts();
            this.loadNewsData();
        } else if (error) {
            console.error('Account 데이터 로드 오류:', error);
            this.showToast('오류', 'Account 정보를 불러올 수 없습니다.', 'error');
        }
    }

    // Getter methods for all account fields
    get accountName() {
        return getFieldValue(this.account, ACCOUNT_NAME_FIELD) || '';
    }

    get accountPhone() {
        return getFieldValue(this.account, ACCOUNT_PHONE_FIELD) || '';
    }

    get accountWebsite() {
        return getFieldValue(this.account, ACCOUNT_WEBSITE_FIELD) || '';
    }

    get accountIndustry() {
        return getFieldValue(this.account, ACCOUNT_INDUSTRY_FIELD) || '';
    }

    get accountAnnualRevenue() {
        const revenue = getFieldValue(this.account, ACCOUNT_ANNUAL_REVENUE_FIELD);
        return revenue ? '₩' + revenue.toLocaleString() : '';
    }

    get accountEmployees() {
        return getFieldValue(this.account, ACCOUNT_EMPLOYEES_FIELD) || '';
    }

    get accountShippingAddress() {
        const address = getFieldValue(this.account, ACCOUNT_SHIPPING_ADDRESS_FIELD);
        if (address) {
            return `${address.street || ''} ${address.city || ''} ${address.state || ''} ${address.postalCode || ''} ${address.country || ''}`;
        }
        return '';
    }

    get accountDescription() {
        return getFieldValue(this.account, ACCOUNT_DESCRIPTION_FIELD) || '';
    }

    get businessNumber() {
        return getFieldValue(this.account, BUSINESS_NUMBER_FIELD) || '';
    }

    get isKeyAccount() {
        return getFieldValue(this.account, KEY_ACCOUNT_FIELD) || false;
    }

    get businessNumberVerified() {
        return getFieldValue(this.account, BUSINESS_NUMBER_VERIFIED_FIELD) || '';
    }

    get accountSource() {
        return getFieldValue(this.account, ACCOUNT_SOURCE_FIELD) || '';
    }

    get accountType() {
        return getFieldValue(this.account, ACCOUNT_TYPE_FIELD) || '';
    }

    get createdDate() {
        const date = getFieldValue(this.account, ACCOUNT_CREATED_DATE_FIELD);
        return date ? new Date(date).toLocaleDateString('ko-KR') : '';
    }

    get modifiedDate() {
        const date = getFieldValue(this.account, ACCOUNT_MODIFIED_DATE_FIELD);
        return date ? new Date(date).toLocaleDateString('ko-KR') : '';
    }

    // Tab management
    get isSummaryTab() {
        return this.selectedTab === 'summary';
    }

    get isDetailsTab() {
        return this.selectedTab === 'details';
    }

    get isRelatedTab() {
        return this.selectedTab === 'related';
    }

    get isNewsTab() {
        return this.selectedTab === 'news';
    }

    // Priority and status indicators
    get priorityVariant() {
        if (this.isKeyAccount) return 'success';
        if (this.accountAnnualRevenue && parseFloat(this.accountAnnualRevenue.replace(/[₩,]/g, '')) > 1000000000) return 'warning';
        return 'neutral';
    }

    get priorityLabel() {
        if (this.isKeyAccount) return '주요 고객';
        if (this.accountAnnualRevenue && parseFloat(this.accountAnnualRevenue.replace(/[₩,]/g, '')) > 1000000000) return '대기업';
        return '일반';
    }

    // Tab management
    get detailsTabClass() {
        return this.selectedTab === 'details' ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item';
    }

    get relatedTabClass() {
        return this.selectedTab === 'related' ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item';
    }

    get newsTabClass() {
        return this.selectedTab === 'news' ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item';
    }

    get showDetailsTab() {
        return this.selectedTab === 'details';
    }

    get showRelatedTab() {
        return this.selectedTab === 'related';
    }

    get showNewsTab() {
        return this.selectedTab === 'news';
    }

    // Tab handlers
    handleDetailsTab() {
        this.selectedTab = 'details';
    }

    handleRelatedTab() {
        this.selectedTab = 'related';
    }

    handleNewsTab() {
        this.selectedTab = 'news';
    }

    // Load related record counts
    async loadRelatedCounts() {
        try {
            // 실제 구현에서는 Apex 메서드를 호출하여 관련 레코드 수를 가져옵니다
            // 지금은 하드코딩된 값으로 시연
            this.relatedCounts = {
                contacts: 0,
                opportunities: 1,
                cases: 0,
                attachments: 0
            };
        } catch (error) {
            console.error('관련 레코드 수 로드 오류:', error);
        }
    }

    // Quick actions
    handleCall() {
        if (this.accountPhone) {
            window.open(`tel:${this.accountPhone}`);
        } else {
            this.showToast('정보 없음', '전화번호가 등록되지 않았습니다.', 'warning');
        }
    }

    handleWebsite() {
        if (this.accountWebsite) {
            window.open(this.accountWebsite, '_blank');
        } else {
            this.showToast('정보 없음', '웹사이트가 등록되지 않았습니다.', 'warning');
        }
    }

    handleCreateContact() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contact',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `AccountId=${this.recordId}`
            }
        });
    }

    handleCreateOpportunity() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `AccountId=${this.recordId}`
            }
        });
    }

    handleCreateCase() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `AccountId=${this.recordId}`
            }
        });
    }

    // Navigation to related records
    handleViewContacts() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                relationshipApiName: 'Contacts',
                actionName: 'view'
            }
        });
    }

    handleViewOpportunities() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                relationshipApiName: 'Opportunities',
                actionName: 'view'
            }
        });
    }

    handleViewCases() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                relationshipApiName: 'Cases',
                actionName: 'view'
            }
        });
    }

    // Utility methods
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    // Industry insights
    get industryInsights() {
        if (this.accountIndustry) {
            const insights = this.getIndustrySpecificInsights(this.accountIndustry);
            return insights;
        }
        return [];
    }

    getIndustrySpecificInsights(industry) {
        const insights = [];
        
        if (industry.includes('Technology') || industry.includes('Software')) {
            insights.push('🚀 기술 기업: 혁신적 솔루션 제안 기회');
            insights.push('📈 디지털 트랜스포메이션 관련 서비스 검토');
        } else if (industry.includes('Healthcare') || industry.includes('Medical')) {
            insights.push('🏥 헬스케어: 규제 준수 및 보안 중요');
            insights.push('📊 데이터 분석 및 환자 관리 솔루션');
        } else if (industry.includes('Financial') || industry.includes('Banking')) {
            insights.push('💰 금융: 보안 및 컴플라이언스 최우선');
            insights.push('🔐 리스크 관리 및 자동화 솔루션');
        } else {
            insights.push('💼 업종별 맞춤 솔루션 검토 필요');
            insights.push('📋 업계 동향 및 경쟁사 분석 진행');
        }
        
        return insights;
    }

    // Business insights based on company size
    get companyInsights() {
        const insights = [];
        const employees = getFieldValue(this.account, ACCOUNT_EMPLOYEES_FIELD);
        
        if (employees) {
            if (employees >= 1000) {
                insights.push('🏢 대기업: 전사적 도입 및 확장 가능성');
                insights.push('🎯 다부서 연계 프로젝트 제안');
            } else if (employees >= 100) {
                insights.push('🏬 중견기업: 단계적 도입 전략 수립');
                insights.push('📈 성장 지원 솔루션 집중');
            } else {
                insights.push('🚀 중소기업: 효율성 및 ROI 중심 접근');
                insights.push('💡 간단하고 실용적인 솔루션 제안');
            }
        }
        
        return insights;
    }

    // HTML 템플릿을 위한 추가 getter 메서드들
    get summaryTabClass() {
        return this.selectedTab === 'summary' ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item';
    }

    get accountSummaryData() {
        return [
            {
                label: '회사명',
                value: this.accountName,
                icon: 'standard:account',
                variant: 'brand'
            },
            {
                label: '전화번호',
                value: this.accountPhone,
                icon: 'utility:phone',
                variant: 'success'
            },
            {
                label: '웹사이트',
                value: this.accountWebsite,
                icon: 'utility:world',
                variant: 'brand'
            },
            {
                label: '업종',
                value: this.accountIndustry,
                icon: 'utility:building',
                variant: 'warning'
            },
            {
                label: '연간 매출',
                value: this.accountAnnualRevenue,
                icon: 'utility:currency',
                variant: 'success'
            },
            {
                label: '직원 수',
                value: this.accountEmployees,
                icon: 'utility:people',
                variant: 'brand'
            }
        ];
    }

    get detailFields() {
        return [
            { label: '계정명', apiName: 'Name', value: this.accountName },
            { label: '전화번호', apiName: 'Phone', value: this.accountPhone },
            { label: '웹사이트', apiName: 'Website', value: this.accountWebsite },
            { label: '업종', apiName: 'Industry', value: this.accountIndustry },
            { label: '연간 매출', apiName: 'AnnualRevenue', value: this.accountAnnualRevenue },
            { label: '직원 수', apiName: 'NumberOfEmployees', value: this.accountEmployees },
            { label: '배송 주소', apiName: 'ShippingAddress', value: this.accountShippingAddress },
            { label: '설명', apiName: 'Description', value: this.accountDescription },
            { label: '계정 소스', apiName: 'AccountSource', value: this.accountSource },
            { label: '계정 유형', apiName: 'Type', value: this.accountType },
            { label: '사업자 번호', apiName: 'BusinessNumber__c', value: this.businessNumber },
            { label: '주요 고객', apiName: 'Key_Account__c', value: this.isKeyAccount ? '예' : '아니오' },
            { label: '사업자 번호 검증', apiName: 'BusinessNumberVerified__c', value: this.businessNumberVerified ? '검증됨' : '미검증' }
        ];
    }

    get relatedSummary() {
        return [
            {
                name: '연락처',
                count: this.relatedCounts.contacts,
                icon: 'standard:contact',
                variant: 'brand'
            },
            {
                name: '영업기회',
                count: this.relatedCounts.opportunities,
                icon: 'standard:opportunity',
                variant: 'success'
            },
            {
                name: '케이스',
                count: this.relatedCounts.cases,
                icon: 'standard:case',
                variant: 'warning'
            },
            {
                name: '첨부파일',
                count: this.relatedCounts.attachments,
                icon: 'standard:file',
                variant: 'neutral'
            }
        ];
    }

    get sampleNewsData() {
        return this.newsData.length > 0 ? this.newsData : null;
    }

    // 이벤트 핸들러들
    handleTabSelect(event) {
        this.selectedTab = event.currentTarget.dataset.tab;
    }

    handlePhoneClick() {
        if (this.accountPhone) {
            window.open(`tel:${this.accountPhone}`);
        }
    }

    handleWebsiteClick() {
        if (this.accountWebsite) {
            window.open(this.accountWebsite, '_blank');
        }
    }

    handleNewRecord(event) {
        const objectName = event.currentTarget.dataset.object;
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: objectName,
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `AccountId=${this.recordId}`
            }
        });
    }

    handleViewRelated(event) {
        const objectName = event.currentTarget.dataset.object;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                relationshipApiName: this.getRelationshipName(objectName),
                actionName: 'view'
            }
        });
    }

    handleKeyDown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleViewRelated(event);
        }
    }

    getRelationshipName(objectName) {
        const relationships = {
            '연락처': 'Contacts',
            '영업기회': 'Opportunities',
            '케이스': 'Cases',
            '첨부파일': 'AttachedContentDocuments'
        };
        return relationships[objectName] || objectName;
    }
}
