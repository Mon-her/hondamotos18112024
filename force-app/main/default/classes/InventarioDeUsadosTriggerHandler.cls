public class InventarioDeUsadosTriggerHandler extends TriggerHandler {

  private list<Inventario_de_Usados__c> newInventarioDeUsadosList;
  private list<Inventario_de_Usados__c> oldInventarioDeUsadosList;  
  private Map<Id, Inventario_de_Usados__c> newInventarioDeUsadosMap;
  private Map<Id, Inventario_de_Usados__c> oldInventarioDeUsadosMap;

  public InventarioDeUsadosTriggerHandler() {
    
    newInventarioDeUsadosList = (list<Inventario_de_Usados__c>) Trigger.New;
    oldInventarioDeUsadosList = (list<Inventario_de_Usados__c>) Trigger.Old;
    newInventarioDeUsadosMap = (Map<Id, Inventario_de_Usados__c>) Trigger.NewMap;
    oldInventarioDeUsadosMap = (Map<Id, Inventario_de_Usados__c>) Trigger.OldMap;
  }
    
    public override void beforeInsert() {
       // AFOG_InventarioUsadosUtilidades_cls.sendAlertOpportunityConsigRetiradoInsert( newInventarioDeUsadosList );
        Set<String> setPlacas = New Set<String>();    
        Map<String, Asset> mapAssets = New Map<String, Asset>();
        for(Inventario_de_Usados__c i : newInventarioDeUsadosList) {
        	setPlacas.add(i.Placas__c);
        }
        List<Asset> lstAssets = [Select Id, Vin__c, Placa__c from Asset where Placa__c in: setPlacas];
        List<Inventario_de_Usados__c> lstInvPlacas = [Select Id,Placas__c ,Estado_del_vehiculo__c from Inventario_de_Usados__c 
                                                      where Placas__c in: setPlacas AND Placas__c != null AND  Estado_del_vehiculo__c NOT IN ('FACTURADO', 'CONSIG. RETIRADO' ) ];
        Map<string, Inventario_de_Usados__c> mapInvs = New Map< string , Inventario_de_Usados__c>();
        for(Inventario_de_Usados__c i : lstInvPlacas){
            mapInvs.put(i.Placas__c, i);
        }
        SYSTEM.DEBUG('LIST INV UADOS @@@ ' + JSON.serializePretty( mapInvs.Values()) + 'inv to insert @@@ '+ JSON.serializePretty( newInventarioDeUsadosList ) );
        if(lstInvPlacas.size()>0){
            for(Inventario_de_Usados__c i : newInventarioDeUsadosList) {
                if( mapInvs.containsKey(i.Placas__c) && mapInvs.get(i.Placas__c).Placas__c == i.Placas__c ){  
			    	i.addError('Error, otro vehículo ya contiene la misma Placa que esta intentando agregar.');
                }
            }
        }
	    for(Asset a : lstAssets) {
            mapAssets.put(a.Placa__c, a);
        }
        for(Inventario_de_Usados__c i : newInventarioDeUsadosList) {
            
            if(i.Linea__c != null ){
                i.Nombre_De_Producto__c = strNull(i.Marca__c) +'/'+ strNull(i.Linea__c) +'/'+ strNull(i.Version__c) +'/'+ strNull(i.Traccion__c) +'/'+ strNull(i.Caja__c) +'/'+ strNull(i.Color__c) +'/'+strNull( i.Ano__c);//i.Nombre_De_Producto__c = i.Marca__c +'/'+ i.Linea__c +'/'+ i.Version__c +'/'+ i.Traccion__c +'/'+ i.Caja__c +'/'+ i.Color__c +'/'+ i.Ano__c;
            } else {
                i.Nombre_De_Producto__c = strNull(i.Marca__c) +'/'+ strNull(i.Linea_otras_marcas__c) +'/'+ strNull(i.Version__c) +'/'+ strNull(i.Traccion__c) +'/'+ strNull(i.Caja__c) +'/'+ strNull(i.Color__c) +'/'+ strNull(i.Ano__c);//i.Nombre_De_Producto__c = i.Marca__c +'/'+ i.Linea_otras_marcas__c +'/'+ i.Version__c +'/'+ i.Traccion__c +'/'+ i.Caja__c +'/'+ i.Color__c +'/'+ i.Ano__c;
            }
            
            if(i.Version__c != null){
                i.Nombre_De_Producto__c = strNull(i.Marca__c) +'/'+ strNull(i.Linea__c) +'/'+ strNull(i.Version__c) +'/'+ strNull(i.Traccion__c) +'/'+ strNull(i.Caja__c) +'/'+ strNull(i.Color__c) +'/'+ strNull(i.Ano__c);//i.Nombre_De_Producto__c = i.Marca__c +'/'+ i.Linea__c +'/'+ i.Version__c +'/'+ i.Traccion__c +'/'+ i.Caja__c +'/'+ i.Color__c +'/'+ i.Ano__c;
            } else {
                i.Nombre_De_Producto__c = strNull(i.Marca__c) +'/'+ strNull(i.Linea_otras_marcas__c) +'/'+ strNull(i.Version_otras_marcas__c) +'/'+ strNull(i.Traccion__c) +'/'+ strNull(i.Caja__c) +'/'+ strNull(i.Color__c) +'/'+ strNull(i.Ano__c);//i.Nombre_De_Producto__c = i.Marca__c +'/'+ i.Linea_otras_marcas__c +'/'+ i.Version_otras_marcas__c +'/'+ i.Traccion__c +'/'+ i.Caja__c +'/'+ i.Color__c +'/'+ i.Ano__c;
            }
            
         	if(mapAssets.containsKey(i.Placas__c)) {
                i.Vin__c = mapAssets.get(i.Placas__c).Vin__c;
            }
        }
        
    }
    
    private String strNull(String str){
        if (String.isBlank(str)) return ''; else return str;
    }
    
    public override void beforeUpdate() {
        AFOG_InventarioUsadosUtilidades_cls.sendAlertOpportunityConsigRetiradoUpdate( newInventarioDeUsadosList  , oldInventarioDeUsadosMap );

        for(Inventario_de_Usados__c i : newInventarioDeUsadosList) { 
			if(i.Linea__c != null ){
                i.Nombre_De_Producto__c = strNull(i.Marca__c) +'/'+ strNull(i.Linea__c) +'/'+ strNull(i.Version__c) +'/'+ strNull(i.Traccion__c) +'/'+ strNull(i.Caja__c) +'/'+ strNull(i.Color__c) +'/'+ strNull(i.Ano__c);//i.Nombre_De_Producto__c = i.Marca__c +'/'+ i.Linea__c +'/'+ i.Version__c +'/'+ i.Traccion__c +'/'+ i.Caja__c +'/'+ i.Color__c +'/'+ i.Ano__c;
            } else {
                i.Nombre_De_Producto__c = strNull(i.Marca__c) +'/'+ strNull(i.Linea_otras_marcas__c) +'/'+ strNull(i.Version__c) +'/'+ strNull(i.Traccion__c) +'/'+ strNull(i.Caja__c) +'/'+ strNull(i.Color__c) +'/'+ strNull(i.Ano__c);//i.Nombre_De_Producto__c = i.Marca__c +'/'+ i.Linea_otras_marcas__c +'/'+ i.Version__c +'/'+ i.Traccion__c +'/'+ i.Caja__c +'/'+ i.Color__c +'/'+ i.Ano__c;
            }
            
            if(i.Version__c != null){
                i.Nombre_De_Producto__c = strNull(i.Marca__c) +'/'+ strNull(i.Linea__c) +'/'+ strNull(i.Version__c) +'/'+ strNull(i.Traccion__c) +'/'+ strNull(i.Caja__c) +'/'+ strNull(i.Color__c) +'/'+ strNull(i.Ano__c);//i.Nombre_De_Producto__c = i.Marca__c +'/'+ i.Linea__c +'/'+ i.Version__c +'/'+ i.Traccion__c +'/'+ i.Caja__c +'/'+ i.Color__c +'/'+ i.Ano__c;
            } else {
                i.Nombre_De_Producto__c = strNull(i.Marca__c) +'/'+ strNull(i.Linea_otras_marcas__c) +'/'+ strNull(i.Version_otras_marcas__c) +'/'+ strNull(i.Traccion__c) +'/'+ strNull(i.Caja__c) +'/'+ strNull(i.Color__c) +'/'+ strNull(i.Ano__c);//i.Nombre_De_Producto__c = i.Marca__c +'/'+ i.Linea_otras_marcas__c +'/'+ i.Version_otras_marcas__c +'/'+ i.Traccion__c +'/'+ i.Caja__c +'/'+ i.Color__c +'/'+ i.Ano__c;
            }        
        }
        List<Inventario_de_Usados__c> lstInvPlacas = [Select Id from Inventario_de_Usados__c 
                                                      where Placas__c =: newInventarioDeUsadosList[0].Placas__c AND Placas__c != null AND Estado_del_vehiculo__c <> 'FACTURADO'];
        if(lstInvPlacas.size()>0 && oldInventarioDeUsadosList[0].Placas__c != newInventarioDeUsadosList[0].Placas__c){
            newInventarioDeUsadosList[0].addError('Error, otro vehículo ya contiene la misma Placa que esta intentando modificar.');
        }
    }
    
    public override void afterInsert() {
    
        List<Product2> lstProductos = New List<Product2>();
        List<PricebookEntry> lstPbe = New List<PricebookEntry>();
		Set<String> setPlacas = New Set<String>();
        
        RecordType rtProductos = [Select Id from RecordType where DeveloperName =: Label.RecordTypeAutos  and sobjecttype='Product2'];// AFOG 27/01/2022 INCLUDE FILTER  and sobjecttype='Product2'
        
        for(Inventario_de_Usados__c i : newInventarioDeUsadosList) {
			setPlacas.add(i.Placas__c);
            
            Product2 p = New Product2();
            
            p.RecordTypeId = rtProductos.Id;
            p.Tipo_Producto__c = 'Usados';
            p.IsActive = true;
            p.Ano_modelo__c  = i.Ano__c != null ? Integer.valueOf(i.Ano__c) : null;
            p.Caja__c = i.Caja__c;
            p.Cilindraje__c  = i.Cilindraje__c != null ? String.valueOf(i.Cilindraje__c) : null;
            p.Ciudad_de_la_placa__c  = i.Ciudad_Placa__c;
            p.Color__c = i.Color__c;
            p.Especificaciones__c = i.Estado_Del_Vehiculo__c;
            p.Fecha_Compra__c = i.Fecha_De_Factura__c;
            p.Kilometraje__c = i.Kilometraje__c != null ? Integer.valueOf(i.Kilometraje__c) : null;
            p.Linea__c = i.Linea__c;
            p.Marca__c = i.Marca__c;
            p.Name = i.Nombre_De_Producto__c;
            p.Nombre_Comercial__c = i.Nombre_De_Producto__c;
            p.Placa__c = i.Placas__c;
            p.Tipo_de_combustible__c = i.Tipo_de_Combustible__c;
            p.Tipo_de_veh_culo__c = i.Tipo_Inv_Usado__c;
            p.Traccin__c = i.Traccion__c;
            if(i.Version__c == '' && i.Version__c == null){
                p.Version__c = i.Version_otras_marcas__c;
            } else {
                p.Version__c = i.Version__c;
            }
            p.Numero_VIN__c = i.Vin__c;
            p.Inventario_de_Usados__c = i.Id;
            p.ProductCode = i.Name;
            lstProductos.add(p);
        }
        
        List<Product2> lstPrd = [Select Id, Placa__c from Product2 where Placa__c in: setPlacas and Placa__c!=''];
	    List<OpportunityLineItem> lstOli = [Select Id, Product2Id, OpportunityId from OpportunityLineItem where Product2Id in: lstPrd];
        Set<Id> setOpps = New Set<Id>();
        for (OpportunityLineItem oli : lstOli){
            setOpps.add(oli.OpportunityId);
        }
        List<Opportunity> lstOppty = [Select Id, StageName, Estado_V__c from Opportunity where Id in: setOpps AND StageName = 'PU'];
        List<Opportunity> lstOppUpdate = New List<Opportunity>();
        for (Opportunity opp : lstOppty){
            Opportunity Op = New Opportunity();
            op.Id = opp.Id;
            op.Estado_V__c = 'Inactivo';
            lstOppUpdate.add(op);
        }
        if(lstOppUpdate.size() > 0) {
            update lstOppUpdate;
        }
        
        Pricebook2 pb = [Select Id from Pricebook2 where Name = 'Precios Usados'];
        if (lstProductos.size() > 0){
            insert lstProductos;
            for(Product2 p : lstProductos){
                PriceBookEntry pbe = New PriceBookEntry();
                pbe.Product2Id = p.Id;
                pbe.Fecha_Activacion__c = System.today();
				pbe.IsActive = true;
                pbe.Pricebook2Id = pb.Id;
                if (newInventarioDeUsadosMap.containsKey(p.Inventario_de_Usados__c)) {
                    Decimal precio = newInventarioDeUsadosMap.get(p.Inventario_de_Usados__c).Precio_Venta__c;
                    if(precio == null) {
                        pbe.UnitPrice = 0;
                    } else {
                        pbe.UnitPrice = precio;
                    }
                }
                lstPbe.add(pbe);
            }   
            if(lstPbe.size() > 0){
                insert lstPbe;
            }
        }
    }
    
    public override void afterUpdate() {
    
        List<Product2> lstProductos = New List<Product2>();
        List<PricebookEntry> lstPbe = New List<PricebookEntry>();
        
        RecordType rtProductos = [Select Id from RecordType where DeveloperName =: Label.RecordTypeAutos  and sobjecttype='Product2']; // AFOG 27/01/2022 INCLUDE FILTER  and sobjecttype='Product2'
        Set<Id> setIds = New Set<Id> ();
        for(Inventario_de_Usados__c i : newInventarioDeUsadosList) {
        	setIds.add(i.Id);
        }
        Map<Id, Product2> mapProducts = New Map<Id, Product2>();
        Pricebook2 pb = [Select Id from Pricebook2 where Name = 'Precios Usados'];
        
        List<Product2> listProducts = [Select Id, Inventario_de_Usados__c, 
                                       (Select Id, Pricebook2Id from PriceBookEntries where Pricebook2Id =: pb.Id) 
                                       from product2 where Inventario_de_Usados__c in: setIds];
        for (Product2 p : listProducts){
			mapProducts.put(p.Inventario_de_Usados__c, p);
        }
        
        for(Inventario_de_Usados__c i : newInventarioDeUsadosList) {
            
            Product2 p = New Product2();
            if(mapProducts.ContainsKey(i.Id)) {
                p.Id = mapProducts.get(i.Id).Id;
            }
            p.RecordTypeId = rtProductos.Id;
            p.IsActive = true;
            p.Ano_modelo__c = i.Ano__c != null ? Integer.valueOf(i.Ano__c) : null;
            p.Caja__c = i.Caja__c;
            p.Cilindraje__c  = i.Cilindraje__c != null ? String.valueOf(i.Cilindraje__c) : null;
            p.Ciudad_de_la_placa__c  = i.Ciudad_Placa__c;
            p.Color__c = i.Color__c;
            p.Especificaciones__c = i.Estado_Del_Vehiculo__c;
            p.Fecha_Compra__c = i.Fecha_De_Factura__c;
            p.Kilometraje__c = i.Kilometraje__c != null ? Integer.valueOf(i.Kilometraje__c) : null;
            p.Linea__c = i.Linea__c;
            p.Marca__c = i.Marca__c;
            p.Name = i.Nombre_De_Producto__c;
            p.Nombre_Comercial__c = i.Nombre_De_Producto__c;
            p.Placa__c = i.Placas__c;
            p.Tipo_de_combustible__c = i.Tipo_de_Combustible__c;
            p.Tipo_de_veh_culo__c = i.Tipo_Inv_Usado__c;
            p.Traccin__c = i.Traccion__c;
            if(i.Version__c == '' && i.Version__c == null){
                p.Version__c = i.Version_otras_marcas__c;
            } else {
                p.Version__c = i.Version__c;
            }
            p.Numero_VIN__c = i.Vin__c;
            p.Inventario_de_Usados__c = i.Id;
            
            lstProductos.add(p);
        }
        
        if (lstProductos.size() > 0){
            update lstProductos;
            
            for(Product2 p : lstProductos){
                PriceBookEntry pbe = New PriceBookEntry();
                if(mapProducts.ContainsKey(p.Inventario_de_Usados__c)) {
                    pbe.Id = mapProducts.get(p.Inventario_de_Usados__c).PricebookEntries[0].Id;
                }
                pbe.Fecha_Activacion__c = System.today();
				pbe.IsActive = true;
                if (newInventarioDeUsadosMap.containsKey(p.Inventario_de_Usados__c)) {
                    Decimal precio = newInventarioDeUsadosMap.get(p.Inventario_de_Usados__c).Precio_Venta__c;
                    if(precio == null) {
                        pbe.UnitPrice = 0;
                    } else {
                        pbe.UnitPrice = precio;
                    }
                }
                lstPbe.add(pbe);
            }   
            if(lstPbe.size() > 0){
                update lstPbe;
            }
        }
    }
    
    public override void beforeDelete() {
    
        List<Product2> lstProductos = New List<Product2>();
        List<PricebookEntry> lstPbe = New List<PricebookEntry>();
        
        RecordType rtProductos = [Select Id from RecordType where DeveloperName =: Label.RecordTypeAutos  and sobjecttype='Product2']; // AFOG 27/01/2022 INCLUDE FILTER  and sobjecttype='Product2'
        Set<Id> setIds = New Set<Id> ();
        for(Inventario_de_Usados__c i : oldInventarioDeUsadosList) {
        	setIds.add(i.Id);
        }

        Map<Id, Product2> mapProducts = New Map<Id, Product2>();
        Pricebook2 pb = [Select Id from Pricebook2 where Name = 'Precios Usados'];
        
        List<Product2> listProducts = [Select Id, Inventario_de_Usados__c, 
                                       (Select Id, Pricebook2Id from PriceBookEntries where Pricebook2Id =: pb.Id) 
                                       from product2 where Inventario_de_Usados__c in: setIds];
        if(listProducts.size() > 0) {
            for (Product2 p : listProducts){
                mapProducts.put(p.Inventario_de_Usados__c, p);
            }
            
            for(Inventario_de_Usados__c i : oldInventarioDeUsadosList) {
                
                Product2 p = New Product2();
                if(mapProducts.ContainsKey(i.Id)) {
                    p.Id = mapProducts.get(i.Id).Id;
                    p.Inventario_de_Usados__c = i.Id;
                }
                lstProductos.add(p);
            }
            
            if (lstProductos.size() > 0){
                for(Product2 p : lstProductos){
                    PriceBookEntry pbe = New PriceBookEntry();
                    if(mapProducts.ContainsKey(p.Inventario_de_Usados__c)) {
                        pbe.Id = mapProducts.get(p.Inventario_de_Usados__c).PricebookEntries[0].Id;
                    }
                    lstPbe.add(pbe);
                }   
                if(lstPbe.size() > 0){
                    delete lstPbe;
                    delete lstProductos;
                }
            }
        }
    }
}