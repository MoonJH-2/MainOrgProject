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
    
})