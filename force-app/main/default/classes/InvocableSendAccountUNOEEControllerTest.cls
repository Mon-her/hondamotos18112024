/**
* Fanalca
* @author           Juan Pablo Rodríguez
* Description:      Apex class for code coverage of InvocableSendAccountUNOEEController
*
* Changes (Version)
* -------------------------------------------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     Aug/12/2024   Juan Pablo Rodríguez       Class definition.
*********************************************************************************************************/

@IsTest
private class InvocableSendAccountUNOEEControllerTest {
    private static List<Account> accounts;
    private static List<AM_Municipio__c> cities;
    
    @TestSetup
    static void dataFactory() { 
        cities = new List<AM_Municipio__c>{
            new AM_Municipio__c(
                Name = 'Test',
                AM_Codigo_DANE_municipio__c = '9',
                AM_Codigo_SIPRES_municipio__c = '9999999999',
                ID_UNOEE__c = '99999999',
                ID_PAIS_SAP__c = 'CO',
                ID_POBLACION_SAP__c = '99999',
                ID_REGION_SAP__c = '99',
                AM_Nombre_departamento__c = 'Test',
                AM_Codigo_DANE_departamento__c = '99',
                AM_Codigo_SIPRES_departamento__c = '999999'
            )
        };
        Insert cities;

        accounts = new List<Account>{
            new Account(
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('AM_CUE_Persona_natural').getRecordTypeId(),
                FirstName = 'Test',
                LastName = 'Account',
                Cuenta_Clave__c = 'NO',
                AM_Tipo_de_documento__c = 'Pasaporte',
                Phone = '9999999999',
                PersonEmail = 'test1@test.com.invalid',
                AM_Tipo_de_usuario__c = 'Cliente No Honda',
                AM_Numero_de_documento__c = 'C99999999',
                Genero__c = 'Masculino',
                AM_Ocupacion__pc = 'Empleado',
                AM_Ciudad__c = cities.get(0).Id,
                Permiso_de_Contacto__c = 'Autorizado',
                AM_Estado__c = 'Activo',
                Sucursal__c = '999'
            )
        };
        Insert accounts;
    }

    @IsTest
    static void sendAccount() {
        List<InvocableSendAccountUNOEEController.Results> results = new List<InvocableSendAccountUNOEEController.Results>();
        List<InvocableSendAccountUNOEEController.Requests> requests = new List<InvocableSendAccountUNOEEController.Requests>();
        List<Account> accs = [SELECT Id FROM Account LIMIT 10];
        
        Test.startTest();
            InvocableSendAccountUNOEEController.Requests req = new InvocableSendAccountUNOEEController.Requests();
            req.accountId = accs.get(0).Id;
            requests.add(req);
            results = InvocableSendAccountUNOEEController.sendAccount(requests);
        Test.stopTest();
        
        // Assertion
        Assert.areEqual('200', results.get(0).statusCode);
        Assert.isTrue(results.get(0).message.containsIgnoreCase('El registro de cuenta fue creada/actualizada con éxito en UNOEE'));
    }

}