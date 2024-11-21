/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Consume of Web Service class to create an Order in SAP.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     28/Nov/2020     Juan Ansaldi            Class definition.
* @version  1.1                     Juan Ansaldi                    
*********************************************************************************************************/
public class MotosCreacionPedidoEnSAP {
    @AuraEnabled
    public static String CrearPedido(Id oppId){
        String body1;
        String body2;
        List<FanalcaCreacionPedidosSAP.Position_element> lstPosition = new List<FanalcaCreacionPedidosSAP.Position_element>();
        List<FanalcaCreacionPedidosSAP.Header_element> lstHeader = new List<FanalcaCreacionPedidosSAP.Header_element>();
        Account codigoSAPcliente;
        Account codigoSAPpagador;
        Account codigoSAPfactura;
        Account codigoSAPmercancia;
        Account codigoSAPprendario;    
        
        list<Account> accountsUpdate = new list<Account>();
        Quote objQuote;
        
        try{                                        
            Opportunity objSFoppty = [select Account.RecordType.IsPersonType, Id, Fecha_de_determinacion_del_precio__c, Amount, Tipo_de_Pago__c, CloseDate, Pricebook2Id,
                                      Destinatario_Factura__c, Destinatario_Mercanc_a__c, Pagador__c, Titular_prendario__c,
                                      Numero_de_Oportunidad__c, AccountId, Account.BillingStreet, Account.BillingState, Account.BillingCity,
                                      OwnerId, Fecha_de_validez__c, ID_de_pedido_ERP__c, Account.BillingPostalCode, Account.BillingCountry,
                                      Account.ShippingStreet, Account.ShippingState, Account.ShippingCity, Account.ShippingPostalCode, Motivo_de_Oportunidad_Vendida__c,
                                      Cu_l_marca_averigu_durante_la_compra__c, Averigu_sobre_otras_marcas__c, Que_otras_marcas_consideraron__c, Concesionario2__c, Agencia2__c,
                                      Account.ShippingCountry,(Select Id, OpportunityId, ProductCode, PriceBookEntryId, Valor_soat__c, Valor_matrcula__c, Soat__c,
                                                                Cuota_Inicial__c, Valor_seguro_robo__c, Descuento_valor__c, Quantity, UnitPrice, Anticipo__c, Avaluado_por__c,
                                                                Casco__c, Cheque_posfechado_avalado__c, Contrato__c, Accesorios__c, Cuota_mensual__c, Definici_n_de_aprobaciones__c,
                                                                DescARD__c, DescAuto__c, Descuento_aplicado_antes_de_impuesto__c, DescValARD__c, DescValAuto__c, 
                                                                Desembolso_entidad_financiera__c, FinancieraPlan__c, Impoconsumo__c, Iva__c, Otros_gastos__c, Plazo_en_meses__c,
                                                                Precio_de_lista_antes_de_impuesto__c, Recompra__c, Saldo_a_financiar__c, Saldo_contra_entrega__c, Sitio_de_matrcula__c,
                                                                Tipo_Carrocera__c, Valor_Total_Vehculo__c, Valor_Vehculo__c, Total__c, Subtotal__c, Valor_ARD__c
                                                                from OpportunityLineItems)
                                      from Opportunity where Id =: oppId Limit 1];
            
                List<Quote> lstQuote = [select Id, Realizo_consulta_de_precios__c, OpportunityId from Quote where OpportunityId =: objSFoppty.Id AND IsSyncing = true];
                if(lstQuote.size() == 0 ) {
                    return 'Error, verifica de que exista una cotización sincronizada a la oportunidad.';
                } else {
                    objQuote = lstQuote[0];
                }
            
            
            //Validaciones antes de hacer callouts
            if (objSFoppty.Account.RecordType.IsPersonType && objSFoppty.Motivo_de_Oportunidad_Vendida__c == null) {
                return 'Error, el Motivo de Oportunidad vendida no puede ser nulo.';
            }

            if (objSFoppty.Account.RecordType.IsPersonType){
                if (objSFoppty.Averigu_sobre_otras_marcas__c == null) {
                    return 'Error, el campo ¿Averiguó sobre otras marcas? no puede ser nulo.';
                } else if(objSFoppty.Averigu_sobre_otras_marcas__c == 'Si') {
                    if (objSFoppty.Cu_l_marca_averigu_durante_la_compra__c == null) {
                        return 'Error, el campo ¿Cuál marca averiguó durante la compra? no puede ser nulo.';
                    }
                }    
            }
            
            
            User objSFuser =  [select Id, Codigo_ERP__c from User where Id =: objSFoppty.OwnerId];
            
            if(objSFoppty.OpportunityLineItems.size() != 1) {
                return 'Error, verifica que haya solamente un producto en la oportunidad antes de hacer el envio.';
            }
            
            date fechaHoy = date.today();            
            if(objSFoppty.Fecha_de_validez__c < fechaHoy) {
                return 'Error, la fecha de validez de la oportunidad no puede ser menor al día de hoy.';
            }
            
            if(objSFoppty.ID_de_pedido_ERP__c != null) {
                 return system.label.GTAO_msmOrderInSAP;//'Error, este pedido ya se envió a SAP.';
            }
            
            if(objQuote.Realizo_consulta_de_precios__c == false) {
                return 'Error, debe haber hecho la consulta de precios en la cotización previo a enviar el pedido a SAP.';
            }
            
            if (objSFoppty.AccountId == null) {
                return 'Error, verifica de que exista un cliente en el campo Nombre de la cuenta.';
            } 
            
            if (objSFoppty.Pagador__c == null) {
                return 'Error, verifica de que exista un cliente en el campo Pagador.';
            } 
            
            if (objSFoppty.Destinatario_Factura__c == null) {
                return 'Error, verifica de que exista un cliente en el campo Destinatario Factura.';
            }
            
            if (objSFoppty.Destinatario_Mercanc_a__c == null) {
                return 'Error, verifica de que exista un cliente en el campo Destinatario Mercancia.';
            } 
            
            if (objSFoppty.Titular_prendario__c == null) {
                return 'Error, verifica de que exista un cliente en el campo Titular Prendario.';
            }
            //Fin de validaciones
            
            
            //Inicio de Callouts de Cuentas, hasta 5 si es necesario            
            
            codigoSAPcliente = [select Id, Codigo_ERP__c from Account where Id =: objSFoppty.AccountId];
            if (codigoSAPcliente.Codigo_ERP__c == null) {
                String respuestaCrearPrincipal = MotosSendAccountToSAP.SendAccountOrder(codigoSAPcliente.Id, MotosSendAccountToSAP.Crear);
                if (respuestaCrearPrincipal.contains('Error')) return 'Error, Hubo un error al Crear la Cuenta Principal en SAP: ' + respuestaCrearPrincipal;
                if (respuestaCrearPrincipal.isNumeric()) {
                    codigoSAPcliente.Codigo_ERP__c = respuestaCrearPrincipal;
                    accountsUpdate.add(codigoSAPcliente);
                }
            }
            

            if (objSFoppty.Pagador__c != codigoSAPcliente.Id){
                codigoSAPpagador = [select Id, Codigo_ERP__c,Lista_Restrictiva__c from Account where Id =: objSFoppty.Pagador__c];
                if (codigoSAPpagador.Lista_Restrictiva__c==null) return 'Error, El cliente Pagador no tiene marcado el campo Lista Restrictiva!';
                if (codigoSAPpagador.Codigo_ERP__c == null) {
                    String respuestaCrearPagador = MotosSendAccountToSAP.SendAccountOrder(codigoSAPpagador.Id, MotosSendAccountToSAP.Crear);
                    if (respuestaCrearPagador.contains('Error')) {
                        if (accountsUpdate.size()>0) update accountsUpdate;
                        return 'Error, Hubo un error al Crear el Pagador en SAP: ' + respuestaCrearPagador;
                    }
                    if (respuestaCrearPagador.isNumeric()) {
                        codigoSAPpagador.Codigo_ERP__c = respuestaCrearPagador;
                        accountsUpdate.add(codigoSAPpagador);
                    }
                }
            }
                
             
            
            if (objSFoppty.Destinatario_Factura__c != codigoSAPcliente.Id && objSFoppty.Destinatario_Factura__c != objSFoppty.Pagador__c){
                codigoSAPfactura = [select Id, Codigo_ERP__c,Lista_Restrictiva__c from Account where Id =: objSFoppty.Destinatario_Factura__c];
                if (codigoSAPfactura.Lista_Restrictiva__c==null) return 'Error, El cliente Destinatario de Factura no tiene marcado el campo Lista Restrictiva!';
                if (codigoSAPfactura.Codigo_ERP__c == null) {
                    String respuestaCrearDestinatarioFactura = MotosSendAccountToSAP.SendAccountOrder(codigoSAPfactura.Id, MotosSendAccountToSAP.Crear);
                    if (respuestaCrearDestinatarioFactura.contains('Error')) {
                        if (accountsUpdate.size()>0) update accountsUpdate;
                        return 'Error, Hubo un error al Crear el Destinatario de Factura en SAP: ' + respuestaCrearDestinatarioFactura;
                    }
                    if (respuestaCrearDestinatarioFactura.isNumeric()) {
                        codigoSAPfactura.Codigo_ERP__c = respuestaCrearDestinatarioFactura;
                        accountsUpdate.add(codigoSAPfactura);
                    }
                }
            }
            
                        
            if (objSFoppty.Destinatario_Mercanc_a__c != codigoSAPcliente.Id && objSFoppty.Destinatario_Mercanc_a__c != objSFoppty.Pagador__c && objSFoppty.Destinatario_Mercanc_a__c != objSFoppty.Destinatario_Factura__c){
                codigoSAPmercancia = [select Id, Codigo_ERP__c,Lista_Restrictiva__c from Account where Id =: objSFoppty.Destinatario_Mercanc_a__c];
                if (codigoSAPmercancia.Lista_Restrictiva__c==null) return 'Error, El cliente Destinatario de Mercancía no tiene marcado el campo Lista Restrictiva!';
                if (codigoSAPmercancia.Codigo_ERP__c == null) {
                    String respuestaCrearDestinatarioMercancia = MotosSendAccountToSAP.SendAccountOrder(codigoSAPmercancia.Id, MotosSendAccountToSAP.Crear);
                    if (respuestaCrearDestinatarioMercancia.contains('Error')) {
                        if (accountsUpdate.size()>0) update accountsUpdate;
                        return 'Error, Hubo un error al Crear el Destinatario de Mercancía en SAP: ' + respuestaCrearDestinatarioMercancia;
                    }
                    if (respuestaCrearDestinatarioMercancia.isNumeric()) {
                        codigoSAPmercancia.Codigo_ERP__c = respuestaCrearDestinatarioMercancia;
                        accountsUpdate.add(codigoSAPmercancia);
                    }
                }
            }
            
             
            if (objSFoppty.Titular_prendario__c != codigoSAPcliente.Id && objSFoppty.Titular_prendario__c != objSFoppty.Pagador__c && objSFoppty.Titular_prendario__c != objSFoppty.Destinatario_Factura__c && objSFoppty.Titular_prendario__c != objSFoppty.Destinatario_Mercanc_a__c){
                codigoSAPprendario = [select Id, Codigo_ERP__c,Lista_Restrictiva__c from Account where Id =: objSFoppty.Titular_prendario__c];
                if (codigoSAPprendario.Lista_Restrictiva__c==null) return 'Error, El cliente Titular no tiene marcado el campo Lista Restrictiva!';
                if (codigoSAPprendario.Codigo_ERP__c == null) {
                    String respuestaCrearTitular = MotosSendAccountToSAP.SendAccountOrder(codigoSAPprendario.Id, MotosSendAccountToSAP.Crear);
                    if (respuestaCrearTitular.contains('Error')) {
                        if (accountsUpdate.size()>0) update accountsUpdate;
                        return 'Error, Hubo un error al Crear el Titular en SAP: ' + respuestaCrearTitular;
                    }
                    if (respuestaCrearTitular.isNumeric()) {
                        codigoSAPprendario.Codigo_ERP__c = respuestaCrearTitular;
                        accountsUpdate.add(codigoSAPprendario);
                    }
                }
            }
            
            if (codigoSAPcliente.Id == objSFoppty.Pagador__c) codigoSAPPagador = codigoSAPcliente;
            if (codigoSAPcliente.Id == objSFoppty.Destinatario_Factura__c) codigoSAPfactura = codigoSAPcliente;
            if (codigoSAPcliente.Id == objSFoppty.Destinatario_Mercanc_a__c) codigoSAPmercancia = codigoSAPcliente;
            if (codigoSAPcliente.Id == objSFoppty.Titular_prendario__c) codigoSAPprendario = codigoSAPcliente;
            
            //Si el pagador no es igual a la cuenta principal entonces ya tiene un valor, al hacerse un soql para él
            
            if (codigoSAPfactura == null &&  objSFoppty.Pagador__c == objSFoppty.Destinatario_Factura__c) codigoSAPfactura = codigoSAPPagador; //si destinatario factura no tiene valor es porque no es igual a cliente principal pero sí a pagador, y pagador es diferente del cliente principal
            
            if (codigoSAPmercancia == null &&  objSFoppty.Destinatario_Mercanc_a__c == objSFoppty.Pagador__c) codigoSAPmercancia = codigoSAPPagador;
            if (codigoSAPmercancia == null &&  objSFoppty.Destinatario_Mercanc_a__c == objSFoppty.Destinatario_Factura__c) codigoSAPmercancia = codigoSAPfactura;
            
            if (codigoSAPprendario == null &&  objSFoppty.Titular_prendario__c == objSFoppty.Pagador__c) codigoSAPprendario = codigoSAPPagador;
            if (codigoSAPprendario == null &&  objSFoppty.Titular_prendario__c == objSFoppty.Destinatario_Factura__c) codigoSAPprendario = codigoSAPfactura;
            if (codigoSAPprendario == null &&  objSFoppty.Titular_prendario__c == objSFoppty.Destinatario_Mercanc_a__c) codigoSAPprendario = codigoSAPmercancia;
            
            FanalcaCreacionPedidosSAP.Position_element objWSPosition = new FanalcaCreacionPedidosSAP.Position_element();
            objWSPosition.PERNR1 = codigoSAPpagador.codigo_ERP__c; 
            objWSPosition.PERNR1_TXT = codigoSAPpagador.codigo_ERP__c;
            objWSPosition.PERNR2 = codigoSAPprendario.Codigo_ERP__c;
            objWSPosition.PERNR2_TXT = codigoSAPprendario.Codigo_ERP__c;
            objWSPosition.VKORG2 = objSFoppty.Concesionario2__c;
            objWSPosition.VKORG2_TXT = objSFoppty.Concesionario2__c;
            objWSPosition.MATNR = objSFoppty.OpportunityLineItems[0].ProductCode;
            if (objSFoppty.OpportunityLineItems[0].Quantity != null) {
                objWSPosition.KWMENG = String.valueOf(objSFoppty.OpportunityLineItems[0].Quantity);
            }else
            {
                objWSPosition.KWMENG = '1';
            }
            if (objSFoppty.OpportunityLineItems[0].UnitPrice != null) {
                objWSPosition.NETWR = String.valueOf(objSFoppty.OpportunityLineItems[0].UnitPrice);
            }
            lstPosition.add(objWSPosition);
            FanalcaCreacionPedidosSAP.Header_element objWSHeader = new FanalcaCreacionPedidosSAP.Header_element();
            objWSHeader.KUNNR = codigoSAPcliente.Codigo_ERP__c; 
            objWSHeader.BSTKD = objSFoppty.Numero_de_Oportunidad__c; 
            objWSHeader.AUART = Label.Clase_de_documento;
            objWSHeader.VKORG = objSFoppty.Concesionario2__c;
            objWSHeader.VTWEG = Label.Canal;
            objWSHeader.SPART = Label.Sector;
            objWSHeader.VKBUR = objSFoppty.Agencia2__c;
            if (objSFoppty.Fecha_de_determinacion_del_precio__c != null) {
                date fecha = objSFoppty.Fecha_de_determinacion_del_precio__c;
                String fechaString = String.valueOf(fecha);
                objWSHeader.BNDDT = fechaString.left(10).right(2) + '.' + fechaString.left(7).right(2) + '.' + fechaString.left(4);
            }
            if (objSFoppty.Fecha_de_validez__c != null) {
                date fecha = objSFoppty.Fecha_de_validez__c; 
                String fechaString = String.valueOf(fecha);
                objWSHeader.ANGDT = fechaString.left(10).right(2) + '.' + fechaString.left(7).right(2) + '.' + fechaString.left(4);
            }
            objWSHeader.ABRVW = objSFoppty.Tipo_de_Pago__c.left(3).right(1);
            objWSHeader.NETWR_D = Label.Procedimiento_de_determinaci_n_de_precios; 
            objWSHeader.KUNNR2 = codigoSAPcliente.Codigo_ERP__c; 
            objWSHeader.KUNNR2_TXT = codigoSAPcliente.Codigo_ERP__c; 
            objWSHeader.PERNR = objSFuser.Codigo_ERP__c; 
            objWSHeader.PERNR_TXT = objSFuser.Codigo_ERP__c;
            objWSHeader.VKBURO = objSFoppty.Agencia2__c;
            objWSHeader.VKBURO_TXT = objSFoppty.Agencia2__c; 
            objWSHeader.KUNAG = codigoSAPfactura.Codigo_ERP__c; 
            objWSHeader.KUNAG_TXT = codigoSAPfactura.Codigo_ERP__c;
            objWSHeader.KUNNG = codigoSAPmercancia.Codigo_ERP__c; 
            objWSHeader.KUNNG_TXT = codigoSAPmercancia.Codigo_ERP__c;
            objWSHeader.VSOAT = String.valueOf(objSFoppty.OpportunityLineItems[0].Soat__c);
            if (objSFoppty.OpportunityLineItems[0].Valor_matrcula__c != null) {
                objWSHeader.VMATRI = String.valueOf(objSFoppty.OpportunityLineItems[0].Valor_matrcula__c); 
            }
            if (objSFoppty.OpportunityLineItems[0].Cuota_Inicial__c != null) {
                objWSHeader.VCINIC = String.valueOf(objSFoppty.OpportunityLineItems[0].Cuota_Inicial__c);
            }
            if (objSFoppty.OpportunityLineItems[0].Valor_seguro_robo__c > 0) {
                objWSHeader.VSEGR = '100';
            } else {
                objWSHeader.VSEGR = '0';
            }
            if (objSFoppty.OpportunityLineItems[0].Descuento_valor__c != null) {
                objWSHeader.VDESC = String.valueOf(objSFoppty.OpportunityLineItems[0].Descuento_valor__c);
            }
            lstHeader.add(objWSHeader);
            
           //Iniciar el envío
           FanalcaCreacionPedidosSAP.HTTPS_Port enviarWS = new FanalcaCreacionPedidosSAP.HTTPS_Port();
           FanalcaCreacionPedidosSAP.DT_SALES_ORDER_CR_MO objWS = new FanalcaCreacionPedidosSAP.DT_SALES_ORDER_CR_MO();
            
            Blob headerValue = Blob.valueOf('WSUSER'+':'+'beta1234');
            string authorizationHeader ='Basic '+EncodingUtil.base64Encode(headerValue);
            enviarWS.inputHttpHeaders_x = new Map<String, String>();
            enviarWS.inputHttpHeaders_x.put('Authorization',authorizationHeader); 
            enviarWS.inputHttpHeaders_x.put('Content-Type', 'application/soap+xml');
            enviarWS.timeout_x = 8000;
            
           FanalcaCreacionPedidosSAP.DT_RESPONSE_SALES_ORDER respuesta = enviarWS.CREATE(lstHeader, lstPosition);
            if(accountsUpdate.size() > 0) update accountsUpdate;
          //AO 12/11/2021 This value VBELN is always empty because the WS now going to works in an asincronic way   if (respuesta.VBELN != null && respuesta.VBELN.isNumeric() && Long.valueOf(respuesta.VBELN)>0 ) {    
                Product2 product = [select Id, Color__c, Name, Ano_modelo__c, ProductCode from Product2 where ProductCode =: objSFoppty.OpportunityLineItems[0].ProductCode];
                Order objSFord = new Order();
                OrderItem orderProduct = new OrderItem();
                objSFord.AccountId = objSFoppty.AccountId;
                objSFord.EffectiveDate = objSFoppty.CloseDate;
                objSFord.Status = 'Draft';
                objSFord.OpportunityId = objSFoppty.Id;
                objSFord.Pricebook2Id = objSFoppty.Pricebook2Id;
                objSFord.BillingStreet = objSFoppty.Account.BillingStreet;
                objSFord.BillingState = objSFoppty.Account.BillingState;
                objSFord.BillingCity = objSFoppty.Account.BillingCity;
                objSFord.BillingPostalCode = objSFoppty.Account.BillingPostalCode;
                objSFord.BillingCountry = objSFoppty.Account.BillingCountry;
                objSFord.ShippingStreet = objSFoppty.Account.ShippingStreet;
                objSFord.ShippingState = objSFoppty.Account.ShippingState;
                objSFord.ShippingCity = objSFoppty.Account.ShippingCity;
                objSFord.ShippingPostalCode = objSFoppty.Account.ShippingPostalCode;
                objSFord.ShippingCountry = objSFoppty.Account.ShippingCountry;
                //AO 12/11/2021 This value VBELN is always empty because the WS now going to works in an asincronic way  objSFord.ID_de_pedido_ERP__c = respuesta.VBELN;
                objSFord.Tipo_de_pago2__c = objSFoppty.Tipo_de_pago__c;
                objSFord.Valor__c = objSFoppty.Amount;
                objSFord.Color__c = product.Color__c;
                objSFord.Modelo__c = String.valueOf(product.Ano_modelo__c);
                objSFord.Motocicleta_o_producto__c = product.Name;
                objSFord.Comprador__c = objSFoppty.AccountId;
                objSFord.Pagador__c = objSFoppty.Pagador__c;
                objSFord.Titular_prendario__c = objSFoppty.Titular_prendario__c;
                if(objSFoppty.OpportunityLineItems[0].DescARD__c == null) {
                    objSFoppty.OpportunityLineItems[0].DescARD__c = 0;
                }
                if(objSFoppty.OpportunityLineItems[0].Descuento_aplicado_antes_de_impuesto__c == null) {
                    objSFoppty.OpportunityLineItems[0].Descuento_aplicado_antes_de_impuesto__c = 0;
                }
                objSFord.Descuento_en_precio__c = (objSFoppty.OpportunityLineItems[0].Valor_ARD__c  * -1) + objSFoppty.OpportunityLineItems[0].Descuento_aplicado_antes_de_impuesto__c;
                insert objSFord;
                orderProduct.OrderId = objSFord.Id;
                orderProduct.PriceBookEntryId = objSFoppty.OpportunityLineItems[0].PriceBookEntryId;
                orderProduct.Quantity = objSFoppty.OpportunityLineItems[0].Quantity;
                orderProduct.UnitPrice = objSFoppty.OpportunityLineItems[0].UnitPrice;
                orderProduct.Accesorios__c = objSFoppty.OpportunityLineItems[0].Accesorios__c;
                orderProduct.Avaluado_por__c = objSFoppty.OpportunityLineItems[0].Avaluado_por__c;
                orderProduct.Casco__c = objSFoppty.OpportunityLineItems[0].Casco__c;
                orderProduct.Cheque_posfechado_avalado__c = objSFoppty.OpportunityLineItems[0].Cheque_posfechado_avalado__c;
                orderProduct.Contrato__c = objSFoppty.OpportunityLineItems[0].Contrato__c;
                orderProduct.Cuota_inicial__c = objSFoppty.OpportunityLineItems[0].Cuota_inicial__c;
                orderProduct.Cuota_mensual__c = objSFoppty.OpportunityLineItems[0].Cuota_mensual__c;
                orderProduct.Definici_n_de_aprobaciones__c = objSFoppty.OpportunityLineItems[0].Definici_n_de_aprobaciones__c;
                orderProduct.DescARD__c = objSFoppty.OpportunityLineItems[0].DescARD__c;
                orderProduct.DescAuto__c = objSFoppty.OpportunityLineItems[0].DescAuto__c;
                orderProduct.Descuento_aplicado_antes_de_impuesto__c = objSFoppty.OpportunityLineItems[0].Descuento_aplicado_antes_de_impuesto__c;
                orderProduct.DescValARD__c = objSFoppty.OpportunityLineItems[0].DescValARD__c;
                orderProduct.DescValAuto__c = objSFoppty.OpportunityLineItems[0].DescValAuto__c;
                orderProduct.Desembolso_entidad_financiera__c = objSFoppty.OpportunityLineItems[0].Desembolso_entidad_financiera__c;
                orderProduct.FinancieraPlan__c = objSFoppty.OpportunityLineItems[0].FinancieraPlan__c;
                orderProduct.Impoconsumo__c = objSFoppty.OpportunityLineItems[0].Impoconsumo__c;
                orderProduct.Iva__c = objSFoppty.OpportunityLineItems[0].Iva__c;
                orderProduct.Otros_gastos__c = objSFoppty.OpportunityLineItems[0].Otros_gastos__c;
                orderProduct.Plazo_en_meses__c = objSFoppty.OpportunityLineItems[0].Plazo_en_meses__c;
                orderProduct.Precio_de_lista_antes_de_impuesto__c = objSFoppty.OpportunityLineItems[0].Precio_de_lista_antes_de_impuesto__c;
                orderProduct.Recompra__c = objSFoppty.OpportunityLineItems[0].Recompra__c;
                orderProduct.Saldo_a_financiar__c = objSFoppty.OpportunityLineItems[0].Saldo_a_financiar__c;
                orderProduct.Saldo_contra_entrega__c = objSFoppty.OpportunityLineItems[0].Saldo_contra_entrega__c;
                orderProduct.Sitio_de_matrcula__c = objSFoppty.OpportunityLineItems[0].Sitio_de_matrcula__c;
                orderProduct.Tipo_Carrocera__c = objSFoppty.OpportunityLineItems[0].Tipo_Carrocera__c;
                orderProduct.Total__c = objSFoppty.OpportunityLineItems[0].Total__c;
                orderProduct.Descuento_valor__c = objSFoppty.OpportunityLineItems[0].Descuento_valor__c;
                orderProduct.Valor_matrcula__c = objSFoppty.OpportunityLineItems[0].Valor_matrcula__c;
                orderProduct.Valor_seguro_robo__c = objSFoppty.OpportunityLineItems[0].Valor_seguro_robo__c;
                orderProduct.Valor_Total_Vehculo__c = objSFoppty.OpportunityLineItems[0].Valor_Total_Vehculo__c;
                orderProduct.Valor_Vehculo__c = objSFoppty.OpportunityLineItems[0].Valor_Vehculo__c;
                orderProduct.Anticipo__c = objSFoppty.OpportunityLineItems[0].Anticipo__c;
                orderProduct.Valor_soat2__c = objSFoppty.OpportunityLineItems[0].Soat__c;
                insert orderProduct;
                
                objSFord.Status = 'Activated';
                update objSFord;
              //AO 12/11/2021 This value VBELN is always empty because the WS now going to works in an asincronic way    system.debug('respuesta.VBELN: ' + respuesta.VBELN);
             // AO 12/11/2021 This value VBELN is always empty because the WS now going to works in an asincronic way   //   objSFoppty.ID_de_pedido_ERP__c = respuesta.VBELN;
                objSFoppty.Order_Generated__c = true;
            	objSFoppty.GTAO_PedidoEnviadoSAP__c = true; //AO inactive next WS call
                update objSFoppty;
                
                objSFoppty.Se_creo_pedido_en_SAP__c = true;
                update objSFoppty;
                return respuesta.MSSGS + ' Id de Pedido en SAP: ';// AO 12/11/2021 This value VBELN is always empty because the WS now going to works in an asincronic way // + respuesta.VBELN;
           /* } else {
                return 'Error: ' + respuesta.MSSGS;
            }  */              
        }catch(Exception ex){
            system.debug('Error: ' + ex.getMessage() + ' Caused by: ' + ex.getCause());
            Log__c log = new Log__c();
            body1 = JSON.serialize(lstHeader);
            body2 = JSON.serialize(lstPosition);
            log.body__c = body1+' '+body2;
            log.Web_Service__c = 'Crear Pedido en SAP';
            insert log;
            return 'Error: ' + ex.getMessage() + ' Caused by: ' + ex.getCause();
        }
        
        
    }
}