/******************************************************************************************************************
     * Autor:       AFOG Cloud Service
     * Descripción: Esta clase se utiliza  para desarrollar la lógica de reasignar clientes en SARHA y revisión del 
     *              campo agencia
     * Fecha:       11/12/2022
     * Referencia:  ORD:00069 Casos Salesforce Autos
     ******************************************************************************************************************/
public with sharing class AFOG_AccountTriggerHanler_cls {
    /******************************************************************************************************************
     * Autor:       AFOG Cloud Service
     * Descripción: En este método se identifica que el regsitro de cuenta a tenido un cambio de propietario y se 
     *              actualiza la cuenta con el concesionario del nuevo propietario
     * Fecha:       11/12/2022
     * Referencia:  ORD:00069 Casos Salesforce Autos
     ******************************************************************************************************************/
    public static void updateAccountOppConcesionario( map< id,account > mapNewAccount, map< id, account > mapOldAccount ){
        map< id,id >        mapAccUserId        = new map< id,id >(); 
        map< id,id >        mapAccountIdConcesi = new  map< id,id >();
        try {
            for( account varAcc: mapNewAccount.values() ){
                if( varAcc.OwnerId != mapOldAccount.get( varAcc.Id).OwnerId ){
                    mapAccUserId.put( varAcc.Id, varAcc.OwnerId );
                }
            } 
            system.debug('[AFOG_AccountTriggerHanler_cls][updateAccountOppConcesionario] mapAccUserId @@@@' +JSON.serializePretty( mapAccUserId ));  
            map< id,id > mapUserConcesionari= getMapUserConcesiorioId( mapAccUserId ); 
            system.debug('[AFOG_AccountTriggerHanler_cls][updateAccountOppConcesionario] mapUserConcesionari @@@@' +JSON.serializePretty( mapUserConcesionari ));  
           
            for( account varAcc: mapNewAccount.values() ){
                if( mapUserConcesionari.containsKey( varAcc.OwnerId )){
                    varAcc.Concesionario_Vitrina__c = mapUserConcesionari.get( varAcc.OwnerId );
                    mapAccountIdConcesi.put( varAcc.Id, mapUserConcesionari.get( varAcc.OwnerId ) );
                }
            } 
            system.debug('[AFOG_AccountTriggerHanler_cls][updateAccountOppConcesionario] mapAccountIdConcesi @@@@' +JSON.serializePretty( mapAccountIdConcesi ));  
              
    
            list< Opportunity> lstOppToUpdate = updateOpportunityConcesion(  mapUserConcesionari, mapAccountIdConcesi );
            system.debug('[AFOG_AccountTriggerHanler_cls][updateAccountOppConcesionario] lstOppToUpdate @@@@' +JSON.serializePretty( lstOppToUpdate ));  
           
            update lstOppToUpdate;
            
        } catch (Exception e ) {
            system.debug('[AFOG_AccountTriggerHanler_cls][updateAccountOppConcesionario] getCause @@@' + e.getCause()
                        +'[AFOG_AccountTriggerHanler_cls][updateAccountOppConcesionario] getLineNumber @@@'+ e.getLineNumber()
                        +'[AFOG_AccountTriggerHanler_cls][updateAccountOppConcesionario] getMessage @@@'+ e.getMessage() 
                        +'[AFOG_AccountTriggerHanler_cls][updateAccountOppConcesionario] getStackTraceString @@@'+ e.getStackTraceString()
                        +'[AFOG_AccountTriggerHanler_cls][updateAccountOppConcesionario] getTypeName @@@'+ e.getTypeName() );
        }
    } 

    /******************************************************************************************************************
     * Autor:       AFOG Cloud Service
     * Descripción: En este método se identifica que el regsitro de cuenta a tenido un cambio de propietario y se 
     *              actualiza la cuenta con el concesionario del nuevo propietario
     * Fecha:       11/12/2022
     * Referencia:  ORD:00069 Casos Salesforce Autos
     ******************************************************************************************************************/
    public static list< Opportunity> updateOpportunityConcesion(  map< id,id > mapUserConcesionariY, map< id,id > mapAccountIdConcesiY ){
        list< Opportunity>  lstOppToUpdate = new list< Opportunity>();
        list< Opportunity > lstOppor = [SELECT Id,OwnerId,Concesionario__c,AccountId FROM Opportunity WHERE AccountId IN: mapAccountIdConcesiY.keySet()];
        for( Opportunity varOpp: lstOppor ){
            if (  mapAccountIdConcesiY.containsKey( varOpp.AccountId ) ) {
                varOpp.Concesionario__c = mapAccountIdConcesiY.get( varOpp.AccountId );
                varOpp.Vitrina__c   =   mapAccountIdConcesiY.get( varOpp.AccountId );
                lstOppToUpdate.add( varOpp );
            }
        }
        return lstOppToUpdate ;
    }


     /******************************************************************************************************************
     * Autor:       AFOG Cloud Service
     * Descripción: En este método se obtiene los registros de usuario y concesiontario
     * Fecha:       11/12/2022
     * Referencia:  ORD:00069 Casos Salesforce Autos
     ******************************************************************************************************************/ 
    public static  map< id,id >  getMapUserConcesiorioId( map< id,id > mapAccUserIdX  ){
        map< id,string >    mapUserId           = new map< id, string >();
        map< id,id >        mapUserIdConcesio   = new map< id, id >(); // key==> userId  value ==> concesionario Id
        map< string,id >    mapUsername         = new map< string, id >();
        List< user > lstUsers = [SELECT Id,Username FROM User WHERE Id IN: mapAccUserIdX.values()];
        system.debug('[AFOG_AccountTriggerHanler_cls][getMapUserConcesiorioId] @@@@ '+ JSON.serializePretty( lstUsers ));
        for( user varU: lstUsers ){
            mapUserId.put( varU.Id, varU.Username );
            mapUsername.put( varU.Username , varU.Id);
        }
        system.debug('[AFOG_AccountTriggerHanler_cls][mapUserId] @@@@ '+ JSON.serializePretty( mapUserId ));
        system.debug('[AFOG_AccountTriggerHanler_cls][mapUsername] @@@@ '+ JSON.serializePretty( mapUsername ));
        
        list< AFOG_UsuarioConcesionario__c > lstUsuarioConcesionario = [SELECT id,name,AFOG_ConcesionarioVitrina__c, AFOG_UserName__c 
                                                                        FROM AFOG_UsuarioConcesionario__c 
                                                                        WHERE  AFOG_UserName__c IN: mapUsername.keySet()];

        system.debug('[AFOG_AccountTriggerHanler_cls][lstUsuarioConcesionario] @@@@ '+ JSON.serializePretty( lstUsuarioConcesionario ));
        
        for( AFOG_UsuarioConcesionario__c varConces: lstUsuarioConcesionario ){
            if( mapUsername.containsKey( varConces.AFOG_UserName__c) ){
                mapUserIdConcesio.put( mapUsername.get( varConces.AFOG_UserName__c), varConces.AFOG_ConcesionarioVitrina__c );
            }            
        }
        system.debug('[AFOG_AccountTriggerHanler_cls][mapUserIdConcesio] @@@@ '+ JSON.serializePretty( mapUserIdConcesio ));
      
        return mapUserIdConcesio;
    }

}