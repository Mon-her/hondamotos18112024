({
    doInit: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        console.log('do Init');
        /*
        //Realizar validaciones de Account: Lista Restrictiva, email y telefono
        //Checar si están validados telefono e email
        //PersonMobilePhone,Telefono_Validado__c,PersonEmail,AM_Correo_Electronico_Trabajo__c,Email_Validado__c
        var mensaje;
        if (component.get("v.simpleRecord.Account.PersonMobilePhone")!=null && component.get("v.simpleRecord.Account.PersonMobilePhone")!='' && !component.get("v.simpleRecord.Account.Telefono_Validado__c")){
            mensaje = 'El teléfono de la cuenta principal no ha sido validado!';
        }
        if (component.get("v.simpleRecord.Account.RecordType.IsPersonType") && component.get("v.simpleRecord.Account.PersonEmail")!= null && component.get("v.simpleRecord.Account.PersonEmail")!= '' && !component.get("v.simpleRecord.Account.Email_Validado__c")){
            mensaje = 'El Email de la cuenta principal no ha sido validado!';
        }
        if (!component.get("v.simpleRecord.Account.RecordType.IsPersonType") && component.get("v.simpleRecord.Account.AM_Correo_Electronico_Trabajo__c")!= null && component.get("v.simpleRecord.Account.AM_Correo_Electronico_Trabajo__c")!= '' && !component.get("v.simpleRecord.Account.Email_Validado__c")){
            mensaje = 'El Email de la cuenta principal no ha sido validado!';
        }
        console.log('component:' + component);
        console.log('v.simpleRecord.Account.PersonMobilePhone: ' + component.get("v.simpleRecord.Account.PersonMobilePhone"));
        console.log('v.simpleRecord.Account.PersonEmail: ' + component.get("v.simpleRecord.Account.PersonEmail"));
        console.log('v.simpleRecord.Account.AM_Correo_Electronico_Trabajo__c: ' + component.get("v.simpleRecord.Account.AM_Correo_Electronico_Trabajo__c"));
        //Checar si tiene marcado Lista Restrictiva
        console.log('v.simpleRecord.Account.Lista_Restrictiva__c: ' + component.get("v.simpleRecord.Account.Lista_Restrictiva__c"));
        if (!component.get("v.simpleRecord.Account.Lista_Restrictiva__c")){
            mensaje = 'No se puede enviar para creación en ERP porque no se ha confirmado la validación en listas restrictivas de la cuenta principal!';
        }
        
        if (mensaje!=null){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: "Error!",
                message: mensaje,
                type: "error",
                mode: 'sticky'
            });
            toastEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
            return;
        }
        
        
        var action;
        action = component.get("c.CrearPedido");
        action.setParams({
            oppId: component.get("v.recordId")
        });
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: "Info",
            message: "Por favor esperar un momento mientras el pedido se envia...",
            type: "info",
            duration: '2000'
        });
        toastEvent.fire();
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resp = response.getReturnValue();
                if(resp.includes('Error')){
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                        title: "Error!",
                        message: resp,
                        type: "error",
                        mode: 'sticky'
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Exitoso!",
                        message: resp,
                        type: "success",
                        mode: 'sticky'
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire();
                    $A.get("e.force:closeQuickAction").fire();
                }
            }
            else {
                console.log("Failed with state: " + state);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "Error!",
                    message: "Hubo un error, verifica de tener los siguientes campos ingresados en Cotización: Tipo de pago y en los productos de cotización: Cantidad, Precio unitario, Soat, Cuota inicial, Seguro robo, Matricula y Descuento antes de aplicado impuesto.",
                    type: "error",
                    mode: 'sticky'
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);    */    
    },
    handleRecordUpdated: function(component, event, helper) {
        console.log('handleRecordUpdated');
        $A.get('e.force:refreshView').fire();
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
            
            //Realizar validaciones de Account: Lista Restrictiva, email y telefono
            //Checar si están validados telefono e email
            //PersonMobilePhone,Telefono_Validado__c,PersonEmail,AM_Correo_Electronico_Trabajo__c,Email_Validado__c
            //Titular_prendario__c	Pagador__c	Destinatario_Mercanc_a__c	Destinatario_Factura__c
            var mensaje;
            if(component.get("v.simpleRecord.ID_de_pedido_ERP__c")!=null ){
                 mensaje =  $A.get("$Label.c.GTAO_msmOrderInSAP");
            }
             if ( component.get("v.simpleRecord.GTAO_PedidoEnviadoSAP__c")){  //AO 09-12-2021 Inactive call out in WS
                mensaje =  $A.get("$Label.c.GTAO_msmOrderSentToSap");   //AO 09-12-2021 Inactive call out in WS
            }
            if (!component.get("v.simpleRecord.Account.Autorizacion_digital__pc") && component.get("v.simpleRecord.Account.PersonMobilePhone")!=null && component.get("v.simpleRecord.Account.PersonMobilePhone")!='' && !component.get("v.simpleRecord.Account.Telefono_Validado__c")){
                mensaje = 'El teléfono de la cuenta principal no ha sido validado!';
            }
            if (component.get("v.simpleRecord.Account.RecordType.IsPersonType") && component.get("v.simpleRecord.Account.PersonEmail")!= null && component.get("v.simpleRecord.Account.PersonEmail")!= '' && !component.get("v.simpleRecord.Account.Email_Validado__c")){
                mensaje = 'El Email de la cuenta principal no ha sido validado!';
            }
            //if (!component.get("v.simpleRecord.Account.RecordType.IsPersonType") && component.get("v.simpleRecord.Account.AM_Correo_Electronico_Trabajo__c")!= null && component.get("v.simpleRecord.Account.AM_Correo_Electronico_Trabajo__c")!= '' && !component.get("v.simpleRecord.Account.Email_Validado__c")){
            //    mensaje = 'El Email de la cuenta principal no ha sido validado!';
            //}
            if (component.get("v.simpleRecord.Account.RecordType.IsPersonType") &&  !component.get("v.simpleRecord.Account.Autorizacion_digital__pc") && component.get("v.simpleRecord.Account.Permiso_de_Contacto__c")=='Autorizado' && (component.get("v.simpleRecord.Account.Adjuntos__c")==null || component.get("v.simpleRecord.Account.Adjuntos__c")==0) ){
                mensaje = 'El Permiso de contacto de la cuenta principal está autorizado pero no hay adjuntos!';
            }
            if (component.get("v.simpleRecord.Account.RecordType.IsPersonType") && component.get("v.simpleRecord.Account.PersonBirthdate") == null || component.get("v.simpleRecord.Account.PersonBirthdate") == ""){
                mensaje = 'La fecha de nacimiento de la Cuenta principal no puede estar vacía.';
            }
            
            if (component.get("v.simpleRecord.Account.RecordType.IsPersonType") ){
                if (!component.get("v.simpleRecord.Account.AM_Estado_civil__pc") ) mensaje = 'La cuenta Principal no tiene establecido un Estado Civil!';
                if (!component.get("v.simpleRecord.Account.Tiene_Hijos__c") ) mensaje = 'La cuenta Principal no tiene establecido si tiene hijos!';
                if (!component.get("v.simpleRecord.Account.Nivel_educativo__c") ) mensaje = 'La cuenta Principal no tiene establecido el nivel educativo!';
                if (!component.get("v.simpleRecord.Account.AM_Nivel_Socioeconomico__c") ) mensaje = 'La cuenta Principal no tiene establecido un nivel socioeconómico!';
            	if (!component.get("v.simpleRecord.Account.Nivel_de_ingresos__c") ) mensaje = 'La cuenta Principal no tiene establecido un nivel de ingresos!';
                
                
                //Validaciones de la oportunidad
                if (component.get("v.simpleRecord.Averigu_sobre_otras_marcas__c")=='Si' && !component.get("v.simpleRecord.Referencia_que_averiguo_motos__c") ) mensaje = 'La oportunidad no tiene establecido la Referencia que averiguó!';
                if (component.get("v.simpleRecord.Tipo_de_cliente__c") == 'Cliente Otra Marca' && !component.get("v.simpleRecord.Marca_de_motocicleta_anterior__c") ) mensaje = 'La oportunidad no tiene establecido la Marca de motocicleta anterior!';
                if (component.get("v.simpleRecord.Tipo_de_cliente__c") == 'Cliente Otra Marca' && !component.get("v.simpleRecord.Referencia_Modelo__c") ) mensaje = 'La oportunidad no tiene establecido la Referencia/Modelo!';
                if (component.get("v.simpleRecord.Tipo_de_cliente__c") == 'Cliente Otra Marca' && !component.get("v.simpleRecord.Qu_hizo_con_su_anterior_motocicleta__c") ) mensaje = 'La oportunidad no tiene establecido ¿Qué hizo con su anterior motocicleta?!';
                if (component.get("v.simpleRecord.Tipo_de_cliente__c") == 'Cliente Otra Marca' && !component.get("v.simpleRecord.Tiempo_q_tuvo_moto_ant__c") ) mensaje = 'La oportunidad no tiene establecido el Tiempo que tuvo la motocicleta anterior!';
                
                if (component.get("v.simpleRecord.Tipo_de_cliente__c") == 'Cliente Honda' && !component.get("v.simpleRecord.Qu_hizo_con_su_anterior_motocicleta__c") ) mensaje = 'La oportunidad no tiene establecido ¿Qué hizo con su anterior motocicleta?!';
                if (component.get("v.simpleRecord.Tipo_de_cliente__c") == 'Cliente Honda' && !component.get("v.simpleRecord.Tiempo_q_tuvo_moto_ant__c") ) mensaje = 'La oportunidad no tiene establecido el Tiempo que tuvo la motocicleta anterior!';
                if (component.get("v.simpleRecord.Tipo_de_cliente__c") == 'Cliente Honda' && !component.get("v.simpleRecord.Referencia_Modelo__c") ) mensaje = 'La oportunidad no tiene establecido la Referencia/Modelo!';
                
                    
            }
            
            
            //console.log('v.simpleRecord.Account.Permiso_de_Contacto__c: ' + component.get("v.simpleRecord.Account.Permiso_de_contacto_del__pc"));
            //console.log('v.simpleRecord.Account.Adjuntos__c: ' + component.get("v.simpleRecord.Account.Adjuntos__c"));
            
            //console.log('component:' + component);
            //console.log('v.simpleRecord.Account.PersonMobilePhone: ' + component.get("v.simpleRecord.Account.PersonMobilePhone"));
            //console.log('v.simpleRecord.Account.PersonEmail: ' + component.get("v.simpleRecord.Account.PersonEmail"));
            //console.log('v.simpleRecord.Account.AM_Correo_Electronico_Trabajo__c: ' + component.get("v.simpleRecord.Account.AM_Correo_Electronico_Trabajo__c"));
            //Checar si tiene marcado Lista Restrictiva
            //console.log('v.simpleRecord.Account.Lista_Restrictiva__c: ' + component.get("v.simpleRecord.Account.Lista_Restrictiva__c"));
            if (!component.get("v.simpleRecord.Account.Lista_Restrictiva__c")){
                mensaje = 'No se puede enviar para creación en ERP porque no se ha confirmado la validación en listas restrictivas de la cuenta principal!';
            }
            
            if (!component.get("v.simpleRecord.Account.AM_Direccion__c") && (!component.get("v.simpleRecord.Account.Prefijo_Complemento__c") || !component.get("v.simpleRecord.Account.AM_Complemento__c") )){
                mensaje = 'No se puede enviar para creación en ERP porque no se ha diligenciado la dirección de la cuenta principal!';
            }
            
            //Validaciones de Pagador
            //if (!component.get("v.simpleRecord.Pagador__r.Autorizacion_digital__pc") && component.get("v.simpleRecord.Pagador__r.PersonMobilePhone")!=null && component.get("v.simpleRecord.Pagador__r.PersonMobilePhone")!='' && !component.get("v.simpleRecord.Pagador__r.Telefono_Validado__c")){
            //   mensaje = 'El teléfono del Pagador no ha sido validado!';
            //}
            //if (component.get("v.simpleRecord.Pagador__.RecordType.IsPersonType") && component.get("v.simpleRecord.Pagador__r.PersonEmail")!= null && component.get("v.simpleRecord.Pagador__r.PersonEmail")!= '' && !component.get("v.simpleRecord.Pagador__r.Email_Validado__c")){
            //    mensaje = 'El Email del Pagador no ha sido validado!';
            //}
            //if (!component.get("v.simpleRecord.Pagador__r.RecordType.IsPersonType") && component.get("v.simpleRecord.Pagador__r.AM_Correo_Electronico_Trabajo__c")!= null && component.get("v.simpleRecord.Pagador__r.AM_Correo_Electronico_Trabajo__c")!= '' && !component.get("v.simpleRecord.Pagador__r.Email_Validado__c")){
            //    mensaje = 'El Email del Pagador no ha sido validado!';
            //}
            
            if (component.get("v.simpleRecord.Pagador__r.RecordType.IsPersonType") && !component.get("v.simpleRecord.Pagador__r.Autorizacion_digital__pc") && component.get("v.simpleRecord.Pagador__r.Permiso_de_Contacto__c")=='Autorizado' && (component.get("v.simpleRecord.Pagador__r.Adjuntos__c")==null || component.get("v.simpleRecord.Pagador__r.Adjuntos__c")==0) ){
                mensaje = 'El Permiso de contacto del Pagador está autorizado pero no hay adjuntos!';
            }
            
            console.log('v.simpleRecord.Pagador__r.Lista_Restrictiva__c: ' + component.get("v.simpleRecord.Pagador__r.Lista_Restrictiva__c"));
            if (!component.get("v.simpleRecord.Pagador__r.Lista_Restrictiva__c")){
                mensaje = 'No se puede enviar para creación en ERP porque no se ha confirmado la validación en listas restrictivas del Pagador!';
            }
            
            if (!component.get("v.simpleRecord.Pagador__r.AM_Direccion__c") && (!component.get("v.simpleRecord.Pagador__r.Prefijo_Complemento__c") || !component.get("v.simpleRecord.Pagador__r.AM_Complemento__c") )){
                mensaje = 'No se puede enviar para creación en ERP porque no se ha diligenciado la dirección de la cuenta del Pagador!';
            }
            //Validaciones de destinatario Factura
            //if (!component.get("v.simpleRecord.Destinatario_Factura__r.Autorizacion_digital__pc") && component.get("v.simpleRecord.Destinatario_Factura__r.PersonMobilePhone")!=null && component.get("v.simpleRecord.Destinatario_Factura__r.PersonMobilePhone")!='' && !component.get("v.simpleRecord.Destinatario_Factura__r.Telefono_Validado__c")){
            //    mensaje = 'El teléfono del Destinatario de Factura no ha sido validado!';
            //}
            //if (component.get("v.simpleRecord.Destinatario_Factura__r.RecordType.IsPersonType") && component.get("v.simpleRecord.Destinatario_Factura__r.PersonEmail")!= null && component.get("v.simpleRecord.Destinatario_Factura__r.PersonEmail")!= '' && !component.get("v.simpleRecord.Destinatario_Factura__r.Email_Validado__c")){
            //    mensaje = 'El Email del Destinatario de Factura no ha sido validado!';
            //}
            //if (!component.get("v.simpleRecord.Destinatario_Factura__r.RecordType.IsPersonType") && component.get("v.simpleRecord.Destinatario_Factura__r.AM_Correo_Electronico_Trabajo__c")!= null && component.get("v.simpleRecord.Destinatario_Factura__r.AM_Correo_Electronico_Trabajo__c")!= '' && !component.get("v.simpleRecord.Destinatario_Factura__r.Email_Validado__c")){
            //    mensaje = 'El Email del Destinatario de Factura no ha sido validado!';
            //}
            
            if (component.get("v.simpleRecord.Destinatario_Factura__r.RecordType.IsPersonType") && !component.get("v.simpleRecord.Destinatario_Factura__r.Autorizacion_digital__pc") && component.get("v.simpleRecord.Destinatario_Factura__r.Permiso_de_Contacto__c")=='Autorizado' && (component.get("v.simpleRecord.Destinatario_Factura__r.Adjuntos__c")==null || component.get("v.simpleRecord.Destinatario_Factura__r.Adjuntos__c")==0) ){
                mensaje = 'El Permiso de contacto del Destinatario de Factura está autorizado pero no hay adjuntos!';
            }
            
            console.log('v.simpleRecord.Destinatario_Factura__r.Lista_Restrictiva__c: ' + component.get("v.simpleRecord.Destinatario_Factura__r.Lista_Restrictiva__c"));
            if (!component.get("v.simpleRecord.Destinatario_Factura__r.Lista_Restrictiva__c")){
                mensaje = 'No se puede enviar para creación en ERP porque no se ha confirmado la validación en listas restrictivas del Destinatario de Factura!';
            }
            
            if (!component.get("v.simpleRecord.Destinatario_Factura__r.AM_Direccion__c") && (!component.get("v.simpleRecord.Destinatario_Factura__r.Prefijo_Complemento__c") || !component.get("v.simpleRecord.Destinatario_Factura__r.AM_Complemento__c") )){
                mensaje = 'No se puede enviar para creación en ERP porque no se ha diligenciado la dirección de la cuenta del Destinatario de Factura!';
            }
            //Validaciones de destinatario Mercancía
            //if (!component.get("v.simpleRecord.Destinatario_Mercanc_a__r.Autorizacion_digital__pc") && component.get("v.simpleRecord.Destinatario_Mercanc_a__r.PersonMobilePhone")!=null && component.get("v.simpleRecord.Destinatario_Mercanc_a__r.PersonMobilePhone")!='' && !component.get("v.simpleRecord.Destinatario_Mercanc_a__r.Telefono_Validado__c")){
            //    mensaje = 'El teléfono del Destinatario de Mercancía no ha sido validado!';
            //}
            //if (component.get("v.simpleRecord.Destinatario_Mercanc_a__r.RecordType.IsPersonType") && component.get("v.simpleRecord.Destinatario_Mercanc_a__r.PersonEmail")!= null && component.get("v.simpleRecord.Destinatario_Mercanc_a__r.PersonEmail")!= '' && !component.get("v.simpleRecord.Destinatario_Mercanc_a__r.Email_Validado__c")){
            //    mensaje = 'El Email del Destinatario de Mercancía no ha sido validado!';
            //}
            //if (!component.get("v.simpleRecord.Destinatario_Mercanc_a__r.RecordType.IsPersonType") && component.get("v.simpleRecord.Destinatario_Mercanc_a__r.AM_Correo_Electronico_Trabajo__c")!= null && component.get("v.simpleRecord.Destinatario_Mercanc_a__r.AM_Correo_Electronico_Trabajo__c")!= '' && !component.get("v.simpleRecord.Destinatario_Mercanc_a__r.Email_Validado__c")){
            //    mensaje = 'El Email del Destinatario de Mercancía no ha sido validado!';
            //}
            
            if (component.get("v.simpleRecord.Destinatario_Mercanc_a__r.RecordType.IsPersonType") && !component.get("v.simpleRecord.Destinatario_Mercanc_a__r.Autorizacion_digital__pc") && component.get("v.simpleRecord.Destinatario_Mercanc_a__r.Permiso_de_Contacto__c")=='Autorizado' && (component.get("v.simpleRecord.Destinatario_Mercanc_a__r.Adjuntos__c")==null || component.get("v.simpleRecord.Destinatario_Mercanc_a__r.Adjuntos__c")==0) ){
                mensaje = 'El Permiso de contacto del Destinatario de Mercancía está autorizado pero no hay adjuntos!';
            }
            
            console.log('v.simpleRecord.Destinatario_Mercanc_a__r.Lista_Restrictiva__c: ' + component.get("v.simpleRecord.Destinatario_Mercanc_a__r.Lista_Restrictiva__c"));
            if (!component.get("v.simpleRecord.Destinatario_Mercanc_a__r.Lista_Restrictiva__c")){
                mensaje = 'No se puede enviar para creación en ERP porque no se ha confirmado la validación en listas restrictivas del Destinatario de Mercancía!';
            }
            
            if (!component.get("v.simpleRecord.Destinatario_Mercanc_a__r.AM_Direccion__c") && (!component.get("v.simpleRecord.Destinatario_Mercanc_a__r.Prefijo_Complemento__c") || !component.get("v.simpleRecord.Destinatario_Mercanc_a__r.AM_Complemento__c") )){
                mensaje = 'No se puede enviar para creación en ERP porque no se ha diligenciado la dirección de la cuenta del Destinatario de Mercancía!';
            }
             //Validaciones de Titular Prendario
            //if (!component.get("v.simpleRecord.Titular_prendario__r.Autorizacion_digital__pc") && component.get("v.simpleRecord.Titular_prendario__r.PersonMobilePhone")!=null && component.get("v.simpleRecord.Titular_prendario__r.PersonMobilePhone")!='' && !component.get("v.simpleRecord.Titular_prendario__r.Telefono_Validado__c")){
            //    mensaje = 'El teléfono del Titular Prendario no ha sido validado!';
            //}
            //if (component.get("v.simpleRecord.Titular_prendario__r.RecordType.IsPersonType") && component.get("v.simpleRecord.Titular_prendario__r.PersonEmail")!= null && component.get("v.simpleRecord.Titular_prendario__r.PersonEmail")!= '' && !component.get("v.simpleRecord.Titular_prendario__r.Email_Validado__c")){
            //   mensaje = 'El Email del Titular Prendario no ha sido validado!';
            //}
            //if (!component.get("v.simpleRecord.Titular_prendario__r.RecordType.IsPersonType") && component.get("v.simpleRecord.Titular_prendario__r.AM_Correo_Electronico_Trabajo__c")!= null && component.get("v.simpleRecord.Titular_prendario__r.AM_Correo_Electronico_Trabajo__c")!= '' && !component.get("v.simpleRecord.Titular_prendario__r.Email_Validado__c")){
            //    mensaje = 'El Email del Titular Prendario no ha sido validado!';
            //}
            
            if (component.get("v.simpleRecord.Titular_prendario__r.RecordType.IsPersonType") && !component.get("v.simpleRecord.Titular_prendario__r.Autorizacion_digital__pc") && component.get("v.simpleRecord.Titular_prendario__r.Permiso_de_Contacto__c")=='Autorizado' && (component.get("v.simpleRecord.Titular_prendario__r.Adjuntos__c")==null || component.get("v.simpleRecord.Titular_prendario__r.Adjuntos__c")==0) ){
                mensaje = 'El Permiso de contacto del Titular Prendario está autorizado pero no hay adjuntos!';
            }
            
            console.log('v.simpleRecord.Titular_prendario__r.Lista_Restrictiva__c: ' + component.get("v.simpleRecord.Titular_prendario__r.Lista_Restrictiva__c"));
            if (!component.get("v.simpleRecord.Titular_prendario__r.Lista_Restrictiva__c")){
                mensaje = 'No se puede enviar para creación en ERP porque no se ha confirmado la validación en listas restrictivas del Titular Prendario!';
            }
            
            if (!component.get("v.simpleRecord.Titular_prendario__r.AM_Direccion__c") && (!component.get("v.simpleRecord.Titular_prendario__r.Prefijo_Complemento__c") || !component.get("v.simpleRecord.Titular_prendario__r.AM_Complemento__c") )){
                mensaje = 'No se puede enviar para creación en ERP porque no se ha diligenciado la dirección de la cuenta del Titular Prendario!';
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
            
            
            var action;
            action = component.get("c.CrearPedido");
            action.setParams({
                oppId: component.get("v.recordId")
            });
            
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: "Info",
                message: "Por favor esperar un momento mientras el pedido se envia...",
                type: "info",
                duration: '2000'
            });
            toastEvent.fire();
            
            action.setCallback(this, function(response) {
                var state = response.getState();
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
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Error!",
                        message: "Hubo un error, verifica de tener los siguientes campos ingresados en Cotización: Tipo de pago y en los productos de cotización: Cantidad, Precio unitario, Soat, Cuota inicial, Seguro robo, Matricula y Descuento antes de aplicado impuesto.",
                        type: "error",
                    	duration: '10000'
                    });
                    toastEvent.fire();
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
        $A.get("e.force:closeQuickAction").fire() ;
    }
})