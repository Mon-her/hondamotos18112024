//Made by Me, August '21
//Custom Labels used: changeAccountOwnerCSVSeparator
//Test Class: ChangeAccountOwnerCSV_Test
//Description: This is the controller for the LWC ChangeAccountOwnerCSV, to reassign (from a csv file) massively accounts and related contacts, tasks, opps and related accounts
//Uses: ChangeAccountOwnerCSVBatch to execute the owner changes
public class ChangeAccountOwnerCSV {
    @AuraEnabled
    public static list<accountOwnerChangesData> readCSVFile(Id idContentDocument){
      //  list<Account> lstAccsToInsert = new list<Account>();
        //list< TECH_ChangeUser__c > lstChangeUserOld = [SELECT Id,Name,TECH_NewUser__c, Tech_User__c, Tech_User__R.id  FROM TECH_ChangeUser__c ];
        //delete lstChangeUserOld;
        list<accountOwnerChangesData> lstWrpNewOwner = new list<accountOwnerChangesData>();
        if(idContentDocument != null) {            
            // getting File Data based on document id 
            try{    
                ContentVersion objVersion = [SELECT Id, VersionData FROM ContentVersion WHERE ContentDocumentId =:idContentDocument];
                // split the file data
                set< string > setUserName = new set< string >();
                set< string > setDocument = new set< string >();
                list<String> lstCSVLines = objVersion.VersionData.toString().split('\n');           
                for(Integer i = 1; i < lstCSVLines.size(); i++){
                    list<String> csvRowData = lstCSVLines[i].split(Label.changeAccountOwnerCSVSeparator); // , or ;
                    csvRowData[1]= csvRowData[1].replaceAll( '\\s+', '');   
                    csvRowData[0]= csvRowData[0].replaceAll( '\\s+', '');                 
                    setUserName.add( csvRowData[1] );
                    setDocument.add( csvRowData[0] );
                }  
                system.debug('\n set username @@'+ setUserName );
                map<string,User> mapUser = getMapUser( setUserName );  
                map<string,Account> mapAccount = getMapAccount( setDocument );  
                system.debug('\n map user @@@ '+ JSON.serializePretty( mapUser )); 
                list<TECH_ChangeUser__c>  lstChangeUser = new  list<TECH_ChangeUser__c>();         

                for(Integer i = 1; i < lstCSVLines.size(); i++){
                    list<String> csvRowData = lstCSVLines[i].split(Label.changeAccountOwnerCSVSeparator); // , or ;
                    string strAccountDocument= csvRowData[0].replaceAll( '\\s+', ''); 
                    string strUsername= csvRowData[1].replaceAll( '\\s+', ''); 
                    system.debug('\n document' +  strAccountDocument + '\n username @@'+ csvRowData[1]+ '\ncontiene user @@' +  mapUser.containsKey( strUsername ) );
                    if( mapUser.containsKey( strUsername ) && mapAccount.containsKey( strAccountDocument ) ){
                        accountOwnerChangesData objWrp = new accountOwnerChangesData();
                        Account cuenta = mapAccount.get( strAccountDocument );
                        objWrp.numeroDocumento = strAccountDocument; // Document
                        objWrp.accountName = cuenta.Name ; // Account Name  
                        objWrp.accountId = cuenta.Id ; // Account Id  
                        objWrp.newOwner = strUsername ; // UserName  
                        objWrp.newOwnerId = mapUser.get( strUsername ).Id ; // UserName  
                        objWrp.newOwnerProfileName = mapUser.get( strUsername ).Profile.Name ; // UserName  
                        objWrp.oldOwner = cuenta.Owner.UserName ; // Account Owner Old Name
                        objWrp.oldOwnerId = cuenta.OwnerId ; // Account Owner Old
                        objWrp.oldOwnerProfileName = cuenta.Owner.Profile.Name ; // Account Old Owner Profile Name
                        lstWrpNewOwner.add( objWrp ); 
                        //TECH_ChangeUser__c objChangeUser = new TECH_ChangeUser__c();
                        //objChangeUser.Name = strUserDocument;
                        //objChangeUser.TECH_NewUser__c = strUsername;
                        //objChangeUser.Tech_User__c =  mapUser.get( strUsername ); 
                        //objChangeUser.TECH_ContentDocument__c = idContentDocument;
                        //if(  mapAccount.containskey( strUserDocument ) ){
                        //    objChangeUser.TECH_NombreCuenta__c = mapAccount.get( strUserDocument );
                        //}
                        //lstChangeUser.add( objChangeUser);    
                    }                         
                }
                system.debug('\N CSV FILE @@@' + JSON.serializePretty( lstCSVLines ) + '\n lst wrapper @@@' + JSON.serializePretty( lstWrpNewOwner ) );          
                //if(!lstWrpNewOwner.isEmpty()) {
                //    insert lstChangeUser;
                //}
                
                system.debug('Deleting objVersion: ' + objVersion);
                ContentDocument documento = new ContentDocument(Id= idContentDocument);
                delete documento;
            }
            catch (Exception e) {
                System.debug( '\n\n\n\t<<<<<<<<< ExceptionType >>>>>>>>> \n\t\t@@--> getCause > ' + e.getCause() + '\n\t\t@@--> getLineNumber > ' + e.getLineNumber() + '\n\t\t@@--> getMessage > '+ e.getMessage() + '\n\t\t@@--> getStackTraceString > '+ e.getStackTraceString() + '\n\t\t@@--> getTypeName > ' + e.getTypeName() + '\n\n' );    
                throw new AuraHandledException('\n\n\n\t<<<<<<<<< ExceptionType >>>>>>>>> \n\t\t@@--> getCause > ' + e.getCause() + '\n\t\t@@--> getLineNumber > ' + e.getLineNumber() + '\n\t\t@@--> getMessage > '+ e.getMessage() + '\n\t\t@@--> getStackTraceString > '+ e.getStackTraceString() + '\n\t\t@@--> getTypeName > ' + e.getTypeName() + '\n\n');
            } 
        }
        return lstWrpNewOwner;
    }  
    
    public static map<string,User> getMapUser( set<String> setUserName ){
        map<string,User> mapDocumentUser = new map<string,User>();
        list< user > lstUser =[SELECT Id,Username,Name,Email,Profile.Name FROM User WHERE username IN:setUserName ];
        for( user varUser: lstUser ){
            if( string.isNotBlank( varUser.username )){
                mapDocumentUser.put( varUser.Username, varUser );
            }            
        }      
        return mapDocumentUser;    
    } 

  
    public static map<string, Account> getMapAccount( set<String> setDocument ){
        map<string,Account> mapAccount = new map<string,Account>();
        //user objCurrentUser = [SELECT Id,AM_Concesionario__c,profile.name,Username FROM User WHERE ID =: UserInfo.getUserId() ];
        //boolean isAdmin = false;    
        //list< string > lstAdminUser = new list<string>{'dcrodriguez','crgutierrez','lquinayas','admin@fanalca'};
        //for( string varString: lstAdminUser ) {
        //    if( objCurrentUser.Username.contains( varString ) ){
        //        isAdmin= true;
        //    }
        //}
        //system.debug('\n is admin @@'+isAdmin);

        list< Account > lstAccount =[SELECT Id,Name,AM_Numero_de_documento__c,owner.AM_Concesionario__c, OwnerId, Owner.Profile.Name,Owner.UserName FROM Account WHERE AM_Numero_de_documento__c IN:setDocument ];
        for( Account  varAccount: lstAccount ){
            if( string.isNotBlank( varAccount.AM_Numero_de_documento__c )   ){
                mapAccount.put( varAccount.AM_Numero_de_documento__c, varAccount );
            }            
        }      
        system.debug('\n map account @@@' + mapAccount );
        return mapAccount;   
    }
    
    @AuraEnabled
    public static recordsToProcess processAccounts(list<accountOwnerChangesData> lstDatosCuentas){
        system.debug(lstDatosCuentas.size());
        DateTime horaInicioProceso = system.now();
        
        recordsToProcess totalRecordsProcess = new recordsToProcess();
        //list<tasksOwnerChangesData> lstTasksToProcess = new list<tasksOwnerChangesData>();
        map<Id,tasksOwnerChangesData> mapDatosTasks = new map<Id,tasksOwnerChangesData>();
            
        //1. Prepare Account Data to send to update in batch class
        list<Account> lstCuentas;
        map<Id,accountOwnerChangesData> mapDatosCuentas = new map<Id,accountOwnerChangesData>();
        set<Id> newOwnerIds = new set<Id>();
        set<Id> oldOwnerIds = new set<Id>();
        map<Id, list<Id>> mapConcesionariosXUsuario = new map<Id, list<Id>>();
        
        for (accountOwnerChangesData data: lstDatosCuentas){
            system.debug(data);
            mapDatosCuentas.put(data.accountId, data);
            newOwnerIds.add(data.newOwnerId);  
            oldOwnerIds.add(data.oldOwnerId);
            
            //for tasks, to get the whatids for accounts
            tasksOwnerChangesData datoTaskAccount = new tasksOwnerChangesData();
            datoTaskAccount.whatId = data.AccountId;
            datoTaskAccount.newOwnerId = data.newOwnerId;
            datoTaskAccount.oldOwnerId = data.oldOwnerId;
            datoTaskAccount.oldOwnerProfileName = data.oldOwnerProfileName;
            datoTaskAccount.newOwnerProfileName = data.newOwnerProfileName;
            mapDatosTasks.put(datoTaskAccount.whatId, datoTaskAccount);
            //lstTasksToProcess.add(datoTaskAccount);
        }
        
        
        
        for (Miembro_de_Concesionario__c mc: [Select Id,Nombre_de_asesor__c,Concesionario__c from Miembro_de_Concesionario__c where Nombre_de_asesor__c in: newOwnerIds]){
            if (!mapConcesionariosXUsuario.containsKey(mc.Nombre_de_asesor__c)) mapConcesionariosXUsuario.put(mc.Nombre_de_asesor__c, new list<Id>());
            mapConcesionariosXUsuario.get(mc.Nombre_de_asesor__c).add(mc.Concesionario__c);
        }
        
        lstCuentas = [Select Id, OwnerId from Account where Id in:mapDatosCuentas.keySet()];
        
        for (Account acc: lstCuentas){
            acc.OwnerId = mapDatosCuentas.get(acc.Id).newOwnerId;
            //buscar en el mapa de concesionarios por usuario y setear concesionario cuando solo tiene un concesionario matriculado el new owner
            if (mapConcesionariosXUsuario.containsKey(acc.OwnerId)){
                if (mapConcesionariosXUsuario.get(acc.OwnerId).size()==1) acc.Concesionario_Vitrina__c= mapConcesionariosXUsuario.get(acc.OwnerId)[0];
            }
        }
        
        
        totalRecordsProcess.nCuentas = lstCuentas.size();
        if (lstCuentas.size()>0){
            System.debug('Ready to update ' + lstCuentas.size() + ' accounts.');
            ChangeAccountOwnerCSVBatch batchable = new ChangeAccountOwnerCSVBatch(lstCuentas, 'Cuentas',horaInicioProceso);
            Database.executebatch(batchable, 1);    
        }
        
        
        //2. Prepare Opportunity Data
        set<String> setAllStages = new Set<String>{'P0', 'P1', 'P2', 'P3', 'P4', 'P5','-P0', '-P1', '-P2', '-P3'};
        list<Opportunity> lstOppsToProcess = new list<Opportunity>();
        list<Opportunity> allOppsRelated = [Select AccountId, Id, OwnerId, Owner.Name,Owner.Profile.Name, recordType.DeveloperName from Opportunity where StageName IN: setAllStages AND AccountId in:mapDatosCuentas.keySet()  AND OwnerId in:oldOwnerIds];
        for (Opportunity op: allOppsRelated) {
            accountOwnerChangesData datoCuenta = mapDatosCuentas.get(op.AccountId);
            
            if (datoCuenta!=null && op.OwnerId == datoCuenta.oldOwnerId) {
                if ( (op.recordType.DeveloperName.toUpperCase().contains('MOTO') && datoCuenta.newOwnerProfileName.toUpperCase().contains('MOTO')) || (op.recordType.DeveloperName.toUpperCase().contains('AUTO') && datoCuenta.newOwnerProfileName.toUpperCase().contains('AUTO'))){
                    op.OwnerId = datoCuenta.newOwnerId;
                    
                    //buscar en el mapa de concesionarios por usuario y setear concesionario cuando solo tiene un concesionario matriculado el new owner
                    if (mapConcesionariosXUsuario.containsKey(op.OwnerId)){
                        if (mapConcesionariosXUsuario.get(op.OwnerId).size()==1) op.Vitrina__c= mapConcesionariosXUsuario.get(op.OwnerId)[0];
                    }
                    
                    lstOppsToProcess.add(op);   
                    system.debug('op to UpdateOwner: ' + op);
                    
                    //for tasks, to get the whatids for opps
                    tasksOwnerChangesData datoTaskAccount = new tasksOwnerChangesData();
                    datoTaskAccount.whatId = op.Id;
                    datoTaskAccount.newOwnerId = datoCuenta.newOwnerId;
                    datoTaskAccount.oldOwnerId = datoCuenta.oldOwnerId;
                    datoTaskAccount.oldOwnerProfileName = datoCuenta.oldOwnerProfileName;
                    datoTaskAccount.newOwnerProfileName = datoCuenta.newOwnerProfileName;
                    mapDatosTasks.put(datoTaskAccount.whatId, datoTaskAccount);
                    //lstTasksToProcess.add(datoTaskAccount);
                }
            }
        }
        
        totalRecordsProcess.nOportunidades = lstOppsToProcess.size();
        if (lstOppsToProcess.size()>0){
            System.debug('Ready to update ' + lstOppsToProcess.size() + ' opps.');
            ChangeAccountOwnerCSVBatch batchable = new ChangeAccountOwnerCSVBatch(lstOppsToProcess,'Oportunidades',horaInicioProceso);
            Database.executebatch(batchable, 1);    
        }
        
        //3. Prepare Contactos to update
        list<Contact> lstAllContactsRelated = [Select Id, OwnerId,AccountId from Contact where Account.RecordType.DeveloperName = 'AM_CUE_Cuenta_empresarial' AND OwnerId in: oldOwnerIds AND AccountId in: mapDatosCuentas.keySet()];
        list<Contact> lstContactsToProcess = new list<Contact>();
        
        for (contact c: lstAllContactsRelated){
            accountOwnerChangesData datoCuenta = mapDatosCuentas.get(c.AccountId);    
            if (c.OwnerId == datoCuenta.oldOwnerId) {
                c.ownerId= datoCuenta.newOwnerId;
                lstContactsToProcess.add(c);
            }
        }
        
        totalRecordsProcess.nContactos = lstContactsToProcess.size();
        if (lstContactsToProcess.size()>0){
            System.debug('Ready to update ' + lstContactsToProcess.size() + ' contacs.');
            ChangeAccountOwnerCSVBatch batchable = new ChangeAccountOwnerCSVBatch(lstContactsToProcess, 'Contactos',horaInicioProceso);
            Database.executebatch(batchable, 1);    
        }
        
        //4. Related Tasks, from accounts and opps
        list<Task> lstTasksToProcess = new list<Task>();       
        list<Task> allTasksRelated = [Select ActivityDate,Subject, WhatId,What.Type, Id, OwnerId, Owner.Name,Owner.Profile.Name, recordType.DeveloperName from Task where WhatId IN: mapDatosTasks.keySet() and Status = 'Programada' AND OwnerId in:oldOwnerIds AND RecordTypeId <> null];
        for (Task t: allTasksRelated) {
            tasksOwnerChangesData datoTask = mapDatosTasks.get(t.whatId);
           
            if (datoTask!=null && t.OwnerId == datoTask.oldOwnerId) {
                if ( (t.recordType.DeveloperName.toUpperCase().contains('MOTO') && datoTask.newOwnerProfileName.toUpperCase().contains('MOTO')) || (t.recordType.DeveloperName.toUpperCase().contains('AUTO') && datoTask.newOwnerProfileName.toUpperCase().contains('AUTO'))){
                    t.OwnerId = datoTask.newOwnerId;
                    lstTasksToProcess.add(t);   
                    system.debug('t to UpdateOwner: ' + t);
                }
            }
        }
        
        totalRecordsProcess.nTareas = lstTasksToProcess.size();
        if (lstTasksToProcess.size()>0){
            System.debug('Ready to update ' + lstTasksToProcess.size() + ' tasks.');
            ChangeAccountOwnerCSVBatch batchable = new ChangeAccountOwnerCSVBatch(lstTasksToProcess, 'Tareas',horaInicioProceso);
            Database.executebatch(batchable, 1);    
        }
        
        //5. Related Accounts
        list<Account> lstAccountsToProcess = new list<Account>();
        List<Relacion_de_Cuenta__c> lstRelaciones = [Select Id, Cuenta_Relacionada__c,Cuenta_Relacionada__r.OwnerId,Cuenta_Principal__c From Relacion_de_Cuenta__c Where Cuenta_Principal__c =: mapDatosCuentas.keySet() AND Cuenta_Relacionada__r.OwnerId in: oldOwnerIds];
        for(Relacion_de_Cuenta__c rel : lstRelaciones) {
            accountOwnerChangesData datoCuenta = mapDatosCuentas.get(rel.Cuenta_Principal__c);  
            if (rel.Cuenta_Relacionada__r.OwnerId == datoCuenta.oldOwnerId){
                Account acc = new Account(Id=rel.Cuenta_Relacionada__c, OwnerId=datoCuenta.newOwnerId);
                
                //buscar en el mapa de concesionarios por usuario y setear concesionario cuando solo tiene un concesionario matriculado el new owner
                if (mapConcesionariosXUsuario.containsKey(acc.OwnerId)){
                    if (mapConcesionariosXUsuario.get(acc.OwnerId).size()==1) acc.Concesionario_Vitrina__c= mapConcesionariosXUsuario.get(acc.OwnerId)[0];
                }
                lstAccountsToProcess.add(acc);
            }
        }
        
        totalRecordsProcess.nCuentasRelacionadas = lstAccountsToProcess.size();
        if (lstAccountsToProcess.size()>0){
            System.debug('Ready to update ' + lstAccountsToProcess.size() + ' Cuentas Relacionadas.');
            ChangeAccountOwnerCSVBatch batchable = new ChangeAccountOwnerCSVBatch(lstAccountsToProcess,'Cuentas Relacionadas',horaInicioProceso);
            if (Test.isRunningTest()) Database.executebatch(batchable, 10);  
            else  Database.executebatch(batchable, 1);
        }
        
        //Indicates the permission in VRs
        //list<ReasignacionMasiva__c> lstReasignacionMasiva = [select Id from ReasignacionMasiva__c where Name=:UserINfo.getUserName()];
        
        //if (lstReasignacionMasiva.size()==0){
            //ReasignacionMasiva__c obj = new ReasignacionMasiva__c(Name = UserINfo.getUserName(),SetupOwnerId = UserINfo.getUserId());
        //    obj.Id_Usuario__c = UserInfo.getUserId();
        //    insert obj;
        //    system.debug(obj);    
        //}
        
        ReasignacionMasiva__c obj = ReasignacionMasiva__c.getValues(UserINfo.getUserId());
        system.debug(obj);  
        if (obj==null) {
            obj = new ReasignacionMasiva__c(Name=UserINfo.getUserName(), Id_Usuario__c=UserInfo.getUserId(), SetupOwnerId = UserINfo.getUserId());
            insert obj;
            system.debug(obj);    
        }
                
        //Return the summary records to update
        return totalRecordsProcess;
    }
    
    public class accountOwnerChangesData{
        @AuraEnabled public  string numeroDocumento { get; set;}
        @AuraEnabled public  string accountName  { get; set;}
        @AuraEnabled public  string accountId  { get; set;}
        @AuraEnabled public  string newOwner { get; set;}
        @AuraEnabled public  string newOwnerId { get; set;}
        @AuraEnabled public  string newOwnerProfileName { get; set;}
        @AuraEnabled public  string oldOwner { get; set;}
        @AuraEnabled public  string oldOwnerId { get; set;}
        @AuraEnabled public  string oldOwnerProfileName { get; set;}
    }
    
    public class recordsToProcess{
        @AuraEnabled public Integer nCuentas {get;set;}
        @AuraEnabled public Integer nCuentasRelacionadas {get;set;}
        @AuraEnabled public Integer nContactos {get;set;}
        @AuraEnabled public Integer nOportunidades {get;set;}
        @AuraEnabled public Integer nTareas {get;set;}
    }
    
    public class tasksOwnerChangesData{
        @AuraEnabled public  string whatId  { get; set;}
        @AuraEnabled public  string newOwnerId { get; set;}
        @AuraEnabled public  string newOwnerProfileName { get; set;}
        @AuraEnabled public  string oldOwnerId { get; set;}
        @AuraEnabled public  string oldOwnerProfileName { get; set;}
    }
}