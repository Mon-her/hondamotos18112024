/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Consume of Web Service class to get prices and discounts from SAP.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     02/Dic/2020     Juan Ansaldi            Class definition.
* @version  1.1     		        Juan Ansaldi                    
*********************************************************************************************************/
public class MotosConsultaPreciosDescuentos {
    @AuraEnabled
    public static String ConsultaPreciosDescuentos(Id quoteId){
        List<FanalcaConsultaPreciosDescuentos.Row_element> lstRowElement = new List<FanalcaConsultaPreciosDescuentos.Row_element>();
        try{                            
 
            List<QuoteLineItem> listQli = new List<QuoteLineItem>();
            Quote objQuote = [select Id, Tipo_de_Pago__c, OpportunityId, Concesionario__c, Concesionario__r.Codigo_concesionario__c, Realizo_consulta_de_precios__c from Quote where Id =: quoteId];
            Map<String, QuoteLineItem> productCodeMap = new Map<String, QuoteLineItem>();
            
            listQli = [Select Id, QuoteId, Product2Id, Product2.ProductCode, Valor_soat__c, Valor_matrcula__c,
                       Cuota_Inicial__c, Descuento_aplicado_antes_de_impuesto__c, Descuento_valor__c,
                       Quantity, UnitPrice, Valor_seguro_robo__c
                       from QuoteLineItem where QuoteId =: objQuote.Id]; 
            if(listQli.size() == 0) {
                return 'Error: Debe agregar un producto en la cotización antes de hacer la consulta.';
            }
            
            Opportunity opp = [Select Id, Concesionario__c, Concesionario__r.Codigo_concesionario__c, Concesionario2__c from Opportunity where Id =: objQuote.OpportunityId];
            //Concesionario__c con = [Select Id, Codigo_concesionario__c from Concesionario__c where Id =: opp.Concesionario__c];
            
            for(QuoteLineItem qli : listQli){
                productCodeMap.put(qli.Product2.ProductCode, qli);
                FanalcaConsultaPreciosDescuentos.Row_element objWSrowElement = new FanalcaConsultaPreciosDescuentos.Row_element();
                if (qli.Product2.ProductCode != null) {	
                	objWSrowElement.MATNR = qli.Product2.ProductCode;
                }
                if (objQuote.Tipo_de_Pago__c != null) {
                	objWSrowElement.ABRVW = '0' + objQuote.Tipo_de_Pago__c.left(3).right(1);
                }
                if (qli.Quantity != null) {
                    objWSrowElement.MENGE = String.valueOf(qli.Quantity);
                } 
                if (qli.UnitPrice != null) {
                    objWSrowElement.NETWR = '0';
                } else {
                    objWSrowElement.NETWR = '0';
                }
                if (qli.valor_soat__c != null) {
                    objWSrowElement.VSOAT = String.valueOf(qli.valor_soat__c);
                } else {
                    objWSrowElement.VSOAT = '0';
                }
                if (qli.cuota_inicial__c != null) {
                    objWSrowElement.VCINI = String.valueOf(qli.cuota_inicial__c);
                } else {
                    objWSrowElement.VCINI = '0';
                }
                if (qli.valor_seguro_robo__c == null || qli.valor_seguro_robo__c == 0 || qli.valor_seguro_robo__c == 0.00) {
                    objWSrowElement.VSEGR = '0';
                } else {
                    objWSrowElement.VSEGR = '100';
                }
                if (qli.valor_matrcula__c != null) {
                    objWSrowElement.VMATR = String.valueOf(qli.valor_matrcula__c);
                } else {
                    objWSrowElement.VMATR = '0';
                }
                if (qli.Descuento_valor__c != null) {
                    objWSrowElement.VZD05 = String.valueOf(qli.Descuento_valor__c);
                } else {
                    objWSrowElement.VZD05 = '0';
                }
                if (opp.Concesionario2__c != null) {
                    objWSrowElement.VKORG = String.valueOf(opp.Concesionario2__c);
                }
                lstRowElement.add(objWSrowElement);
            }
                    
           //Iniciar el envío
           FanalcaConsultaPreciosDescuentos.HTTPS_Port enviarWS = new FanalcaConsultaPreciosDescuentos.HTTPS_Port();
            
            Blob headerValue = Blob.valueOf('WSUSER'+':'+'beta1234');string authorizationHeader ='Basic '+EncodingUtil.base64Encode(headerValue);
            enviarWS.inputHttpHeaders_x = new Map<String, String>();enviarWS.inputHttpHeaders_x.put('Authorization',authorizationHeader); 
            enviarWS.inputHttpHeaders_x.put('Content-Type', 'application/soap+xml');
            enviarWS.timeout_x = 60000;

           List<FanalcaConsultaPreciosDescuentos.Row_element> respuesta = enviarWS.GET(lstRowElement);
           system.debug('Respuesta: ' + respuesta);
            
            Log__c log = new Log__c();
            String body1 = JSON.serialize(lstRowElement[0]);
            log.body__c = body1;
            log.Web_Service__c = 'Consulta de precios y descuentos';
            insert log;
            
            if(respuesta != null){
                for (FanalcaConsultaPreciosDescuentos.Row_element row : respuesta){
                    if(row.MATNR != null & productCodeMap.containsKey(row.MATNR)) {
                        QuoteLineItem qli = productCodeMap.get(row.MATNR);     
                        if (row.ZPR0 != null || row.ZPR0 != '') {
                            qli.Precio_de_lista_antes_de_impuesto__c = Integer.valueOf(row.ZPR0);
                        }
                        if (row.ZIC1 != null || row.ZIC1 != '') {
                            qli.Iva__c = Integer.valueOf(row.ZIC1);
                        }
                        if (row.ZIC2 != null || row.ZIC2 != '') {
                            qli.Impoconsumo__c = Integer.valueOf(row.ZIC2);
                        }
                        if (row.ZIC4 != null || row.ZIC4 != '') {
                            qli.Costo__c = Integer.valueOf(row.ZIC4);
                        }
                        if (row.ZSUB1 != null || row.ZSUB1 != '') {
                            qli.UnitPrice = Integer.valueOf(row.ZSUB1);
                        }
                        if (row.ZSUB2 != null || row.ZSUB2 != '') {
                            qli.Subtotal_Precio_Motocicleta__c = Integer.valueOf(row.ZSUB2);
                        }
                        if (row.ZD01 != null || row.ZD01 != '') {
                            qli.DescAuto__c = Integer.valueOf(row.ZD01);
                        }
                        if (row.ZD02 != null || row.ZD02 != '') {
                            qli.DescValAuto__c = Integer.valueOf(row.ZD02);
                        }
                        if (row.ZD03 != null || row.ZD03 != '') {
                            qli.DescARD__c = Integer.valueOf(row.ZD03);
                        }
                        if (row.ZD04 != null || row.ZD04 != '') {
                            qli.DescValARD__c = Integer.valueOf(row.ZD04);
                        }
                        qli.Descuento_Valor__c = null;
                        if (row.ZD05 != null || row.ZD05 != '') {
                            qli.Descuento_Valor__c = Integer.valueOf(row.ZD05);
                        }
                        if (row.ZD06 != null || row.ZD06 != '') {
                            qli.Desc_Manual__c = Integer.valueOf(row.ZD06);
                        }
                        if (row.ZD07 != null || row.ZD07 != '') {
                            qli.Descuento_aplicado_antes_de_impuesto__c = Integer.valueOf(row.ZD07);
                        }
                        if (row.ZV01 != null || row.ZV01 != '') {
                            qli.Valor_matrcula__c = Integer.valueOf(row.ZV01);
                        }
                        if (row.ZV02 != null || row.ZV02 != '') {
                            qli.Valor_soat__c = Integer.valueOf(row.ZV02);
                        }
                        if (row.ZV11 != null || row.ZV11 != '') {
                            qli.Cuota_Inicial__c = Integer.valueOf(row.ZV11);
                        }
                        if (row.ZV16 != null || row.ZV16 != '') {
                            qli.Valor_seguro_robo__c = Integer.valueOf(row.ZV16);
                        }
                        if (row.ZZ01 != null || row.ZZ01 != '') {
                            qli.Valor_Dummy_1__c = Integer.valueOf(row.ZZ01);
                        }
                        if (row.ZZA2 != null || row.ZZA2 != '') {
                            qli.Valor_Dummy_2__c = Integer.valueOf(row.ZZA2);
                        }
                        if (row.ZZ03 != null || row.ZZ03 != '') {
                            qli.Valor_Dummy_3__c = Integer.valueOf(row.ZZ03);
                        }
                        if (row.ZZ04 != null || row.ZZ04 != '') {
                            qli.Valor_Dummy_4__c = Integer.valueOf(row.ZZ04);
                        }
                        qli.integracion_by_pass__c = true;
                    } else {
                        return 'Error: El producto no se encuentra en SAP.';
                    }
                }
            }else{
                return 'Error: El producto no se encuentra en SAP o verifica de tener los siguientes campos ingresados en Cotización: Tipo de pago y en los productos de cotización: Cantidad, Precio unitario, Soat, Cuota inicial, Seguro robo, Matricula y Descuento antes de aplicado impuesto.';
            }
            update productCodeMap.values();
            
            objQuote.Fecha_de_determinacion_del_precio__c = date.today();
            Date firstDayOfMonth = System.today().toStartOfMonth();            
            Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
            objQuote.Fecha_de_validez__c = lastDayOfMonth;
            objQuote.Realizo_consulta_de_precios__c = true;
            update objQuote;

            
            if (productCodeMap.values().size()>0){
                list <Database.SaveResult> SaveResultQuery = database.update(productCodeMap.values(),false);
                for(Database.SaveResult result : SaveResultQuery)
                    if (result.isSuccess()){
                        return 'Consulta de precios y descuentos exitosa!';
                    } else {
                        for(Database.Error e: result.getErrors()){
                            return 'Error: '+e.getMessage()+' En los campos '+e.getFields();
                        }
                    } 
                return 'Error: Algo salio mal en el ingreso de datos a Salesforce. Contacta a tu administrador para solucionarlo.';
            }
            else {
                return 'Error: Algo salio mal en el ingreso de datos a Salesforce. Contacta a tu administrador para solucionarlo.';         
            }
            
        }catch(Exception ex){
            system.debug('Error: ' + ex.getMessage() + ' Caused by: ' + ex.getCause());
            Log__c log = new Log__c();
            String body1 = JSON.serialize(lstRowElement[0]);
            log.body__c = body1;
            log.Web_Service__c = 'Consulta de precios y descuentos';
            insert log;
             return 'Error: ' + ex.getMessage() + ' Causado por: ' + ex.getCause();
        }       
    }
}