({
    doInitAction : function(component, event, helper) {
              var action = component.get("c.anularPedido");
        action.setParams({ "oppId": component.get("v.recordId") });
         action.setCallback( this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.op", response.getReturnValue());
                console.log(response.getReturnValue());
               
                    var vartitle = $A.get("$Label.c.AFOG_Pedido"); 
                    var msm	= $A.get("$Label.c.AFOG_PEDIDO_CANCELADO");
                    msm = msm.replace('{x}', response.intTaskNumber);
                    helper.showToast( vartitle , msm ,'trt' , 'pester');                    
                
                $A.get('e.force:refreshView').fire();
                var dismissActionPanel = $A.get("event.force:closeQuickAction");
                dismissActionPanel.fire();
            }
            else if(state = "ERROR"){
                var errorMsg = response.getError();
                if (errorMsg) {
                    if (errorMsg[0] && errorMsg[0].message) {
                        // log the error passed in to AuraHandledException                     
                        let toastParams = {
                        title: "Error",
                        message:  errorMsg[0].message, // Default error message
                        type: "error"
                        };
                        let toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams(toastParams);
                        toastEvent.fire();
                    }
                } else {
                    alert("Unknown error");
                }
            }           
        });
        $A.enqueueAction(action);
    },

     // function automatic called by aura:waiting event  
     showSpinner: function(component, event, helper) {
        // make Spinner attribute true for displaying loading spinner 
        component.set("v.spinner", true); 
    },
     
    // function automatic called by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hiding loading spinner    
        component.set("v.spinner", false);
    }
})