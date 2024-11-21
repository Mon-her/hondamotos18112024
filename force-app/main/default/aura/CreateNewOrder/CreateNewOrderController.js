({
    doInit: function(component, event, helper) {
        //$A.get('e.force:refreshView').fire();
        console.log('do Init');  
    },
    handleRecordUpdated: function(component, event, helper) {
        console.log('handleRecordUpdated');
        $A.get('e.force:refreshView').fire();
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");

            var mensaje;
            /*if (component.get("v.simpleRecord.Tipo_de_Oportunidad__c") == 'Usados' && (component.get("v.simpleRecord.Bodega_Usados__c") == null || component.get("v.simpleRecord.Bodega_Usados__c") == "")){
                component.set("v.mensaje", 'Error: Si el tipo de Oportunidad es "Usados", debe rellenar el campo Bodega Usados.');
                $A.get('e.force:refreshView').fire();
                return;
            }*/
            
            /*if (component.get("v.simpleRecord.Concesionario__c") == null || component.get("v.simpleRecord.Concesionario__c") == ''){
                component.set("v.mensaje", 'Error, la Oportunidad debe estar asignada a un Concesionario antes de crear el Pedido en SF.');
                $A.get('e.force:refreshView').fire();
                return;
            }*/
            
            if (component.get("v.simpleRecord.Vitrina__c") == null || component.get("v.simpleRecord.Vitrina__c") == ''){
                component.set("v.mensaje", 'Error, la Oportunidad debe estar asignada a una Vitrina antes de crear el Pedido en SF.');
                $A.get('e.force:refreshView').fire();
                return;
            }
            
            if (component.get("v.simpleRecord.RecordType.DeveloperName") == 'Oportunidad_Autos' && !component.get("v.simpleRecord.Realizo_Best_Drive__c")){
                component.set("v.mensaje", 'Error, la Oportunidad debe tener diligenciado si Realizó Best Drive.');
                $A.get('e.force:refreshView').fire();
                return;
            }
            
            if (mensaje!=null){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "Error!",
                    message: mensaje,
                    type: "error",
                    duration: '10000'
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
                return;
            }
            
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: "Info",
                message: "Por favor esperar un momento mientras se crea el pedido...",
                type: "info",
                duration: '2000'
            });
            toastEvent.fire();
            
            var action;
            action = component.get("c.EnviarPedido");
            action.setParams({
                oppId: component.get("v.recordId")
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log(state);
                if (state === "SUCCESS") {
                    var resp = response.getReturnValue();
                    if(resp.includes('Error')){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: "Error!",
                            message: resp,
                            type: "error",
                    		duration: '10000'
                        });
                        toastEvent.fire();
                        $A.get('e.force:refreshView').fire();
                        $A.get("e.force:closeQuickAction").fire();
                    } else {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: "Exitoso!",
                            message: resp,
                            type: "success",
                   			duration: '10000'
                        });
                        toastEvent.fire();
                        $A.get('e.force:refreshView').fire();
                        $A.get("e.force:closeQuickAction").fire();
                    }
                }
                else {
                    console.log("Failed with state: " + state);
                    console.log(response.getError()[0]);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Error!",
                        message: "Hubo un error, comunicate con tu administrador del sistema por favor.",
                        type: "error",
                    	duration: '10000'
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire();
                    $A.get("e.force:closeQuickAction").fire();
                }
            });
            $A.enqueueAction(action);
        } else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    },
    handleClose : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        $A.get("e.force:closeQuickAction").fire() ;
    }
})