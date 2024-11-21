/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Integration class for creating and updating Products in Saleforce with SOAP.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     09/11/2020      Juan Ansaldi            Class definition.
* @version  1.1     12/11/2020      Juan Ansaldi            Class finished and succesfully creates or updates Products from external system. 
*********************************************************************************************************/
global class AutosProductosSOAPWS {
    
    global class AutosProductoWS {
        //PRODUCTOS
        webservice string f121_ind_estado {get;set;} //isActive
        webservice string f120_id {get;set;} // ProductCode
        webservice string f120_descripcion  {get;set;} // Descripción
        webservice string f120_descripcion_corta {get;set;} // Name
        webservice string f120_referencia  {get;set;} // Referencia__c
        webservice string f200_linea {get;set;} // Marca__c
        webservice string f300_grupo {get;set;} // Tipo de vehiculo
        webservice string f350_ancho {get;set;} // Carroceria
        webservice string f400_forma {get;set;} // Año modelo
        webservice string f500_subclase {get;set;} // Cilindraje
        webservice string f550_largo {get;set;} // No puertas
        webservice string H30_Honda_modelos_autos {get;set;} // Linea version
        webservice string H40_familia_de_vehiculos {get;set;} // Linea
        webservice string H80_Honda_proveedores {get;set;} // Manufactura origen
        webservice string I01_Alto_y_Origen {get;set;} // Area
        webservice string SGA_Hac_Prod_Subsegmento {get;set;} // Segmento
        webservice string TVA_Hac_prod_tipo_venta {get;set;} // Tipo_de_auto__c
        webservice string ZAD_Hac_prod_Color {get;set;} // Color__c
        webservice string f104_id_vehiculo {get;set;} // Clase_de_Vehiculo__c
        webservice string f104_id_motor {get;set;} // Numero_de_Motor__c
        webservice string f104_id_caja {get;set;} // Tipo_de_Caja__c
        webservice string f104_id_modelo {get;set;} // Modelo_Ao__c
        webservice string f104_id_pasajeros {get;set;} // No_Pasajeros__c
        webservice string f104_id_servicio {get;set;} // Tipo_de_servicio__c
        webservice string f104_id_fasecolda {get;set;} // Fasecolda__c
        webservice string f104_id_fecha_compra {get;set;} // Fecha_Compra__c
        webservice string f104_id_combustible {get;set;} // Tipo_de_combustible__c
        webservice string f104_id_traccion {get;set;} // Traccin__c
        webservice string f104_id_placa {get;set;} // Ciudad_de_la_placa__c 
        webservice string f104_id_chasis {get;set;} // Chasis__c 
        webservice string f104_id_extension_color {get;set;} //Extension_color__c
        webservice string f104_id_marca {get;set;} //Marca_usado__c
        webservice string f104_id_linea {get;set;} //Linea_usado__c
        webservice string f104_id_cilindraje {get;set;} // Cilindraje_usado__c
        webservice string f104_id_carroceria {get;set;} //Carroceria_usado__c
        webservice string referencia_comercial {get;set;} //Referencia_comercial__c
    }
    
    global class AutosClienteRta{
        webservice String error {get;set;}
        webservice String MnsjRta {get;set;}
        webservice String idSF {get;set;}
    }
    
    webservice static list<AutosClienteRta> CrearProducto(list<AutosProductoWS> lstproducto ) {
        list <AutosClienteRta> lstclienteRta = new list<AutosClienteRta>();
        list <Product2> lstinsertpr = new list<Product2>();
        RecordType rtAutosProducto = [SELECT Id, DeveloperName FROM RecordType 
                                          WHERE sobjecttype ='Product2' and isActive=true and 
                                          DeveloperName =:Label.AutosRecordTypeDevNameProduct limit 1];
        
        try{
           
            for(AutosProductoWS producto : lstproducto){               
                Product2 objProducto = new Product2();
                objProducto.RecordTypeId = rtAutosProducto.Id;
                objProducto.Name = producto.f120_descripcion;
                if(producto.f121_ind_estado == '0') {
                    objProducto.IsActive = false;
                } else if(producto.f121_ind_estado == '1') {
                    objProducto.IsActive = true;
                }
                objProducto.ProductCode = producto.f120_id;
                objProducto.Description = producto.f120_descripcion_corta;
                objProducto.Referencia__c = producto.f120_referencia;
                objProducto.Marca__c = producto.f200_linea;
                objProducto.Tipo_de_veh_culo__c = producto.f300_grupo;
                objProducto.Carrocera__c = producto.f350_ancho;
                if (producto.f400_forma != null || producto.f400_forma != '') {
                    objProducto.Ano_modelo__c = Integer.valueOf(producto.f400_forma);
                }
                objProducto.Cilindraje__c = producto.f500_subclase;
                objProducto.Nmero_de_Puertas__c = producto.f550_largo;
                objProducto.Version__c = producto.H30_Honda_modelos_autos;
                objProducto.Linea__c = producto.H40_familia_de_vehiculos;
                objProducto.Manufactura_origen__c = producto.H80_Honda_proveedores;
                objProducto.Area__c = producto.I01_Alto_y_Origen;
                objProducto.Segmento__c = producto.SGA_Hac_Prod_Subsegmento;
                objProducto.Tipo_de_auto__c = producto.TVA_Hac_prod_tipo_venta;
                objProducto.Color__c = producto.ZAD_Hac_prod_Color;     
                objProducto.Clase_de_Vehiculo__c = producto.f104_id_vehiculo;
                objProducto.Numero_de_Motor__c = producto.f104_id_motor;
                objProducto.Numero_de_Chasis__c = producto.f104_id_chasis;
                objProducto.Caja__c = producto.f104_id_caja;
                objProducto.Referencia_comercial__c = producto.referencia_comercial;
                if (producto.f104_id_modelo != null || producto.f104_id_modelo != '') {
                    objProducto.Ano_modelo_usado__c = Integer.valueOf(producto.f104_id_modelo);
                }
                if (producto.f104_id_pasajeros != null || producto.f104_id_pasajeros != '') {
                    objProducto.No_Pasajeros__c = Integer.valueOf(producto.f104_id_pasajeros);
                }

                objProducto.Tipo_de_servicio__c = producto.f104_id_servicio;
                objProducto.Fasecolda__c = producto.f104_id_fasecolda;
                
                
                objProducto.Tipo_de_combustible__c = producto.f104_id_combustible;
                objProducto.Traccin__c = producto.f104_id_traccion;
                List<AM_Municipio__c> mun = [Select Id from AM_Municipio__c where Name LIKE :'%' + producto.f104_id_placa + '%' Limit 1];
                if(mun.size() > 0 &&  producto.f104_id_placa != '-'  &&  producto.f104_id_placa != null) {
                    objProducto.Ciudad_de_la_placa__c = mun[0].Id;
                }
                /*objProducto.Marca_usado__c = producto.f104_id_marca;
                objProducto.Linea_usado__c = producto.f104_id_linea;
                objProducto.Carroceria_usado__c = producto.f104_id_carroceria;
                objProducto.Cilindraje_usado__c = producto.f104_id_cilindraje;*/
                objProducto.Extension_color__c = producto.f104_id_extension_color;
                
                objProducto.Tipo_Producto__c = 'Nuevos / Renting';

                string fechaERP = producto.f104_id_fecha_compra; 
                if(fechaERP != null && fechaERP != ''){
                    fechaERP = fechaERP.right(4) + '-' + fechaERP.left(5).right(2) + '-' + fechaERP.left(2);
                    date convertFecha = Date.valueOf(fechaERP);
                    objProducto.Fecha_Compra__c = convertFecha; 
                }
                
                lstinsertpr.add(objProducto);
            }
            
            List<Pricebook2> lstPricebook = new List<Pricebook2> ();
            Set<String> priceBookCode = new Set<String> ();
            List<Product2> lstProductInsert = new List<Product2> ();
            if(lstinsertpr.size()>0){
                list <Database.saveResult> insertResult = database.insert(lstinsertpr, false);
                
                Integer i=0;
                for(Database.saveResult result : insertResult){
                    Product2 c = lstinsertpr.get(i);
                    AutosClienteRta r = new AutosClienteRta();
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
            
        }
        catch(DmlException ex){
            AutosClienteRta crta= new AutosClienteRta();
            crta.error='ERROR';
            crta.mnsjRta=ex.getMessage();//'Problemas en la ejecución del webservice'; 
            crta.idSF='';
            lstclienteRta.add(crta);
        }
        catch (System.exception ex) {
            AutosClienteRta crta= new AutosClienteRta();
            crta.error='ERROR';
            crta.mnsjRta=ex.getMessage();//'Problemas en la ejecución del webservice'; 
            crta.idSF='';
            lstclienteRta.add(crta);
        }
        
        for(AutosClienteRta rta: lstclienteRta){
            System.debug(' ** ERROR WEB SERVICE CLIENTES ** ' + rta);
        }
        return lstclienteRta;
    }
    
    webservice static list<AutosClienteRta> ModificarProducto(list<AutosProductoWS> lstproducto ) {
        list <AutosClienteRta> lstclienteRta = new list<AutosClienteRta>();
        list <Product2> lstinsertpr = new list<Product2>();
        try{
           
            RecordType rtAutosProducto = [SELECT Id, DeveloperName FROM RecordType 
                                          WHERE sobjecttype ='Product2' and isActive=true and 
                                          DeveloperName =:Label.AutosRecordTypeDevNameProduct limit 1];
             //Get the products based on the Product Code, and map them
            set<String> setProductCodes = new set<String>();
            map<String, Product2> mapProductos = new map<String,Product2>();
            for(AutosProductoWS producto : lstproducto){
                setProductCodes.add(producto.f120_id);
            }
            for (Product2 p: [select Id, ProductCode from Product2 where RecordType.DeveloperName =:Label.AutosRecordTypeDevNameProduct and ProductCode  in:setProductCodes ]){
                mapProductos.put(p.ProductCode, p);
            }
            
            for(AutosProductoWS producto : lstproducto){
                                                                   
                Product2 objProducto = new Product2();
                if (mapProductos.containsKey(producto.f120_id)) objProducto.Id = mapProductos.get(producto.f120_id).Id;
                objProducto.RecordTypeId = rtAutosProducto.Id;
                objProducto.Name = producto.f120_descripcion_corta;
                if(producto.f121_ind_estado == '0') {
                    objProducto.IsActive = false;
                } else if(producto.f121_ind_estado == '1') {
                    objProducto.IsActive = true;
                }
                objProducto.Description = producto.f120_descripcion;
                objProducto.Referencia__c = producto.f120_referencia;
                objProducto.Marca__c = producto.f200_linea;
                objProducto.Tipo_de_veh_culo__c = producto.f300_grupo;
                objProducto.Carrocera__c = producto.f350_ancho;
                if (producto.f400_forma != null || producto.f400_forma != '') {
                    objProducto.Ano_modelo__c = Integer.valueOf(producto.f400_forma);
                }
                objProducto.Cilindraje__c = producto.f500_subclase;
                objProducto.Nmero_de_Puertas__c = producto.f550_largo;
                objProducto.Version__c = producto.H30_Honda_modelos_autos;
                objProducto.Linea__c = producto.H40_familia_de_vehiculos;
                objProducto.Manufactura_origen__c = producto.H80_Honda_proveedores;
                objProducto.Area__c = producto.I01_Alto_y_Origen;
                objProducto.Segmento__c = producto.SGA_Hac_Prod_Subsegmento;
                objProducto.Tipo_de_auto__c = producto.TVA_Hac_prod_tipo_venta;
                objProducto.Color__c = producto.ZAD_Hac_prod_Color;     
                objProducto.Clase_de_Vehiculo__c = producto.f104_id_vehiculo;
                objProducto.Numero_de_Motor__c = producto.f104_id_motor;
                objProducto.Numero_de_Chasis__c = producto.f104_id_chasis;
                objProducto.Caja__c = producto.f104_id_caja;
                objProducto.Referencia_comercial__c = producto.referencia_comercial;
                if (producto.f104_id_modelo != null || producto.f104_id_modelo != '') {
                    objProducto.Ano_modelo_usado__c = Integer.valueOf(producto.f104_id_modelo);
                }
                if (producto.f104_id_pasajeros != null || producto.f104_id_pasajeros != '') {
                    objProducto.No_Pasajeros__c = Integer.valueOf(producto.f104_id_pasajeros);
                }
                objProducto.Tipo_de_servicio__c = producto.f104_id_servicio;
                objProducto.Fasecolda__c = producto.f104_id_fasecolda;
                string fechaERP = producto.f104_id_fecha_compra; 
                if(fechaERP != null || fechaERP != ''){
                    fechaERP = fechaERP.right(4) + '-' + fechaERP.left(5).right(2) + '-' + fechaERP.left(2);
                    date convertFecha = Date.valueOf(fechaERP);
                    objProducto.Fecha_Compra__c = convertFecha; 
                }
                objProducto.Tipo_de_combustible__c = producto.f104_id_combustible;
                objProducto.Traccin__c = producto.f104_id_traccion;
                List<AM_Municipio__c> mun = [Select Id from AM_Municipio__c where Name LIKE :'%' + producto.f104_id_placa + '%' Limit 1];
                if(mun.size() > 0 &&  producto.f104_id_placa != '-' &&  producto.f104_id_placa != null) {
                    objProducto.Ciudad_de_la_placa__c = mun[0].Id;
                }  
                /*objProducto.Marca_usado__c = producto.f104_id_marca;
                objProducto.Linea_usado__c = producto.f104_id_linea;
                objProducto.Carroceria_usado__c = producto.f104_id_carroceria;
                objProducto.Cilindraje_usado__c = producto.f104_id_cilindraje;*/
                objProducto.Extension_color__c = producto.f104_id_extension_color;

                lstinsertpr.add(objProducto);
            }
            
            if(lstinsertpr.size()>0){
                list <Database.SaveResult> SaveResult= database.update(lstinsertpr,false);
                
                Integer i=0;
                for(Database.SaveResult result : SaveResult){
                    Product2 p = lstinsertpr.get(i);
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
    
    
    //////////////////Clase y Metodo para Actualizar el precio de los autos////////////////////////////
    global class PrecioWS{
      
        //LISTA DE PRECIO
        webservice string f126_id_lista_precio {get;set;} // Name
        
        //ENTRADA DE LISTA DE PRECIO
        webservice string f126_referencia_item {get;set;} // ProductCode
        webservice string f126_precio {get;set;} // UnitPrice
        webservice string f126_fecha_activacion {get;set;} // Fecha_activacion__c
        webservice string f126_fecha_inactivacion {get;set;} // IsActive    
        
    }
    
    webservice static list<AutosClienteRta> setPriceAuto(PrecioWS precio ) {    
        list <AutosClienteRta> lstclienteRta = new list<AutosClienteRta>();
        list <PricebookEntry> lstUpsert = new list<PricebookEntry>();
        try{   
            List<PriceBook2> lstPBooks = New List<PriceBook2>();
            PriceBook2 pb;
            if(precio.f126_id_lista_precio == 'LCV') {
               lstPBooks = [select Id, Name from PriceBook2 where Name = 'Autos'];
               pb = lstPBooks[0];
            } else {
                lstPBooks = [select Id, Name from PriceBook2 where Name=:precio.f126_id_lista_precio];
                if (lstPBooks.size()==0) {
                    pb = New Pricebook2(Name=precio.f126_id_lista_precio, IsActive=true);
                    Insert pb;
                } else { 
                    pb = lstPBooks[0];
                }
            }
            
            list<Product2> lstProduct = [select Id, Name from Product2 where RecordType.DeveloperName =:Label.AutosRecordTypeDevNameProduct and ProductCode=:precio.f126_referencia_item  ];
            Product2 product;
            if (lstProduct.size()==0) Throw new DmlException('Auto "' + precio.f126_referencia_item + '" no encontrado.');
            else product = lstProduct[0];
            
            list<PricebookEntry> pbes = [select Id,Fecha_Inactivacion__c from PricebookEntry where Product2Id=:product.Id and Pricebook2Id=:pb.Id];
            PricebookEntry pbe;
            if (pbes.size()==0) {
                pbe = new PriceBookEntry();
                pbe.Pricebook2Id = pb.Id;
                pbe.Product2Id = product.Id;
            }
            else pbe = pbes[0];
            
            if(precio.f126_precio != null && precio.f126_precio != '')
            {
                    if(product.Name.Contains('HEV') ) {
                        pbe.UnitPrice = Decimal.valueof(precio.f126_precio) * Decimal.valueOf(Label.Etiqueta1_13);
                        pbe.UnitPrice = Math.round(pbe.UnitPrice);
                    } else if(product.Name.Contains('10A') ) {
                        pbe.UnitPrice = Decimal.valueof(precio.f126_precio) * Decimal.valueOf(Label.Etiqueta1_35);
                        pbe.UnitPrice = Math.round(pbe.UnitPrice);
                    } else {
                        pbe.UnitPrice = Decimal.valueof(precio.f126_precio) * Decimal.valueOf(Label.Etiqueta1_27);
                        pbe.UnitPrice = Math.round(pbe.UnitPrice);
                    }
                
            }
            if(precio.f126_fecha_activacion != null && precio.f126_fecha_activacion != '') pbe.Fecha_Activacion__c = Date.newInstance(Integer.valueOf(Precio.f126_fecha_activacion.right(4)), Integer.valueOf(Precio.f126_fecha_activacion.left(5).right(2)), Integer.valueOf(Precio.f126_fecha_activacion.left(2)));
            if (precio.f126_fecha_inactivacion!=null && precio.f126_fecha_inactivacion!=''){
                pbe.Fecha_Inactivacion__c = Date.newInstance(Integer.valueOf(Precio.f126_fecha_inactivacion.right(4)), Integer.valueOf(Precio.f126_fecha_inactivacion.left(5).right(2)), Integer.valueOf(Precio.f126_fecha_inactivacion.left(2)));
            }else{
                if (pbe.Fecha_Inactivacion__c!=null) pbe.Fecha_Inactivacion__c = null;
            }
            pbe.IsActive = true;
            
            lstUpsert.add(pbe);
            //upsert pbe;
            
            list <Database.UpsertResult> SaveResult= database.upsert(lstUpsert ,false);
                    
            Integer i=0;
            for(Database.UpsertResult result : SaveResult){
                PricebookEntry c= lstUpsert.get(i);
                AutosClienteRta r= new AutosClienteRta();
                if (result.isSuccess()){
                    r.MnsjRta='Operación exitosa';
                    r.error='';
                    r.idSF=c.id;
                }else{
                    for(Database.Error e: result.getErrors()){
                        r.error='Error: ' +e.getMessage();//+' Campos '+e.getFields();
                        r.MnsjRta ='Operación fallida';
                        r.idSF=c.id;
                    }
                }
                lstclienteRta.add(r);
                i+=i;
            }
        }
        catch (System.exception ex) {
          AutosClienteRta crta= new AutosClienteRta();
          crta.error='ERROR: ' + ex.getMessage();// + ex.getLineNumber();
          crta.mnsjRta='Problemas en la ejecución del webservice'; 
          crta.idSF='';
          lstclienteRta.add(crta);
         }
        
        for(AutosClienteRta rta: lstclienteRta){
            System.debug(' ** ERROR WEB SERVICE PRODUCTOS ** ' + rta);
        }
        return lstclienteRta ;
    }
}