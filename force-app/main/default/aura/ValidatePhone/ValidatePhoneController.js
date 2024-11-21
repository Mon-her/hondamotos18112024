({
    doInit: function(component, event, helper) {
        component.set("v.mensaje", 'Enviando Código de Verificación...');
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
            console.log("You loaded a record in ");
            //helper.createdTour = component.get("v.simpleRecord.TourCreado__c");
			let button = component.find('btnSubmit');
           
            
            
            var numero;
            var isPersonAccount = component.get("v.simpleRecord.RecordType.IsPersonType");
            console.log('isPersonAccount: ' + isPersonAccount);
            if (isPersonAccount)
                numero = component.get("v.simpleRecord.PersonMobilePhone");
            else{
                component.set("v.mensaje", 'La Cuenta no es de tipo Natural!');
                button.set('v.disabled',true);
                return;
            }
                //numero = component.get("v.Phone");
            if (numero==null || numero==''){
                component.set("v.mensaje", 'La Cuenta no tiene un número de celular que validar!');
                button.set('v.disabled',true);
                return;
            }
            
            var action;
            action = component.get("c.validarTelefono");
            
            action.setParams({
                numero: numero,
                mensaje: 'Código de Verificación es: '
            });
            console.log('Parámetros seteados');
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //component.set("v.mensaje", 'The Account has been Sent!');
                    let mensajeDevuelto = response.getReturnValue();
                    console.log(mensajeDevuelto);
                    if (!mensajeDevuelto.includes("Error")){
                        helper.Codigo = mensajeDevuelto;
                        button.set('v.disabled',false);
                        component.set("v.mensaje",'Validar el Código?');
                    }                  	
                    else{
                        component.set("v.mensaje", mensajeDevuelto);
                    }
                       
                    //$A.get('e.force:refreshView').fire();
                }
                else {
                    console.log("Failed with state: " + state);
                    component.set("v.mensaje", 'Un Error ha ocurrido al enviar la Validación!');
                }
            });
            
            // Send action off to be executed
            $A.enqueueAction(action);
            console.log('ln 55'); 
        } else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    },
    
    enviarWS: function(component, event, helper) {
        var codigo = component.find("txtCodigo").get("v.value");
        if (codigo=='') {
            component.set("v.mensaje", 'Ingrese un Código para Validar');
            //return null;
        }
        let button = component.find('btnSubmit');
        var action;
        //console.log('helper.Codigo: ' + helper.Codigo);
        //Si el código es igual al enviado por el web service, entonces no pasa nada y sale de aquí
        if (codigo ==helper.Codigo) {
        	component.set("v.mensaje", 'Código Verificado, Actualizando registro...');
            button.set('v.disabled',true);
            action = component.get("c.setValidatedPhone");
            action.setParams({
            	accountId: component.get("v.recordId")
            });
        }else{
            //Si el código no es igual al enviado por el Web Service, entonces se procede a eliminar el teléfono
        	action = component.get("c.removePhone");
            action.setParams({
            	accountId: component.get("v.recordId"),
                isPersonAccount: component.get("v.simpleRecord.RecordType.IsPersonType")
            });
            component.set("v.mensaje", 'Por favor espere mientras se Elimina el Teléfono!');
        }
        
        console.log('Parámetros seteados');
        // Add callback behavior for when response is received
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let mensajeDevuelto = response.getReturnValue();
                component.set("v.mensaje", mensajeDevuelto);
                $A.get('e.force:refreshView').fire();
            }
            else {
                console.log("Failed with state: " + state);
                component.set("v.mensaje", 'Un Error ha ocurrido al enviar la Validación!');
            }
        });
        
        button.set('v.disabled',true);
        
        // Send action off to be executed
        $A.enqueueAction(action);
        
        //$A.get("e.force:closeQuickAction").fire(); no funciona, supongo porque aun no termina de cargar el form		
    },
    
    handleClose : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire() ;
    },
    
    handleSuccess: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    }
})