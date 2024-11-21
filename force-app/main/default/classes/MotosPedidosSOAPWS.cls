/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Integration class for updating Orders in Saleforce with SOAP.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     14/11/2020      Juan Ansaldi            Class definition.
* @version  1.1     20/11/2020      Juan Ansaldi            Class finished and succesfully updates Orders from external system. 
*********************************************************************************************************/
global class MotosPedidosSOAPWS {
    
    global class MotosPedidosWS {
        webservice string VBAK_VBELN {get;set;} //ID de pedido en SAP
		webservice string VBAK_ABRVW {get;set;} // Tipo_de_Pago__c en el objeto Oportunidad
        webservice string VBAK_BNDDT  {get;set;} // Fecha_de_determinacion_del_precio en objeto Oportunidad
        webservice string VBAP_MATNR {get;set;} // codigo_producto__c en producto de oportunidad
        webservice string VBAP_NETWR  {get;set;} // UnitPrice 
        webservice string VSOAT {get;set;} // valor_soat__c
        webservice string VMATRI {get;set;} // valor_matricula__c
        webservice string VCINIC {get;set;} // valor_cuota_inicial__c
        webservice string VSEGR {get;set;} // valor_seguro_robo__c
        webservice string VDESC {get;set;} // Descuento_valor__c
        webservice string VBAK_KUNAG {get;set;} // Destinatario_Factura__c en oportunidad
        webservice string VBAK_KUNNG {get;set;} // Destinatario_Mercancia__c
        webservice string VBAK_PERNR1 {get;set;} // Pagador__c
        webservice string VBAK_PERNR2 {get;set;} // Titular_prendario__c
    }
    
    global class MotosClienteRta{
        webservice String error {get;set;}
        webservice String MnsjRta {get;set;}
        webservice String idSF {get;set;}
    }
    
    webservice static list<MotosClienteRta> ModificarPedido(list<MotosPedidosWS> lstPedidos ) {
        list <MotosClienteRta> lstclienteRta = new list<MotosClienteRta>();
        list <Order> lstinsertOrd = new list<Order>();
        list <OrderItem> lstInsertOrdItem = new list<OrderItem>();

        Set<String> setIdPedidoSAP = new Set<String>();
        Map<String, Order> mapOrders = new Map<String, Order>();
        Set<String> setOpportunityIds = new Set<String>();
        Map<String, Opportunity> mapOpportunities = new Map<String, Opportunity>();
        List<Opportunity> lstOpportunitiesUpdate = new List<Opportunity>();
        List<QuoteLineItem> lstQliInsert = new List<QuoteLineItem>();
        List<QuoteLineItem> listQliDelete = new List<QuoteLineItem>();
        List<OrderItem> listOiDelete = new List<OrderItem>();
        
        try{
           
            for(MotosPedidosWS pedido : lstPedidos){               
				setIdPedidoSAP.add(pedido.VBAK_VBELN);
            }
            
            for(Order o : [Select Id, Name, OrderNumber, OpportunityId, Pricebook2Id, Opportunity.SyncedQuoteId, Opportunity.ID_de_pedido_ERP__c, 
                           (select Id, Product2.ProductCode from OrderItems) 
                           from Order where Opportunity.ID_de_pedido_ERP__c in: setIdPedidoSAP ]){
                mapOrders.put(o.Opportunity.ID_de_pedido_ERP__c, o);
                setOpportunityIds.add(o.OpportunityId);
            }
            
            for(Opportunity o : [Select Id, Name, (Select Id, ProductCode from OpportunityLineItems) from Opportunity where Id in: setOpportunityIds]) {
                mapOpportunities.put(o.Id, o);
            }
            Integer j=0;
            for(MotosPedidosWS pedido : lstPedidos){ 
                List<Account> mercancia = [select Id, Codigo_ERP__c from Account where Codigo_ERP__c =: pedido.VBAK_KUNNG];
                List<Account> factura = [select Id, Codigo_ERP__c from Account where Codigo_ERP__c =: pedido.VBAK_KUNAG];
                List<Account> pagador = [select Id, Codigo_ERP__c from Account where Codigo_ERP__c =: pedido.VBAK_PERNR1];
                List<Account> titular = [select Id, Codigo_ERP__c from Account where Codigo_ERP__c =: pedido.VBAK_PERNR2];
                
                Order objPedido = new Order();
                objPedido = mapOrders.containsKey(pedido.VBAK_VBELN) ? mapOrders.get(pedido.VBAK_VBELN) : null;
                objPedido.Tipo_de_Pago2__c = getTipoDePago_SAP(pedido.VBAK_ABRVW);
				if (pagador.size() > 0) objPedido.Pagador__c = pagador[0].Id;
                if (titular.size() > 0) objPedido.Titular_prendario__c = titular[0].Id;
                objPedido.Status = 'Draft';
                update objPedido;
                //Opportunity and OpportunityLineItem
                if (mapOrders.containsKey(pedido.VBAK_VBELN)) {
                    Opportunity opp = new Opportunity(); 
                    opp.Id = mapOrders.get(pedido.VBAK_VBELN).OpportunityId;
                    string fechaERP = pedido.VBAK_BNDDT;
                    system.debug(fechaERP);
                    if(fechaERP != null && fechaERP != ''){
                        date convertFecha = Date.valueOf(fechaERP);
                        opp.Fecha_de_determinacion_del_precio__c = convertFecha; 
                    }
                    opp.Tipo_de_Pago__c = getTipoDePago_SAP(pedido.VBAK_ABRVW);
                    if (factura.size() > 0) opp.Destinatario_Factura__c = factura[0].Id;
                    if (mercancia.size() > 0) opp.Destinatario_Mercanc_a__c = mercancia[0].Id;
                    if (pagador.size() > 0) opp.Pagador__c = pagador[0].Id;
                    if (titular.size() > 0) opp.Titular_prendario__c = titular[0].Id;
                    
                    lstOpportunitiesUpdate.add(opp);
                    
                    List<Product2> prd = [select Id, ProductCode from Product2 where ProductCode =: pedido.VBAP_MATNR];
                    List<QuoteLineItem> lstQli = [select Id, QuoteId, PricebookEntryId from QuoteLineItem where QuoteId =: mapOrders.get(pedido.VBAK_VBELN).Opportunity.SyncedQuoteId AND Product2.ProductCode =: pedido.VBAP_MATNR limit 1];
                    QuoteLineItem qli = new QuoteLineItem();
                    if (lstQli.size() > 0) qli = lstQli[0];
                    listQliDelete = [select Id from QuoteLineItem where QuoteId =: mapOrders.get(pedido.VBAK_VBELN).Opportunity.SyncedQuoteId AND Product2.ProductCode !=: pedido.VBAP_MATNR];
                    List<PricebookEntry> pbe = new List<PriceBookEntry>();
                    if(prd.size()>0){
                      pbe = [select Id from PricebookEntry where ProductCode =: prd[0].ProductCode AND Pricebook2Id =: mapOrders.get(pedido.VBAK_VBELN).PriceBook2Id];  
                    }
                    if(qli.QuoteId == null) {
                        qli.QuoteId = mapOrders.get(pedido.VBAK_VBELN).Opportunity.SyncedQuoteId;
                    }
                    if(qli.PricebookEntryId == null) {
                        if(pbe.size()>0) {
                            qli.PricebookEntryId = pbe[0].Id;
                        }                        
                    }
                    qli.Quantity = 1;
                    if (pedido.VBAP_NETWR != null || pedido.VBAP_NETWR != '') {
                        qli.Precio_de_lista_antes_de_impuesto__c = Integer.ValueOf(pedido.VBAP_NETWR);
                        qli.UnitPrice = Integer.ValueOf(pedido.VBAP_NETWR);
                    }
                    if (pedido.VSOAT != null || pedido.VSOAT != '') {
                        qli.Valor_soat__c = Integer.ValueOf(pedido.VSOAT);
                    }
                    if (pedido.VMATRI != null || pedido.VMATRI != '') {
                        qli.Valor_matrcula__c = Integer.ValueOf(pedido.VMATRI);
                    }
                    if (pedido.VCINIC != null || pedido.VCINIC != '') {
                        qli.Cuota_Inicial__c = Integer.ValueOf(pedido.VCINIC);
                    }
                    if (pedido.VSEGR != null || pedido.VSEGR != '') {
                        qli.Valor_seguro_robo__c = Integer.ValueOf(pedido.VSEGR);
                    }
                    if (pedido.VDESC != null || pedido.VDESC != '') {
                        qli.Descuento_Valor__c = Integer.ValueOf(pedido.VDESC);
                    }
                    
                    lstQliInsert.add(qli);
                    
					listOiDelete = [select Id from OrderItem where OrderId =: mapOrders.get(pedido.VBAK_VBELN).Id AND Product2.ProductCode !=: pedido.VBAP_MATNR];
                    List<OrderItem> lstOi = [select Id, OrderId, PricebookEntryId from OrderItem where OrderId =: mapOrders.get(pedido.VBAK_VBELN).Id AND Product2.ProductCode =: pedido.VBAP_MATNR limit 1];
                    OrderItem ordItem = new OrderItem();
                    if (lstOi.size() > 0) ordItem = lstOi[0];
                    if (ordItem.OrderId == null){
                       ordItem.OrderId = objPedido.Id; 
                    }
                    if (ordItem.PricebookEntryId == null){
                        if(pbe.size()>0){
                            ordItem.PricebookEntryId = pbe[0].Id;
                        }
                    }
                    ordItem.Quantity = 1;
                    if (pedido.VBAP_NETWR != null || pedido.VBAP_NETWR != '') {
                        ordItem.Precio_de_lista_antes_de_impuesto__c = Integer.ValueOf(pedido.VBAP_NETWR);
                        ordItem.UnitPrice = Integer.ValueOf(pedido.VBAP_NETWR);
                    }
                    if (pedido.VSOAT != null || pedido.VSOAT != '') {
                        ordItem.Valor_soat2__c = Integer.ValueOf(pedido.VSOAT);
                    }
                    if (pedido.VMATRI != null || pedido.VMATRI != '') {
                        ordItem.Valor_matrcula__c = Integer.ValueOf(pedido.VMATRI);
                    }
                    if (pedido.VCINIC != null || pedido.VCINIC != '') {
                        ordItem.Cuota_Inicial__c = Integer.ValueOf(pedido.VCINIC);
                    }
                    if (pedido.VSEGR != null || pedido.VSEGR != '') {
                        ordItem.Valor_seguro_robo__c = Integer.ValueOf(pedido.VSEGR);
                    }
                    if (pedido.VDESC != null || pedido.VDESC != '') {
                        ordItem.Descuento_Valor__c = Integer.ValueOf(pedido.VDESC);
                    }
                    lstInsertOrdItem.add(ordItem);
                }
                lstinsertOrd.add(objPedido);
            }
            
            if(lstinsertOrd.size()>0){
                list <Database.UpsertResult> SaveResultOrderItem = database.upsert(lstInsertOrdItem,false);
                list <Database.SaveResult> SaveResultOppty = database.update(lstOpportunitiesUpdate,false);
                list <Database.UpsertResult> SaveResultQLI = database.upsert(lstQliInsert,false);
                if (listOiDelete.size() > 0) {
                    delete listOiDelete;
                }
                if (listQliDelete.size() > 0) {
                    delete listQliDelete;
                }
                lstinsertOrd[0].status = 'Activated';
                list <Database.SaveResult> SaveResultOrder = database.update(lstinsertOrd,false);
                
                Integer i=0;
                for(Database.UpsertResult result : SaveResultOrderItem){
                    OrderItem ordI = lstInsertOrdItem.get(i);
                    MotosClienteRta r = new MotosClienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta='Operación exitosa producto de pedido';
                        r.error='';
                        r.idSF=ordI.id;
                    } else {
                        for(Database.Error e: result.getErrors()){
                            r.error='Error en producto de pedido: '+e.getMessage()+' Campos '+e.getFields();
                            r.MnsjRta ='Operación fallida';
                            r.idSF=ordI.id;
                        }
                    }
                    lstclienteRta.add(r);
                    i+=i;
                }
                
                i=0;
                for(Database.UpsertResult result : SaveResultQLI){
                    QuoteLineItem qli = lstQliInsert.get(i);
                    MotosClienteRta r = new MotosClienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta='Operación exitosa producto de cotización';
                        r.error='';
                        r.idSF=qli.id;
                    } else {
                        for(Database.Error e: result.getErrors()){
                            r.error='Error producto de cotización: '+e.getMessage()+' Campos '+e.getFields();
                            r.MnsjRta ='Operación fallida';
                            r.idSF=qli.id;
                        }
                    }
                    lstclienteRta.add(r);
                    i+=i;
                }
                
                i=0;
                for(Database.SaveResult result : SaveResultOrder){
                    Order p = lstinsertOrd.get(i);
                    MotosClienteRta r = new MotosClienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta='Operación exitosa pedido';
                        r.error='';
                        r.idSF=p.id;
                    } else {
                        for(Database.Error e: result.getErrors()){
                            r.error='Error pedido: '+e.getMessage()+' Campos '+e.getFields();
                            r.MnsjRta ='Operación fallida';
                            r.idSF=p.id;
                        }
                    }
                    lstclienteRta.add(r);
                    i+=i;
                }
                
                i=0;
                for(Database.SaveResult result : SaveResultOppty){
                    Opportunity o = lstOpportunitiesUpdate.get(i);
                    MotosClienteRta r = new MotosClienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta='Operación exitosa oportunidad';
                        r.error='';
                        r.idSF=o.id;
                    } else {
                        for(Database.Error e: result.getErrors()){
                            r.error='Error oportunidad: '+e.getMessage()+' Campos '+e.getFields();
                            r.MnsjRta ='Operación fallida';
                            r.idSF=o.id;
                        }
                    }
                    lstclienteRta.add(r);
                    i+=i;
                }
            }
        }
        catch (System.exception ex) {
            MotosClienteRta crta= new MotosClienteRta();
            crta.error='ERROR';
            crta.mnsjRta=ex.getMessage();//'Problemas en la ejecución del webservice'; 
            crta.idSF='';
            lstclienteRta.add(crta);
        }
        
        return lstclienteRta;
    }
        
    //This method returns the value of Tipo de Pago picklist value in Salesforce based on codes in SAP
    private static String getTipoDePago_SAP(String Codigo){
        switch on Codigo {
            when '01' {	return '101'; }	
            when '02' {	return '102'; }
            when '03' {	return '103'; }
            when '04' {	return '104'; }
            when '05' {	return '105'; }
            when '07' {	return '107'; }
            when else { return ''; }
        }
    }
}