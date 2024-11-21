/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Integration class for creating and updating Accounts in Saleforce with SOAP.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     03/11/2020      Juan Ansaldi            Class definition.
* @version  1.1     09/11/2020      Juan Ansaldi            Class finished and succesfully creates or updates Accounts from external system. 
* @version  1.2     07/04/2021      Jonathan Parrales       Update method changes, to upsert instead of update 
*********************************************************************************************************/
global class AutosClienteSOAPWS {
    
    global class AutosClienteWS {
        webservice string F201_ID_SF {get;set;} //ID in SF for Update method, March 21, now is Codigo UNOEE in SF
        webservice string F200_IND_TIPO_TERCERO {get;set;}
        webservice string F207_ID_CRITERIO_MAYOR {get;set;}
        webservice string F201_IND_ESTADO_ACTIVO {get;set;}
        webservice string F200_ID_TIPO_IDENT {get;set;}
        webservice string F200_ID {get;set;}
        webservice string F200_RAZON_SOCIAL {get;set;}
        webservice string F200_NOMBRES {get;set;}
        webservice string F200_APELLIDO1 {get;set;}
        webservice string F200_APELLIDO2 {get;set;}
        webservice string F015_TELEFONO {get;set;}
        webservice string F015_EMAIL {get;set;}
        webservice string F015_ID_PAIS {get;set;}
        webservice string F015_ID_DEPTO {get;set;}
        webservice string F015_ID_CIUDAD {get;set;}
        webservice string F015_DIRECCION1 {get;set;}
        webservice string F015_CELULAR {get;set;}        
        webservice string F200_FECHA_NACIMIENTO {get;set;}
        webservice string F201_ID_SUCURSAL {get;set;}
        webservice string F200_IND_ESTADO {get;set;}
    }
    
    global class AutosClienteRta{
        webservice String error {get;set;}
        webservice String MnsjRta {get;set;}
        webservice String idSF {get;set;}
    }
    
    webservice static list<AutosClienteRta> CrearCliente(list<AutosClienteWS> lstcliente ) {
        list <AutosClienteRta> lstclienteRta = new list<AutosClienteRta>();
        list <Account> insertacct = new list<Account>();
        try{
            //Get the Municipios and map them
            set<String> setMunicipioDANECodes = new set<String>();
            set<String> setDepartamentoDANECodes = new set<String>();
            set<String> setTipoDocumentos = new set<String>();
            set<String> setNumeroDocumentos = new set<String>();
            map<String, Account> mapCuentasxDocumento = new map<String, Account>();
            
            map<String, map<string, AM_Municipio__c>> mapMunicipios = new map<String, map<string, AM_Municipio__c>>();
            //Converting codes like 012 to 12, without the 0 in left position, 'cause the object municipio__c doesn´t save a 0 in the left position
            for(AutosClienteWS cliente : lstcliente){
                cliente.F015_ID_CIUDAD = string.valueOf(integer.valueOf(cliente.F015_ID_CIUDAD));
                cliente.F015_ID_DEPTO = string.valueOf(integer.valueOf(cliente.F015_ID_DEPTO));
                setMunicipioDANECodes.add(cliente.F015_ID_CIUDAD);
                setDepartamentoDANECodes.add(cliente.F015_ID_DEPTO);
                
                setTipoDocumentos.add(Utilities.getTipoDocumentoUNOEE_To_SF(cliente.F200_ID_TIPO_IDENT));
                setNumeroDocumentos.add(cliente.F200_ID);
            }
            for (AM_Municipio__c m: [select Id, AM_Codigo_DANE_municipio__c, AM_Codigo_DANE_departamento__c from AM_Municipio__c 
                                     where AM_Codigo_DANE_municipio__c in:setMunicipioDANECodes and AM_Codigo_DANE_departamento__c in:setDepartamentoDANECodes])
            {
                if (mapMunicipios.containsKey(m.AM_Codigo_DANE_departamento__c)){
                    mapMunicipios.get(m.AM_Codigo_DANE_departamento__c).put(m.AM_Codigo_DANE_municipio__c, m);                           
                }else{
                    mapMunicipios.put(m.AM_Codigo_DANE_departamento__c, new map<string,AM_Municipio__c>{m.AM_Codigo_DANE_municipio__c => m});
                }
            }
            
            //Mapear cuentas para luego verificar si existen o no
            for (Account a: [select Id, AM_Tipo_de_documento__c,AM_Numero_de_documento__c from Account where AM_Tipo_de_documento__c in:setTipoDocumentos and AM_Numero_de_documento__c in:setNumeroDocumentos]){
                mapCuentasxDocumento.put(a.AM_Tipo_de_documento__c + a.AM_Numero_de_documento__c,a);
            }
            
            for(AutosClienteWS cliente : lstcliente){
                                
                Account objCliente = new Account ();
                objCliente.Creado_en_UNOEE__c = true;
                objCliente.Codigo_UNOEE__c = cliente.F201_ID_SF;
                 if (mapCuentasxDocumento.containsKey(objCliente.AM_Tipo_de_documento__c+objCliente.AM_Numero_de_documento__c)){
                    objCliente.Id=mapCuentasxDocumento.get(objCliente.AM_Tipo_de_documento__c+objCliente.AM_Numero_de_documento__c).Id;
                }
                //Fields related between Persona Jurídica and Persona Natural 
                objCliente.MC_Autoriza_tratardatos_personales__c = cliente.F207_ID_CRITERIO_MAYOR;
                if(cliente.F201_IND_ESTADO_ACTIVO == '0') {
                    objCliente.Sucursal_activa__c = false;
                } else if (cliente.F201_IND_ESTADO_ACTIVO == '1') {
                    objCliente.Sucursal_activa__c = true;
                }
                
                objCliente.AM_Numero_de_documento__c = cliente.F200_ID;
                objCliente.Phone = String.isBlank(cliente.F015_TELEFONO) ? null : cliente.F015_TELEFONO;//cliente.F015_TELEFONO;
                if (mapMunicipios.containsKey(cliente.F015_ID_DEPTO) && mapMunicipios.get(cliente.F015_ID_DEPTO).containsKey(cliente.F015_ID_CIUDAD)){
                    objCliente.AM_Ciudad__c = mapMunicipios.get(cliente.F015_ID_DEPTO).get(cliente.F015_ID_CIUDAD).Id;
                }
                objCliente.DireccionERP__c = cliente.F015_DIRECCION1;
                objCliente.Sucursal__c = cliente.F201_ID_SUCURSAL;
                if(cliente.F200_IND_ESTADO == '0') {
                    objCliente.AM_Estado__c = 'Inactivo';
                } else if (cliente.F200_IND_ESTADO == '1') {
                    objCliente.AM_Estado__c = 'Activo';
                }   
                objCliente.AM_Tipo_de_usuario__c = 'Cliente Honda';                    
                if (objCliente.Id == null) objCliente.AccountSource = 'Registro migrado';
                
                RecordType pnRecordType;
                RecordType pjRecordType;
                for (RecordType rt: [SELECT id,DeveloperName FROM RecordType WHERE sobjecttype ='Account' and isActive=true]){
                    if (rt.DeveloperName == Label.AutosRecordTypeDevNameAccountNatural) pnRecordType = rt;
                    if (rt.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) pjRecordType = rt;
                }
                
                //Persona Natural
                if(cliente.F200_IND_TIPO_TERCERO.equals('1')){
                    objCliente.recordTypeID = pnRecordType.Id;
                    objCliente.Salutation = 'No especificado';
                    //objCliente.AM_Estado_civil__pc = 'Soltero';
                    objCliente.AM_Tipo_de_documento__c = getTipoDocumento_UNOEE(cliente.F200_ID_TIPO_IDENT);
                    objCliente.FirstName = cliente.F200_NOMBRES.SubStringBefore(' ');//cliente.F200_NOMBRES;
					objCliente.Segundo_Nombre__c = cliente.F200_NOMBRES.SubStringAfter(' ');                   
                    objCliente.LastName = cliente.F200_APELLIDO1;
                    objCliente.Primer_nombre__c = objCliente.FirstName;//cliente.F200_NOMBRES;
                    objCliente.Primer_Apellido__c = cliente.F200_APELLIDO1;
                    objCliente.Segundo_Apellido__c = cliente.F200_APELLIDO2;
                    objCliente.PersonEmail = cliente.F015_EMAIL;
                    objCliente.PersonMobilePhone = cliente.F015_CELULAR;
                    string fechaERP = cliente.F200_FECHA_NACIMIENTO;
                    if(fechaERP != null && fechaERP != ''){ 
                        fechaERP = fechaERP.left(4) + '-' + fechaERP.left(6).right(2) + '-' + fechaERP.right(2);
                        date convertFecha = Date.valueOf(fechaERP);
                        objCliente.PersonBirthdate = convertFecha;
                    }
                } 
                
                //Persona Jurídica 
                else if(cliente.F200_IND_TIPO_TERCERO.equals('2')){ 
                    objCliente.recordTypeID = pjRecordType.Id;
                    objCliente.AM_Tipo_de_documento__c = getTipoDocumento_UNOEE(cliente.F200_ID_TIPO_IDENT);                                     
                    objCliente.Name = cliente.F200_RAZON_SOCIAL;
                    objCliente.MC_Correo_electronico_Empresa__c = cliente.F015_EMAIL;
                }
                insertacct.add(objCliente);
            }
            
            if(insertacct.size()>0){
                 system.debug('AutosClientesSOAPWS: Hay Elementos que insertar: ' + insertacct.size()); 
                //Schema.SObjectField ExtId = Account.Fields.Codigo_SAP__c;
                list <Database.upsertResult> upsertResult= database.upsert(insertacct,false);//list <Database.SaveResult> SaveResult= database.insert(insertacct,false);//list <Database.upsertResult> upsertResult= database.upsert(insertacct,ExtId,false);
                    
                Integer i=0;
                for(Database.upsertResult result : upsertResult){//for(Database.SaveResult result : SaveResult){//for(Database.upsertResult result : upsertResult){
                    Account c= insertacct.get(i);
                    AutosClienteRta r= new AutosClienteRta();
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
    
    /*
    webservice static list<AutosClienteRta> CrearCliente(list<AutosClienteWS> lstcliente ) {
        list <AutosClienteRta> lstclienteRta = new list<AutosClienteRta>();
        list <Account> insertacct = new list<Account>();
        try{
            //Get the Municipios and map them
            set<String> setMunicipioDANECodes = new set<String>();
            set<String> setDepartamentoDANECodes = new set<String>();
            
            map<String, map<string, AM_Municipio__c>> mapMunicipios = new map<String, map<string, AM_Municipio__c>>();
            //Converting codes like 012 to 12, without the 0 in left position, 'cause the object municipio__c doesn´t save a 0 in the left position
            for(AutosClienteWS cliente : lstcliente){
                cliente.F015_ID_CIUDAD = string.valueOf(integer.valueOf(cliente.F015_ID_CIUDAD));
                cliente.F015_ID_DEPTO = string.valueOf(integer.valueOf(cliente.F015_ID_DEPTO));
                setMunicipioDANECodes.add(cliente.F015_ID_CIUDAD);
                setDepartamentoDANECodes.add(cliente.F015_ID_DEPTO);
            }
            for (AM_Municipio__c m: [select Id, AM_Codigo_DANE_municipio__c, AM_Codigo_DANE_departamento__c from AM_Municipio__c 
                                     where AM_Codigo_DANE_municipio__c in:setMunicipioDANECodes and AM_Codigo_DANE_departamento__c in:setDepartamentoDANECodes]){
                                         if (mapMunicipios.containsKey(m.AM_Codigo_DANE_departamento__c)){
                                             mapMunicipios.get(m.AM_Codigo_DANE_departamento__c).put(m.AM_Codigo_DANE_municipio__c, m);                           
                                         }else{
                                             mapMunicipios.put(m.AM_Codigo_DANE_departamento__c, new map<string,AM_Municipio__c>{m.AM_Codigo_DANE_municipio__c => m});
                                         }
                                     }
            
            for(AutosClienteWS cliente : lstcliente){
                                
                Account objCliente = new Account ();
                
                //Fields related between Persona Jurídica and Persona Natural 
                objCliente.MC_Autoriza_tratardatos_personales__c = cliente.F207_ID_CRITERIO_MAYOR;
                if(cliente.F201_IND_ESTADO_ACTIVO == '0') {
                    objCliente.Sucursal_activa__c = false;
                } else if (cliente.F201_IND_ESTADO_ACTIVO == '1') {
                    objCliente.Sucursal_activa__c = true;
                }
                
                objCliente.AM_Numero_de_documento__c = cliente.F200_ID;
                objCliente.Phone = cliente.F015_TELEFONO;
                if (mapMunicipios.containsKey(cliente.F015_ID_DEPTO) && mapMunicipios.get(cliente.F015_ID_DEPTO).containsKey(cliente.F015_ID_CIUDAD)){
                    objCliente.AM_Ciudad__c = mapMunicipios.get(cliente.F015_ID_DEPTO).get(cliente.F015_ID_CIUDAD).Id;
                }
                objCliente.DireccionERP__c = cliente.F015_DIRECCION1;
                objCliente.Sucursal__c = cliente.F201_ID_SUCURSAL;
                if(cliente.F200_IND_ESTADO == '0') {
                    objCliente.AM_Estado__c = 'Inactivo';
                } else if (cliente.F200_IND_ESTADO == '1') {
                    objCliente.AM_Estado__c = 'Activo';
                }   
                objCliente.AM_Tipo_de_usuario__c = 'Cliente Honda';                    
                objCliente.AccountSource = 'Registro migrado';
                
                RecordType pnRecordType;
                RecordType pjRecordType;
                for (RecordType rt: [SELECT id,DeveloperName FROM RecordType WHERE sobjecttype ='Account' and isActive=true]){
                    if (rt.DeveloperName == Label.AutosRecordTypeDevNameAccountNatural) pnRecordType = rt;
                    if (rt.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) pjRecordType = rt;
                }
                
                //Persona Natural
                if(cliente.F200_IND_TIPO_TERCERO.equals('1')){
                    objCliente.recordTypeID = pnRecordType.Id;
                    objCliente.Salutation = 'No especificado';
                    //objCliente.AM_Estado_civil__pc = 'Soltero';
                    objCliente.AM_Tipo_de_documento__c = getTipoDocumento_UNOEE(cliente.F200_ID_TIPO_IDENT);
                    objCliente.FirstName = cliente.F200_NOMBRES;
                    objCliente.LastName = cliente.F200_APELLIDO1;
                    objCliente.Primer_nombre__c = cliente.F200_NOMBRES;
                    objCliente.Primer_Apellido__c = cliente.F200_APELLIDO1;
                    objCliente.Segundo_Apellido__c = cliente.F200_APELLIDO2;
                    objCliente.PersonEmail = cliente.F015_EMAIL;
                    objCliente.PersonMobilePhone = cliente.F015_CELULAR;
                    string fechaERP = cliente.F200_FECHA_NACIMIENTO;
                    if(fechaERP != null && fechaERP != ''){ 
                        fechaERP = fechaERP.left(4) + '-' + fechaERP.left(6).right(2) + '-' + fechaERP.right(2);
                        date convertFecha = Date.valueOf(fechaERP);
                        objCliente.PersonBirthdate = convertFecha;
                    }
                } 
                
                //Persona Jurídica 
                else if(cliente.F200_IND_TIPO_TERCERO.equals('2')){ 
                    objCliente.recordTypeID = pjRecordType.Id;
                    objCliente.AM_Tipo_de_documento__c = getTipoDocumento_UNOEE(cliente.F200_ID_TIPO_IDENT);                                     
                    objCliente.Name = cliente.F200_RAZON_SOCIAL;
                    objCliente.MC_Correo_electronico_Empresa__c = cliente.F015_EMAIL;
                }
                insertacct.add(objCliente);
            }
            
            if(insertacct.size()>0){
                list <Database.saveResult> insertResult = database.insert(insertacct, false);
                
                Integer i=0;
                for(Database.saveResult result : insertResult){
                    Account c = insertacct.get(i);
                    AutosClienteRta r = new AutosClienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta = 'Operación exitosa';
                        r.error = '';
                        r.idSF = c.id;
                    }else{
                        for(Database.Error e: result.getErrors()){
                            if (e instanceof Database.DuplicateError){
                                // Handle the duplicate error by first casting it as a DuplicateError class
                                // This lets you use methods of that class (e.g., getDuplicateResult())
                                Database.DuplicateError duplicateError = (Database.DuplicateError)e;
                                Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
       
                                // Return only match results of matching rules that find duplicate records
                                Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
             
                                // Just grab first match result (which contains the duplicate record found and other match info)
                                Datacloud.MatchResult matchResult = matchResults[0];
                                
                                Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                                
                                r.error='Error: Registro Duplicado Encontrado: ' + ' Name: ' + matchRecords[0].getRecord().get('Name') + ', Id: ' +matchRecords[0].getRecord().get('Id');
                                r.idSF=(String)matchRecords[0].getRecord().get('Id');
                            }else{
                            	r.error='Error: '+e.getMessage()+' Campos '+e.getFields();    
                            	r.idSF=c.id;
                            } 
                            r.MnsjRta ='Operación fallida';
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
            crta.mnsjRta=ex.getMessage();//'Problemas en la ejecución del webservice'; 
            crta.idSF='';
            lstclienteRta.add(crta);
        }
        
        for(AutosClienteRta rta: lstclienteRta){
            System.debug(' ** ERROR WEB SERVICE CLIENTES ** ' + rta);
        }
        return lstclienteRta;
    }*/
    
    /*
    webservice static list<AutosClienteRta> ModificarCliente(list<AutosClienteWS> lstcliente ) {
        list <AutosClienteRta> lstclienteRta = new list<AutosClienteRta>();
        list <Account> insertacct = new list<Account>();
        try{
            //Get the Municipios and map them
            set<String> setMunicipioDANECodes = new set<String>();
            set<String> setDepartamentoDANECodes = new set<String>();
            
            map<String, map<string, AM_Municipio__c>> mapMunicipios = new map<String, map<string, AM_Municipio__c>>();
            //Converting codes like 012 to 12, without the 0 in left position, 'cause the object municipio__c doesn´t save a 0 in the left position
            for(AutosClienteWS cliente : lstcliente){
                cliente.F015_ID_CIUDAD = string.valueOf(integer.valueOf(cliente.F015_ID_CIUDAD));
                cliente.F015_ID_DEPTO = string.valueOf(integer.valueOf(cliente.F015_ID_DEPTO));
                setMunicipioDANECodes.add(cliente.F015_ID_CIUDAD);
                setDepartamentoDANECodes.add(cliente.F015_ID_DEPTO);
            }
            for (AM_Municipio__c m: [select Id, AM_Codigo_DANE_municipio__c, AM_Codigo_DANE_departamento__c from AM_Municipio__c 
                                     where AM_Codigo_DANE_municipio__c in:setMunicipioDANECodes and AM_Codigo_DANE_departamento__c in:setDepartamentoDANECodes]){
                                         if (mapMunicipios.containsKey(m.AM_Codigo_DANE_departamento__c)){
                                             mapMunicipios.get(m.AM_Codigo_DANE_departamento__c).put(m.AM_Codigo_DANE_municipio__c, m);                           
                                         }else{
                                             mapMunicipios.put(m.AM_Codigo_DANE_departamento__c, new map<string,AM_Municipio__c>{m.AM_Codigo_DANE_municipio__c => m});
                                         }
                                     }
            
            for(AutosClienteWS cliente : lstcliente){
                
                System.debug(' ** REQUEST ** ' + cliente);
                
                Account objCliente = new Account ();
                
                objCliente.Id = (cliente.F201_ID_SF==null || cliente.F201_ID_SF=='') ? null : cliente.F201_ID_SF;
                //Fields related between Persona Jurídica and Persona Natural 
                objCliente.MC_Autoriza_tratardatos_personales__c = cliente.F207_ID_CRITERIO_MAYOR;
                if(cliente.F201_IND_ESTADO_ACTIVO == '0') {
                    objCliente.Sucursal_activa__c = false;
                } else if (cliente.F201_IND_ESTADO_ACTIVO == '1') {
                    objCliente.Sucursal_activa__c = true;
                }
                
                objCliente.AM_Numero_de_documento__c = cliente.F200_ID;
                objCliente.Phone = cliente.F015_TELEFONO;
                if (mapMunicipios.containsKey(cliente.F015_ID_DEPTO) && mapMunicipios.get(cliente.F015_ID_DEPTO).containsKey(cliente.F015_ID_CIUDAD)){
                    objCliente.AM_Ciudad__c = mapMunicipios.get(cliente.F015_ID_DEPTO).get(cliente.F015_ID_CIUDAD).Id;
                }
                objCliente.DireccionERP__c = cliente.F015_DIRECCION1;
                objCliente.Sucursal__c = cliente.F201_ID_SUCURSAL;
                if(cliente.F200_IND_ESTADO == '0') {
                    objCliente.AM_Estado__c = 'Inactivo';
                } else if (cliente.F200_IND_ESTADO == '1') {
                    objCliente.AM_Estado__c = 'Activo';
                }   
                
                objCliente.AM_Tipo_de_usuario__c = 'Cliente Honda';                    
                objCliente.AccountSource = 'Registro migrado';
                
                //Validate recordtype
                RecordType pnRecordType;
                RecordType pjRecordType;
                for (RecordType rt: [SELECT id,DeveloperName FROM RecordType WHERE sobjecttype ='Account' and isActive=true]){
                    if (rt.DeveloperName == Label.AutosRecordTypeDevNameAccountNatural) pnRecordType = rt;
                    if (rt.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) pjRecordType = rt;
                }
                
                //Persona Natural
                if(cliente.F200_IND_TIPO_TERCERO.equals('1')){
                    objCliente.recordTypeID = pnRecordType.Id;
                    objCliente.Salutation = 'No especificado';
                    //objCliente.AM_Estado_civil__pc = 'Soltero';
                    objCliente.AM_Tipo_de_documento__c = getTipoDocumento_UNOEE(cliente.F200_ID_TIPO_IDENT);
                    objCliente.FirstName = cliente.F200_NOMBRES;
                    objCliente.LastName = cliente.F200_APELLIDO1;
                    objCliente.Primer_nombre__c = cliente.F200_NOMBRES;
                    objCliente.Primer_Apellido__c = cliente.F200_APELLIDO1;
                    objCliente.Segundo_Apellido__c = cliente.F200_APELLIDO2;
                    objCliente.PersonEmail = cliente.F015_EMAIL;
                    objCliente.PersonMobilePhone = cliente.F015_CELULAR;                    
                    string fechaERP = cliente.F200_FECHA_NACIMIENTO;
                    if(fechaERP != null && fechaERP != ''){ 
                        fechaERP = fechaERP.left(4) + '-' + fechaERP.left(6).right(2) + '-' + fechaERP.right(2);
                        date convertFecha = Date.valueOf(fechaERP);
                        objCliente.PersonBirthdate = convertFecha;
                    } else {
                         objCliente.PersonBirthdate = null;
                    }
                } 
                
                //Persona Jurídica 
                else if(cliente.F200_IND_TIPO_TERCERO.equals('2')){ 
                    objCliente.recordTypeID = pjRecordType.Id;
                    objCliente.AM_Tipo_de_documento__c = getTipoDocumento_UNOEE(cliente.F200_ID_TIPO_IDENT);                                     
                    objCliente.Name = cliente.F200_RAZON_SOCIAL;
                    objCliente.MC_Correo_electronico_Empresa__c = cliente.F015_EMAIL;
                }
                insertacct.add(objCliente);
            }
            
            if(insertacct.size()>0){
                list <Database.SaveResult> SaveResult= database.update(insertacct,false);
                    
                Integer i=0;
                for(Database.SaveResult result : SaveResult){
                    Account c = insertacct.get(i);
                    AutosClienteRta r = new AutosClienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta='Operación exitosa';
                        r.error='';
                        r.idSF=c.id;
                    } else {
                         for(Database.Error e: result.getErrors()){
                            if (e instanceof Database.DuplicateError){
                                // Handle the duplicate error by first casting it as a DuplicateError class
                                // This lets you use methods of that class (e.g., getDuplicateResult())
                                Database.DuplicateError duplicateError = (Database.DuplicateError)e;
                                Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
       
                                // Return only match results of matching rules that find duplicate records
                                Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
             
                                // Just grab first match result (which contains the duplicate record found and other match info)
                                Datacloud.MatchResult matchResult = matchResults[0];
                                
                                Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                                
                                r.error='Error: Registro Duplicado Encontrado: ' + ' Name: ' + matchRecords[0].getRecord().get('Name') + ', Id: ' +matchRecords[0].getRecord().get('Id');
                                r.idSF=(String)matchRecords[0].getRecord().get('Id');
                            }else{
                            	r.error='Error: '+e.getMessage()+' Campos '+e.getFields();    
                            	r.idSF=c.id;
                            } 
                            r.MnsjRta ='Operación fallida';
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
            crta.mnsjRta=ex.getMessage();//'Problemas en la ejecución del webservice'; 
            crta.idSF='';
            lstclienteRta.add(crta);
        }
        
        for(AutosClienteRta rta: lstclienteRta){
            System.debug(' ** ERROR WEB SERVICE CLIENTES ** ' + rta);
        }
        return lstclienteRta;
    }*/
    
    webservice static list<AutosClienteRta> ModificarCliente(list<AutosClienteWS> lstcliente ) {
        list <AutosClienteRta> lstclienteRta = new list<AutosClienteRta>();
        list <Account> insertacct = new list<Account>();
        try{
            //Get the Municipios and map them
            set<String> setMunicipioDANECodes = new set<String>();
            set<String> setDepartamentoDANECodes = new set<String>();
            set<String> setCodigosERP = new set<String>(); //Set de Codigos ERP para luego obtener las cuentas basadas en este codigo erp, y así tener el Id para realizar update
            set<String> setTipoDocumentos = new set<String>();
            set<String> setNumeroDocumentos = new set<String>();
            map<String,Account> mapCuentas = new map<String,Account>();
            map<String, Account> mapCuentasxDocumento = new map<String, Account>();
            
            map<String, map<string, AM_Municipio__c>> mapMunicipios = new map<String, map<string, AM_Municipio__c>>();
            //Converting codes like 012 to 12, without the 0 in left position, 'cause the object municipio__c doesn´t save a 0 in the left position
            for(AutosClienteWS cliente : lstcliente){
                cliente.F015_ID_CIUDAD = string.valueOf(integer.valueOf(cliente.F015_ID_CIUDAD));
                cliente.F015_ID_DEPTO = string.valueOf(integer.valueOf(cliente.F015_ID_DEPTO));
                setMunicipioDANECodes.add(cliente.F015_ID_CIUDAD);
                setDepartamentoDANECodes.add(cliente.F015_ID_DEPTO);
                setCodigosERP.add(cliente.F201_ID_SF);
                setTipoDocumentos.add(Utilities.getTipoDocumentoUNOEE_To_SF(cliente.F200_ID_TIPO_IDENT));
                setNumeroDocumentos.add(cliente.F200_ID);
            }
            for (AM_Municipio__c m: [select Id, AM_Codigo_DANE_municipio__c, AM_Codigo_DANE_departamento__c from AM_Municipio__c 
                                     where AM_Codigo_DANE_municipio__c in:setMunicipioDANECodes and AM_Codigo_DANE_departamento__c in:setDepartamentoDANECodes])
            {
                if (mapMunicipios.containsKey(m.AM_Codigo_DANE_departamento__c)){
                    mapMunicipios.get(m.AM_Codigo_DANE_departamento__c).put(m.AM_Codigo_DANE_municipio__c, m);                           
                }else{
                    mapMunicipios.put(m.AM_Codigo_DANE_departamento__c, new map<string,AM_Municipio__c>{m.AM_Codigo_DANE_municipio__c => m});
                }
            }
            //Mapear cuentas para luego verificar si existen o no
            for (Account a: [select Id,Codigo_UNOEE__c from Account where Codigo_UNOEE__c in:setCodigosERP AND Codigo_UNOEE__c <> null]){
                mapCuentas.put(a.Codigo_UNOEE__c,a);
            }
            for (Account a: [select Id, AM_Tipo_de_documento__c,AM_Numero_de_documento__c from Account where AM_Tipo_de_documento__c in:setTipoDocumentos and AM_Numero_de_documento__c in:setNumeroDocumentos]){
                mapCuentasxDocumento.put(a.AM_Tipo_de_documento__c + a.AM_Numero_de_documento__c,a);
            }
            
            for(AutosClienteWS cliente : lstcliente){
                
                System.debug(' ** REQUEST ** ' + cliente);
                
                Account objCliente = new Account ();
                
                //objCliente.Id = (cliente.F201_ID_SF==null || cliente.F201_ID_SF=='') ? null : cliente.F201_ID_SF;
                objCliente.Codigo_UNOEE__c = (cliente.F201_ID_SF==null || cliente.F201_ID_SF=='') ? null : cliente.F201_ID_SF;
                objCliente.Id = mapCuentas.get(cliente.F201_ID_SF)?.Id;
                if (objCliente.Id==null) objCliente.Id = mapCuentasxDocumento.get(Utilities.getTipoDocumentoUNOEE_To_SF(cliente.F200_ID_TIPO_IDENT) + cliente.F200_ID)?.Id; //Added 20210324, si no encuentra por codigo erp, entonces buscar por tipo y numero de documento
                if (objCliente.Id==null) objCliente.Creado_en_UNOEE__c = true;
                objCliente.Codigo_UNOEE__c = cliente.F201_ID_SF; //Added 20210324
                //Fields related between Persona Jurídica and Persona Natural 
                objCliente.MC_Autoriza_tratardatos_personales__c = cliente.F207_ID_CRITERIO_MAYOR;
                if(cliente.F201_IND_ESTADO_ACTIVO == '0') {
                    objCliente.Sucursal_activa__c = false;
                } else if (cliente.F201_IND_ESTADO_ACTIVO == '1') {
                    objCliente.Sucursal_activa__c = true;
                }
                
                objCliente.AM_Numero_de_documento__c = cliente.F200_ID;
                objCliente.Phone =  String.isBlank(cliente.F015_TELEFONO) ? null : cliente.F015_TELEFONO; //cliente.F015_TELEFONO;
                if (mapMunicipios.containsKey(cliente.F015_ID_DEPTO) && mapMunicipios.get(cliente.F015_ID_DEPTO).containsKey(cliente.F015_ID_CIUDAD)){
                    objCliente.AM_Ciudad__c = mapMunicipios.get(cliente.F015_ID_DEPTO).get(cliente.F015_ID_CIUDAD).Id;
                }
                objCliente.DireccionERP__c = cliente.F015_DIRECCION1;
                objCliente.Sucursal__c = cliente.F201_ID_SUCURSAL;
                if(cliente.F200_IND_ESTADO == '0') {
                    objCliente.AM_Estado__c = 'Inactivo';
                } else if (cliente.F200_IND_ESTADO == '1') {
                    objCliente.AM_Estado__c = 'Activo';
                }   
                
                objCliente.AM_Tipo_de_usuario__c = 'Cliente Honda';                    
                objCliente.AccountSource = 'Registro migrado';
                
                //Validate recordtype
                RecordType pnRecordType;
                RecordType pjRecordType;
                for (RecordType rt: [SELECT id,DeveloperName FROM RecordType WHERE sobjecttype ='Account' and isActive=true]){
                    if (rt.DeveloperName == Label.AutosRecordTypeDevNameAccountNatural) pnRecordType = rt;
                    if (rt.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) pjRecordType = rt;
                }
                
                //Persona Natural
                if(cliente.F200_IND_TIPO_TERCERO.equals('1')){
                    objCliente.recordTypeID = pnRecordType.Id;
                    //objCliente.Salutation = 'No especificado';
                    //objCliente.AM_Estado_civil__pc = 'Soltero';
                    objCliente.AM_Tipo_de_documento__c = getTipoDocumento_UNOEE(cliente.F200_ID_TIPO_IDENT);
                    objCliente.FirstName = cliente.F200_NOMBRES.SubStringBefore(' ');//cliente.F200_NOMBRES;
                    objCliente.Segundo_Nombre__c = cliente.F200_NOMBRES.SubStringAfter(' ');   
                    objCliente.LastName = cliente.F200_APELLIDO1;
                    objCliente.Primer_nombre__c = objCliente.FirstName;//cliente.F200_NOMBRES;
                    objCliente.Primer_Apellido__c = cliente.F200_APELLIDO1;
                    objCliente.Segundo_Apellido__c = cliente.F200_APELLIDO2;
                    objCliente.PersonEmail = cliente.F015_EMAIL;
                    objCliente.PersonMobilePhone = cliente.F015_CELULAR;                    
                    string fechaERP = cliente.F200_FECHA_NACIMIENTO;
                    if(fechaERP != null && fechaERP != ''){ 
                        fechaERP = fechaERP.left(4) + '-' + fechaERP.left(6).right(2) + '-' + fechaERP.right(2);
                        date convertFecha = Date.valueOf(fechaERP);
                        objCliente.PersonBirthdate = convertFecha;
                    } else {
                         objCliente.PersonBirthdate = null;
                    }
                } 
                
                //Persona Jurídica 
                else if(cliente.F200_IND_TIPO_TERCERO.equals('2')){ 
                    objCliente.recordTypeID = pjRecordType.Id;
                    objCliente.AM_Tipo_de_documento__c = getTipoDocumento_UNOEE(cliente.F200_ID_TIPO_IDENT);                                     
                    objCliente.Name = cliente.F200_RAZON_SOCIAL;
                    objCliente.MC_Correo_electronico_Empresa__c = cliente.F015_EMAIL;
                }
                insertacct.add(objCliente);
            }
            
            if(insertacct.size()>0){
                list <Database.upsertResult> upsertResult= database.upsert(insertacct,false); //Changed 20210407 list <Database.SaveResult> SaveResult= database.update(insertacct,false);
                    
                Integer i=0;
                for(Database.upsertResult result : upsertResult){//for(Database.SaveResult result : SaveResult){
                    Account c = insertacct.get(i);
                    AutosClienteRta r = new AutosClienteRta();
                    if (result.isSuccess()){
                        r.MnsjRta='Operación exitosa';
                        r.error='';
                        r.idSF=c.id;
                    } else {
                         for(Database.Error e: result.getErrors()){
                            if (e instanceof Database.DuplicateError){
                                // Handle the duplicate error by first casting it as a DuplicateError class
                                // This lets you use methods of that class (e.g., getDuplicateResult())
                                Database.DuplicateError duplicateError = (Database.DuplicateError)e;
                                Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
       
                                // Return only match results of matching rules that find duplicate records
                                Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
             
                                // Just grab first match result (which contains the duplicate record found and other match info)
                                Datacloud.MatchResult matchResult = matchResults[0];
                                
                                Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                                
                                r.error='Error: Registro Duplicado Encontrado: ' + ' Name: ' + matchRecords[0].getRecord().get('Name') + ', Id: ' +matchRecords[0].getRecord().get('Id');
                                r.idSF=(String)matchRecords[0].getRecord().get('Id');
                            }else{
                            	r.error='Error: '+e.getMessage()+' Campos '+e.getFields();    
                            	r.idSF=c.id;
                            } 
                            r.MnsjRta ='Operación fallida';
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
            crta.mnsjRta=ex.getMessage();//'Problemas en la ejecución del webservice'; 
            crta.idSF='';
            lstclienteRta.add(crta);
        }
        
        for(AutosClienteRta rta: lstclienteRta){
            System.debug(' ** ERROR WEB SERVICE CLIENTES ** ' + rta);
        }
        return lstclienteRta;
    }
    
    //This method returns the correspondent Tipo Documento picklist value in Salesforce based on codes in UNOEE
    private static String getTipoDocumento_UNOEE(String Codigo){
        switch on Codigo {
            when 'C' {	return 'Cédula de ciudadanía';        }	
            when 'E' {	return 'Cédula de extranjería';       }
            when 'D' {	return 'Código de NIT de extranjería';}
            when 'N' {	return 'NIT';           }
            when 'P' {	return 'Pasaporte';         }
            when 'X' {	return 'Sociedad extranjera sin NIT'; }
            when 'T' {	return 'Tarjeta de identidad';        }
            when 'J' {	return 'Tarjeta extranjeria';         }
            when else {	return '';   }//NUIP No está codificado
        }
    }
    
}