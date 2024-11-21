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
            
			let button = component.find('btnSubmit');
            
            let codigoERP = component.get("v.simpleRecord.Codigo_ERP__c"); console.log(codigoERP);
            if (!(codigoERP==null || codigoERP=='')){
                component.set("v.mensaje", 'Esta cuenta ya ha sido creado en SAP!');
                button.set('v.disabled',true);
                return;
            }

			//Checar si están validados telefono e email
			//PersonMobilePhone,Telefono_Validado__c,PersonEmail,AM_Correo_Electronico_Trabajo__c,Email_Validado__c
            if (component.get("v.simpleRecord.PersonMobilePhone")!=null && component.get("v.simpleRecord.PersonMobilePhone")!='' && !component.get("v.simpleRecord.Telefono_Validado__c")){
                component.set("v.mensaje", 'El teléfono de esta cuenta no ha sido validado!');
                button.set('v.disabled',true);
                return;
            }
            if (component.get("v.simpleRecord.RecordType.IsPersonType") && component.get("v.simpleRecord.PersonEmail")!= null && component.get("v.simpleRecord.PersonEmail")!= '' && !component.get("v.simpleRecord.Email_Validado__c")){
                component.set("v.mensaje", 'El Email de esta cuenta no ha sido validado!');
                button.set('v.disabled',true);
                return;
            }
            if (!component.get("v.simpleRecord.RecordType.IsPersonType") && component.get("v.simpleRecord.AM_Correo_Electronico_Trabajo__c")!= null && component.get("v.simpleRecord.AM_Correo_Electronico_Trabajo__c")!= '' && !component.get("v.simpleRecord.Email_Validado__c")){
                component.set("v.mensaje", 'El Email de esta cuenta no ha sido validado!');
                button.set('v.disabled',true);
                return;
            }
            
            //Checar si tiene marcado Lista Restrictiva
            if (!component.get("v.simpleRecord.Lista_Restrictiva__c")){
                component.set("v.mensaje", 'No se puede enviar para creación en ERP porque no se ha confirmado la validación en listas restrictivas!');
                button.set('v.disabled',true);
            }else{
                button.set('v.disabled',false);
                component.set("v.mensaje", 'Por favor confirme el envío de la Cuenta a SAP...');
            }

            
            //Codigo_ERP__c
        } else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    },
    
    enviarWS: function(component, event, helper) {
       var action;
        action = component.get("c.SendAccount");
        console.log('ln 32');
        action.setParams({
            accountId: component.get("v.recordId"),
            accion: 'C'
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
                component.set("v.mensaje", 'An Error has occurred to send the Account!');
            }
        });
        //Disable Button
        let button = component.find('btnSubmit');
        button.set('v.disabled',true);
        // Send action off to be executed
        $A.enqueueAction(action);
        console.log('ln 55');
        component.set("v.mensaje", 'Por favor espere mientras se envía la Cuenta...');
        /*
        var action;
        action = component.get("c.SendAccount");
        console.log('ln 32');
        action.setParams({
            accountId: component.get("v.recordId"),
            accion: component.find("cbOpcionWS").get("v.value")
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
                component.set("v.mensaje", 'An Error has occurred to send the Account!');
            }
        });
        //Disable Button
        let button = component.find('btnSubmit');
        button.set('v.disabled',true);
        // Send action off to be executed
        $A.enqueueAction(action);
        console.log('ln 55');
        component.set("v.mensaje", 'Please wait a moment as long as the Account is being sent...');
        //$A.get("e.force:closeQuickAction").fire(); no funciona, supongo porque aun no termina de cargar el form
        */
		
    },
    
    handleClose : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire() ;
    },
    
    handleSuccess: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    }
})