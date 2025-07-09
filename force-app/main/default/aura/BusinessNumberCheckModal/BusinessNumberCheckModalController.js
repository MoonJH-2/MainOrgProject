({
    doInit : function (component, event, helper) {
        component.set('v.isLoading', true);

        helper.apexCall(component, event, helper, 'checkBusinessNumber', {
            recordId : component.get('v.recordId')
        })
        .then($A.getCallback(function(result) {
            let r = result.r;
            console.log('BusinessNumberCheckModal doInit : ', r);
            
            if(r.isSuccess){
                component.set('v.resBody', r.resultMap);
                component.set('v.isFlag', true);
                component.set('v.status', r.resultMap.b_stt);
                if(r.resultMap.b_stt_cd != '' && r.resultMap.b_stt_cd !='01'){
                    component.set('v.isFlag', false);
                    component.set('v.failResult', '조회하신 사업자는 ' + r.resultMap.b_stt + ' 입니다.');
                } else if(r.resultMap.b_stt_cd == '') {
                    component.set('v.isFlag', false);
                    component.set('v.failResult', '국세청에 등록되지 않은 사업자등록번호입니다.');       
                }
            } else {
                if(r.errorMessage == 'AlreadyCheck') {
                    component.set('v.isAlready', true);
                } else {
                    helper.toast('error', 'Error', r.errorMessage);
                    helper.closeModal();
                }
            }  
            component.set('v.isLoading', false);
        }))
        .catch(function(error) {
            console.log('# BusinessNumberCheckModal doInit error : ' + JSON.stringify(error.message));
            helper.closeModal();
            component.set('v.isLoading', true);
        });
    },

    handleClickConfirm : function (component, event, helper) {
      if(component.get('v.isFlag')){
        helper.apexCall(component, event, helper, 'updateBusinessNumberVerified', {
            recordId : component.get('v.recordId')
        })
        .then($A.getCallback(function(result) {
            let r = result.r;
            console.log('BusinessNumberCheckModal handleClickConfirm : ', r);
            helper.closeModal();
            helper.refreshView();
            
            if(r.isSuccess){
                helper.toast('success', 'Success', '사업자번호 진위 확인이 완료되었습니다.');
            } else {
                helper.toast('error', 'Error', r.errorMessage);
            }  
        }))
        .catch(function(error) {
            console.log('# BusinessNumberCheckModal handleClickConfirm error : ' + JSON.stringify(error.message));
            helper.closeModal();
        });
      } else {
        helper.closeModal();
      }  
    },

    handleClickClose : function (component, event, helper) {
        helper.closeModal();
    }
})