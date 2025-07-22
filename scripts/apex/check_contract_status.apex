// Contract 00000112 상태 확인 및 수정
System.debug('🔍 =====Contract 00000112 상태 확인=====');

try {
    // 1. Contract 00000112 조회
    List<Contract> contracts = [
        SELECT Id, ContractNumber, Status, AccountId, Account.Name, 
               StartDate, EndDate, ActivatedDate, ActivatedById
        FROM Contract 
        WHERE ContractNumber = '00000112'
        LIMIT 1
    ];
    
    if (contracts.isEmpty()) {
        System.debug('❌ Contract 00000112를 찾을 수 없습니다.');
        return;
    }
    
    Contract targetContract = contracts[0];
    System.debug('📋 Contract 정보:');
    System.debug('   • Contract Number: ' + targetContract.ContractNumber);
    System.debug('   • Account: ' + targetContract.Account.Name);
    System.debug('   • Status: ' + targetContract.Status);
    System.debug('   • Start Date: ' + targetContract.StartDate);
    System.debug('   • End Date: ' + targetContract.EndDate);
    System.debug('   • Activated Date: ' + targetContract.ActivatedDate);
    
    // 2. Contract Status 필드의 picklist 값들 확인
    Schema.DescribeFieldResult fieldResult = Contract.Status.getDescribe();
    List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
    
    System.debug('');
    System.debug('✅ 사용 가능한 Status 값들:');
    for (Schema.PicklistEntry entry : picklistEntries) {
        if (entry.isActive()) {
            System.debug('   • ' + entry.getValue() + ' (' + entry.getLabel() + ')');
        }
    }
    
    // 3. 현재 Status 값이 유효한지 확인
    Boolean isValidStatus = false;
    for (Schema.PicklistEntry entry : picklistEntries) {
        if (entry.isActive() && entry.getValue() == targetContract.Status) {
            isValidStatus = true;
            break;
        }
    }
    
    System.debug('');
    System.debug('📊 Status 검증 결과:');
    System.debug('   • 현재 Status: ' + targetContract.Status);
    System.debug('   • 유효한 값인가: ' + isValidStatus);
    
    // 4. Status가 유효하지 않다면 수정
    if (!isValidStatus) {
        System.debug('');
        System.debug('🔧 Status 수정 중...');
        
        Contract contractToUpdate = new Contract();
        contractToUpdate.Id = targetContract.Id;
        contractToUpdate.Status = 'Activated'; // 유효한 값으로 설정
        
        try {
            update contractToUpdate;
            System.debug('✅ Contract Status가 "Activated"로 수정되었습니다.');
        } catch (Exception e) {
            System.debug('❌ Contract 수정 실패: ' + e.getMessage());
        }
    } else {
        System.debug('✅ 현재 Status는 유효합니다.');
    }
    
} catch (Exception e) {
    System.debug('❌ 오류 발생: ' + e.getMessage());
    System.debug('   스택 추적: ' + e.getStackTraceString());
}

System.debug('');
System.debug('✅ =====Contract 상태 확인 완료=====');
