({
    doInit: function(component, event, helper) {
        component.set("v.mensaje", 'Verificando Email...');
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
			//let button = component.find('btnSubmit');
           
            /*
            var email;
            var isPersonAccount = component.get("v.simpleRecord.RecordType.IsPersonType");
            console.log('isPersonAccount: ' + isPersonAccount);
            if (isPersonAccount)
                email = component.get("v.simpleRecord.PersonEmail");
            else{
                email = component.get("v.simpleRecord.AM_Correo_Electronico_Trabajo__c");
            }
                
            if (email==null || email==''){
                component.set("v.mensaje", 'La Cuenta no tiene un email que validar!');
                button.set('v.disabled',true);
                return;
            }
            */
            var action;
            action = component.get("c.validarEmail");
            
            action.setParams({
                accountId: component.get("v.recordId")
                //email: email,
            });
            console.log('Parámetros seteados');
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    let mensajeDevuelto = response.getReturnValue();
                    component.set("v.mensaje", mensajeDevuelto);
                    /*
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
                     */  
                    $A.get('e.force:refreshView').fire();
                }
                else {
                    console.log("Failed with state: " + state);
                    //component.set("v.mensaje", 'Un Error ha ocurrido al enviar la Validación!');
                    console.log(response.getError());
                    component.set("v.mensaje", response.getError()[0].message);
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
    
    /*enviarWS: function(component, event, helper) {
        
        let button = component.find('btnSubmit');
      
        
        //Si el código no es igual al enviado por el Web Service, entonces se procede a eliminar el teléfono
        var action;
        action = component.get("c.removeEmail");

        action.setParams({
            accountId: component.get("v.recordId"),
            isPersonAccount: component.get("v.simpleRecord.RecordType.IsPersonType")
        });
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
                component.set("v.mensaje", 'An Error has occurred to Update the Account!');
            }
        });
        
        button.set('v.disabled',true);
        
        // Send action off to be executed
        $A.enqueueAction(action);
        component.set("v.mensaje", 'Email Inválido, Por favor espere mientras se Elimina el Email!');
        //$A.get("e.force:closeQuickAction").fire(); no funciona, supongo porque aun no termina de cargar el form		
    },*/
    
    handleClose : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire() ;
    },
    
    handleSuccess: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    }
})