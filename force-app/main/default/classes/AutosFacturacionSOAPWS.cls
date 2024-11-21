/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Integration class for creating and updating Invoices in Saleforce with SOAP.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     31/03/2021      Juan Ansaldi            Class definition.
* @version  1.1     31/03/2021      Juan Ansaldi            Class finished and succesfully updates Invoices from external system. 
*********************************************************************************************************/
global class AutosFacturacionSOAPWS {
    
    global class AutosInvoiceWS {
        //PRODUCTOS
        webservice string f461_referencia {get;set;} // ID SALESFORCE
		webservice string f350_consec_docto {get;set;} // Numero de factura
        webservice string Estado {get;set;} // Estado
        webservice string Fecha_factura  {get;set;} // Fecha Factura
        webservice string f461_motivo {get;set;} // Motivo Anulación
        webservice string f461_descripcion_Motivo {get;set;} // Descripcion Anulación
    }
    
    global class AutosClienteRta{
        webservice String error {get;set;}
        webservice String MnsjRta {get;set;}
        webservice String idSF {get;set;}
    }
    
    webservice static List<AutosClienteRta> ModificarFactura(List<AutosInvoiceWS> lstInvoice ) {
        List <AutosClienteRta> lstclienteRta = new List<AutosClienteRta>();
        List <Opportunity> lstUpdateOpp = new List<Opportunity>();
        List <Order> lstupdateOrd = new List<Order>();

        Set<String> setOpportunityIds = new Set<String>();
        Map<String, Order> mapOrders = new Map<String, Order>();
        Set<Id> setOpps = new Set<Id>();
        List<Opportunity> lstOpps = new List<Opportunity>();
        
        try{
            
            for(AutosInvoiceWS i : lstInvoice){               
				setOpportunityIds.add(i.f461_referencia);
            }
            
            for(Order o : [Select Id, Name, OrderNumber, OpportunityId, Opportunity.Numero_de_Oportunidad__c, Opportunity.StageName 
                           from Order where Opportunity.Numero_de_Oportunidad__c in: setOpportunityIds ]){
                mapOrders.put(o.Opportunity.Numero_de_Oportunidad__c, o);
                setOpps.add(o.OpportunityId);
            }
            List<Inventario_de_Usados__c> lstInvUsados = New List<Inventario_de_Usados__c>();
            lstOpps = [Select Id, Tipo_de_Oportunidad__c from Opportunity where Id in: setOpps AND Tipo_de_Oportunidad__c = 'Usados'];
            for(AutosInvoiceWS inv : lstInvoice){                                           
                Order objPedido = new Order();
                objPedido.Id = mapOrders.containsKey(inv.f461_referencia) ? mapOrders.get(inv.f461_referencia).Id : null;
                string fchaERP = inv.Fecha_factura; 
				if(fchaERP != null && fchaERP != ''){
                    fchaERP = fchaERP.right(4) + '-' + fchaERP.left(5).right(2) + '-' + fchaERP.left(2);
                    date convertFecha1 = Date.valueOf(fchaERP);
                    objPedido.Fecha_de_factura__c = convertFecha1; 
                }
                
                if (inv.f350_consec_docto != null && inv.f350_consec_docto != '') {
                    objPedido.N_mero_de_Factura__c = inv.f350_consec_docto; 
                }
                
                lstupdateOrd.add(objPedido);
                
                if (mapOrders.containsKey(inv.f461_referencia)) {
                    if(mapOrders.get(inv.f461_referencia).Opportunity.StageName == 'PU') {
                        AutosClienteRta crta = new AutosClienteRta();
                        crta.error = '';
                        crta.mnsjRta = 'La oportunidad esta en etapa PU, no se realizan cambios.'; 
                        crta.idSF = mapOrders.get(inv.f461_referencia).OpportunityId;
                        lstclienteRta.add(crta);
                        return lstclienteRta;
                    }
                    Opportunity opp = New Opportunity();
                    opp.Id = mapOrders.get(inv.f461_referencia).OpportunityId;
                    
                    string fechaERP = inv.Fecha_factura; 
                    if(fechaERP != null && fechaERP != ''){
                        fechaERP = fechaERP.right(4) + '-' + fechaERP.left(5).right(2) + '-' + fechaERP.left(2);
                        date convertFecha = Date.valueOf(fechaERP);
                        opp.Fecha_de_factura__c = convertFecha; 
                    }    
                    
                    if(inv.Estado == '1') {
                        opp.StageName = 'P5';
                        opp.N_mero_de_factura__c = inv.f350_consec_docto; 
                        opp.N_mero_de_anulaci_n__c = null;
                    } else if(inv.Estado == '2') {
                        opp.StageName = 'P3';//opp.StageName = 'P4';
                        opp.N_mero_de_anulaci_n__c = inv.f350_consec_docto;
                        opp.Fecha_de_factura__c = null; //added onJuly 6th '21 requested in a meeting of UAT
                        opp.N_mero_de_factura__c = ''; //added onJuly 6th '21
                        opp.Usado_Separado__c = null;
                        opp.VIN__c = '';
                        opp.Placa__c = '';
                        opp.Vehiculo__c = null; //for new autos
                        opp.Se_creo_pedido_en_UNOEE__c = false;
                        if(lstOpps.size()> 0) {
                            List<OpportunityLineItem> lstOli = [Select Id, Product2Id, OpportunityId from OpportunityLineItem where OpportunityId in: lstOpps];	
                            if(lstOli.size()> 0){
                                Set<Id> setProductId = New Set<Id>();
                                for(OpportunityLineItem oli : lstOli){
                                    setProductId.add(oli.Product2Id);
                                }
                                List<Product2> lstProducts = [Select Id, Inventario_de_Usados__c from Product2 where Id in: setProductId];
                                if(lstProducts.size()> 0) {
                                    Set<Id> setInvUsados = New Set<Id>();
                                    for(Product2 p : lstProducts){
                                        setInvUsados.add(p.Inventario_de_Usados__c);
                                    }
                                    lstInvUsados = [Select Id from Inventario_de_Usados__c where Id in: setInvUsados];
                                    List<Product2> lstPrdUpdate = New List<Product2>();
                       			    List<Inventario_de_Usados__c> lstInvUpdate = New List<Inventario_de_Usados__c>();
                                    if(lstInvUsados.size()> 0){
                                        for(Product2 p : lstProducts){
                                            Product2 p2 = New Product2();
                                            p2.Id = p.Id;
                                            p2.IsActive = true;
                                            lstPrdUpdate.add(p2);
                                        }
                                        for(Inventario_de_Usados__c i : lstInvUsados){
                                            Inventario_de_Usados__c u = New Inventario_de_Usados__c();
                                            u.Id = i.Id;
                                            u.Oportunidad__c = null;
                                            u.Estado_Del_Vehiculo__c = 'DISPONIBLE';
                                            lstInvUpdate.add(u);
                                        }
                                        if(lstInvUpdate.size()> 0 ){
                                            update lstInvUpdate;
                                        }
                                        if(lstPrdUpdate.size()> 0){
                                            update lstPrdUpdate;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    List<Attachment> lstAtt = [SELECT Id, Name FROM Attachment WHERE ParentID IN: setOpps];
                    if(lstAtt.size()> 0) delete lstAtt;
                    List<ContentDocumentLink> cdl = [Select Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN: setOpps];
                    Set<Id> conDocId = New Set<Id>();
                    if(cdl.size()>0){
                        for (ContentDocumentLink c : cdl) {
                            conDocId.add(c.ContentDocumentId);
                        }
                    }
                    List<ContentDocument> cdList = [Select Id from ContentDocument where Id IN: conDocId];
                    if(cdList.size()> 0) delete cdList;
                    
                    opp.Motivo_Anula__c = inv.f461_motivo;
                    opp.Descripcion_de_Anulacion__c = inv.f461_descripcion_Motivo;
                    lstUpdateOpp.add(opp);
                }
                
            }
            
            if(lstUpdateOpp.size()>0){
                list <Database.SaveResult> SaveResult = database.update(lstUpdateOpp,false);
                update lstUpdateOpp;
                Integer i=0;
                for(Database.SaveResult result : SaveResult){
                    Opportunity p = lstUpdateOpp.get(i);
                    AutosClienteRta r = new AutosClienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta='Operación exitosa';
                        r.error='';
                        r.idSF=p.id;
                    } else {
                        for(Database.Error e: result.getErrors()){
                            r.error='Error: '+e.getMessage()+' Campos '+e.getFields();
                            r.MnsjRta ='Operación fallida';
                            r.idSF=p.id;
                        }
                    }
                    lstclienteRta.add(r);
                    i+=i;
                }
            }
            
        }
        catch (System.exception ex) {
            AutosClienteRta crta= new AutosClienteRta();
            crta.error='ERROR';
            crta.mnsjRta=ex.getMessage()+' Campos '+ex.getCause();//'Problemas en la ejecución del webservice'; 
            crta.idSF='';
            lstclienteRta.add(crta);
        }
        
        for(AutosClienteRta rta: lstclienteRta){
            System.debug(' ** ERROR WEB SERVICE CLIENTES ** ' + rta);
        }
        return lstclienteRta;
    }
}