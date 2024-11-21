({
    doInit: function(component, event, helper) {
       
        var action;
        action = component.get("c.ConsultaPreciosDescuentos");
        action.setParams({
            quoteId: component.get("v.recordId")
        });
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: "Info",
            message: "Por favor esperar un momento mientras se solicitan los datos...",
            type: "info",
            duration: '2000'
        });
        toastEvent.fire();
        
        component.set("v.mensaje", 'Por favor esperar un momento mientras se solicitan los datos...');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resp = response.getReturnValue();
                console.log(response);
                if(resp.includes('Error')){
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                        title: "Error!",
                        message: resp,//"Hubo un error, verifica de tener los siguientes campos ingresados en Cotización: Tipo de pago y en los productos de cotización: Cantidad, Precio unitario, Soat, Cuota inicial, Seguro robo, Matricula y Descuento antes de aplicado impuesto.",
                        type: "error",
                    	duration: '10000'
                	});
                	toastEvent.fire();
                    component.set("v.mensaje", resp);
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
                    component.set("v.mensaje", resp);
                    $A.get('e.force:refreshView').fire();
                    $A.get("e.force:closeQuickAction").fire();
                }
            }
            else {
                console.log("Failed with state: " + state);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "Error!",
                    message: "Hubo un error del lado de SAP. Contacta a tu administrador para solucionarlo.",
                    type: "error",
                    duration: '10000'
                });
                toastEvent.fire();
                component.set("v.mensaje", 'Hubo un error del lado de SAP. Contacta a tu administrador para solucionarlo.');
                $A.get("e.force:closeQuickAction").fire() ;
            }
        });
        $A.enqueueAction(action);        
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
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
    }
})