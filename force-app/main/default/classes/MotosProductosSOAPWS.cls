/**
* Fanalca
* @author           Jonathan Parrales
* Description:      Integration class for creating and updating Motos Products in Saleforce with SOAP.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     09/11/2020      Jonathan Parrales       Class definition.
* @version  1.1     12/11/2020      Jonathan Parrales       Class finished and succesfully creates or updates Products from external system. 
*********************************************************************************************************/
global class MotosProductosSOAPWS {
    global class ProductoWS{
        webservice string MARA_MATNR {get;set;}
		webservice string MARA_SEGMENT {get;set;}
        webservice string MARA_MKTXT {get;set;}
        webservice string AUSP_MODELO {get;set;}
        webservice string AUSP_COLOR {get;set;}
        webservice string AUSP_LINEA {get;set;}
        webservice string MARA_LVORM {get;set;}
        
    }
    
    global class ClienteRta{
        webservice String error {get;set;}
        webservice String MnsjRta {get;set;}
        webservice String idSF {get;set;}
    }
    
    webservice static list<clienteRta> productoAdd(list<ProductoWS> lstProductos ){
        system.debug('MotosProductosSOAPWS: Entrando a productoAdd'); 
        list <clienteRta> lstclienteRta = new list<clienteRta>();
        list <Product2> lstInsertar = new list<Product2>();
        try{
            RecordType rtMotosProducto = [SELECT id,DeveloperName FROM RecordType WHERE sobjecttype ='Product2' and isActive=true and DeveloperName =:Label.MotosRecordTypeDevNameProduct limit 1];
            for(ProductoWS producto : lstProductos){
                System.debug(' ** REQUEST ** ' + producto);
                
                Product2 objProducto = new Product2 ();
                objProducto.RecordTypeId= rtMotosProducto.Id;
                objProducto.ProductCode = producto.MARA_MATNR;
                objProducto.Segmento__c = producto.MARA_SEGMENT;
                objProducto.Referencia__c = producto.MARA_MKTXT;
                objProducto.Name = producto.MARA_MKTXT;
                objProducto.Ano_modelo__c = Integer.valueOf(producto.AUSP_MODELO);
                objProducto.Color__c = producto.AUSP_COLOR;
                objProducto.Family = producto.AUSP_LINEA;
                objProducto.isActive = producto.MARA_LVORM =='X' ? false : true;
                lstInsertar.add(objProducto);
            }
            
            if(lstInsertar.size()>0){
                system.debug('MotosProductosSOAPWS: Hay Elementos que insertar: ' + lstInsertar.size()); 
                list <Database.SaveResult> SaveResult= database.insert(lstInsertar,false);
                    
                Integer i=0;
                for(Database.SaveResult result : SaveResult){
                    Product2 c= lstInsertar.get(i);
                    clienteRta r= new clienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta='Operación exitosa';
                        r.error='';
                        r.idSF=c.id;
                    }else{
                        for(Database.Error e: result.getErrors()){
                            r.error='Error: '+e.getMessage();
                            r.MnsjRta ='Operación fallida';
                            r.idSF=c.id;
                        }
                    }
                    lstclienteRta.add(r);
                    i+=i;
                }
             } 
        }
        catch (System.exception ex) {
          clienteRta crta= new clienteRta();
          crta.error='ERROR: ' + ex.getMessage();
          crta.mnsjRta='Problemas en la ejecución del webservice'; 
          crta.idSF='';
          lstclienteRta.add(crta);
         }
        
        for(clienteRta rta: lstclienteRta){
            System.debug(' ** ERROR WEB SERVICE PRODUCTOS ** ' + rta);
        }
        system.debug('MotosProductosSOAPWS: Saliendo de productoAdd'); 
        return lstclienteRta ;
    }
    
    webservice static list<clienteRta> productoUpdate(list<ProductoWS> lstProductos ){
        system.debug('MotosProductosSOAPWS: Entrando a productoUpdate'); 
        list <clienteRta> lstclienteRta = new list<clienteRta>();
        list <Product2> lstActualizar = new list<Product2>();
        try{
            RecordType rtMotosProducto = [SELECT id,DeveloperName FROM RecordType WHERE sobjecttype ='Product2' and isActive=true and DeveloperName =:Label.MotosRecordTypeDevNameProduct limit 1];
            
            //Get the products based on the Product Code, and map them
            set<String> setProductCodes = new set<String>();
            map<String,Product2> mapProductos = new map<String,Product2>();
            for(ProductoWS producto : lstProductos){
                setProductCodes.add(producto.MARA_MATNR);
            }
            for (Product2 p: [select Id, ProductCode from Product2 where RecordType.DeveloperName =:Label.MotosRecordTypeDevNameProduct and ProductCode  in:setProductCodes ]){
                mapProductos.put(p.ProductCode, p);
            }
            
            for(ProductoWS producto : lstProductos){
                System.debug(' ** REQUEST ** ' + producto);
                
                Product2 objProducto = new Product2 ();
                if (mapProductos.containsKey(producto.MARA_MATNR)) objProducto.Id = mapProductos.get(producto.MARA_MATNR).Id;
                objProducto.RecordTypeId= rtMotosProducto.Id;
                objProducto.ProductCode = producto.MARA_MATNR;
                objProducto.Segmento__c = producto.MARA_SEGMENT;
                objProducto.Referencia__c = producto.MARA_MKTXT;
                objProducto.Name = producto.MARA_MKTXT;
                objProducto.Ano_modelo__c = Integer.valueOf(producto.AUSP_MODELO);
                objProducto.Color__c = producto.AUSP_COLOR;
                objProducto.Family = producto.AUSP_LINEA;
                objProducto.isActive = producto.MARA_LVORM =='X' ? false : true;
                lstActualizar.add(objProducto);
            }
            
            if(lstActualizar.size()>0){
                system.debug('MotosProductosSOAPWS: Hay Elementos que actualizar: ' + lstActualizar.size()); 
                list <Database.SaveResult> SaveResult= database.update(lstActualizar,false);
                    
                Integer i=0;
                for(Database.SaveResult result : SaveResult){
                    Product2 c= lstActualizar.get(i);
                    clienteRta r= new clienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta='Operación exitosa';
                        r.error='';
                        r.idSF=c.id;
                    }else{
                        for(Database.Error e: result.getErrors()){
                            r.error='Error: '+e.getMessage();
                            r.MnsjRta ='Operación fallida';
                            r.idSF=c.id;
                        }
                    }
                    lstclienteRta.add(r);
                    i+=i;
                }
             } 
        }
        catch (System.exception ex) {
          clienteRta crta= new clienteRta();
          crta.error='ERROR: ' + ex.getMessage();
          crta.mnsjRta='Problemas en la ejecución del webservice'; 
          crta.idSF='';
          lstclienteRta.add(crta);
         }
        
        for(clienteRta rta: lstclienteRta){
            System.debug(' ** ERROR WEB SERVICE PRODUCTOS ** ' + rta);
        }
        system.debug('MotosProductosSOAPWS: Saliendo de productoUpdate'); 
        return lstclienteRta ;
    }
    
    /*
    global class PrecioWS{
      
        //LISTA DE PRECIO
        webservice string f126_id_lista_precio {get;set;} // Name
        
        //ENTRADA DE LISTA DE PRECIO
        webservice string f126_referencia_item {get;set;} // ProductCode
        webservice string f126_precio {get;set;} // UnitPrice
        webservice string f126_fecha_activacion {get;set;} // Fecha_activacion__c
        webservice string f126_fecha_inactivacion {get;set;} // IsActive    
        
    }
    webservice static list<ClienteRta> setPriceAuto(PrecioWS precio ) {    
        system.debug('MotosProductosSOAPWS: Entrando a setPriceAuto'); 
        list <clienteRta> lstclienteRta = new list<clienteRta>();
        list <PricebookEntry> lstUpsert = new list<PricebookEntry>();
        try{
        	PriceBook2 pb = [select Id, Name from PriceBook2 where Name=:precio.f126_id_lista_precio];
            Product2 product = [select Id from Product2 where ProductCode=:precio.f126_referencia_item];
            
        	list<PricebookEntry> pbes = [select Id from PricebookEntry where Product2Id=:product.Id and Pricebook2Id=:pb.Id];
            PricebookEntry pbe;
            if (pbes.size()==0) {
                pbe = new PriceBookEntry();
            	pbe.Pricebook2Id = pb.Id;
                pbe.Product2Id = product.Id;
                
                //Setear las fechas de activación e inactivación, crear los campos en pricebookentry
                //crear campo concatenado Auto/Moto + ProductCode en producto para que sea exclusivo y evitar duplicados
                //en el update de productos tanto en motos como en autos, debo filtrar solo los productos del correspondiente tipo de producto (auto o moto)
            }
            else pbe= pbes[0];
            
            pbe.UnitPrice = Decimal.valueof(precio.f126_precio);
        	pbe.Fecha_Activacion__c = Date.newInstance(Integer.valueOf(Precio.f126_fecha_activacion.left(4)), Integer.valueOf(Precio.f126_fecha_activacion.mid(4,2)), Integer.valueOf(Precio.f126_fecha_activacion.right(2)));
            if (precio.f126_fecha_inactivacion!=null && precio.f126_fecha_inactivacion!=''){
                pbe.Fecha_Inactivacion__c = Date.newInstance(Integer.valueOf(Precio.f126_fecha_inactivacion.left(4)), Integer.valueOf(Precio.f126_fecha_inactivacion.mid(4,2)), Integer.valueOf(Precio.f126_fecha_inactivacion.right(2)));
                pbe.IsActive = false;
            }
            
            lstUpsert.add(pbe);
            //upsert pbe;
            
            list <Database.UpsertResult> SaveResult= database.upsert(lstUpsert ,false);
                    
            Integer i=0;
            for(Database.UpsertResult result : SaveResult){
                PricebookEntry c= lstUpsert.get(i);
                clienteRta r= new clienteRta();
                if (result.isSuccess()){
                    r.MnsjRta='Operación exitosa';
                    r.error='';
                    r.idSF=c.id;
                }else{
                    for(Database.Error e: result.getErrors()){
                        r.error='Error: '+e.getMessage()+' Campos '+e.getFields();
                        r.MnsjRta ='Operación fallida';
                        r.idSF=c.id;
                    }
                }
                lstclienteRta.add(r);
                i+=i;
            }
		}
        catch (System.exception ex) {
          clienteRta crta= new clienteRta();
          crta.error='ERROR';
          crta.mnsjRta='Problemas en la ejecución del webservice'; 
          crta.idSF='';
          lstclienteRta.add(crta);
         }
        
        for(clienteRta rta: lstclienteRta){
            System.debug(' ** ERROR WEB SERVICE PRODUCTOS ** ' + rta);
        }
        system.debug('MotosProductosSOAPWS: Saliendo de setPriceAuto'); 
        return lstclienteRta ;
    }
    */
    
}