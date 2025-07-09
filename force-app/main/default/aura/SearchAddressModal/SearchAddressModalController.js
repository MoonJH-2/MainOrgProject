({
    doInit : function(component, event, helper) {
        window.setTimeout(
            $A.getCallback(function(){
                var inputCmp = component.find('addressInput');
                if(inputCmp) {
                    inputCmp.focus();
                }
            }), 400
        );
    },

    searchAddress: function (component, event, helper) {
        component.set('v.pagingNumber', 1);
        helper.searchAddress(component, event, helper);
    },

    handleEnterSearch: function (component, event, helper) {
        if(event.keyCode === 13){
            component.set('v.pagingNumber', 1);
            helper.searchAddress(component, event, helper);
        }
    },

    handleClickAddress: function (component, event, helper) {
        component.set('v.isLoading', true);

        var index = event.currentTarget.getAttribute('data-index');
        var searchResults = component.get('v.searchResults');
        var selectedResult = searchResults[index];
        console.log('selectedResult', selectedResult);
        

        component.set('v.selectedResult', selectedResult);
        component.set('v.saveSearchText', component.set('v.searchText'));

        var vfHost = window.location.protocol + '//' + window.location.hostname +
                     '/apex/SearchAddressMap?admCd=' + selectedResult.admCd +
                     '&rnMgtSn=' + selectedResult.rnMgtSn  +
                     '&udrtYn='  + selectedResult.udrtYn   +
                     '&buldMnnm' + selectedResult.buldMnnm +
                     '&buldSlno' + selectedResult.buldSlno;
        component.set('v.vfHost', vfHost);
        console.log('vfHost', vfHost);
        
        component.set('v.isSelected', true);
        component.set('v.isLoading', false);
    },

    handleTrueSearchAddress: function(component, event, helper){
        component.set('v.isLoading', true);
        component.set('v.isSelected', false);
        if(component.get('v.saveSearchText') != '' && component.get('v.searchText') != component.get('v.saveSearchText')){
            component.set('v.pagingNumber', 1);
            helper.searchAddress(component, event, helper);
        }
        component.set('v.isLoading', false);
    },

    handleTrueEnterSearch: function(component, event, helper){
        if(event.keyCode ==13){
            component.set('v.isLoading', true);
            component.set('v.isSelected', false);

            if(component.get('v.searchText') != component.get('v.saveSearchText')) {
                component.set('v.pagingNumber', 1);
                helper.searchAddress(component, event, helper);
            }
            component.set('v.isLoading', false);
        }
    },

    handleChangePage: function(component, event, helper){
        try {
            var pageCountListIndex = component.get('v.pageCountListIndex');
            var pageAllCountList = component.get('v.pageAllCountList');
            var changePage = Number(event.currentTarget.value);
            var name = event.currentTarget.name;

            if(name == 'first'){
                changePage = 1;
                pageCountListIndex = 0;
            }else if(name =='previous'){
                if(pageCountListIndex < 0){
                    pageCountListIndex = 0;
                    changePage = pageAllCountList[pageCountListIndex][0] + 1;
                }else{
                    changePage = pageAllCountList[pageCountListIndex][pageAllCountList[pageCountListIndex].length -1] + 1;
                }
            }else if(name == 'next') {
                pageCountListIndex++;
                if(pageCountListIndex >= pageAllCountList.length){
                    pageCountListIndex = pageAllCountList.length - 1;
                    changePage = pageAllCountList[pageCountListIndex][pageAllCountList[pageCountListIndex].length - 1] + 1;
                } else {
                    changePage = pageAllCountList[pageCountListIndex][0] + 1;
                }
            }

            component.set('v.pagingNumber', changePage);
            component.set('v.pageCountListIndex', pageCountListIndex);
            component.set('v.pageCountList', pageAllCountList[pageCountListIndex]);

            helper.searchAddress(component, event, helper);
        } catch (error) {
            console.log('# SearchAddressModal handleChangePage Error : ' + JSON.stringify(error.message));
            
        }
    },

    handleClose : function(component, event, helper) {
        helper.closeModal();
    },

    handleSaveBtn: function (component, event, helper) {
        component.set('v.isLoading', true);

        var selectedResult = component.get('v.selectedResult');
        helper.apexCall(component, event, helper, 'setShippingAddress',{
            recordId    : component.get('v.recordId'),
            address     : selectedResult,
            detailInto  : component.get('v.detailedAddress') 
        })
        .then($A.getCallback(function(result){
            let r = result.r;
            console.log('# SearchAddressModal handleSaveBtn : ', r);

            if(r.isSuccess){
                helper.toast('success', 'Success', '주소가 저장되었습니다.');
            } else {
                helper.toast('error', 'Error', r.errorMessage);
            }

            component.set('v.isLoading', false);
            helper.closeModal();
            helper.refreshView();
            
        }))
        .catch(function(error){
            console.log('SearchAddressModal handleSaveBtn error : ' + JSON.stringify(error.message));
            helper.toast('error', 'Error', '오류가 발생하였습니다. 관리자에게 문의바랍니다.');
            
            component.set('v.isLoading', false);
            helper.closeModal();
            helper.refreshView();
        })
    }



})