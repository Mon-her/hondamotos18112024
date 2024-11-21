/**
* Fanalca
* @author           Raul Mora
* Description:      Account trigger handler class.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     06/12/2018      Raul Mora (RM)          Class definition.
*********************************************************************************************************/
public class RM_AccountTriggerHandler_cls {
    //Avoid recursive call.
    public static boolean blnFirstRun = true;
    public static boolean blnSpouseAcc = false;
    
    /**
    * @Method:      accountBeforeInsert
    * @param:       List Account
    * @Description: Manage account before inser event.
    * @author       Raul Mora - 03122018
    */
    public static void accountBeforeInsert( List<Account> lstAccount ){
        createSpouseAccount( lstAccount, null );
        if( !blnSpouseAcc ) {
            createLegalRepresentativeAccount( lstAccount, null );    
        }
        
    }
    /**
    * @Method:      accountBeforeUpdate
    * @param:       List Account
    * @Description: Manage account before update event.
    * @author       Raul Mora - 10122018
    */
    public static void accountBeforeUpdate( List<Account> lstAccount, Map<ID,Account> mpOldAccount ){
        createSpouseAccount( lstAccount, mpOldAccount );
        if( !blnSpouseAcc ) {
            createLegalRepresentativeAccount( lstAccount, mpOldAccount );
        }
    }
    
    /**
    * @Method:      createSpouseAccount
    * @param:       List Account
    * @Description: Create an account based on the fields filled on the spouse section when another account is created or modified.
    * @author       Raul Mora - 03122018
    * @Mofify       Andrés Oliva -07022021 Replace phone by personMobilePhone personal account. 
    */
    public static void createSpouseAccount( List<Account> lstAccount, Map<ID,Account> mpOldAccount ){
        List<Account> lstAccNew = new List<Account>();
        Map<String,String> mpSpouseMainAccDoc = new Map<String,String>();
        Set<String> stNumDoc = new Set<String>();
        Account objAccTemp;
        String strSecondLastName;
        String strSecondFirstName;
        Boolean blnPopulatePrimary = false;
        Boolean blnChangeNumeroDoc = false;
        Boolean blnInfoOnly = false;
        RecordType objRecType = [ Select Id
                                  From RecordType
                                  Where SobjectType = 'Account'
                                  And DeveloperName = 'AM_CUE_Persona_natural' Limit 1 ];
        for( Account objAcc : lstAccount ) {
            if( ( mpOldAccount == null ) || ( mpOldAccount != null && mpOldAccount.get( objAcc.Id ).AM_Numero_de_documento_conyuge__c == null && objAcc.AM_Numero_de_documento_conyuge__c != null ) ) {
                blnChangeNumeroDoc = true;
                if( objAcc.RecordTypeId == objRecType.Id && objAcc.AM_Tipo_de_documento_conyuge__c != null && objAcc.AM_Numero_de_documento_conyuge__c != null && objAcc.AM_Primer_Apellido_Conyuge__pc != null ) {
                    strSecondLastName = objAcc.AM_Segundo_Apellido_Conyuge__pc != null ? ' ' + objAcc.AM_Segundo_Apellido_Conyuge__pc : '';
                    strSecondFirstName  = objAcc.AM_Segundo_Nombre_Conyuge__pc != null ? ' ' + objAcc.AM_Segundo_Nombre_Conyuge__pc : '';
                    objAccTemp = new Account();    
                    objAccTemp.RecordTypeId = objRecType.Id;
                    objAccTemp.Salutation = objAcc.Salutation == 'Sr' ? 'Sra' : 'Sr';
                    objAccTemp.AM_Tipo_de_documento__c = objAcc.AM_Tipo_de_documento_conyuge__c;
                    objAccTemp.AM_Numero_de_documento__c = objAcc.AM_Numero_de_documento_conyuge__c;
                    stNumDoc.add( objAccTemp.AM_Numero_de_documento__c );
                    objAccTemp.LastName = objAcc.AM_Primer_Apellido_Conyuge__pc + strSecondLastName;
                    objAccTemp.FirstName = ( objAcc.AM_Primer_Nombre_Conyuge__pc != null ? objAcc.AM_Primer_Nombre_Conyuge__pc : '' ) + strSecondFirstName;
                    objAccTemp.AM_Ocupacion__pc = objAcc.AM_Ocupacion_Conyuge__pc;
                    objAccTemp.AM_En_cual_actividad_clasifica_su_labor__pc = objAcc.AM_En_cual_actividad_clasifica_Conyuge__pc;
                    objAccTemp.PersonMobilePhone = objAcc.AM_Movil_Conyuge__pc; // AO 07/02/2021 Replace phone by personMobilePhone
                    objAccTemp.PersonOtherPhone = objAcc.AM_Tel_Trabajo_Conyuge__pc;            
                    objAccTemp.PersonEmail = objAcc.AM_Email_trabajo_Conyuge__pc;
                    objAccTemp.PersonHasOptedOutOfEmail = objAcc.No_recibir_correos_electr_nicos_conyuge__c;
                    objAccTemp.RM_Cuenta_Relacionada__c = mpOldAccount != null ? objAcc.Id : null;
                    mpSpouseMainAccDoc.put( objAccTemp.AM_Numero_de_documento__c, objAcc.AM_Numero_de_documento__c );
                    lstAccNew.add( objAccTemp );
                } 
            }
        }
        if( !lstAccNew.isEmpty() ) {
            List<Account> lstAccDuplicated = [ Select Id, AM_Numero_de_documento__c  
                                               From Account 
                                               Where AM_Numero_de_documento__c IN: stNumDoc ];
            if( !lstAccDuplicated.isEmpty() ) {
                blnInfoOnly = true;
                stNumDoc.clear();
                for( Account objA : lstAccDuplicated ) {
                    stNumDoc.add( objA.AM_Numero_de_documento__c );
                }
                for( Integer i = 0; lstAccNew.size() > i; i++ ) {
                    if( stNumDoc.contains( lstAccNew.get( i ).AM_Numero_de_documento__c ) ) {
                        lstAccNew.remove( i );
                    }
                }
            }  
        }
        if( !lstAccNew.isEmpty() ) {        
            Database.SaveResult[] srList = Database.insert( lstAccNew, false );
            blnSpouseAcc = true;
            /*try {
            insert lstAccNew;
            } catch (Exception e) {
            Trigger.new[0].addError( 'Favor revisar los datos del Cónyuge ' + e. );
            }*/
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful.
                    blnPopulatePrimary = true;
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        Trigger.new[0].addError( 'Favor revisar los datos del Cónyuge: ' + err.getMessage() );     
                        //System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
            if( blnPopulatePrimary && mpOldAccount == null ) {
                populatePrimaryAccount( mpSpouseMainAccDoc );
            }
        } else if( mpOldAccount != null && lstAccNew.isEmpty() && blnChangeNumeroDoc && !blnInfoOnly ) {
            Trigger.new[0].addError( 'Favor completar los datos del Cónyuge' );  
        }
    }
    
    /**
    * @Method:      createLegalRepresentativeAccount
    * @param:       List Account
    * @Description: Create an account based on the fields filled on the legal representative section when another account is created or modified.
    * @author       Raul Mora - 17122018
    */
    public static void createLegalRepresentativeAccount( List<Account> lstAccount, Map<ID,Account> mpOldAccount ){
        List<Account> lstAccNew = new List<Account>();
        Map<String,String> mpMainAccDoc = new Map<String,String>();
        Set<String> stNumDoc = new Set<String>();
        Account objAccTemp;
        String strSecondLastName;
        String strSecondFirstName;
        Boolean blnPopulatePrimary = false;
        Boolean blnChangeNumeroDoc = false;
        Boolean blnInfoOnly = false;
        RecordType objRecType = [ Select Id
                                  From RecordType
                                  Where SobjectType = 'Account'
                                  And DeveloperName = 'AM_CUE_Cuenta_empresarial' Limit 1 ];
        for( Account objAcc : lstAccount ) {
            if( ( mpOldAccount == null ) || ( mpOldAccount != null && mpOldAccount.get( objAcc.Id ).AM_Numero_de_documento_representante__c == null && objAcc.AM_Numero_de_documento_representante__c != null ) ) {
                blnChangeNumeroDoc = true;
                if( objAcc.RecordTypeId == objRecType.Id && objAcc.AM_Tipo_de_documento_representante__c != null && objAcc.AM_Numero_de_documento_representante__c != null && objAcc.AM_Primer_apellido_representante__c != null ) {
                    strSecondLastName = objAcc.AM_Segundo_apellido_representante__c != null ? ' ' + objAcc.AM_Segundo_apellido_representante__c : '';
                    strSecondFirstName  = objAcc.AM_Segundo_nombre_representante__c != null ? ' ' + objAcc.AM_Segundo_nombre_representante__c : '';
                    objAccTemp = new Account();    
                    objAccTemp.Salutation = objAcc.Salutation == 'Sr' ? 'Sra' : 'Sr';
                    objAccTemp.AM_Tipo_de_documento__c = objAcc.AM_Tipo_de_documento_representante__c;
                    objAccTemp.AM_Numero_de_documento__c = '' + objAcc.AM_Numero_de_documento_representante__c;
                    stNumDoc.add( objAccTemp.AM_Numero_de_documento__c );
                    objAccTemp.LastName = objAcc.AM_Primer_apellido_representante__c + strSecondLastName;
                    objAccTemp.FirstName = ( objAcc.AM_Primer_nombre_representante__c != null ? objAcc.AM_Primer_nombre_representante__c : '' ) + strSecondFirstName;
                    //objAccTemp.AM_Ocupacion__pc = objAcc.AM_Ocupacion_Conyuge__pc;
                    //objAccTemp.AM_En_cual_actividad_clasifica_su_labor__pc = objAcc.AM_En_cual_actividad_clasifica_Conyuge__pc;
                    objAccTemp.PersonMobilePhone = objAcc.AM_Telefono_representante__c; // 07/02/2021 AO relace phone by fax 
                    //objAccTemp.PersonOtherPhone = objAcc.AM_Tel_Trabajo_Conyuge__pc; 
                    objAccTemp.PersonHasOptedOutOfEmail = objAcc.AM_No_recibir_correos_elect_contacto__c;           
                    objAccTemp.PersonEmail = objAcc.AM_Correo_electronico_representante__c;
                    objAccTemp.RM_Cuenta_Relacionada__c = mpOldAccount != null ? objAcc.Id : null;
                    mpMainAccDoc.put( objAccTemp.AM_Numero_de_documento__c, objAcc.AM_Numero_de_documento__c );
                    lstAccNew.add( objAccTemp );
                } 
            }
        }
        if( !lstAccNew.isEmpty() ) {
            List<Account> lstAccDuplicated = [ Select Id, AM_Numero_de_documento__c  
                                               From Account 
                                               Where AM_Numero_de_documento__c IN: stNumDoc ];
            system.debug('\n\n--> lst dup '+lstAccDuplicated);
            if( !lstAccDuplicated.isEmpty() ) {
                blnInfoOnly = true;
                stNumDoc.clear();
                for( Account objA : lstAccDuplicated ) {
                    stNumDoc.add( objA.AM_Numero_de_documento__c );
                }
                for( Integer i = 0; lstAccNew.size() > i; i++ ) {
                    if( stNumDoc.contains( lstAccNew.get( i ).AM_Numero_de_documento__c ) ) {
                        system.debug('\n\n--> in for ich ');
                        lstAccNew.remove( i );
                        system.debug('\n\n--> lst after remove '+lstAccNew);
                    }
                }
            }  
        }
        if( !lstAccNew.isEmpty() ) {
            Database.SaveResult[] srList = Database.insert( lstAccNew, false );
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful.
                    blnPopulatePrimary = true;
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        Trigger.new[0].addError( 'Favor revisar los datos del Representante Legal: ' + err.getMessage() );     
                        //System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
            if( blnPopulatePrimary && mpOldAccount == null ) {
                populatePrimaryAccount( mpMainAccDoc );
            }
            
        } else if( mpOldAccount != null && lstAccNew.isEmpty() && blnChangeNumeroDoc && !blnInfoOnly ) {
            Trigger.new[0].addError( 'Favor completar los datos del Representante Legal' );  
        }
    }
    /**
    * @Method:      populatePrimaryAccount
    * @param:       Map<String,String>
    * @Description: Update created spouse account with the id of the parent account.
    * @author       Raul Mora - 03122018
    */
    @future
    public static void populatePrimaryAccount( Map<String,String> mpAccDoc ) {
        system.debug( '--> primary acc '+mpAccDoc.values() );
        system.debug( '--> spouse acc ' + mpAccDoc.keySet() );
        Map<String,String> mpMainIdDoc = new Map<String,String>();
        List<Account> lstAccUpdate = new List<Account>();
        List<Account> lstAcc = [ Select Id, AM_Numero_de_documento__c 
                                 From Account
                                 Where AM_Numero_de_documento__c IN: mpAccDoc.keySet()
                                 Or AM_Numero_de_documento__c IN: mpAccDoc.values() ];
        system.debug( '--> lstAcc ' + lstAcc );
        for( Account objAcc : lstAcc ) {
            if( !mpAccDoc.containsKey( objAcc.AM_Numero_de_documento__c ) ) {
                mpMainIdDoc.put( objAcc.AM_Numero_de_documento__c, objAcc.Id );
            }            
        }
        
        for( Account objAcc : lstAcc ) {
            if( mpAccDoc.containsKey( objAcc.AM_Numero_de_documento__c ) ) {
                objAcc.RM_Cuenta_Relacionada__c = mpMainIdDoc.get( mpAccDoc.get( objAcc.AM_Numero_de_documento__c ) );
                lstAccUpdate.add( objAcc );
            }            
        }
        
        if( !lstAccUpdate.isEmpty() ) {
            update lstAccUpdate;
        }
    }
    
}