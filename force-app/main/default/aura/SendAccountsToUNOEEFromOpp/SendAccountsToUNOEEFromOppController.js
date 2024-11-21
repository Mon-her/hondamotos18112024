({
    doInit: function(component, event, helper) {
        component.set("v.mensaje", 'Cargando datos de las Cuentas...');
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
            console.log("You loaded a record in ");
            
			//let button = component.find('btnSubmit');
            

            //if (component.get("v.simpleRecord.Creado_en_UNOEE__c")){
            //    component.set("v.mensaje", 'Esta cuenta ya ha sido creada en UNOEE!');
                //button.set('v.disabled',true);
                //return;
            //}

            //button.set('v.disabled',false);
            //component.set("v.mensaje", 'Por favor confirme el envío de la Cuenta a UNOEE...');
            //let button = component.find('btnSubmit');
            if (!component.get("v.simpleRecord.Facturar_a_nombre_de__r.IsPersonAccount") && !component.get("v.simpleRecord.Propietario_vehiculo__r.IsPersonAccount"))
            {
                component.set("v.mensaje", 'Las cuentas Facturar a nombre de y Propietario del vehículo son de tipo Jurídica. Ninguna cuenta se envió a UNOE!');
                return;
            }
            if (!component.get("v.simpleRecord.Consultado_en_listas_restrictivas__c") )
            {
                component.set("v.mensaje", 'Esta Oportunidad no ha sido Consultado en listas restrictivas!');
                return;
            }
            
            if (component.get("v.simpleRecord.Amount") == null )
            {
                component.set("v.mensaje", 'Esta Oportunidad no tiene establecido un Importe!');
                return;
            }
            if (component.get("v.simpleRecord.Propietario_vehiculo__c") == null )
            {
                component.set("v.mensaje", 'Esta Oportunidad no tiene establecido el Propietario del Vehículo!');
                return;
            }
            if (component.get("v.simpleRecord.Numero_consulta_en_Iistas_restrictivas__c") == null )
            {
                component.set("v.mensaje", 'Esta Oportunidad no tiene establecido el campo Número consulta en listas restrictivas!');
                return;
            }
            if (component.get("v.simpleRecord.Propietario_vehiculo__r.AM_Direccion__c") == null )
            {
                component.set("v.mensaje", 'El Propietario del Vehículo no tiene establecida la Dirección, por favor llénela antes de continuar!');
                return;
            }
            
            if (component.get("v.simpleRecord.Facturar_a_nombre_de__c") == null )
            {
                component.set("v.mensaje", 'Esta Oportunidad no tiene establecido a quién se le está facturando!');
                //button.set('v.disabled',true);
                return;
            }
			if (component.get("v.simpleRecord.Facturar_a_nombre_de__r.AM_Direccion__c") == null )
            {
                component.set("v.mensaje", 'La cuenta a facturar no tiene establecida la Dirección, por favor llénela antes de continuar!');
                return;
            }

            if (!component.get("v.simpleRecord.Facturar_a_nombre_de__r.Codigo_Postal__c") == null && !component.get("v.simpleRecord.Facturar_a_nombre_de__r.IsPersonAccount"))
            {
                component.set("v.mensaje", 'La cuenta a facturar no tiene establecido el codigo postal, por favor llénelo antes de continuar!');
                return;
            }

            var propietarioSameAsFactura = false;
            if (component.get("v.simpleRecord.Propietario_vehiculo__c")==component.get("v.simpleRecord.Facturar_a_nombre_de__c")) propietarioSameAsFactura = true;
            
            if (component.get("v.simpleRecord.Facturar_a_nombre_de__r.IsPersonAccount") )
            {
                var actionCtaFactura;
                actionCtaFactura = component.get("c.SendAccountFacturar");
                actionCtaFactura.setParams({
                     accountId: component.get("v.simpleRecord.Facturar_a_nombre_de__c"),
                     totalOpp: component.get("v.simpleRecord.Amount")
                });
                
                console.log('enviando a UnoE cuenta factura con monto');
                actionCtaFactura.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        //component.set("v.mensaje", 'The Account has been Sent!');
                        let mensajeDevuelto = response.getReturnValue();
                        component.set("v.mensaje", mensajeDevuelto);
                        if (mensajeDevuelto.toUpperCase().includes('ERROR')){
                            console.log(`Error al Enviar la Cuenta de Facturar a nombre de. ${mensajeDevuelto}`);
                            component.set("v.mensaje", `Error al Enviar la Cuenta de Facturar a nombre de. ${mensajeDevuelto}`);
                            return;
                        }else
                            component.set("v.mensaje", 'La Cuenta de Facturar a nombre de ha sido enviado a UNO-E satisfactoriamente!');
                            //component.set("v.mensaje", mensajeDevuelto);
                        
                        //Hacer el envío de la cuenta Propietario en caso de que sea diferente a la de facturar
                        if (!propietarioSameAsFactura){
                            if (component.get("v.simpleRecord.Propietario_vehiculo__r.IsPersonAccount")){
                                console.log('enviando a UnoE cuenta propietario sin monto');
                                var actionCtaPropietario;
                                actionCtaPropietario = component.get("c.SendAccount");
                                actionCtaPropietario.setParams({
                                    accountId: component.get("v.simpleRecord.Propietario_vehiculo__c"),
                                });
                                actionCtaPropietario.setCallback(this, function(response) {
                                    var state = response.getState();
                                    if (state === "SUCCESS") {
                                        //component.set("v.mensaje", 'The Account has been Sent!');
                                        let mensajeDevuelto = response.getReturnValue();
                                        if (mensajeDevuelto.toUpperCase().includes('ERROR')){
                                            console.log(`Error al Enviar la Cuenta del Propietario del Vehículo. ${mensajeDevuelto}`);
                                            component.set("v.mensaje", `Error al Enviar la Cuenta del Propietario del Vehículo. ${mensajeDevuelto}`);
                                            return;
                                        }else
                                            //component.set("v.mensaje", mensajeDevuelto);
                                            component.set("v.mensaje", 'Las cuentas del propietario del vehículo y facturación han sido enviadas a UNO-E satisfactoriamente!');
                                        $A.get('e.force:refreshView').fire();
                                    }
                                    else {
                                        console.log("Failed with state: " + state);
                                        component.set("v.mensaje", 'Un Error ha ocurrido al enviar la Cuenta del Propietario del Vehículo!');
                                        $A.get('e.force:refreshView').fire();
                                    }
                                });
                                $A.enqueueAction(actionCtaPropietario);
                            }else{
                                component.set("v.mensaje", 'La cuenta de Facturación fue enviada exitosamente, sin embargo la cuenta de propietario del vehículo es cuenta jurídica, por tanto no fue enviada!');
                            }
                            
                        }
                        
                    }
                    else {
                        console.log("Failed with state: " + state);
                        console.log(response.getError()[0]);
                        component.set("v.mensaje", 'Un Error ha ocurrido al enviar la Cuenta!');
                    }
                });
                
                $A.enqueueAction(actionCtaFactura);
                component.set("v.mensaje", 'Por favor espere mientras se envía la Cuenta...');
            
            }else{
                if (component.get("v.simpleRecord.Propietario_vehiculo__r.IsPersonAccount")){
                    console.log('enviando a UnoE cuenta propietario sin monto');
                    var actionCtaPropietario;
                    actionCtaPropietario = component.get("c.SendAccount");
                    actionCtaPropietario.setParams({
                        accountId: component.get("v.simpleRecord.Propietario_vehiculo__c"),
                    });
                    actionCtaPropietario.setCallback(this, function(response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                            //component.set("v.mensaje", 'The Account has been Sent!');
                            let mensajeDevuelto = response.getReturnValue();
                            if (mensajeDevuelto.toUpperCase().includes('ERROR')){
                                console.log(`Error al Enviar la Cuenta del Propietario del Vehículo. ${mensajeDevuelto}`);
                                component.set("v.mensaje", `Error al Enviar la Cuenta del Propietario del Vehículo. ${mensajeDevuelto}`);
                                return;
                            }else
                                //component.set("v.mensaje", mensajeDevuelto);
                                component.set("v.mensaje", 'La cuenta del propietario del vehículo ha sido enviada a UNO-E satisfactoriamente, sin embargo, la cuenta de Facturar no fue enviada por ser Jurídica!');
                            $A.get('e.force:refreshView').fire();
                        }
                        else {
                            console.log("Failed with state: " + state);
                            component.set("v.mensaje", 'Un Error ha ocurrido al enviar la Cuenta del Propietario del Vehículo!');
                            $A.get('e.force:refreshView').fire();
                        }
                    });
                    $A.enqueueAction(actionCtaPropietario);
                }else{
                    component.set("v.mensaje", 'No fue enviada ninguna cuenta por ser jurídicas!');
                }
            }
            /*
            var actionCtaFactura;
            var propietarioSameAsFactura = false;
            if (component.get("v.simpleRecord.Propietario_vehiculo__c")==component.get("v.simpleRecord.Facturar_a_nombre_de__c")) propietarioSameAsFactura = true;
            
            actionCtaFactura = component.get("c.SendAccountFacturar");
            actionCtaFactura.setParams({
                 accountId: component.get("v.simpleRecord.Facturar_a_nombre_de__c"),
                 totalOpp: component.get("v.simpleRecord.Amount")
            });
            
            console.log('enviando a UnoE cuenta factura con monto');
            actionCtaFactura.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //component.set("v.mensaje", 'The Account has been Sent!');
                    let mensajeDevuelto = response.getReturnValue();
                    component.set("v.mensaje", mensajeDevuelto);
                    if (mensajeDevuelto.toUpperCase().includes('ERROR')){
                        console.log(`Error al Enviar la Cuenta de Facturar a nombre de. ${mensajeDevuelto}`);
                        component.set("v.mensaje", `Error al Enviar la Cuenta de Facturar a nombre de. ${mensajeDevuelto}`);
                        return;
                    }else
                        component.set("v.mensaje", 'La Cuenta de Facturar a nombre de ha sido enviado a UNO-E satisfactoriamente!');
                        //component.set("v.mensaje", mensajeDevuelto);
                    
                    //Hacer el envío de la cuenta Propietario en caso de que sea diferente a la de facturar
                    if (!propietarioSameAsFactura){
                        console.log('enviando a UnoE cuenta propietario sin monto');
                        var actionCtaPropietario;
                        actionCtaPropietario = component.get("c.SendAccount");
                        actionCtaPropietario.setParams({
                            accountId: component.get("v.simpleRecord.Propietario_vehiculo__c"),
                        });
                        actionCtaPropietario.setCallback(this, function(response) {
                            var state = response.getState();
                            if (state === "SUCCESS") {
                                //component.set("v.mensaje", 'The Account has been Sent!');
                                let mensajeDevuelto = response.getReturnValue();
                                if (mensajeDevuelto.toUpperCase().includes('ERROR')){
                                    console.log(`Error al Enviar la Cuenta del Propietario del Vehículo. ${mensajeDevuelto}`);
                                    component.set("v.mensaje", `Error al Enviar la Cuenta del Propietario del Vehículo. ${mensajeDevuelto}`);
                                    return;
                                }else
                                    //component.set("v.mensaje", mensajeDevuelto);
                                    component.set("v.mensaje", 'Las cuentas del propietario del vehículo y facturación han sido enviadas a UNO-E satisfactoriamente!');
                                $A.get('e.force:refreshView').fire();
                            }
                            else {
                                console.log("Failed with state: " + state);
                                component.set("v.mensaje", 'Un Error ha ocurrido al enviar la Cuenta del Propietario del Vehículo!');
                                $A.get('e.force:refreshView').fire();
                            }
                        });
                        $A.enqueueAction(actionCtaPropietario);
                    }
                    
                }
                else {
                    console.log("Failed with state: " + state);
                    console.log(response.getError()[0]);
                    component.set("v.mensaje", 'Un Error ha ocurrido al enviar la Cuenta!');
                }
            });
            
            $A.enqueueAction(actionCtaFactura);
            component.set("v.mensaje", 'Por favor espere mientras se envía la Cuenta...');
            
            */

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