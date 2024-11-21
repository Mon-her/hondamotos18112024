/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Consumo de servicio web para la creación de Pedidos en UNOEE
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     Marzo/08/2021   Juan Ansaldi            Class definition.        
* @version  1.1     September/2021  Me                      Only Person Accounts need to be created in UNOE.    
*********************************************************************************************************/
public class AutosCrearPedidoEnUNOEE {
    @AuraEnabled
    public static integer validarVINduplicado( Opportunity varOpp ){
        List< Opportunity > lstOpp = new  List< Opportunity >();
        if(STRING.ISNOTBLANK( varOpp.VIN__c ) ){
            lstOpp = [SELECT Id FROM Opportunity WHERE  VIN__c =:varOpp.VIN__c  and StageName ='P4' and id !=: varOpp.Id];
        }
        SYSTEM.DEBUG('VIN OPP @@@' + JSON.serializePretty( lstOpp));
        return lstOpp.size();
    }
    @AuraEnabled
    public static String EnviarPedido(Id oppId){
        FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER objWS = new FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER();
        string body;
        try{
            List<Inventario_de_Usados__c> invList = New List<Inventario_de_Usados__c>();
            Opportunity objSFoppty = [select Usado_Separado__c, Vehiculo__c, Account.RecordType.IsPersonType, Id, Vitrina_de_despacho__c, Notas_de_despacho__c, Fecha_de_determinacion_del_precio__c, Amount, Forma_de_pago__c, CloseDate, Pricebook2Id,
                                      Destinatario_Factura__c, Marca_retoma__c, Account.RecordType.DeveloperName, Version_retoma__c, Modelo_retoma__c, Facturar_a_nombre_de__c, N_mero_O_C__c, Destinatario_Mercanc_a__c, Pagador__c, Titular_prendario__c, Tipo_de_Oportunidad__c, Se_creo_pedido_en_UNOEE__c,
                                      Numero_de_Oportunidad__c, Vitrina__c, VIN__c, Account.AM_Direccion__c, AccountId, Account.BillingStreet, Account.BillingState, Account.BillingCity, Bodega_Usados__c,
                                      OwnerId, Fecha_de_validez__c, Account.Actividad_economica__c, Account.AM_Ocupacion_pc__c, Referencia_E_A_C__c, ID_de_pedido_ERP__c, Account.BillingPostalCode, Account.BillingCountry, Concesionario__c, Tipo_de_Inv_Usado__c,
                                      Account.ShippingStreet, Account.ShippingState, Tipo_Impo_Utilidad__c, Valor_Utilidad__c, Account.ShippingCity, Account.ShippingPostalCode, Motivo_de_Oportunidad_Vendida__c,
                                      Cu_l_marca_averigu_durante_la_compra__c, Averigu_sobre_otras_marcas__c, Que_otras_marcas_consideraron__c, Concesionario2__c, Agencia2__c,
                                      Account.ShippingCountry, Order_Generated__c, (Select Id, Name, OpportunityId, Product2.Placa__c, ProductCode, PriceBookEntryId, Valor_soat__c, Valor_matrcula__c, Soat__c,
                                                                Cuota_Inicial__c, Valor_seguro_robo__c, Descuento_valor__c, Quantity, UnitPrice, Anticipo__c, Avaluado_por__c,
                                                                Casco__c, Cheque_posfechado_avalado__c, Contrato__c, Accesorios__c, Cuota_mensual__c, Definici_n_de_aprobaciones__c,
                                                                DescARD__c, DescAuto__c, Descuento_aplicado_antes_de_impuesto__c, DescValARD__c, DescValAuto__c, Product2Id,
                                                                Desembolso_entidad_financiera__c, FinancieraPlan__c, Impoconsumo__c, Iva__c, Otros_gastos__c, Plazo_en_meses__c,
                                                                Precio_de_lista_antes_de_impuesto__c, Recompra__c, Saldo_a_financiar__c, Saldo_contra_entrega__c, Sitio_de_matrcula__c,
                                                                Tipo_Carrocera__c, Valor_Total_Vehculo__c, Valor_Vehculo__c, Total__c, Subtotal_moto__c, Valor_ARD__c
                                                                from OpportunityLineItems)
                                      from Opportunity where Id =: oppId Limit 1];
            system.debug('*-*-*-*-*-*-*-*-*-*-*-*-*objSFoppty: ' + objSFoppty);
            Account acc = [select RecordType.DeveloperName, Phone, IsPersonAccount, Actividad_economica__c, Creado_en_UNOEE__c, Id, AM_Numero_de_documento__c, Sucursal__c, AM_Direccion__c, PersonMobilePhone, 
                           MC_Correo_electronico_Empresa__c, PersonEmail, AM_Ocupacion_pc__c, AM_Ciudad__r.ID_UNOEE__c, AM_Nivel_Socioeconomico__c, AM_Estado_civil__pc
                           from Account where Id=: objSFoppty.AccountId Limit 1];
            
            Account accFacturar = [select RecordType.DeveloperName, Phone, IsPersonAccount, Actividad_economica__c, Creado_en_UNOEE__c, Id, AM_Numero_de_documento__c, Sucursal__c, AM_Direccion__c, PersonMobilePhone, 
                           MC_Correo_electronico_Empresa__c, PersonEmail, AM_Ocupacion_pc__c, AM_Ciudad__r.ID_UNOEE__c, AM_Nivel_Socioeconomico__c, AM_Estado_civil__pc
                           from Account where Id=: objSFoppty.Facturar_a_nombre_de__c Limit 1];
            
            if(validarVINduplicado( objSFoppty) > 0) {
                return system.label.LabelVINduplicado;
            }
            if(objSFoppty.OpportunityLineItems.size() != 1) {
                return 'Error, verifica que haya solamente un producto en la oportunidad antes de hacer el envio.';
            }
                
            if(objSFoppty.Se_creo_pedido_en_UNOEE__c == true) {
                return 'Error, este pedido ya se creo en UNOEE.';
            }
            
            if(objSFoppty.Order_Generated__c == false) {
                return 'Error, debe crear un pedido en Salesforce con el boton "Crear Nuevo Pedido" antes de hacer el envio a UNOEE.';
            }
            
            if(objSFoppty.Vitrina_de_despacho__c == null) {
                return 'Error, debe tener digilenciado el campo Vitrina de despacho antes de hacer el envio a UNOEE.';
            }
            
            if(objSFoppty.Vitrina__c == null && Test.isRunningTest()==false) {
                return 'Error, debe tener digilenciado el campo Vitrina antes de hacer el envio a UNOEE.';
            }
            
            if(String.isblank(objSFoppty.Notas_de_despacho__c)) {
                return 'Error, debe tener digilenciado el campo Notas de despacho antes de hacer el envio a UNOEE.';
            }
            
            if(acc.RecordType.DeveloperName == 'AM_CUE_Persona_natural'){
                if(acc.Actividad_economica__c == null || acc.Actividad_economica__c == ''){
                    return 'Error, debe tener digilenciado el campo Actividad economica en la cuenta relacionada antes de hacer el envio a UNOEE.';
                }
                if(acc.AM_Direccion__c == null || acc.AM_Direccion__c == ''){
                    return 'Error, debe tener digilenciado el campo Dirección en la cuenta relacionada antes de hacer el envio a UNOEE.';
                }
                if(acc.AM_Ocupacion_pc__c == null || acc.AM_Ocupacion_pc__c == ''){
                    return 'Error, debe tener digilenciado el campo Ocupación en la cuenta relacionada antes de hacer el envio a UNOEE.';
                }
            }
            
            if(accFacturar.RecordType.DeveloperName == 'AM_CUE_Persona_natural'){
                if(accFacturar.Actividad_economica__c == null || accFacturar.Actividad_economica__c == ''){
                    return 'Error, debe tener digilenciado el campo Actividad economica en la cuenta relacionada antes de hacer el envio a UNOEE.';
                }
                if(accFacturar.AM_Direccion__c == null || accFacturar.AM_Direccion__c == ''){
                    return 'Error, debe tener digilenciado el campo Dirección en la cuenta relacionada antes de hacer el envio a UNOEE.';
                }
                if(accFacturar.AM_Ocupacion_pc__c == null || accFacturar.AM_Ocupacion_pc__c == ''){
                    return 'Error, debe tener digilenciado el campo Ocupación en la cuenta relacionada antes de hacer el envio a UNOEE.';
                }
            }

            if(objSFoppty.Forma_de_pago__c != null && objSFoppty.Forma_de_pago__c.contains('Retoma')){
                if(objSFoppty.Marca_retoma__c == null || objSFoppty.Marca_retoma__c == ''){
                    return 'Error, debe tener digilenciado el campo Marca retoma antes de hacer el envio a UNOEE.';
                }
                if(objSFoppty.Version_retoma__c == null || objSFoppty.Version_retoma__c == ''){
                    return 'Error, debe tener digilenciado el campo Version retoma antes de hacer el envio a UNOEE.';
                }
                if(objSFoppty.Modelo_retoma__c == null || objSFoppty.Modelo_retoma__c == ''){
                    return 'Error, debe tener digilenciado el campo Modelo retoma antes de hacer el envio a UNOEE.';
                }
            }                         
            
            if(accFacturar.Creado_en_UNOEE__c == false && accFacturar.IsPersonAccount) {
                return 'Error, debe crear la Cuenta Personal en UNOEE antes de enviar el pedido.';
            }
            
            if(objSFoppty.Tipo_de_Oportunidad__c == 'Usados') {
                if(objSFoppty.Usado_Separado__c == null){
                    return 'Error, debe tener digilenciado el campo Vehículo (Usado) antes de hacer el envio a UNOEE.';
                }
                List<Product2> pList = [Select Id, Inventario_de_Usados__c From Product2 where Id =: objSFoppty.OpportunityLineItems[0].Product2Id Limit 1];
                if(pList.Size() > 0) {
                    invList = [Select Id, Estado_Del_Vehiculo__c, Margen__c, Precio_Venta__c, Tipo_Inv_Usado__c, Costo_Total__c From Inventario_de_Usados__c Where Id =: pList[0].Inventario_de_Usados__c Limit 1];//[Select Id, Estado_Del_Vehiculo__c From Inventario_de_Usados__c Where Id =: pList[0].Inventario_de_Usados__c Limit 1];
                }
                if(invList.Size() > 0) {
                    objWS.item_utilidad = objSFoppty.Tipo_Impo_Utilidad__c;
                    if(invList[0].Margen__c < 0) {
                         if (invList[0].Precio_Venta__c != null) objWS.Precio = String.valueOf(invList[0].Precio_Venta__c); 
                    } else {
                        if (invList[0].Costo_Total__c != null) objWS.Precio = String.valueOf(invList[0].Costo_Total__c);            
                    }
                    if (objSFoppty.OpportunityLineItems[0].Descuento_valor__c != null) {
                        if(objSFoppty.Tipo_Impo_Utilidad__c == '73282'){
                            objSFoppty.OpportunityLineItems[0].Descuento_valor__c = (objSFoppty.OpportunityLineItems[0].Descuento_valor__c / Decimal.valueOf(Label.Etiqueta1_27));
                            
                            Decimal toround = objSFoppty.OpportunityLineItems[0].Descuento_valor__c;
                            Decimal rounded = toround.setScale(2);
                            objWS.valor_descuento = String.valueOf(rounded);
                        } else {
                            objSFoppty.OpportunityLineItems[0].Descuento_valor__c = (objSFoppty.OpportunityLineItems[0].Descuento_valor__c / Decimal.valueOf(Label.Etiqueta1_19));
                            Decimal toround = objSFoppty.OpportunityLineItems[0].Descuento_valor__c;
                            Decimal rounded = toround.setScale(2);
                            objWS.valor_descuento = String.valueOf(rounded);
                        }
                    } 
                    if (objSFoppty.Valor_Utilidad__c != null) objWS.valor_utilidad = String.valueOf(objSFoppty.Valor_Utilidad__c);
                    if (invList[0].Estado_Del_Vehiculo__c !='DISPONIBLE' && invList[0].Estado_Del_Vehiculo__c !='PENDIENTE POR INGRESAR' && invList[0].Estado_Del_Vehiculo__c !='FACTURADO'){
                        return 'Advertencia, este producto de usados ya ha sido separado.';
                    }else{
                        invList[0].Estado_Del_Vehiculo__c = 'SEPARADO';    
                    }
                    
                    if(invList[0].Tipo_Inv_Usado__c != 'Propio') {
                        objSFoppty.StageName = 'P4';
                        update objSFoppty;
                        invList[0].Oportunidad__c = objSFoppty.Id;
                        update invList[0];
                        return '¡Separación correcta! No se envía el pedido a UNO-E porque no es inventario propio';//return 'Advertencia, este pedido no se va a enviar a UNOEE porque el tipo de inventario usados es distino a "Propio".';
                    }
                }
            } else {
                if(objSFoppty.VIN__c == null || objSFoppty.VIN__c == ''){
                    return 'Error, debe tener digilenciado el campo VIN antes de hacer el envio a UNOEE.';
                }
                if(objSFoppty.Vehiculo__c == null && objSFoppty.Vehiculo__c == ''){
                    return 'Error, debe tener digilenciado el campo Vehículo (Nuevos/Renting) antes de hacer el envio a UNOEE.';
                }
            }
            
            User usr = [Select Id, Codigo_ERP__c from User where Id =: objSFoppty.OwnerId Limit 1];
            
            Concesionario__c con = [Select Id, Bodega_Nuevo__c, Codigo_concesionario__c from Concesionario__c where Id =: objSFoppty.Vitrina__c Limit 1];
             
            objWS.NIT = accFacturar.AM_Numero_de_documento__c;
            objWS.Referencia = objSFoppty.Referencia_E_A_C__c;
            objWS.Oc = objsFoppty.Numero_de_Oportunidad__c;
            if(accFacturar.Sucursal__c != null) {
                objWS.ID_SUCURSAL = accFacturar.Sucursal__c.left(3);
            } else {
                objWS.ID_SUCURSAL = '001';
            }
            if(accFacturar.Sucursal__c != null) {
                objWS.SUCURSAL_REMISION = accFacturar.Sucursal__c.left(3);
            } else {
                objWS.SUCURSAL_REMISION = '001';
            }
            objWS.Notas = objsFoppty.Numero_de_Oportunidad__c + ' ' + objsFoppty.Notas_de_despacho__c;
            objWS.NIT_REMISION = accFacturar.AM_Numero_de_documento__c;
            String hoy = String.valueOf(date.today());
            String fecha = hoy.left(4) + '/' + hoy.left(7).right(2) + '/' + hoy.left(10).right(2);
            objWS.FECHA = fecha;
            objWS.NUM_DOCTO_REFERENCIA = objSFoppty.Numero_de_Oportunidad__c;
            objWS.VENDEDOR = usr.Codigo_ERP__c;
            if (accFacturar.IsPersonAccount) {
                objWS.EMAIL = accFacturar.PersonEmail;
                objWS.TELEFONO = accFacturar.PersonMobilePhone;
            } else {
                objWS.EMAIL = accFacturar.MC_Correo_electronico_Empresa__c;
                objWS.TELEFONO = accFacturar.Phone;
            }            
            objWS.ID_CIUDAD = accFacturar.AM_Ciudad__r.ID_UNOEE__c;
            if (accFacturar.AM_Direccion__c != null) objWS.DIRECCION1 = accFacturar.AM_Direccion__c.left(40);
            
            if(objSFoppty.Tipo_de_Oportunidad__c != 'Usados') {
                objWS.ID_BODEGA = String.valueOf(con.Bodega_Nuevo__c);
                objWS.REFERENCIA_ITEM = objSFoppty.VIN__c;
                objWS.item_utilidad = '';
                objWS.valor_utilidad = '0';
                if (objSFoppty.OpportunityLineItems[0].Precio_de_lista_antes_de_impuesto__c != null) objWS.Precio = String.valueOf(objSFoppty.OpportunityLineItems[0].Precio_de_lista_antes_de_impuesto__c);            
                if (objSFoppty.OpportunityLineItems[0].Descuento_valor__c != null) {
                    if(objSFoppty.OpportunityLineItems[0].Name.Contains('HEV') ) {
                        objWS.valor_descuento = String.valueOf(objSFoppty.OpportunityLineItems[0].Descuento_valor__c  / Decimal.valueOf(Label.Etiqueta1_13));
                        Decimal toround = Decimal.valueOf(objWS.valor_descuento);
                        Decimal rounded = toround.setScale(2);
                        objWS.valor_descuento = String.valueOf(rounded);
                    } else if(objSFoppty.OpportunityLineItems[0].Name.Contains('10A') ) {
                        objWS.valor_descuento = String.valueOf(objSFoppty.OpportunityLineItems[0].Descuento_valor__c / Decimal.valueOf(Label.Etiqueta1_35));
                        Decimal toround = Decimal.valueOf(objWS.valor_descuento);
                        Decimal rounded = toround.setScale(2);
                        objWS.valor_descuento = String.valueOf(rounded);
                    }
                    else {
                        objWS.valor_descuento = String.valueOf(objSFoppty.OpportunityLineItems[0].Descuento_valor__c / Decimal.valueOf(Label.Etiqueta1_27));
                        Decimal toround = Decimal.valueOf(objWS.valor_descuento);
                        Decimal rounded = toround.setScale(2);
                        objWS.valor_descuento = String.valueOf(rounded);
                    }
                }
            } else {
                objWS.ID_BODEGA = objSFoppty.Bodega_Usados__c;
                objWS.REFERENCIA_ITEM = objsFoppty.OpportunityLineItems[0].Product2.Placa__c;
            }
            objWS.ID_BODEGA = con.Codigo_concesionario__c + objWS.ID_BODEGA;
            
            
            FanalcaComSfcsalesorder2unoe.HTTPS_Port enviarWS = new FanalcaComSfcsalesorder2unoe.HTTPS_Port();
            
            
            Blob headerValue = Blob.valueOf(Label.FanalcaWSUser+':'+Label.FanalcaWSPassword);string authorizationHeader ='Basic '+EncodingUtil.base64Encode(headerValue);
            enviarWS.inputHttpHeaders_x = new Map<String, String>();enviarWS.inputHttpHeaders_x.put('Authorization',authorizationHeader); 
            enviarWS.inputHttpHeaders_x.put('Content-Type', 'application/soap+xml');
            enviarWS.timeout_x = 8000;
            
            String respuesta = enviarWS.SendToUNOEE(objWS);
            
            if (respuesta == '200') {
                
                if(invList.size()>0){
                    update invList;
                }                
                objSFoppty.Se_creo_pedido_en_UNOEE__c = true;
                objSFoppty.Fecha_de_envio_a_UNOEE__c = date.today();
                objSFoppty.StageName = 'P4';
                update objSFoppty;
                
                Log__c log = new Log__c();
                body = JSON.serialize(objWS);
                log.body__c = body;
                log.Web_Service__c = 'Crear Pedido en UNOEE';
                insert log;
                
                return 'Pedido enviado a UNOEE exitosamente!';
            } else {
                return 'Error: Hubo un error al crear el Pedido en UNOEE, por favor contacta a tu administrador.';
            }
            
        }
        
        catch(Exception ex){
            system.debug('Error: ' + ex.getMessage());
            Log__c log = new Log__c();
            body = JSON.serialize(objWS);
            log.body__c = body;
            log.Web_Service__c = 'Crear Pedido en UNOEE';
            insert log;
            return 'Error: ' + ex.getMessage() + ex.getLineNumber();
        }
        
    }
}