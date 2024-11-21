/**
* Fanalca
* @author           Jonathan Parrales
* Description:      Web Service class to create/update data.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     05/11/2020      Jonathan Parrales       Class definition.
* @version  1.1     09/11/2020      Jonathan Parrales       Duplicate Error handle, to return Id of duplicate accout     
* @version  1.2     14/12/2020      Jonathan Parrales       Search by numero and tipo documento when creating, if exists update not create  
* @version  1.3     2021/01/18      Jonathan Parrales       Modify in cliente Update, now search for document after not find by codigo erp, and create the account when no account is found
*********************************************************************************************************/
global class MotosClienteSOAPWS {
    global class ClienteWS{
        webservice string KNA1_KUNNR_KNA1_STCD1 {get;set;} //ID Cliente SF
        webservice string KNA1_STCDT {get;set;} //AM_Tipo_de_documento__c
        webservice string KNA1_STCD1 {get;set;} //AM_Numero_de_documento__c
        webservice string KNA1_ANRED {get;set;}
        webservice string KNA1_NAME1 {get;set;}
        webservice string KNA1_NAME3_SEGMENTO1 {get;set;}
        webservice string KNA1_NAME3_SEGMENTO2 {get;set;}
        webservice string KNA1_NAME4_SEGMENTO1 {get;set;}
        webservice string KNA1_NAME4_SEGMENTO2 {get;set;}
        webservice string KNA1_CEL_NUMBER {get;set;}
        webservice string ADR6_SMTP_ADDR {get;set;} //AM_Correo_Electronico_Trabajo__c o PersonEmail
        webservice string KNA1_ORT01 {get;set;}
        webservice string KNA1_STREET {get;set;}
        webservice string KNA1_REGIO {get;set;}
        webservice string KNA1_LAND1 {get;set;}
        webservice string KNA1_TELF1 {get;set;}        
        webservice string KNA1_SKFTO {get;set;}
        webservice string KNA1_STKZN {get;set;} //Record Type X paa persona natural, empty para jurídia
        webservice String FNACIM {get; set;}
        webservice boolean PermisoContacto {get; set;}
        webservice boolean AutorizaTratamientoDatosPersonales {get; set;}
        webservice string OrganizacionVentas {get;set;}
    }
    
    global class ClienteRta{
        webservice String error {get;set;}
        webservice String MnsjRta {get;set;}
        webservice String idSF {get;set;}
    }
    
    webservice static list<clienteRta> clienteAdd(list<clienteWS> lstcliente ){
        system.debug('MotosClientesSOAPWS: Entrando a clienteAdd'); 
        list <clienteRta> lstclienteRta = new list<clienteRta>();
         list <Account> insertacct = new list<Account>();
        //list <Account> updateacct = new list<Account>();
        try{
            //Get the Municipios and map them
            //Municipios tiene unos codigos que sirvirian para departamento y municipio
            //municipio KNA1-ORT01 char 5, pais KNA1-LAND1 char 2
            set<String> setMunicipioDANECodes = new set<String>();
            set<String> setDepartamentoDANECodes = new set<String>();
            set<String> setTipoDocumentos = new set<String>();
            set<String> setNumeroDocumentos = new set<String>();
            map<String, Account> mapCuentasxDocumento = new map<String, Account>();
            //map<String,AM_Municipio__c> mapMunicipios = new map<String,AM_Municipio__c>();
            //Mapa que contiene como key el codigo dane del departamento y como valor, mapa de los municipios de ese departamento
            map<String,map<string,AM_Municipio__c>> mapMunicipios = new map<String,map<string,AM_Municipio__c>>();
            //Converting codes like 012 to 12, without the 0 in left position, 'cause the object municipio__c doesn´t save a 0 in the left position
            for(clienteWS cliente : lstcliente){
                cliente.KNA1_ORT01 = cliente.KNA1_ORT01.trim();//string.valueOf(integer.valueOf(cliente.KNA1_ORT01));
                cliente.KNA1_REGIO = cliente.KNA1_REGIO.trim();//string.valueOf(integer.valueOf(cliente.KNA1_REGIO));
                setMunicipioDANECodes.add(cliente.KNA1_ORT01);
                setDepartamentoDANECodes.add(cliente.KNA1_REGIO);
                
                setTipoDocumentos.add(Utilities.getTipoDocumentoSAP_To_SF(cliente.KNA1_STCDT));
                setNumeroDocumentos.add(cliente.KNA1_STCD1);
            }
            //for (AM_Municipio__c m: [select Id,AM_Codigo_DANE_municipio__c,AM_Codigo_DANE_departamento__c from AM_Municipio__c 
            //                         where AM_Codigo_DANE_municipio__c in:setMunicipioDANECodes and AM_Codigo_DANE_departamento__c in:setDepartamentoDANECodes]){
            //	if (mapMunicipios.containsKey(m.AM_Codigo_DANE_departamento__c)){
            //    	mapMunicipios.get(m.AM_Codigo_DANE_departamento__c).put(m.AM_Codigo_DANE_municipio__c, m);                           
            //    }else{
            //        mapMunicipios.put(m.AM_Codigo_DANE_departamento__c, new map<string,AM_Municipio__c>{m.AM_Codigo_DANE_municipio__c => m});
            //    }
            //}
            for (AM_Municipio__c m: [select Id,ID_POBLACION_SAP__c,ID_REGION_SAP__c from AM_Municipio__c 
                                     where ID_POBLACION_SAP__c in:setMunicipioDANECodes and ID_REGION_SAP__c in:setDepartamentoDANECodes]){
            	if (mapMunicipios.containsKey(m.ID_REGION_SAP__c)){
                	mapMunicipios.get(m.ID_REGION_SAP__c).put(m.ID_POBLACION_SAP__c, m);                           
                }else{
                    mapMunicipios.put(m.ID_REGION_SAP__c, new map<string,AM_Municipio__c>{m.ID_POBLACION_SAP__c => m});
                }
            }
            
            //Mapear cuentas para luego verificar si existen o no
            for (Account a: [select Id, AM_Tipo_de_documento__c,AM_Numero_de_documento__c from Account where AM_Tipo_de_documento__c in:setTipoDocumentos and AM_Numero_de_documento__c in:setNumeroDocumentos]){
                mapCuentasxDocumento.put(a.AM_Tipo_de_documento__c + a.AM_Numero_de_documento__c,a);
            }
            //Get the account record type for Motos
            RecordType rtMotosNatural;
            RecordType rtMotosJuridica;
            for (RecordType rt: [SELECT id,DeveloperName FROM RecordType WHERE sobjecttype ='Account' and isActive=true]){
                if (rt.DeveloperName == Label.MotosRecordTypeDevNameAccountNatural) rtMotosNatural = rt;
                if (rt.DeveloperName == Label.MotosRecordTypeDevNameAccountJuridica) rtMotosJuridica = rt;
            }
            
            for(clienteWS cliente : lstcliente){
                System.debug(' ** REQUEST ** ' + cliente);
                
                Account objCliente = new Account ();
					objCliente.Codigo_ERP__c = cliente.KNA1_KUNNR_KNA1_STCD1;
                  //Si el cliente es jurídico
                if (cliente.KNA1_STKZN==null || cliente.KNA1_STKZN==''){
                	objCliente.RecordTypeId = rtMotosJuridica.Id; 
                    objCliente.Name = cliente.KNA1_NAME1;
                    objCliente.AM_Correo_Electronico_Trabajo__c = cliente.ADR6_SMTP_ADDR; 
                    objCliente.Autoriza_Tratamiento_Datos_Personales__c = cliente.AutorizaTratamientoDatosPersonales==true ? 'Si' : 'No';
                }else{
                    objCliente.RecordTypeId = rtMotosNatural.ID;
                    objCliente.Salutation = Utilities.getSalutationSAP_To_SF(cliente.KNA1_ANRED); //mapeo, en el doc dice char 4 y en sf es un picklist señra,señor
                    objCliente.Primer_Nombre__c = cliente.KNA1_NAME3_SEGMENTO1;
                    objCliente.FirstName = cliente.KNA1_NAME3_SEGMENTO1;
                    objCliente.Segundo_Nombre__c = cliente.KNA1_NAME3_SEGMENTO2;
                    objCliente.LastName = cliente.KNA1_NAME4_SEGMENTO1;
                    objCliente.Primer_Apellido__c = cliente.KNA1_NAME4_SEGMENTO1;
                    objCliente.Segundo_Apellido__c = cliente.KNA1_NAME4_SEGMENTO2;
                    objCliente.PersonEmail = cliente.ADR6_SMTP_ADDR;
                    objCliente.PersonMobilePhone = cliente.KNA1_CEL_NUMBER;
                    
                    if (cliente.FNACIM!=null && cliente.FNACIM!=''){
                        objCliente.PersonBirthdate = Date.newInstance(Integer.valueOf(cliente.FNACIM.left(4)), Integer.valueOf(cliente.FNACIM.mid(4,2)), Integer.valueOf(cliente.FNACIM.right(2)));
                    }else{
                        objCliente.PersonBirthdate = null;
                    }
                    //objCliente.Permiso_de_contacto_del__pc = cliente.PermisoContacto==true ? 'Autorizado' : 'No Autorizado';
                    //objCliente.Permiso_de_Contacto__c = cliente.PermisoContacto==true ? 'Autorizado' : 'No Autorizado';
                    objCliente.Autoriza_Tratamiento_de_Datos_personale__pc = cliente.AutorizaTratamientoDatosPersonales==true ? 'Si' : 'No';
                }
                
                objCliente.Permiso_de_Contacto__c = cliente.PermisoContacto==true ? 'Autorizado' : 'No Autorizado';
                //objCliente.Id = (cliente.KNA1_KUNNR_KNA1_STCD1==null || cliente.KNA1_KUNNR_KNA1_STCD1=='') ? null : cliente.KNA1_KUNNR_KNA1_STCD1; //si tiene algún valor, enviará error cuando intente insertarlo
                objCliente.AM_Tipo_de_documento__c  = Utilities.getTipoDocumentoSAP_To_SF(cliente.KNA1_STCDT); //mapeo, en el doc dice char 2 y en sf es un picklist
                objCliente.AM_Numero_de_documento__c = cliente.KNA1_STCD1;
                objCliente.Organizacion_Ventas__c = cliente.OrganizacionVentas;
                //objCliente.Phone = cliente.KNA1_CEL_NUMBER;  
                //objCliente.AM_Ciudad__c = mapMunicipios.containsKey(cliente.KNA1_ORT01) ? mapMunicipios.get(cliente.KNA1_ORT01).Id : null;//cliente.KNA1_ORT01; //TODO this is lookup
                if (mapMunicipios.containsKey(cliente.KNA1_REGIO) && mapMunicipios.get(cliente.KNA1_REGIO).containsKey(cliente.KNA1_ORT01)){
                    objCliente.AM_Ciudad__c = mapMunicipios.get(cliente.KNA1_REGIO).get(cliente.KNA1_ORT01).Id;
                }else
                    throw new DMLException('Ciudad no Encontrada');  
                objCliente.DireccionERP__c = cliente.KNA1_STREET;//objCliente.AM_Direccion__c = cliente.KNA1_STREET; formula field se guardara en un campo nuevo DireccionERP
                //objCliente.Departamento__c = cliente.KNA1_REGIO; no existe en account tal vez no necesario
                //objCliente.Pais__c = cliente.KNA1_LAND1; //Pais__c no existe en account
                objCliente.Phone = cliente.KNA1_TELF1;
                objCliente.AM_Estado__c = cliente.KNA1_SKFTO=='' ? 'Activo' : 'Inactivo'; //Checar si realmente es este campo (picklist), en el doc no aparece el nombre del campo, y mas bien aparece vacio y tipo boolean
               
                //objCliente.BillingCountry = cliente.KNA1_LAND1;
                //objCliente.BillingCity = cliente.KNA1_ORT01;
                //objCliente.BillingState = cliente.KNA1_REGIO;
                //objCliente.BillingStreet =cliente.KNA1_STREET;
                objCliente.Tipo_de_cuenta__c ='Cliente';
                if (mapCuentasxDocumento.containsKey(objCliente.AM_Tipo_de_documento__c+objCliente.AM_Numero_de_documento__c)){
                    objCliente.Id=mapCuentasxDocumento.get(objCliente.AM_Tipo_de_documento__c+objCliente.AM_Numero_de_documento__c).Id;
                    //updateacct.add(objCliente);
                }//else{
                //	insertacct.add(objCliente);            
                //}
                insertacct.add(objCliente);     
              	
			}
             
             if(insertacct.size()>0){
                 system.debug('MotosClientesSOAPWS: Hay Elementos que insertar: ' + insertacct.size()); 
                //Schema.SObjectField ExtId = Account.Fields.Codigo_SAP__c;
                list <Database.upsertResult> upsertResult= database.upsert(insertacct,false);//list <Database.SaveResult> SaveResult= database.insert(insertacct,false);//list <Database.upsertResult> upsertResult= database.upsert(insertacct,ExtId,false);
                    
                Integer i=0;
                for(Database.upsertResult result : upsertResult){//for(Database.SaveResult result : SaveResult){//for(Database.upsertResult result : upsertResult){
                    Account c= insertacct.get(i);
                    clienteRta r= new clienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta='Operación exitosa';
                        r.error='';
                        r.idSF=c.id;
                    }else{
                        for(Database.Error e: result.getErrors()){
                            if (e instanceof Database.DuplicateError){
                                // Handle the duplicate error by first casting it as a 
                                //   DuplicateError class
                                // This lets you use methods of that class 
                                //  (e.g., getDuplicateResult())
                                Database.DuplicateError duplicateError = 
                                        (Database.DuplicateError)e;
                                Datacloud.DuplicateResult duplicateResult = 
                                        duplicateError.getDuplicateResult();
                                //r.error='Error: '+ duplicateResult.getErrorMessage();
                                
                                // Get duplicate records
                                //list<sObject> duplicateRecords = new List<sObject>();
             
                                // Return only match results of matching rules that 
                                //  find duplicate records
                                Datacloud.MatchResult[] matchResults = 
                                        duplicateResult.getMatchResults();
             
                                // Just grab first match result (which contains the 
                                //   duplicate record found and other match info)
                                Datacloud.MatchResult matchResult = matchResults[0];
                                
                                Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                                
                                // Add matched record to the duplicate records variable
                               // for (Datacloud.MatchRecord matchRecord : matchRecords) {
                                //    System.debug('MatchRecord: ' + matchRecord.getRecord());
                                //    duplicateRecords.add(matchRecord.getRecord());
                                //}
                                
                                r.error='Error: Registro Duplicado Encontrado: ' + ' Name: ' + matchRecords[0].getRecord().get('Name') + ', Id: ' +matchRecords[0].getRecord().get('Id');
                                //r.MnsjRta ='El Cliente ya Existe';
                                r.idSF=(String)matchRecords[0].getRecord().get('Id');
                            }else{
                            	r.error='Error: '+e.getMessage() + ' ' + e.getFields();    
                                //r.MnsjRta ='Operación fallida';
                            	r.idSF=c.id;
                            }
                            //r.error='Error: '+e.getMessage()+' Campos '+e.getFields();
                            r.MnsjRta ='Operación fallida';
                            //r.idSF=c.id;
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
            System.debug(' ** ERROR WEB SERVICE CLIENTES ** ' + rta);
        }
        system.debug('MotosClientesSOAPWS: Saliendo de clienteAdd'); 
        return lstclienteRta ;
    }
    
    webservice static list<clienteRta> clienteUpdate(list<clienteWS> lstcliente ){
        system.debug('MotosClientesSOAPWS: Entrando a clienteUpdate'); 
        list <clienteRta> lstclienteRta = new list<clienteRta>();
         list <Account> insertacct = new list<Account>();
        try{
            //Get the Municipios and map them
            //Municipios tiene unos codigos que sirvirian para departamento y municipio
            //municipio KNA1-ORT01 char 5, pais KNA1-LAND1 char 2
            set<String> setMunicipioDANECodes = new set<String>();
            set<String> setDepartamentoDANECodes = new set<String>();
            set<String> setCodigosERP = new set<String>(); //Set de Codigos ERP para luego obtener las cuentas basadas en este codigo erp, y así tener el Id para realizar update
            set<String> setTipoDocumentos = new set<String>(); //Added: 20210118
            set<String> setNoDocumentos = new set<String>(); //Added: 20210118, Set de Documentos para luego obtener las cuentas basadas en este numero de documento, y así tener el Id para realizar update en caso de no encontrar con codigo erp
            map<String,Account> mapCuentas = new map<String,Account>();
            map<String,Account> mapCuentasXDocs = new map<String,Account>(); //Added: 20210118
            //map<String,AM_Municipio__c> mapMunicipios = new map<String,AM_Municipio__c>();
            //Mapa que contiene como key el codigo dane del departamento y como valor, mapa de los municipios de ese departamento
            map<String,map<string,AM_Municipio__c>> mapMunicipios = new map<String,map<string,AM_Municipio__c>>();
            //Converting codes like 012 to 12, without the 0 in left position, 'cause the object municipio__c doesn´t save a 0 in the left position
            for(clienteWS cliente : lstcliente){
                cliente.KNA1_ORT01 = cliente.KNA1_ORT01.Trim();//string.valueOf(integer.valueOf(cliente.KNA1_ORT01));
                cliente.KNA1_REGIO = cliente.KNA1_REGIO.trim();//string.valueOf(integer.valueOf(cliente.KNA1_REGIO));
                setMunicipioDANECodes.add(cliente.KNA1_ORT01);
                setDepartamentoDANECodes.add(cliente.KNA1_REGIO);
                setCodigosERP.add(cliente.KNA1_KUNNR_KNA1_STCD1);
                setTipoDocumentos.add(Utilities.getTipoDocumentoSAP_To_SF(cliente.KNA1_STCDT)); //Added: 20210118
                setNoDocumentos.add(cliente.KNA1_STCD1); //Added: 20210118
            }
            
            for (Account a: [select Id,Codigo_ERP__c from Account where Codigo_ERP__c in:setCodigosERP]){
                mapCuentas.put(a.Codigo_ERP__c,a);
            }
            for (Account a: [select Id,Codigo_ERP__c,AM_Tipo_de_documento__c,AM_Numero_de_documento__c from Account where AM_Tipo_de_documento__c in:setTipoDocumentos and AM_Numero_de_documento__c in:setNoDocumentos]){
                mapCuentasXDocs.put(a.AM_Tipo_de_documento__c + a.AM_Numero_de_documento__c,a);
            }    
            //for (AM_Municipio__c m: [select Id,AM_Codigo_DANE_municipio__c,AM_Codigo_DANE_departamento__c from AM_Municipio__c 
            //                         where AM_Codigo_DANE_municipio__c in:setMunicipioDANECodes and AM_Codigo_DANE_departamento__c in:setDepartamentoDANECodes]){
            //	if (mapMunicipios.containsKey(m.AM_Codigo_DANE_departamento__c)){
            //    	mapMunicipios.get(m.AM_Codigo_DANE_departamento__c).put(m.AM_Codigo_DANE_municipio__c, m);                           
            //    }else{
            //        mapMunicipios.put(m.AM_Codigo_DANE_departamento__c, new map<string,AM_Municipio__c>{m.AM_Codigo_DANE_municipio__c => m});
            //    }
            //}
            for (AM_Municipio__c m: [select Id,ID_POBLACION_SAP__c,ID_REGION_SAP__c from AM_Municipio__c 
                                     where ID_POBLACION_SAP__c in:setMunicipioDANECodes and ID_REGION_SAP__c in:setDepartamentoDANECodes]){
            	if (mapMunicipios.containsKey(m.ID_REGION_SAP__c)){
                	mapMunicipios.get(m.ID_REGION_SAP__c).put(m.ID_POBLACION_SAP__c, m);                           
                }else{
                    mapMunicipios.put(m.ID_REGION_SAP__c, new map<string,AM_Municipio__c>{m.ID_POBLACION_SAP__c => m});
                }
            }
            //Get the account record type for Motos
            RecordType rtMotosNatural;
            RecordType rtMotosJuridica;
            for (RecordType rt: [SELECT id,DeveloperName FROM RecordType WHERE sobjecttype ='Account' and isActive=true]){
                if (rt.DeveloperName == Label.MotosRecordTypeDevNameAccountNatural) rtMotosNatural = rt;
                if (rt.DeveloperName == Label.MotosRecordTypeDevNameAccountJuridica) rtMotosJuridica = rt;
            }
            
            for(clienteWS cliente : lstcliente){
                System.debug(' ** REQUEST ** ' + cliente);
                
                Account objCliente = new Account ();
                
                  //Si el cliente es jurídico
                if (cliente.KNA1_STKZN==null || cliente.KNA1_STKZN==''){
                	objCliente.RecordTypeId = rtMotosJuridica.Id; 
                    objCliente.Name = cliente.KNA1_NAME1;
                    objCliente.AM_Correo_Electronico_Trabajo__c = cliente.ADR6_SMTP_ADDR; 
                    objCliente.Autoriza_Tratamiento_Datos_Personales__c = cliente.AutorizaTratamientoDatosPersonales==true ? 'Si' : 'No';
                }else{
                    objCliente.RecordTypeId = rtMotosNatural.ID;
                    objCliente.Salutation = Utilities.getSalutationSAP_To_SF(cliente.KNA1_ANRED); //mapeo, en el doc dice char 4 y en sf es un picklist señra,señor
                    objCliente.Primer_Nombre__c = cliente.KNA1_NAME3_SEGMENTO1;
                    objCliente.FirstName = cliente.KNA1_NAME3_SEGMENTO1;
                    objCliente.Segundo_Nombre__c = cliente.KNA1_NAME3_SEGMENTO2;
                    objCliente.LastName = cliente.KNA1_NAME4_SEGMENTO1;
                    objCliente.Primer_Apellido__c = cliente.KNA1_NAME4_SEGMENTO1;
                    objCliente.Segundo_Apellido__c = cliente.KNA1_NAME4_SEGMENTO2;
                    objCliente.PersonEmail = cliente.ADR6_SMTP_ADDR;
                    objCliente.PersonMobilePhone = cliente.KNA1_CEL_NUMBER;
                    if (cliente.FNACIM!=null && cliente.FNACIM!=''){
                        objCliente.PersonBirthdate = Date.newInstance(Integer.valueOf(cliente.FNACIM.left(4)), Integer.valueOf(cliente.FNACIM.mid(4,2)), Integer.valueOf(cliente.FNACIM.right(2)));
                    }else{
                        objCliente.PersonBirthdate = null;
                    }
                    objCliente.Permiso_de_contacto_del__pc = cliente.PermisoContacto==true ? 'Autorizado' : 'No Autorizado';
                    objCliente.Autoriza_Tratamiento_de_Datos_personale__pc = cliente.AutorizaTratamientoDatosPersonales==true ? 'Si' : 'No';
                }
                
                //objCliente.Id = (cliente.KNA1_KUNNR_KNA1_STCD1==null || cliente.KNA1_KUNNR_KNA1_STCD1=='') ? null : cliente.KNA1_KUNNR_KNA1_STCD1; //si tiene algún valor, enviará error cuando intente insertarlo
                objCliente.Id = mapCuentas.get(cliente.KNA1_KUNNR_KNA1_STCD1)?.Id;
                if (objCliente.Id==null) objCliente.Id = mapCuentasXDocs.get(Utilities.getTipoDocumentoSAP_To_SF(cliente.KNA1_STCDT) + cliente.KNA1_STCD1)?.Id; //Added 20210118, si no encuentra por codigo erp, entonces buscar por tipo y numero de documento
                objCliente.Codigo_ERP__c = cliente.KNA1_KUNNR_KNA1_STCD1; //Added 20210118
                objCliente.AM_Tipo_de_documento__c  = Utilities.getTipoDocumentoSAP_To_SF(cliente.KNA1_STCDT); //mapeo, en el doc dice char 2 y en sf es un picklist
                objCliente.AM_Numero_de_documento__c = cliente.KNA1_STCD1;
                objCliente.Organizacion_Ventas__c = cliente.OrganizacionVentas;
                //objCliente.Phone = cliente.KNA1_CEL_NUMBER;  
                //objCliente.AM_Ciudad__c = mapMunicipios.containsKey(cliente.KNA1_ORT01) ? mapMunicipios.get(cliente.KNA1_ORT01).Id : null;//cliente.KNA1_ORT01; //TODO this is lookup
                if (mapMunicipios.containsKey(cliente.KNA1_REGIO) && mapMunicipios.get(cliente.KNA1_REGIO).containsKey(cliente.KNA1_ORT01)){
                    objCliente.AM_Ciudad__c = mapMunicipios.get(cliente.KNA1_REGIO).get(cliente.KNA1_ORT01).Id;
                }else
                    throw new DMLException('Ciudad no Encontrada'); 
                
                objCliente.DireccionERP__c = cliente.KNA1_STREET;//objCliente.AM_Direccion__c = cliente.KNA1_STREET; formula field se guardara en un campo nuevo DireccionERP
                //objCliente.Departamento__c = cliente.KNA1_REGIO; no existe en account tal vez no necesario
                //objCliente.Pais__c = cliente.KNA1_LAND1; //Pais__c no existe en account, revisar si existe en account, si no existe preguntar a catherine
                objCliente.Phone = cliente.KNA1_TELF1;
                objCliente.AM_Estado__c = cliente.KNA1_SKFTO=='' ? 'Activo' : 'Inactivo'; //Checar si realmente es este campo (picklist), en el doc no aparece el nombre del campo, y mas bien aparece vacio y tipo boolean
               
                //objCliente.BillingCountry = cliente.KNA1_LAND1;
                //objCliente.BillingCity = cliente.KNA1_ORT01;
                //objCliente.BillingState = cliente.KNA1_REGIO;
                //objCliente.BillingStreet =cliente.KNA1_STREET;
                system.debug('acc.Name' + objCliente.Name);
              	insertacct.add(objCliente);
			}
             
             if(insertacct.size()>0){
                 system.debug('MotosClientesSOAPWS: Hay Elementos que Actualizar: ' + insertacct.size()); 
                //Schema.SObjectField ExtId = Account.Fields.Codigo_SAP__c;
                list <Database.upsertResult> upsertResult= database.upsert(insertacct,false); //Changed 20210118 list <Database.SaveResult> SaveResult= database.update(insertacct,false);
                    
                Integer i=0;
                for(Database.upsertResult result : upsertResult){//for(Database.SaveResult result : SaveResult){// Changed 20210118
                    Account c= insertacct.get(i);
                    clienteRta r= new clienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta='Operación exitosa';
                        r.error='';
                        r.idSF=c.id;
                    }else{
                        for(Database.Error e: result.getErrors()){
                            if (e instanceof Database.DuplicateError){
                                // Handle the duplicate error by first casting it as a 
                                //   DuplicateError class
                                // This lets you use methods of that class 
                                //  (e.g., getDuplicateResult())
                                Database.DuplicateError duplicateError = 
                                        (Database.DuplicateError)e;
                                Datacloud.DuplicateResult duplicateResult = 
                                        duplicateError.getDuplicateResult();
       
                                // Return only match results of matching rules that 
                                //  find duplicate records
                                Datacloud.MatchResult[] matchResults = 
                                        duplicateResult.getMatchResults();
             
                                // Just grab first match result (which contains the 
                                //   duplicate record found and other match info)
                                Datacloud.MatchResult matchResult = matchResults[0];
                                
                                Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                                
                                r.error='Error: Registro Duplicado Encontrado: ' + ' Name: ' + matchRecords[0].getRecord().get('Name') + ', Id: ' +matchRecords[0].getRecord().get('Id');
                                r.idSF=(String)matchRecords[0].getRecord().get('Id');
                            }else{
                            	r.error='Error: '+e.getMessage();    
                            	r.idSF=c.id;
                            }
                            
                            //r.error='Error: '+e.getMessage()+' Campos '+e.getFields(); 
                            r.MnsjRta ='Operación fallida';
                            //r.idSF=c.id;
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
            System.debug(' ** ERROR WEB SERVICE CLIENTES ** ' + rta);
        }
        system.debug('MotosClientesSOAPWS: Saliendo de clienteUpdate'); 
        return lstclienteRta ;
    }
    
}