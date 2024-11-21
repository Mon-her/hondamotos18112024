({
    doInit: function(component, event, helper) {
        component.set("v.mensaje", 'Cargando datos de la Cuenta...');
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
            console.log("You loaded a record in ");
            
			//let button = component.find('btnSubmit');
            
            //let codigoERP = component.get("v.simpleRecord.Codigo_UNOEE__c"); console.log(codigoERP);
            //if (!(codigoERP==null || codigoERP=='')){
            if (component.get("v.simpleRecord.Creado_en_UNOEE__c")){
                component.set("v.mensaje", 'Esta cuenta ya ha sido creada en UNOEE!');
                //button.set('v.disabled',true);
                return;
            }

            //button.set('v.disabled',false);
            //component.set("v.mensaje", 'Por favor confirme el envío de la Cuenta a UNOEE...');
            
            var action;
            action = component.get("c.SendAccount");
            action.setParams({
                accountId: component.get("v.recordId")
            });
            console.log('Parámetros seteados');
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //component.set("v.mensaje", 'The Account has been Sent!');
                    let mensajeDevuelto = response.getReturnValue();
                    component.set("v.mensaje", mensajeDevuelto);
                    $A.get('e.force:refreshView').fire();
                }
                else {
                    console.log("Failed with state: " + state);
                    component.set("v.mensaje", 'Un Error ha ocurrido al enviar la Cuenta!');
                }
            });
           
            $A.enqueueAction(action);
            component.set("v.mensaje", 'Por favor espere mientras se envía la Cuenta...');

        } else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    },
     
    handleClose : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire() ;
    },
    
    handleSuccess: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    }
})