/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Integration class for updating Invoices in Saleforce with SOAP.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     26/11/2020      Juan Ansaldi            Class definition.
* @version  1.1     26/11/2020      Juan Ansaldi            Class finished and succesfully updates Invoices from external system. 
*********************************************************************************************************/
global class MotosModificarFacturaSOAPWS {
    
    global class MotosFacturaWS {
        webservice string VBAK_BSTKD {get;set;} //ID de Pedido en SAP
		webservice string VBRK_VBELN_VF {get;set;} // N_mero_de_Factura__c en Pedido
        webservice string VBRK_FKDAT  {get;set;} // Fecha_de_factura__c en Pedido
        webservice string VBRK_FSKTO {get;set;} // N_mero_de_anulaci_n__c en Oportunidad
        webservice string VBRK_ZZANUL  {get;set;} // Motivo de perdida en Oportunidad
        
    }
    
    global class MotosClienteRta{
        webservice String error {get;set;}
        webservice String MnsjRta {get;set;}
        webservice String idSF {get;set;}
    }
    
    webservice static list<MotosClienteRta> ModificarPedido(list<MotosFacturaWS> lstFactura ) {
        list <MotosClienteRta> lstclienteRta = new list<MotosClienteRta>();
        list <Order> lstinsertOrd = new list<Order>();

        Set<String> setOpportunityIds = new Set<String>();
        Map<String, Order> mapOrders = new Map<String, Order>();
        Map<String, Opportunity> mapOpportunities = new Map<String, Opportunity>();
        List<Opportunity> lstOpportunitiesUpdate = new List<Opportunity>();
        
        try{
           
            for(MotosFacturaWS pedido : lstFactura){               
				setOpportunityIds.add(pedido.VBAK_BSTKD);
            }
            
            for(Order o : [Select Id, Name, OrderNumber, OpportunityId, Opportunity.ID_de_pedido_ERP__c from Order where Opportunity.ID_de_pedido_ERP__c in: setOpportunityIds ]){
                mapOrders.put(o.Opportunity.ID_de_pedido_ERP__c, o);
            }
            
            
            for(MotosFacturaWS factura : lstFactura){               
                Order objPedido = new Order();
                objPedido.Id = mapOrders.containsKey(factura.VBAK_BSTKD) ? mapOrders.get(factura.VBAK_BSTKD).Id : null;
                if (factura.VBRK_VBELN_VF != null || factura.VBRK_VBELN_VF != '') {
                    objPedido.N_mero_de_Factura__c = factura.VBRK_VBELN_VF;
                }
                string fechaERP = factura.VBRK_FKDAT;
				if(fechaERP != null && fechaERP != ''){
                    fechaERP = fechaERP.right(4) + '-' + fechaERP.left(5).right(2) + '-' + fechaERP.left(2);
                    date convertFecha = Date.valueOf(fechaERP);
                    objPedido.Fecha_de_factura__c = convertFecha; 
                }
                
                //Opportunity
                if (mapOrders.containsKey(factura.VBAK_BSTKD)) {
                    Opportunity opp = new Opportunity(); 
                    opp.Id = mapOrders.get(factura.VBAK_BSTKD).OpportunityId;
                    opp.N_mero_de_anulaci_n__c = factura.VBRK_FSKTO;
                    opp.Motivo_de_Perdida_de_Oportunidad__c = factura.VBRK_ZZANUL;
                    if (factura.VBRK_VBELN_VF != null || factura.VBRK_VBELN_VF != '') {
                        opp.N_mero_de_Factura__c = factura.VBRK_VBELN_VF;
                    }
                    
                    Opportunity p = [Select Id, OwnerId, (Select Id, Product2Id from OpportunityLineItems) from Opportunity where Id =: opp.Id Limit 1];
                    Product2 prod = [Select Id, Name from Product2 where Id =: p.OpportunityLineItems[0].Product2Id];
                    User u = [Select Id, ManagerId from User where Id =: p.OwnerId Limit 1];
                    OpportunityTeamMember  opTeam = New OpportunityTeamMember();
                    opTeam.OpportunityAccessLevel = 'Edit';
                    opTeam.OpportunityId = p.Id;
                    opTeam.UserId = u.ManagerId;
                    opTeam.TeamMemberRole = 'Gerente_ventas';
                    insert opTeam;
                    
                    if (objPedido.N_mero_de_Factura__c!=null && objPedido.N_mero_de_Factura__c!='0') {
                        opp.MKT_ProdVendido__c = prod.Name; 
                    	opp.StageName = 'Vendida';
                    }
					if (!String.isBlank(opp.N_mero_de_anulaci_n__c)) opp.StageName = 'Perdida';
                    lstOpportunitiesUpdate.add(opp);
                }
                lstinsertOrd.add(objPedido);
            }
            
            if(lstinsertOrd.size()>0){
                list <Database.SaveResult> SaveResultOrder = database.update(lstinsertOrd, false);
                list <Database.SaveResult> SaveResultOppty = database.update(lstOpportunitiesUpdate, false);
                
                Integer i=0;
                for(Database.SaveResult result : SaveResultOrder){
                    Order p = lstinsertOrd.get(i);
                    MotosClienteRta r = new MotosClienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta='Operación exitosa';
                        r.error='';
                        r.idSF=p.id;
                    } else {
                        for(Database.Error e: result.getErrors()){
                            r.error='Error Order: '+e.getMessage()+' Campos '+e.getFields();
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
                        r.MnsjRta='Operación exitosa';
                        r.error='';
                        r.idSF=o.id;
                    } else {
                        for(Database.Error e: result.getErrors()){
                            r.error='Error Oportunidad: '+e.getMessage()+' Campos '+e.getFields();
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
            crta.mnsjRta='Exception: '+ex.getMessage();//'Problemas en la ejecución del webservice'; 
            crta.idSF='';
            lstclienteRta.add(crta);
        }
        
        for(MotosClienteRta rta: lstclienteRta){
            System.debug(' ** ERROR WEB SERVICE CLIENTES ** ' + rta);
        }
        return lstclienteRta;
    }
        
  
}