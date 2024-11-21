/**
* Fanalca
* @author           Raul Mora
* Description:      Test class for Account trigger.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     24/12/2018      Raul Mora (RM)          Class definition.
*********************************************************************************************************/
@isTest
private class RM_AccountTriggerHandler_tst {
    
    public static void createData( Boolean blnFailScenario, Boolean blnSpouseAcc, Boolean blnUpdate ) {
        Concesionario__c oConcesion = new Concesionario__c();
        oConcesion.Name                     = 'Cali';
        oConcesion.Codigo_concesionario__c  = 'X9000';
        insert oConcesion;
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='testuser@fanalca.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName ='testuserAgencia@fanalca.com');
        insert u ;

        AFOG_UsuarioConcesionario__c oUsuarioConcesio = new AFOG_UsuarioConcesionario__c();
        oUsuarioConcesio.AFOG_ConcesionarioVitrina__c = oConcesion.id;
        oUsuarioConcesio.AFOG_UserName__c             = 'testuserAgencia@fanalca.com';
        insert oUsuarioConcesio;
       
        Account objAccount = new Account();
               objAccount.Phone = '3102334';
        if( blnSpouseAcc ) {
            objAccount.FirstName ='test';
            objAccount.LastName = 'Test';
            objAccount.Salutation = 'Sra.';
            objAccount.AM_Genero__pc = 'Masculino';
            objAccount.PersonEmail = 'test@test.com';
        }
        
        objAccount.AM_Como_se_entero_de_la_marca__c = 'Radio';
        objAccount.AM_Numero_de_documento__c = '93211232';
        objAccount.AM_Tipo_de_documento__c = 'Pasaporte';
        if( blnSpouseAcc ) {
            objAccount.AM_Tipo_de_documento_conyuge__c = 'Cédula de ciudadanía';
            objAccount.AM_Email_trabajo_Conyuge__pc = 'test@test.com';
            objAccount.AM_Tel_Trabajo_Conyuge__pc = '3212123';
            objAccount.AM_Movil_Conyuge__pc =  !blnFailScenario ? '3212121675' : '3212121675';
            objAccount.AM_En_cual_actividad_clasifica_Conyuge__pc = 'Administrativa';
            objAccount.AM_Ocupacion_Conyuge__pc = 'Otro';
            objAccount.AM_Primer_Nombre_Conyuge__pc = 'TestCon';
            objAccount.AM_Primer_Apellido_Conyuge__pc = 'TestCon';
            objAccount.AM_Numero_de_documento_conyuge__c = !blnFailScenario ? '93211211' : '';
        } else {
            RecordType objRecType = [ Select Id
                                      From RecordType
                                      Where SobjectType = 'Account'
                                      And DeveloperName = 'AM_CUE_Cuenta_empresarial' Limit 1 ];
            system.debug('\n\n--> rec typ '+objRecType);
            objAccount.Name = 'Test';
            objAccount.RecordTypeId = objRecType.Id;
            objAccount.Type = 'Privada';
            objAccount.Industry = 'Consultoria';
            objAccount.AM_Tipo_de_documento_representante__c = 'Cédula de ciudadanía';
            objAccount.AM_Correo_electronico_representante__c = 'test@test.com';
            objAccount.AM_Telefono_representante__c = !blnFailScenario ? '3104331234' : '3104331234';
            objAccount.AM_Primer_nombre_representante__c = 'TestCon';
            objAccount.AM_Primer_apellido_representante__c = 'TestCon';
            objAccount.AM_Numero_de_documento_representante__c = !blnFailScenario ? 93211211 : null;
        }        
            
        insert objAccount;
        if( blnUpdate ) {
            objAccount.AM_Email_trabajo_Conyuge__pc = 'test@test.com';
            objAccount.ownerId = u.id;
            update objAccount;
        }
            
        
    }
    
    static testMethod void myUnitTest() {
        RM_AccountTriggerHandler_tst.createData( false, true, false );
    }
    
    static testMethod void myUnitTest2() {
        RM_AccountTriggerHandler_tst.createData( false, false, false );
    }
    
    static testMethod void myUnitTest3() {
        RM_AccountTriggerHandler_tst.createData( false, true, true );
    }
    
    static testMethod void myUnitTest4() {
        RM_AccountTriggerHandler_tst.createData( true, true, false );
    }
    
    static testMethod void myUnitTest5() {
        RM_AccountTriggerHandler_tst.createData( true, false, false );
    }
}