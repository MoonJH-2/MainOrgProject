({
    /* Default */
    apexCall : function( component, event, helper, methodName, params ) {
        var self = this;
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get('c.' + methodName);

            if(typeof action !== 'undefined') {
                action.setParams(params);

                action.setCallback(helper, function(response) {
                    if (response.getState() === 'SUCCESS') {
                        resolve({'c':component, 'h':helper, 'r':response.getReturnValue(), 'state' : response.getState()});
                    } else {
                        let errors = response.getError();
                        console.log(methodName, errors);
                    }
                });
                $A.enqueueAction(action);
            }
        }));
    },

    toast : function (type, title, message){
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title       : title,
            type        : type,
            message     : message,
            duration    : 3000,
            mode        : 'dismissible'
        });
        toastEvent.fire();

    },
    closeModal : function() {
        $A.get('e.force:closeQuickAction').fire();
    },

    refreshView : function () {
        $A.get('e.force:refreshView').fire();
    },

    /* Additional */
    searchAddress : function (component, event, helper) {
        component.set('v.isLoading', true);
        // 🌈self
        var self = this;
        let searchText      = component.get('v.searchText');
        let pagingNumber    = component.get('v.pagingNumber');

        this.apexCall(component, event, helper, 'getAddress',{
            searchText      : searchText,
            pagingNumber    : pagingNumber
        })
        .then($A.getCallback(function(result){
            let r = result.r;
            console.log('SearchAddressModal searchAddress : ', r);

            if (r.isSuccess) {
                // 검색 성공 시 결과 저장
                component.set('v.searchResults', r.resultMap.jusoList);
                // 전체 결과 수가 변경되었으면 페이지네이션 재계산
                if (component.get('v.allResultCount') != r.resultMap.totalResultCount) {
                    component.set('v.allResultCount', r.resultMap.totalResultCount);
                    helper.calcPaging(component, event, helper);
                }
            
                // 로딩 상태 해제
                component.set('v.isLoading', false);
            }
        }))
        .catch(function(error){
            console.log('SearchAddressModal searchAddress error : ' + JSON.stringify(error.message));
        })

    },
    calcPaging : function(component, event, helper){
        var dividePageCount = component.get('v.dividePageCount');
        var totalPage = Math.ceil(component.get('v.allResultCount')/dividePageCount);
        var pageAllCountList = [];
        var pageCountList = [];

        for(let i = 0; i < totalPage; i++){
            if(pageCountList.length == 10){
                pageAllCountList.push(pageCountList);
                pageCountList = [];
            }
            pageCountList.push(i);
        }
        pageAllCountList.push(pageCountList);
    
        component.set('v.totalPage', totalPage);
        component.set('v.pageAllCountList', pageAllCountList);
        component.set('v.pageCountList', pageAllCountList[0]);

    }
})