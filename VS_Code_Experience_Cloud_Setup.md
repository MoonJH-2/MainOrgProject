# 🛠️ Experience Cloud 개발을 위한 VS Code 설정

## 1. 추천 확장 프로그램 설치

### 필수 확장 프로그램
```bash
# VS Code에서 설치할 확장 프로그램들
code --install-extension salesforce.salesforcedx-vscode
code --install-extension salesforce.salesforcedx-vscode-apex  
code --install-extension salesforce.salesforcedx-vscode-lightning
code --install-extension salesforce.salesforcedx-vscode-lwc
```

### 유용한 확장 프로그램
```bash
code --install-extension bradlc.vscode-tailwindcss
code --install-extension formulahendry.auto-rename-tag
code --install-extension ms-vscode.vscode-json
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint
```

## 2. VS Code 워크스페이스 설정

### .vscode/settings.json
```json
{
    "salesforcedx-vscode-core.show-cli-success-msg": false,
    "salesforcedx-vscode-core.retrieve-test-code-coverage": true,
    "salesforcedx-vscode-lightning.activationMode": "always",
    "salesforcedx-vscode-apex.enable-sobject-refresh-on-startup": true,
    "salesforcedx-vscode-apex.java.home": "/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home",
    "editor.formatOnSave": true,
    "prettier.requireConfig": true,
    "eslint.validate": ["javascript", "lwc"],
    "html.autoClosingTags": true,
    "emmet.includeLanguages": {
        "html": "html",
        "lightning": "html"
    },
    "files.associations": {
        "*.cls": "apex",
        "*.trigger": "apex", 
        "*.page": "visualforce",
        "*.component": "visualforce"
    }
}
```

### .vscode/extensions.json
```json
{
    "recommendations": [
        "salesforce.salesforcedx-vscode",
        "salesforce.salesforcedx-vscode-apex",
        "salesforce.salesforcedx-vscode-lightning", 
        "salesforce.salesforcedx-vscode-lwc",
        "bradlc.vscode-tailwindcss",
        "formulahendry.auto-rename-tag",
        "ms-vscode.vscode-json",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint"
    ]
}
```

## 3. 디버깅 설정

### .vscode/launch.json
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Launch Apex Replay Debugger",
            "type": "apex-replay",
            "request": "launch",
            "logFile": "${command:AskForLogFileName}",
            "stopOnEntry": true,
            "trace": true
        },
        {
            "name": "Launch Experience Site",
            "type": "node",
            "request": "launch", 
            "program": "${workspaceFolder}/scripts/open-experience-site.js",
            "console": "integratedTerminal"
        }
    ]
}
```

## 4. 빌드 및 배포 태스크

### .vscode/tasks.json
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "SFDX: Deploy Experience Cloud Components",
            "type": "shell",
            "command": "sfdx",
            "args": [
                "project", "deploy", "start",
                "--source-dir", "force-app/main/default/lwc,force-app/main/default/experiences,force-app/main/default/digitalExperiences"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared",
                "showReuseMessage": true,
                "clear": false
            },
            "problemMatcher": "$salesforce-cli"
        },
        {
            "label": "SFDX: Run LWC Tests",
            "type": "shell", 
            "command": "npm",
            "args": ["run", "test:unit"],
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        },
        {
            "label": "SFDX: Open Experience Site",
            "type": "shell",
            "command": "sfdx",
            "args": [
                "org", "open", 
                "--path", "/lightning/setup/SetupNetworks/home"
            ],
            "group": "build"
        },
        {
            "label": "SFDX: Publish Experience Site",
            "type": "shell",
            "command": "sfdx", 
            "args": [
                "community", "publish",
                "--name", "${input:experienceSiteName}"
            ],
            "group": "build"
        }
    ],
    "inputs": [
        {
            "id": "experienceSiteName",
            "description": "Experience Site Name",
            "default": "MyExperience",
            "type": "promptString"
        }
    ]
}
```

## 5. 코드 품질 설정

### .eslintrc.json (LWC용)
```json
{
    "extends": ["@salesforce/eslint-config-lwc/recommended"],
    "overrides": [
        {
            "files": ["*.test.js"],
            "rules": {
                "@lwc/lwc/no-unexpected-wire-adapter-usages": "off"
            }
        }
    ],
    "rules": {
        "no-console": "warn",
        "@lwc/lwc/no-leading-uppercase-api-name": "error",
        "@lwc/lwc/valid-api": "error"
    }
}
```

### .prettierrc
```json
{
    "trailingComma": "none",
    "overrides": [
        {
            "files": "**/lwc/**/*.html",
            "options": { "parser": "lwc" }
        },
        {
            "files": "*.{cmp,page,component}",
            "options": { "parser": "html" }
        }
    ]
}
```

## 6. 스니펫 설정

### .vscode/snippets/lwc.json
```json
{
    "LWC Experience Component": {
        "prefix": "lwc-experience",
        "body": [
            "import { LightningElement, api } from 'lwc';",
            "import { NavigationMixin } from 'lightning/navigation';",
            "",
            "export default class ${1:ComponentName} extends NavigationMixin(LightningElement) {",
            "    @api title;",
            "    ",
            "    connectedCallback() {",
            "        // 컴포넌트 초기화",
            "    }",
            "    ",
            "    handleNavigation(event) {",
            "        this[NavigationMixin.Navigate]({",
            "            type: 'standard__namedPage',",
            "            attributes: {",
            "                pageName: 'home'", 
            "            }",
            "        });",
            "    }",
            "}"
        ],
        "description": "Experience Cloud용 LWC 컴포넌트 템플릿"
    },
    "Experience Component Meta": {
        "prefix": "lwc-experience-meta",
        "body": [
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
            "<LightningComponentBundle xmlns=\"http://soap.sforce.com/2006/04/metadata\">",
            "    <apiVersion>60.0</apiVersion>",
            "    <isExposed>true</isExposed>",
            "    <targets>",
            "        <target>lightningCommunity__Page</target>",
            "        <target>lightningCommunity__Default</target>",
            "    </targets>",
            "    <targetConfigs>",
            "        <targetConfig targets=\"lightningCommunity__Default\">",
            "            <property name=\"title\" type=\"String\" default=\"${1:Default Title}\" />",
            "        </targetConfig>",
            "    </targetConfigs>",
            "</LightningComponentBundle>"
        ],
        "description": "Experience Cloud용 LWC 메타데이터 템플릿"
    }
}
```

### .vscode/snippets/apex.json
```json
{
    "Experience Cloud Controller": {
        "prefix": "apex-experience-controller",
        "body": [
            "public with sharing class ${1:ControllerName} {",
            "    ",
            "    @AuraEnabled(cacheable=true)",
            "    public static List<${2:ObjectType}> get${3:MethodName}() {",
            "        try {",
            "            return [",
            "                SELECT Id, Name",
            "                FROM ${2:ObjectType}",
            "                WITH SECURITY_ENFORCED",
            "                LIMIT 50",
            "            ];",
            "        } catch (Exception e) {",
            "            throw new AuraHandledException('Error: ' + e.getMessage());",
            "        }",
            "    }",
            "    ",
            "    @AuraEnabled",
            "    public static String ${4:ActionMethod}(String recordId) {",
            "        try {",
            "            // 액션 로직",
            "            return 'SUCCESS';",
            "        } catch (Exception e) {",
            "            throw new AuraHandledException('Error: ' + e.getMessage());",
            "        }",
            "    }",
            "}"
        ],
        "description": "Experience Cloud용 Apex 컨트롤러 템플릿"
    }
}
```

## 7. 자동화 스크립트

### scripts/setup-experience.sh
```bash
#!/bin/bash

echo "🚀 Experience Cloud 개발 환경 설정 시작..."

# Salesforce CLI 설치 확인
if ! command -v sfdx &> /dev/null; then
    echo "❌ Salesforce CLI가 설치되지 않았습니다."
    echo "📦 Homebrew로 설치 중..."
    brew install salesforce-cli
fi

# Node.js 의존성 설치
echo "📦 Node.js 의존성 설치 중..."
npm install

# VS Code 확장 프로그램 설치
echo "🔧 VS Code 확장 프로그램 설치 중..."
code --install-extension salesforce.salesforcedx-vscode
code --install-extension salesforce.salesforcedx-vscode-apex
code --install-extension salesforce.salesforcedx-vscode-lightning
code --install-extension salesforce.salesforcedx-vscode-lwc

# 스크래치 조직 생성
echo "🏗️ 스크래치 조직 생성 중..."
sfdx org create scratch --definition-file config/project-scratch-def.json --duration-days 30 --alias experience-dev --set-default

# 메타데이터 배포
echo "📤 메타데이터 배포 중..."
sfdx project deploy start

# Experience Site 생성
echo "🌐 Experience Site 생성 중..."
sfdx community create --name "My Experience Site" --template "Customer Service" --url-path-prefix "experience"

echo "✅ 설정 완료!"
echo "🔗 조직 열기: sfdx org open"
echo "🔗 Experience Builder: sfdx org open --path /lightning/setup/SetupNetworks/home"
```

### scripts/deploy-experience.js
```javascript
#!/usr/bin/env node

const { exec } = require('child_process');
const path = require('path');

const deployExperience = async () => {
    console.log('🚀 Experience Cloud 배포 시작...');
    
    try {
        // LWC 컴포넌트 배포
        await runCommand('sfdx project deploy start --source-dir force-app/main/default/lwc');
        console.log('✅ LWC 컴포넌트 배포 완료');
        
        // Experience 설정 배포  
        await runCommand('sfdx project deploy start --source-dir force-app/main/default/experiences');
        console.log('✅ Experience 설정 배포 완료');
        
        // Digital Experience 배포
        await runCommand('sfdx project deploy start --source-dir force-app/main/default/digitalExperiences');
        console.log('✅ Digital Experience 배포 완료');
        
        // Experience Site 게시
        await runCommand('sfdx community publish --name "My Experience Site"');
        console.log('✅ Experience Site 게시 완료');
        
        console.log('🎉 모든 배포가 완료되었습니다!');
        
    } catch (error) {
        console.error('❌ 배포 중 오류 발생:', error);
        process.exit(1);
    }
};

const runCommand = (command) => {
    return new Promise((resolve, reject) => {
        exec(command, (error, stdout, stderr) => {
            if (error) {
                reject(error);
                return;
            }
            console.log(stdout);
            resolve(stdout);
        });
    });
};

deployExperience();
```

## 8. 패키지 관리

### package.json
```json
{
    "name": "experience-cloud-project",
    "version": "1.0.0",
    "description": "Salesforce Experience Cloud Development Project",
    "scripts": {
        "test": "npm run test:unit",
        "test:unit": "sfdx-lwc-jest",
        "test:unit:watch": "sfdx-lwc-jest --watch",
        "test:unit:debug": "sfdx-lwc-jest --debug",
        "test:unit:coverage": "sfdx-lwc-jest --coverage",
        "prettier": "prettier --write \"**/*.{cls,cmp,component,css,html,js,json,md,page,trigger,xml,yaml,yml}\"",
        "prettier:verify": "prettier --list-different \"**/*.{cls,cmp,component,css,html,js,json,md,page,trigger,xml,yaml,yml}\"",
        "lint": "eslint force-app",
        "lint:fix": "eslint force-app --fix",
        "setup": "chmod +x scripts/setup-experience.sh && ./scripts/setup-experience.sh",
        "deploy": "node scripts/deploy-experience.js",
        "open:org": "sfdx org open",
        "open:experience": "sfdx org open --path /lightning/setup/SetupNetworks/home"
    },
    "devDependencies": {
        "@lwc/eslint-plugin-lwc": "^1.7.2",
        "@prettier/plugin-xml": "^3.2.2",
        "@salesforce/eslint-config-lwc": "^3.5.2",
        "@salesforce/eslint-plugin-aura": "^2.1.0",
        "@salesforce/eslint-plugin-lightning": "^1.0.0",
        "@salesforce/sfdx-lwc-jest": "^3.1.1",
        "eslint": "^8.57.0",
        "husky": "^8.0.3",
        "lint-staged": "^15.2.0",
        "prettier": "^3.1.1",
        "prettier-plugin-apex": "^2.0.1"
    },
    "lint-staged": {
        "**/*.{cls,cmp,component,css,html,js,json,md,page,trigger,xml,yaml,yml}": [
            "prettier --write"
        ],
        "force-app/**/*.js": [
            "eslint --fix"
        ]
    },
    "husky": {
        "hooks": {
            "pre-commit": "lint-staged"
        }
    }
}
```

이제 VS Code에서 Salesforce Experience Cloud를 효율적으로 개발할 수 있는 완전한 환경이 구축되었습니다! 🚀

주요 기능:
- ✅ 자동화된 개발 환경 설정
- ✅ 코드 품질 관리 (ESLint, Prettier)
- ✅ 디버깅 및 테스트 지원
- ✅ 빌드 태스크 자동화
- ✅ 유용한 코드 스니펫
- ✅ 배포 자동화 스크립트

Experience Cloud 개발 시 이 설정을 활용하여 생산성을 크게 향상시킬 수 있습니다!
