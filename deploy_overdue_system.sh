#!/bin/bash

# 연체 처리 시스템 배포 스크립트

echo "=== 즉시 연체 처리 시스템 배포 시작 ==="

cd /Users/moonjh/MainOrgProject

echo "1. PaymentOverdueService 배포..."
sf project deploy start --source-dir force-app/main/default/classes/payment_classes/PaymentOverdueService.cls*

echo "2. PaymentMidnightOverdueScheduler 배포..."  
sf project deploy start --source-dir force-app/main/default/classes/payment_classes/PaymentMidnightOverdueScheduler.cls*

echo "3. PaymentOverdueCheckScheduler 재배포..."
sf project deploy start --source-dir force-app/main/default/classes/payment_classes/PaymentOverdueCheckScheduler.cls*

echo "4. PaymentStatusTrigger 재배포..."
sf project deploy start --source-dir force-app/main/default/triggers/PaymentStatusTrigger.trigger*

echo "=== 배포 완료 ==="
