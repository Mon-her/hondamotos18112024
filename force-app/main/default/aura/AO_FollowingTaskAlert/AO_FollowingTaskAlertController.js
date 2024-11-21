({
	doInit: function(component) {        
        var varTaskId  =  component.get("v.recordId"); 
        var action = component.get("c.getTask");
        action.setParams({
            idTask: varTaskId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var response = response.getReturnValue(); 
                var myNextDate = response.Fecha_de_proximo_seguimiento__c != null ? response.Fecha_de_proximo_seguimiento__c:null;              
                if ($A.util.isUndefinedOrNull(myNextDate) == false){
                    component.find("idNextDate").set("v.value", myNextDate );
                }                
            }
        })
       	$A.enqueueAction(action);
               
    },
    
    onChangeInput : function(component, event, helper) {
		
		var varTaskId  =  component.get("v.recordId");
        var varNextTask =  component.get("v.dateInput");  
        var action = component.get("c.showAlert");
        action.setParams({
            idTask: varTaskId,
            datSelected:varNextTask
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var response = response.getReturnValue();  
                if( response.blnSwowAlert ){
                    var vartitle = $A.get("$Label.c.AO_titleFollowingTask"); 
                    var msm	= $A.get("$Label.c.AO_msmFollowingTask");
                    msm = msm.replace('{x}', response.intTaskNumber);
                    helper.showToast( vartitle , msm ,'trt' , 'msgMode');                    
                }
                $A.get('e.force:refreshView').fire();
            }
        })
        $A.enqueueAction(action);
    }
})