# 🚀 VS Code에서 Salesforce Experience Cloud 개발 가이드

## 📋 목차
1. [개발 환경 설정](#1-개발-환경-설정)
2. [Experience Cloud 프로젝트 구조](#2-experience-cloud-프로젝트-구조)
3. [Digital Experience 컴포넌트 개발](#3-digital-experience-컴포넌트-개발)
4. [Community 템플릿 커스터마이징](#4-community-템플릿-커스터마이징)
5. [Lightning Web Components for Experience Sites](#5-lightning-web-components-for-experience-sites)
6. [Experience Builder 커스터마이징](#6-experience-builder-커스터마이징)
7. [배포 및 테스트](#7-배포-및-테스트)
8. [모범 사례](#8-모범-사례)

---

## 1. 개발 환경 설정

### 1.1 필수 확장 프로그램 설치

```bash
# Salesforce CLI 설치 (macOS)
brew install salesforce-cli

# 또는 npm을 통한 설치
npm install -g @salesforce/cli
```

### 1.2 VS Code 확장 프로그램

```json
{
  "recommendations": [
    "salesforce.salesforcedx-vscode",
    "salesforce.salesforcedx-vscode-apex",
    "salesforce.salesforcedx-vscode-lightning",
    "salesforce.salesforcedx-vscode-lwc",
    "ms-vscode.vscode-json",
    "bradlc.vscode-tailwindcss",
    "formulahendry.auto-rename-tag"
  ]
}
```

### 1.3 프로젝트 초기화

```bash
# SFDX 프로젝트 생성
sfdx project generate --name ExperienceCloudProject
cd ExperienceCloudProject

# Experience Cloud용 디렉토리 구조 생성
mkdir -p force-app/main/default/digitalExperiences
mkdir -p force-app/main/default/experiences
mkdir -p force-app/main/default/networkBranding
mkdir -p force-app/main/default/lwc
mkdir -p force-app/main/default/aura
```

---

## 2. Experience Cloud 프로젝트 구조

### 2.1 디렉토리 구조

```
ExperienceCloudProject/
├── force-app/main/default/
│   ├── digitalExperiences/         # Digital Experience 번들
│   │   └── site/
│   │       ├── guestProfile/
│   │       ├── sfdc_cms/
│   │       └── views/
│   ├── experiences/                # Experience 사이트 설정
│   │   └── MyExperience1/
│   ├── networkBranding/           # 브랜딩 설정
│   ├── lwc/                       # Lightning Web Components
│   │   ├── experienceHeader/
│   │   ├── experienceFooter/
│   │   └── customProductCatalog/
│   ├── aura/                      # Aura Components (Legacy)
│   ├── classes/                   # Apex Classes
│   ├── objects/                   # Custom Objects
│   ├── permissionsets/            # Permission Sets
│   └── staticresources/           # Static Resources
├── config/
│   └── project-scratch-def.json
└── sfdx-project.json
```

### 2.2 sfdx-project.json 설정

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true,
      "package": "ExperienceCloudProject",
      "versionName": "ver 0.1",
      "versionNumber": "0.1.0.NEXT"
    }
  ],
  "name": "ExperienceCloudProject",
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "60.0",
  "plugins": {
    "salesforce-alm": {}
  }
}
```

---

## 3. Digital Experience 컴포넌트 개발

### 3.1 Experience Site 메타데이터

```xml
<!-- force-app/main/default/experiences/MyExperience/config/mainAppPage.json -->
{
  "type": "sfdc_cms__view",
  "id": "home",
  "title": "Home",
  "contentKey": "mcms_sl_home",
  "contentType": "news",
  "shouldIndex": true,
  "urlRecipe": "/{!contentKey}",
  "urlRecipeText": "/home",
  "workspace": {
    "isRoot": true
  }
}
```

### 3.2 사이트 설정 파일

```xml
<!-- force-app/main/default/experiences/MyExperience/config/site.json -->
{
  "siteType": "ChatterNetwork",
  "label": "My Experience Site",
  "urlPathPrefix": "experience",
  "status": "Live",
  "siteAdmin": "admin@company.com",
  "subdomain": "experience-developer",
  "branding": {
    "primaryColor": "#1B96FF",
    "primaryColorText": "#FFFFFF",
    "pageBackgroundColor": "#FAFAF9"
  }
}
```

---

## 4. Community 템플릿 커스터마이징

### 4.1 브랜딩 설정

```xml
<!-- force-app/main/default/networkBranding/MyExperience.networkBranding-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<NetworkBranding xmlns="http://soap.sforce.com/2006/04/metadata">
    <loginBackgroundImageUrl>resource_url</loginBackgroundImageUrl>
    <loginFooterText>© 2025 My Company. All rights reserved.</loginFooterText>
    <loginPrimaryColor>#1B96FF</loginPrimaryColor>
    <network>MyExperience</network>
    <primaryColor>#1B96FF</primaryColor>
    <primaryComplementColor>#FFFFFF</primaryComplementColor>
    <quaternaryColor>#F3F3F3</quaternaryColor>
    <quaternaryComplementColor>#747474</quaternaryComplementColor>
    <secondaryColor>#54698D</secondaryColor>
    <tertiaryColor>#E8E8E8</tertiaryColor>
    <tertiaryComplementColor>#AEAEAE</tertiaryComplementColor>
</NetworkBranding>
```

### 4.2 네트워크 설정

```xml
<!-- force-app/main/default/networks/MyExperience.network-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<Network xmlns="http://soap.sforce.com/2006/04/metadata">
    <allowInternalUserLogin>false</allowInternalUserLogin>
    <allowMembersToFlag>false</allowMembersToFlag>
    <changePasswordTemplate>unfiled$public/CommunityChangePasswordEmailTemplate</changePasswordTemplate>
    <communityRoles>
        <customerUserRole>CustomerPortalUser</customerUserRole>
        <employeeUserRole>WorkspaceUser</employeeUserRole>
        <partnerUserRole>PartnerUser</partnerUserRole>
    </communityRoles>
    <description>Customer Portal Experience Site</description>
    <enableCustomVFErrorPageOverrides>false</enableCustomVFErrorPageOverrides>
    <enableDirectMessages>true</enableDirectMessages>
    <enableGuestRecordAccess>true</enableGuestRecordAccess>
    <enableInvitation>true</enableInvitation>
    <enableKnowledgeable>false</enableKnowledgeable>
    <enableMemberVisibility>true</enableMemberVisibility>
    <enableNicknameDisplay>true</enableNicknameDisplay>
    <enablePrivateMessages>true</enablePrivateMessages>
    <enableReputation>false</enableReputation>
    <enableShowAllNetworkSettings>false</enableShowAllNetworkSettings>
    <enableSiteAsContainer>true</enableSiteAsContainer>
    <enableTalkingAboutStats>true</enableTalkingAboutStats>
    <guestMemberVisibilityEnabled>true</guestMemberVisibilityEnabled>
    <maxFileSizeKb>10240</maxFileSizeKb>
    <navigationLinkSet>
        <navigationMenuItem>
            <defaultListViewId></defaultListViewId>
            <label>Home</label>
            <menuItemBranding></menuItemBranding>
            <position>1</position>
            <publiclyAvailable>true</publiclyAvailable>
            <subMenu></subMenu>
            <target>home</target>
            <type>NavigationalTopic</type>
        </navigationMenuItem>
    </navigationLinkSet>
    <networkMemberGroups>
        <profile>Customer Community User</profile>
        <profile>Customer Community Plus User</profile>
    </networkMemberGroups>
    <networkPageOverrides>
        <changePasswordPageOverrideSetting>Standard</changePasswordPageOverrideSetting>
        <forgotPasswordPageOverrideSetting>Standard</forgotPasswordPageOverrideSetting>
        <homePageOverrideSetting>Standard</homePageOverrideSetting>
        <loginPageOverrideSetting>Standard</loginPageOverrideSetting>
        <selfRegPageOverrideSetting>Standard</selfRegPageOverrideSetting>
    </networkPageOverrides>
    <picassoSite>MyExperience</picassoSite>
    <selfRegistration>true</selfRegistration>
    <sendWelcomeEmail>true</sendWelcomeEmail>
    <site>MyExperience</site>
    <status>Live</status>
    <tabs>
        <defaultTab>home</defaultTab>
        <tab>home</tab>
        <tab>Chatter</tab>
    </tabs>
    <urlPathPrefix>experience</urlPathPrefix>
    <welcomeTemplate>unfiled$public/CommunityWelcomeEmailTemplate</welcomeTemplate>
</Network>
```

---

## 5. Lightning Web Components for Experience Sites

### 5.1 Experience Cloud용 LWC 개발

```javascript
// force-app/main/default/lwc/experienceHeader/experienceHeader.js
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ExperienceHeader extends NavigationMixin(LightningElement) {
    @api logoUrl;
    @api siteName;
    @api showSearch = false;
    
    searchTerm = '';
    
    get headerClass() {
        return 'experience-header slds-p-around_medium';
    }
    
    handleSearchInput(event) {
        this.searchTerm = event.target.value;
    }
    
    handleSearch() {
        if (this.searchTerm) {
            // Experience Cloud 검색 페이지로 네비게이션
            this[NavigationMixin.Navigate]({
                type: 'standard__search',
                state: {
                    term: this.searchTerm
                }
            });
        }
    }
    
    handleLogoClick() {
        // 홈 페이지로 네비게이션
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'home'
            }
        });
    }
}
```

```html
<!-- force-app/main/default/lwc/experienceHeader/experienceHeader.html -->
<template>
    <header class={headerClass}>
        <div class="slds-grid slds-grid_align-spread slds-grid_vertical-align-center">
            <!-- Logo Section -->
            <div class="slds-col">
                <div class="logo-container" onclick={handleLogoClick}>
                    <img src={logoUrl} alt={siteName} class="site-logo" />
                    <span class="site-name slds-text-heading_medium">{siteName}</span>
                </div>
            </div>
            
            <!-- Search Section -->
            <div class="slds-col" if:true={showSearch}>
                <div class="search-container slds-grid slds-grid_align-center">
                    <lightning-input 
                        type="search"
                        label="Search"
                        variant="label-hidden"
                        placeholder="Search..."
                        value={searchTerm}
                        onchange={handleSearchInput}
                        class="search-input">
                    </lightning-input>
                    <lightning-button 
                        label="Search"
                        onclick={handleSearch}
                        class="slds-m-left_x-small">
                    </lightning-button>
                </div>
            </div>
            
            <!-- Navigation Menu -->
            <div class="slds-col">
                <nav class="main-navigation">
                    <ul class="slds-list_horizontal slds-has-dividers_right">
                        <li class="slds-item">
                            <a href="/s/" class="nav-link">Home</a>
                        </li>
                        <li class="slds-item">
                            <a href="/s/products" class="nav-link">Products</a>
                        </li>
                        <li class="slds-item">
                            <a href="/s/support" class="nav-link">Support</a>
                        </li>
                        <li class="slds-item">
                            <a href="/s/contact" class="nav-link">Contact</a>
                        </li>
                    </ul>
                </nav>
            </div>
        </div>
    </header>
</template>
```

```css
/* force-app/main/default/lwc/experienceHeader/experienceHeader.css */
.experience-header {
    background-color: var(--lwc-colorBackgroundAlt);
    border-bottom: 1px solid var(--lwc-colorBorder);
}

.logo-container {
    display: flex;
    align-items: center;
    cursor: pointer;
}

.site-logo {
    height: 40px;
    margin-right: 12px;
}

.site-name {
    color: var(--lwc-colorTextDefault);
    font-weight: bold;
}

.search-container {
    max-width: 400px;
}

.search-input {
    min-width: 300px;
}

.main-navigation .nav-link {
    color: var(--lwc-colorTextDefault);
    text-decoration: none;
    padding: 8px 16px;
    border-radius: 4px;
    transition: background-color 0.2s ease;
}

.main-navigation .nav-link:hover {
    background-color: var(--lwc-colorBackgroundRowHover);
    color: var(--lwc-colorTextDefault);
}
```

```xml
<!-- force-app/main/default/lwc/experienceHeader/experienceHeader.js-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightningCommunity__Page</target>
        <target>lightningCommunity__Default</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightningCommunity__Default">
            <property name="logoUrl" type="String" default="" />
            <property name="siteName" type="String" default="My Experience Site" />
            <property name="showSearch" type="Boolean" default="true" />
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

### 5.2 Product Catalog 컴포넌트

```javascript
// force-app/main/default/lwc/customProductCatalog/customProductCatalog.js
import { LightningElement, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getProducts from '@salesforce/apex/ProductCatalogController.getProducts';
import PRODUCT_NAME_FIELD from '@salesforce/schema/Product2.Name';
import PRODUCT_DESCRIPTION_FIELD from '@salesforce/schema/Product2.Description';

export default class CustomProductCatalog extends LightningElement {
    @track products = [];
    @track isLoading = true;
    @track error;
    
    searchTerm = '';
    selectedCategory = '';
    
    get categoryOptions() {
        return [
            { label: 'All Categories', value: '' },
            { label: 'Electronics', value: 'Electronics' },
            { label: 'Clothing', value: 'Clothing' },
            { label: 'Books', value: 'Books' },
            { label: 'Home & Garden', value: 'Home & Garden' }
        ];
    }
    
    connectedCallback() {
        this.loadProducts();
    }
    
    loadProducts() {
        this.isLoading = true;
        getProducts({ 
            searchTerm: this.searchTerm,
            category: this.selectedCategory 
        })
        .then(result => {
            this.products = result;
            this.error = undefined;
        })
        .catch(error => {
            this.error = error.body.message;
            this.products = [];
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
    
    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.debounceSearch();
    }
    
    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
        this.loadProducts();
    }
    
    debounceSearch() {
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.loadProducts();
        }, 300);
    }
    
    handleProductClick(event) {
        const productId = event.currentTarget.dataset.productId;
        // Product 상세 페이지로 네비게이션
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                objectApiName: 'Product2',
                actionName: 'view'
            }
        });
    }
}
```

```html
<!-- force-app/main/default/lwc/customProductCatalog/customProductCatalog.html -->
<template>
    <div class="product-catalog slds-p-around_medium">
        <!-- 헤더 섹션 -->
        <div class="catalog-header slds-m-bottom_large">
            <h1 class="slds-text-heading_large slds-m-bottom_medium">Product Catalog</h1>
            
            <!-- 검색 및 필터 -->
            <div class="slds-grid slds-grid_align-spread slds-grid_vertical-align-end slds-m-bottom_medium">
                <div class="slds-col slds-size_1-of-2">
                    <lightning-input
                        type="search"
                        label="Search Products"
                        placeholder="Search by name or description..."
                        value={searchTerm}
                        onchange={handleSearchChange}>
                    </lightning-input>
                </div>
                <div class="slds-col slds-size_1-of-4">
                    <lightning-combobox
                        label="Category"
                        value={selectedCategory}
                        options={categoryOptions}
                        onchange={handleCategoryChange}>
                    </lightning-combobox>
                </div>
            </div>
        </div>
        
        <!-- 로딩 스피너 -->
        <div if:true={isLoading} class="slds-align_absolute-center slds-p-vertical_xx-large">
            <lightning-spinner alternative-text="Loading products..." size="medium"></lightning-spinner>
        </div>
        
        <!-- 에러 메시지 -->
        <div if:true={error} class="slds-m-bottom_medium">
            <div class="slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_error" role="alert">
                <span class="slds-assistive-text">Error</span>
                <h2>{error}</h2>
            </div>
        </div>
        
        <!-- 상품 그리드 -->
        <div if:false={isLoading} class="product-grid">
            <template if:true={products.length}>
                <div class="slds-grid slds-wrap slds-gutters">
                    <template for:each={products} for:item="product">
                        <div key={product.Id} class="slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-large-size_1-of-3 slds-x-large-size_1-of-4">
                            <div class="product-card" data-product-id={product.Id} onclick={handleProductClick}>
                                <article class="slds-card">
                                    <div class="slds-card__header slds-grid">
                                        <header class="slds-media slds-media_center slds-has-flexi-truncate">
                                            <div class="slds-media__body">
                                                <h2 class="slds-card__header-title">
                                                    <span class="slds-text-heading_small slds-truncate">{product.Name}</span>
                                                </h2>
                                            </div>
                                        </header>
                                    </div>
                                    <div class="slds-card__body slds-card__body_inner">
                                        <div class="product-image-container slds-m-bottom_small">
                                            <img src={product.DisplayUrl} alt={product.Name} class="product-image" />
                                        </div>
                                        <p class="slds-text-body_regular slds-line-clamp_small">{product.Description}</p>
                                        <div class="product-price slds-m-top_small">
                                            <span class="slds-text-heading_medium slds-text-color_success">
                                                {product.ListPrice}
                                            </span>
                                        </div>
                                    </div>
                                    <footer class="slds-card__footer">
                                        <lightning-button 
                                            label="View Details" 
                                            variant="brand" 
                                            class="slds-m-right_x-small">
                                        </lightning-button>
                                        <lightning-button 
                                            label="Add to Cart" 
                                            variant="neutral">
                                        </lightning-button>
                                    </footer>
                                </article>
                            </div>
                        </div>
                    </template>
                </div>
            </template>
            
            <!-- 상품이 없을 때 -->
            <template if:false={products.length}>
                <div class="slds-align_absolute-center slds-p-vertical_xx-large">
                    <div class="slds-text-align_center">
                        <lightning-icon icon-name="utility:search" size="large" class="slds-m-bottom_small"></lightning-icon>
                        <h3 class="slds-text-heading_medium">No products found</h3>
                        <p class="slds-text-body_regular">Try adjusting your search criteria or category filter.</p>
                    </div>
                </div>
            </template>
        </div>
    </div>
</template>
```

---

## 6. Experience Builder 커스터마이징

### 6.1 Apex Controller for Experience Sites

```apex
// force-app/main/default/classes/ProductCatalogController.cls
public with sharing class ProductCatalogController {
    
    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getProducts(String searchTerm, String category) {
        try {
            String query = 'SELECT Id, Name, Description, Family, IsActive FROM Product2 WHERE IsActive = true';
            List<String> conditions = new List<String>();
            
            if (String.isNotBlank(searchTerm)) {
                conditions.add('(Name LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\' OR Description LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\')');
            }
            
            if (String.isNotBlank(category)) {
                conditions.add('Family = \'' + String.escapeSingleQuotes(category) + '\'');
            }
            
            if (!conditions.isEmpty()) {
                query += ' AND ' + String.join(conditions, ' AND ');
            }
            
            query += ' ORDER BY Name LIMIT 50';
            
            List<Product2> products = Database.query(query);
            List<ProductWrapper> productWrappers = new List<ProductWrapper>();
            
            for (Product2 product : products) {
                ProductWrapper wrapper = new ProductWrapper();
                wrapper.Id = product.Id;
                wrapper.Name = product.Name;
                wrapper.Description = product.Description;
                wrapper.Family = product.Family;
                wrapper.DisplayUrl = '/sfsites/c/resource/ProductPlaceholder'; // 기본 이미지
                wrapper.ListPrice = '$0.00'; // PricebookEntry에서 가져올 수 있음
                productWrappers.add(wrapper);
            }
            
            return productWrappers;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching products: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getProductCategories() {
        try {
            List<String> categories = new List<String>();
            
            // Product Family picklist 값들을 가져옴
            Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistEntries) {
                categories.add(entry.getValue());
            }
            
            return categories;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching categories: ' + e.getMessage());
        }
    }
    
    public class ProductWrapper {
        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public String Description { get; set; }
        @AuraEnabled public String Family { get; set; }
        @AuraEnabled public String DisplayUrl { get; set; }
        @AuraEnabled public String ListPrice { get; set; }
    }
}
```

### 6.2 Guest User 권한 설정

```apex
// force-app/main/default/classes/ExperienceCloudSharingHandler.cls
public without sharing class ExperienceCloudSharingHandler {
    
    @AuraEnabled(cacheable=true)
    public static List<Product2> getPublicProducts() {
        // Guest User가 접근 가능한 공개 상품만 반환
        return [
            SELECT Id, Name, Description, Family, IsActive 
            FROM Product2 
            WHERE IsActive = true 
            AND IsArchived = false
            WITH SECURITY_ENFORCED
            ORDER BY Name 
            LIMIT 100
        ];
    }
    
    @AuraEnabled
    public static String submitContactForm(String name, String email, String subject, String message) {
        try {
            // Guest User를 위한 Contact Form 처리
            Case newCase = new Case();
            newCase.Subject = subject;
            newCase.Description = message;
            newCase.SuppliedName = name;
            newCase.SuppliedEmail = email;
            newCase.Origin = 'Experience Cloud';
            newCase.Status = 'New';
            
            insert newCase;
            
            return 'SUCCESS';
            
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting form: ' + e.getMessage());
        }
    }
}
```

---

## 7. 배포 및 테스트

### 7.1 스크래치 조직 설정

```json
// config/project-scratch-def.json
{
  "orgName": "Experience Cloud Dev Org",
  "edition": "Developer",
  "features": [
    "Communities",
    "ExperienceBundle",
    "LightningExperienceEnabled",
    "ForceComEnabled"
  ],
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    },
    "communitiesSettings": {
      "enableNetworksEnabled": true
    },
    "experienceBundle": {
      "enableExperienceBundle": true
    }
  }
}
```

### 7.2 배포 스크립트

```bash
#!/bin/bash
# deploy-experience.sh

echo "🚀 Experience Cloud 배포 시작..."

# 스크래치 조직 생성
echo "📦 스크래치 조직 생성 중..."
sfdx org create scratch --definition-file config/project-scratch-def.json --duration-days 30 --alias experience-dev --set-default

# 소스 배포
echo "📤 소스 코드 배포 중..."
sfdx project deploy start --source-dir force-app

# Permission Set 할당
echo "🔐 권한 설정 중..."
sfdx org assign permset --name Experience_Cloud_Admin

# 샘플 데이터 생성
echo "📊 샘플 데이터 생성 중..."
sfdx data tree import --plan data/sample-data-plan.json

# Experience Site 활성화
echo "🌐 Experience Site 활성화 중..."
sfdx community publish --name "MyExperience"

echo "✅ 배포 완료!"
echo "🔗 Experience Site URL: https://$(sfdx org display --json | jq -r '.result.instanceUrl')/experience"
```

### 7.3 테스트 자동화

```javascript
// force-app/main/default/lwc/customProductCatalog/__tests__/customProductCatalog.test.js
import { createElement } from 'lwc';
import CustomProductCatalog from 'c/customProductCatalog';
import getProducts from '@salesforce/apex/ProductCatalogController.getProducts';

// Mock Apex method
jest.mock(
    '@salesforce/apex/ProductCatalogController.getProducts',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

const mockProducts = [
    {
        Id: 'a01xx0000000001',
        Name: 'Test Product 1',
        Description: 'Test Description 1',
        Family: 'Electronics',
        DisplayUrl: '/test-image-1.jpg',
        ListPrice: '$99.99'
    },
    {
        Id: 'a01xx0000000002',
        Name: 'Test Product 2',
        Description: 'Test Description 2',
        Family: 'Clothing',
        DisplayUrl: '/test-image-2.jpg',
        ListPrice: '$49.99'
    }
];

describe('c-custom-product-catalog', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders product catalog with products', async () => {
        // Mock successful API response
        getProducts.mockResolvedValue(mockProducts);

        const element = createElement('c-custom-product-catalog', {
            is: CustomProductCatalog
        });
        document.body.appendChild(element);

        // Wait for async operations
        await Promise.resolve();

        // Verify products are rendered
        const productCards = element.shadowRoot.querySelectorAll('.product-card');
        expect(productCards.length).toBe(2);
        
        const firstProductName = element.shadowRoot.querySelector('.slds-card__header-title span');
        expect(firstProductName.textContent).toBe('Test Product 1');
    });

    it('handles search functionality', async () => {
        getProducts.mockResolvedValue(mockProducts);

        const element = createElement('c-custom-product-catalog', {
            is: CustomProductCatalog
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Simulate search input
        const searchInput = element.shadowRoot.querySelector('lightning-input[type="search"]');
        searchInput.value = 'Electronics';
        searchInput.dispatchEvent(new CustomEvent('change', { detail: { value: 'Electronics' } }));

        // Wait for debounced search
        await new Promise(resolve => setTimeout(resolve, 400));

        expect(getProducts).toHaveBeenCalledWith({
            searchTerm: 'Electronics',
            category: ''
        });
    });

    it('handles category filter', async () => {
        getProducts.mockResolvedValue(mockProducts);

        const element = createElement('c-custom-product-catalog', {
            is: CustomProductCatalog
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Simulate category selection
        const categoryCombobox = element.shadowRoot.querySelector('lightning-combobox');
        categoryCombobox.dispatchEvent(new CustomEvent('change', { 
            detail: { value: 'Electronics' } 
        }));

        await Promise.resolve();

        expect(getProducts).toHaveBeenCalledWith({
            searchTerm: '',
            category: 'Electronics'
        });
    });

    it('displays error message on API failure', async () => {
        const errorMessage = 'Failed to fetch products';
        getProducts.mockRejectedValue({ body: { message: errorMessage } });

        const element = createElement('c-custom-product-catalog', {
            is: CustomProductCatalog
        });
        document.body.appendChild(element);

        await Promise.resolve();

        const errorElement = element.shadowRoot.querySelector('.slds-theme_error');
        expect(errorElement).toBeTruthy();
        expect(errorElement.textContent).toContain(errorMessage);
    });
});
```

---

## 8. 모범 사례

### 8.1 성능 최적화

```javascript
// 캐시 가능한 메서드 사용
@AuraEnabled(cacheable=true)
public static List<Product2> getProducts() {
    // 캐싱 가능한 정적 데이터
}

// LWC에서 wire 서비스 사용
@wire(getProducts)
wiredProducts({ error, data }) {
    if (data) {
        this.products = data;
    } else if (error) {
        this.error = error;
    }
}
```

### 8.2 보안 고려사항

```apex
// Guest User 접근 제어
public with sharing class ExperienceController {
    @AuraEnabled(cacheable=true)
    public static List<Product2> getPublicProducts() {
        // WITH SECURITY_ENFORCED 사용
        return [SELECT Id, Name FROM Product2 WITH SECURITY_ENFORCED LIMIT 100];
    }
}
```

### 8.3 SEO 최적화

```html
<!-- Experience Page에서 메타 태그 설정 -->
<template>
    <lightning-card title="Product Catalog">
        <!-- 구조화된 데이터 -->
        <script type="application/ld+json">
        {
            "@context": "https://schema.org",
            "@type": "Product",
            "name": "Product Name",
            "description": "Product Description"
        }
        </script>
        
        <!-- 콘텐츠 -->
    </lightning-card>
</template>
```

### 8.4 반응형 디자인

```css
/* 모바일 우선 CSS */
.product-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 1rem;
}

/* 태블릿 */
@media (min-width: 768px) {
    .product-grid {
        grid-template-columns: repeat(2, 1fr);
    }
}

/* 데스크톱 */
@media (min-width: 1024px) {
    .product-grid {
        grid-template-columns: repeat(4, 1fr);
    }
}
```

### 8.5 VS Code 개발 워크플로우

```json
// .vscode/tasks.json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "SFDX: Deploy Experience Components",
            "type": "shell",
            "command": "sfdx project deploy start --source-dir force-app/main/default/lwc,force-app/main/default/experiences",
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": []
        },
        {
            "label": "SFDX: Test Experience Components", 
            "type": "shell",
            "command": "npm run test:unit",
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        }
    ]
}
```

```json
// .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Launch Experience Site",
            "type": "node",
            "request": "launch",
            "program": "${workspaceFolder}/scripts/launch-experience.js",
            "console": "integratedTerminal"
        }
    ]
}
```

---

## 🎯 결론

이 가이드를 통해 VS Code에서 Salesforce Experience Cloud를 효율적으로 개발할 수 있습니다:

✅ **개발 환경 구축**: SFDX, VS Code 확장 프로그램, 프로젝트 구조  
✅ **컴포넌트 개발**: LWC, Aura, Apex Controller  
✅ **커스터마이징**: 브랜딩, 네비게이션, 테마  
✅ **배포 자동화**: 스크래치 조직, CI/CD  
✅ **테스트**: 단위 테스트, 통합 테스트  
✅ **모범 사례**: 성능, 보안, SEO, 반응형

Experience Cloud 개발 시 이 가이드를 참조하여 효율적이고 확장 가능한 커뮤니티 사이트를 구축하세요! 🚀
