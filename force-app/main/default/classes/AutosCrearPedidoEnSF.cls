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
*********************************************************************************************************/
public class AutosCrearPedidoEnSF {
	@AuraEnabled
    public static String EnviarPedido(Id oppId){
        
        try{
            
            Opportunity objSFoppty = [select Account.RecordType.IsPersonType, Id, Fecha_de_determinacion_del_precio__c, Amount, Tipo_de_Pago__c, CloseDate, Pricebook2Id,
                                      Destinatario_Factura__c, Account.RecordType.DeveloperName, AM_Cotizacion_VTEK__c, AM_Numero_de_radicacion__c, Destinatario_Mercanc_a__c, Pagador__c, Titular_prendario__c, Tipo_de_Oportunidad__c, Se_creo_pedido_en_UNOEE__c,
                                      Numero_de_Oportunidad__c, AccountId, Account.BillingStreet, Account.BillingState, Account.BillingCity, Bodega_Usados__c,
                                      OwnerId, Fecha_de_validez__c, ID_de_pedido_ERP__c, Account.BillingPostalCode, Account.BillingCountry,
                                      Account.ShippingStreet, Propietario_vehiculo__c, Account.AM_Direccion__c, Account.AM_Ocupacion_pc__c, Account.Actividad_economica__c, Account.ShippingState, Account.ShippingCity, Account.ShippingPostalCode, Motivo_de_Oportunidad_Vendida__c,
                                      Cu_l_marca_averigu_durante_la_compra__c, Averigu_sobre_otras_marcas__c, Que_otras_marcas_consideraron__c, Concesionario2__c, Agencia2__c,
                                      Account.ShippingCountry, Order_Generated__c, (Select Id, OpportunityId, ProductCode, PriceBookEntryId, Valor_soat__c, Valor_matrcula__c, Soat__c,
                                                                Cuota_Inicial__c, Valor_seguro_robo__c, Descuento_valor__c, Quantity, UnitPrice, Anticipo__c, Avaluado_por__c,
                                                                Casco__c, Cheque_posfechado_avalado__c, Contrato__c, Accesorios__c, Cuota_mensual__c, Definici_n_de_aprobaciones__c,
                                                                DescARD__c, DescAuto__c, Descuento_aplicado_antes_de_impuesto__c, DescValARD__c, DescValAuto__c, 
                                                                Desembolso_entidad_financiera__c, FinancieraPlan__c, Impoconsumo__c, Iva__c, Otros_gastos__c, Plazo_en_meses__c,
                                                                Precio_de_lista_antes_de_impuesto__c, Recompra__c, Saldo_a_financiar__c, Saldo_contra_entrega__c, Sitio_de_matrcula__c,
                                                                Tipo_Carrocera__c, Valor_Total_Vehculo__c, Valor_Vehculo__c, Total__c, Subtotal_moto__c, Valor_ARD__c
                                                                from OpportunityLineItems)
                                      from Opportunity where Id =: oppId Limit 1];

            
            Account acc = [select IsPersonAccount, Creado_en_UNOEE__c, Id, AM_Numero_de_documento__c, Sucursal__c, AM_Direccion__c, PersonMobilePhone, 
                           MC_Correo_electronico_Empresa__c, PersonEmail, AM_Ciudad__r.ID_UNOEE__c, AM_Nivel_Socioeconomico__c, AM_Estado_civil__pc
                           from Account where Id=: objSFoppty.AccountId Limit 1];
            
            User usr = [Select Id, Codigo_ERP__c from User where Id =: objSFoppty.OwnerId Limit 1];
            
            if(acc.Creado_en_UNOEE__c == false && acc.IsPersonAccount) {
                return 'Error, debe crear la Cuenta en UNOEE antes de crear el pedido en Salesforce.';
            }

            /*if(acc.IsPersonAccount == true && acc.AM_Nivel_Socioeconomico__c == null || acc.AM_Nivel_Socioeconomico__c == '') {
                return 'Error, la cuenta relacionada a esta Oportunidad no tiene el campo Nivel Socioeconomico completado.';
            }
            
            if(acc.IsPersonAccount == true && acc.AM_Estado_civil__pc == null || acc.AM_Estado_civil__pc == '') {
                return 'Error, la cuenta relacionada a esta Oportunidad no tiene el campo Estado Civil completado.';
            } */
               
            if(objSFoppty.Propietario_vehiculo__c == null) {
                return 'Error, debe tener digilenciado el campo Propietario Vehículo antes de crear el pedido en Salesforce.';
            }
             
            if(objSFoppty.Tipo_de_Oportunidad__c == 'Renting' && objSFoppty.AM_Cotizacion_VTEK__c == null || objSFoppty.AM_Cotizacion_VTEK__c == '') {
                return 'Error, debe tener digilenciado el campo Cotizacion VTEK antes de crear el pedido en Salesforce.';
            }
            
            if(objSFoppty.Tipo_de_Oportunidad__c == 'Renting' && objSFoppty.AM_Numero_de_radicacion__c  == null || objSFoppty.AM_Numero_de_radicacion__c  == '') {
                return 'Error, debe tener digilenciado el campo Número de Radicación antes de crear el pedido en Salesforce.';
            }
            
            if(objSFoppty.OpportunityLineItems.size() == 0 ) {
                return 'Error, verifica de que exista una cotización sincronizada a la oportunidad.';
            }
            
            if(objSFoppty.OwnerId == null) {
                return 'Error, la Oportunidad debe tener un Propietario antes de crear el pedido en Salesforce.';
            }
            
            if(objSFoppty.Account.RecordType.DeveloperName == 'AM_CUE_Persona_natural'){
                if(objSFoppty.Account.Actividad_economica__c == null || objSFoppty.Account.Actividad_economica__c == ''){
                    return 'Error, debe tener digilenciado el campo Actividad economica en la cuenta relacionada antes de crear el pedido en Salesforce.';
                }
                if(objSFoppty.Account.AM_Direccion__c == null || objSFoppty.Account.AM_Direccion__c == ''){
                    return 'Error, debe tener digilenciado el campo Dirección en la cuenta relacionada antes de crear el pedido en Salesforce.';
                }
                if(objSFoppty.Account.AM_Ocupacion_pc__c == null || objSFoppty.Account.AM_Ocupacion_pc__c == ''){
                    return 'Error, debe tener digilenciado el campo Ocupación en la cuenta relacionada antes de crear el pedido en Salesforce.';
                }
            }
            
            if (objSFoppty.Order_Generated__c == false) {
                
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
                objSFord.Numero_del_pedido__c = objSFoppty.Numero_de_Oportunidad__c;
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
                
                objSFoppty.Order_Generated__c = true;
                update objSFoppty;
                
                return 'Pedido creado en Salesforce exitosamente!';
            } else {
                return 'Error: Este pedido ya se ha creado en Salesforce.';
            }
            
        }
        
        catch(Exception ex){
            system.debug('Error: ' + ex.getMessage());
            return 'Error: ' + ex.getMessage();
        }
        
    }
}