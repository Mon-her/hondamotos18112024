/*************************************************************************************************************
 * @name			LWCExampleController
 * @author			Andres Oliva <andresoliva@gmail.com>
 * @created			19 / 07 / 2020
 * @description		Description of your code
 *
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 * 				No.		Date			Author					Description
 * 				----	------------	--------------------	----------------------------------------------
 * @version		1.0		2020-07-19		Andres Oliva			Changes desription
 *
**************************************************************************************************************/
public WITH sharing class LWCExampleController {


    /*********************************************************************************************************
     * @name			The name of your class or method
     * @author			Andres Oliva <andresoliva@gmail.com>
     * @created			19 / 07 / 2020
     * @description		Description of your code
     * @param			String param : Explanation
     * @return			Explanation of the return value
    **********************************************************************************************************/
    @AuraEnabled
    public static list<wrpNewOwner> readCSVFile(Id idContentDocument){
      //  list<Account> lstAccsToInsert = new list<Account>();
        list< TECH_ChangeUser__c > lstChangeUserOld = [SELECT Id,Name,TECH_NewUser__c, Tech_User__c, Tech_User__R.id  FROM TECH_ChangeUser__c ];
        delete lstChangeUserOld;
        list<wrpNewOwner> lstWrpNewOwner = new list<wrpNewOwner>();
        if(idContentDocument != null) {            
            // getting File Data based on document id 
            try{    
                ContentVersion objVersion = [SELECT Id, VersionData FROM ContentVersion WHERE ContentDocumentId =:idContentDocument];
                // split the file data
                set< string > setUserName = new set< string >();
                set< string > setDocument = new set< string >();
                list<String> lstCSVLines = objVersion.VersionData.toString().split('\n');           
                for(Integer i = 1; i < lstCSVLines.size(); i++){
                    list<String> csvRowData = lstCSVLines[i].split(';'); 
                    csvRowData[1]= csvRowData[1].replaceAll( '\\s+', '');   
                    csvRowData[0]= csvRowData[0].replaceAll( '\\s+', '');                 
                    setUserName.add( csvRowData[1] );
                    setDocument.add( csvRowData[0] );
                }  
                system.debug('\n set username @@'+ setUserName );
                map<string,string> mapUser = getMapUser( setUserName );  
                map<string,string> mapAccount = getMapAccount( setDocument );  
                system.debug('\n map user @@@ '+ JSON.serializePretty( mapUser )); 
                list<TECH_ChangeUser__c>  lstChangeUser = new  list<TECH_ChangeUser__c>();         

                for(Integer i = 1; i < lstCSVLines.size(); i++){
                    list<String> csvRowData = lstCSVLines[i].split(';');
                    string strUserDocument= csvRowData[0].replaceAll( '\\s+', ''); 
                    string strUsername= csvRowData[1].replaceAll( '\\s+', ''); 
                    system.debug('\n document' +  strUserDocument + '\n username @@'+ csvRowData[1]+ '\ncontiene user @@' +  mapUser.containsKey( strUsername ) );
                    if( mapUser.containsKey( strUsername ) && mapAccount.containsKey( strUserDocument ) ){
                        wrpNewOwner objWrp = new wrpNewOwner();
                        objWrp.sDocument = strUserDocument; // Document
                        objWrp.sNewOwner = strUsername ; // UserName  
                        if(  mapAccount.containskey( strUserDocument ) ){
                            objWrp.sAccount  = mapAccount.get( strUserDocument );   
                        }                                         
                        lstWrpNewOwner.add( objWrp ); 
                        TECH_ChangeUser__c objChangeUser = new TECH_ChangeUser__c();
                        objChangeUser.Name = strUserDocument;
                        objChangeUser.TECH_NewUser__c = strUsername;
                        objChangeUser.Tech_User__c =  mapUser.get( strUsername ); 
                        objChangeUser.TECH_ContentDocument__c = idContentDocument;
                        if(  mapAccount.containskey( strUserDocument ) ){
                            objChangeUser.TECH_NombreCuenta__c = mapAccount.get( strUserDocument );
                        }
                        lstChangeUser.add( objChangeUser);    
                    }                         
                }
                system.debug('\N CSV FILE @@@' + JSON.serializePretty( lstCSVLines ) + '\n lst wrapper @@@' + JSON.serializePretty( lstWrpNewOwner ) );          
                if(!lstWrpNewOwner.isEmpty()) {
                    insert lstChangeUser;
                }
            }
            catch (Exception e) {
                System.debug( '\n\n\n\t<<<<<<<<< ExceptionType >>>>>>>>> \n\t\t@@--> getCause > ' + e.getCause() + '\n\t\t@@--> getLineNumber > ' + e.getLineNumber() + '\n\t\t@@--> getMessage > '+ e.getMessage() + '\n\t\t@@--> getStackTraceString > '+ e.getStackTraceString() + '\n\t\t@@--> getTypeName > ' + e.getTypeName() + '\n\n' );	
                throw new AuraHandledException('\n\n\n\t<<<<<<<<< ExceptionType >>>>>>>>> \n\t\t@@--> getCause > ' + e.getCause() + '\n\t\t@@--> getLineNumber > ' + e.getLineNumber() + '\n\t\t@@--> getMessage > '+ e.getMessage() + '\n\t\t@@--> getStackTraceString > '+ e.getStackTraceString() + '\n\t\t@@--> getTypeName > ' + e.getTypeName() + '\n\n');
            } 
        }
        return lstWrpNewOwner;
    }  

    /*********************************************************************************************************
     * @name			The name of your class or method
     * @author			Andres Oliva <andresoliva@gmail.com
     * @created			21 / 07 / 2020
     * @description		Description of your code
     * @param			String param : Explanation
     * @return			Explanation of the return value
    **********************************************************************************************************/
    @AuraEnabled
    public static void callUpdateUser(){      
        list< TECH_ChangeUser__c > lstChangeUser = [SELECT Id,Name,TECH_NewUser__c,TECH_ContentDocument__c, Tech_User__c, Tech_User__R.id  FROM TECH_ChangeUser__c ];
        map< string, wrpNewOwner > mapWrp = new map< string, wrpNewOwner >();
        set< id > setContentDocument = new set< id >();
        for( TECH_ChangeUser__c varChangU: lstChangeUser ){
            setContentDocument.add( varChangU.TECH_ContentDocument__c );
            if( string.IsNotBlank( varChangU.Name ) && string.IsNotBlank(  varChangU.Tech_User__R.id) ){
                wrpNewOwner objWRP = new wrpNewOwner();
                objWRP.sDocument    = varChangU.Name;
                objWRP.sNewOwner    = varChangU.Tech_User__R.id;
                mapWrp.put( varChangU.Name , objWRP );
            }
        }
        changeUserOwner( mapWrp );
        deleteContentDocument( setContentDocument );        
        delete lstChangeUser;        
    }
    /*********************************************************************************************************
     * @name			deleteContentDocument
     * @author			Andres Oliva <andresolivag@gmail.com>
     * @created			16 / 09 / 2020
     * @description		Description of your code
     * @param			set< id >: set contect document id
     * @return			
    **********************************************************************************************************/
    public static void deleteContentDocument( set< id > setContentDocumentId ){
        List<ContentDocument> lstContentDocument =[SELECT FileExtension,FileType,Id,Title FROM ContentDocument WHERE  ID IN: setContentDocumentId];
        delete lstContentDocument;
    }
    /*********************************************************************************************************
     * @name			getMapUser
     * @author			Andres Oliva <andresolivag@gmail.com>
     * @created			20 / 07 / 2020
     * @description		Description of your code
     * @param			String param : Explanation
     * @return			Explanation of the return value
    **********************************************************************************************************/
    public static map<string,string> getMapUser( set<String> setUserName ){
        map<string,string> mapDocumentUser = new map<string,string>();
        list< user > lstUser =[SELECT Id,username FROM User WHERE username IN:setUserName ];
        for( user varUser: lstUser ){
            if( string.isNotBlank( varUser.username )){
                mapDocumentUser.put( varUser.username, varUser.Id );
            }            
        }      
        return mapDocumentUser;    
    } 

    /*********************************************************************************************************
     * @name			The name of your class or method
     * @author			Andres Oliva <andresoliva@gmail.com>
     * @created			22 / 07 / 2020
     * @description		Description of your code
     * @param			String param : Explanation
     * @return			Explanation of the return value
    **********************************************************************************************************/
    public static map<string, string> getMapAccount( set<String> setDocuemnt ){
        map<string,string> mapAccount = new map<string,string>();
        user objCurrentUser = [SELECT Id,AM_Concesionario__c,profile.name,Username FROM User WHERE ID =: UserInfo.getUserId() ];
        boolean isAdmin = false;    
        list< string > lstAdminUser = new list<string>{'dcrodriguez','crgutierrez','lquinayas','admin@fanalca'};
        if(objCurrentUser.AM_Concesionario__c  != null && objCurrentUser.AM_Concesionario__c == 'FANALCA'){
            isAdmin= true;
        }
        for( string varString: lstAdminUser ) {
            if( objCurrentUser.Username.contains( varString ) ){
                isAdmin= true;
            }
        }
        system.debug('\n is admin @@'+isAdmin);

        list< Account > lstAccount =[SELECT Id,Name,AM_Numero_de_documento__c,owner.AM_Concesionario__c FROM Account WHERE AM_Numero_de_documento__c IN:setDocuemnt ];
        for( Account  varAccount: lstAccount ){
            if( string.isNotBlank( varAccount.AM_Numero_de_documento__c ) && ( ( string.isnotblank( varAccount.owner.AM_Concesionario__c ) && varAccount.owner.AM_Concesionario__c.equalsIgnoreCase( objCurrentUser.AM_Concesionario__c ) )|| isAdmin  )  ){
                mapAccount.put( varAccount.AM_Numero_de_documento__c, varAccount.Name );
            }            
        }      
        system.debug('\n map account @@@' + mapAccount );
        return mapAccount;   
    }


    /*********************************************************************************************************
     * @name			The name of your class or method
     * @author			Andres Oliva <andresoliva@gmail.com>
     * @created			19 / 07 / 2020
     * @description		Description of your code
     * @param			String param : Explanation
     * @return			Explanation of the return value
    **********************************************************************************************************/
    @AuraEnabled
    public static void changeUserOwner ( map< string, wrpNewOwner > mapWrpNewOwner ){
        Set< string > setEtapa = new set< string >{'P0', 'P1', 'P2','P3','P4','P5'};
        string sProgramada = 'Programada';
        List< Account >  lstAccount= [  SELECT  AM_Numero_de_documento__c,ownerid,owner.name,Name,RM_Cuenta_Relacionada__r.name,
                                                RM_Cuenta_Relacionada__r.id,RM_Cuenta_Relacionada__r.owner.name,
                                                (Select id, AM_Etapa__c ,name,AM_Tipo_de_cotizacion__c from Oportunidades__r WHERE AM_Etapa__c IN: setEtapa ),
                                                (Select id,what.name,who.name,subject,owner.name from Tasks WHERE Status =: sProgramada)  
                                        FROM Account WHERE AM_Numero_de_documento__c IN:mapWrpNewOwner.keySet()];
        system.debug('\n lstAccounts ' + JSON.serializePretty( lstAccount));
        
       
        List<Account>           lstAccountUpt   = new list<Account>();       
        List<AM_Oportunidad__c> lstCotizacion   = new list<AM_Oportunidad__c>(); 
        List< sobject >         lstSobject      = new list< sobject >();    
        set<string >            setCuentaRelac  = new set< String>(); 
        map<string,string>      mapAccountOwner  = new map<string,string> (); 
        map< string, string  >  mapAccountContactID    = new  map< string, string  >();
        map< string, string  >  mapContactOwner    = new  map< string, string  >();
        set<id>                 setRentingQuote     = new set<id>();

        for( Account varAcc: lstAccount ){
            if(  mapWrpNewOwner.ContainsKey( varAcc.AM_Numero_de_documento__c ) && string.isNotBlank( mapWrpNewOwner.get( varAcc.AM_Numero_de_documento__c ).sNewOwner)){
                string strIdNewOwner = mapWrpNewOwner.get( varAcc.AM_Numero_de_documento__c ).sNewOwner;
                mapAccountOwner.put( varAcc.id, strIdNewOwner );
                Account objAccount= new Account(  id = varAcc.id , ownerId = strIdNewOwner );
                setCuentaRelac.add( varAcc.id );
                if(  string.isNotBlank( varAcc.RM_Cuenta_Relacionada__r.id )){
                    Account objRelatedAcc= new Account(  id = varAcc.RM_Cuenta_Relacionada__r.id, ownerId = strIdNewOwner );                    
                    if( !setCuentaRelac.contains( varAcc.RM_Cuenta_Relacionada__r.id ) ){
                        setCuentaRelac.add( varAcc.RM_Cuenta_Relacionada__r.id );
                        lstSobject.add( objRelatedAcc );
                    }
                }               
                
                lstSobject.add( objAccount );            
                for( AM_Oportunidad__c varOpp: varAcc.Oportunidades__r ){
                    if( varOpp.AM_Tipo_de_cotizacion__c != 'Renting' ){
                        AM_Oportunidad__c objOpp= new AM_Oportunidad__c(id = varOpp.id,ownerId = strIdNewOwner );
                        lstSobject.add( objOpp );  
                    }
                    else{
                        setRentingQuote.add( varOpp.Id );
                    }
                                     
                }
                                        
            }   
            system.debug('\n lst sobjects @@@' + JSON.serializePretty( lstSobject ) );

        }  
        list<Contact> lstContact = [ Select  Id,accountId FROM Contact WHERE accountId IN: mapAccountOwner.keySet() ];
        for( Contact varCont:lstContact ){
            if( mapAccountOwner.containsKey( varCont.AccountId ) ){
                mapAccountContactID.put( varCont.AccountId,varCont.id );
                mapContactOwner.put( varCont.id , mapAccountOwner.get( varCont.AccountId ));
            }           
        }
        list<task > lstTask =[SELECT ID,whoId,whatId FROM TASK where (whoId IN: mapAccountContactID.KeySet() or	whoid IN: mapAccountContactID.values()) and status ='Programada'];
        for(task varTask: lstTask ){
            //account
            if( mapAccountOwner.containsKey( varTask.whoID ) ){
                varTask.OwnerId= mapAccountOwner.get( varTask.whoID );
            }
            // contact
            else if( mapContactOwner.containsKey( varTask.whoID ) && !setRentingQuote.contains( varTask.whatId )){
                varTask.OwnerId= mapContactOwner.get( varTask.whoID );         
            }  
            lstSobject.add( varTask );           
        }
        list< Database.SaveResult > srAccount       = validateDmlUpdate( lstSobject );            
    }

    /*********************************************************************************************************
     * @name			validateDmlUpdate
     * @author			Andres Oliva <andresolivag@gmail.com
     * @created			19 / 07 / 2020
     * @description		Description of your code
     * @param			String param : Explanation
     * @return			Explanation of the return value
    **********************************************************************************************************/
    public static list< Database.SaveResult > validateDmlUpdate(list< sobject > lstSobject ){
        user objUser=[SELECT ID, AO_BypassApex__c FROM USER WHERE ID =: UserInfo.getUserId()];
        objUser.AO_BypassApex__c = true;
        update objUser;

        Database.SaveResult[] srObject = Database.update( lstSobject, false);
        // Iterate through each returned result
        for (Database.SaveResult sr : srObject) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted record. record ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('record fields that affected this error: ' + err.getFields());
                }
            }
        }
        objUser.AO_BypassApex__c = false;
        update objUser;
        return srObject;
    }
    /*********************************************************************************************************
     * @name			The name of your class or method
     * @author			Andres Oliva <andresolivag@gmail.com>
     * @created			19 / 07 / 2020
     * @description		Description of your code
     * @param			String param : Explanation
     * @return			Explanation of the return value
    **********************************************************************************************************/
    public class wrpNewOwner{
        @AuraEnabled public  string sDocument { get; set;}
        @AuraEnabled public  string sNewOwner { get; set;}
        @AuraEnabled public  string sAccount  { get; set;}
    }
}