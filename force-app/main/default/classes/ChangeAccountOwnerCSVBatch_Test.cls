@isTest
public with sharing class ChangeAccountOwnerCSVBatch_Test {

    @isTest
    private static void ChangeAccountOwnerCSVBatchErrorCuentas() {

        Account acc = new Account();

        List<Sobject> lstDatosActualizar = new List<Sobject>{
            acc
        };

        Datetime horaStart = System.now();
        String strObjeto = 'Cuentas';

        Test.startTest();

        ChangeAccountOwnerCSVBatch myBatchObject = new ChangeAccountOwnerCSVBatch(lstDatosActualizar, strObjeto, horaStart);
        Id batchId = Database.executeBatch(myBatchObject);
        
        Test.stopTest();

        List<Log__c> logs = [SELECT Id FROM Log__c];
        System.assert(logs.size() == 1, true);
    }

    @isTest
    private static void ChangeAccountOwnerCSVBatchErrorOpportunity() {

        Opportunity opp = new Opportunity();

        List<Sobject> lstDatosActualizar = new List<Sobject>{
            opp
        };

        Datetime horaStart = System.now();
        String strObjeto = 'Oportunidades';

        Test.startTest();

        ChangeAccountOwnerCSVBatch myBatchObject = new ChangeAccountOwnerCSVBatch(lstDatosActualizar, strObjeto, horaStart);
        Id batchId = Database.executeBatch(myBatchObject);
        
        Test.stopTest();

        List<Log__c> logs = [SELECT Id FROM Log__c];
        System.assert(logs.size() == 1, true);        
    }

    @isTest
    private static void ChangeAccountOwnerCSVBatchErrorContact() {

        Contact con = new Contact();

        List<Sobject> lstDatosActualizar = new List<Sobject>{
            con
        };

        Datetime horaStart = System.now();
        String strObjeto = 'Contactos';

        Test.startTest();

        ChangeAccountOwnerCSVBatch myBatchObject = new ChangeAccountOwnerCSVBatch(lstDatosActualizar, strObjeto, horaStart);
        Id batchId = Database.executeBatch(myBatchObject);
        
        Test.stopTest();

        List<Log__c> logs = [SELECT Id FROM Log__c];
        System.assert(logs.size() == 1, true);
    }


    @isTest
    private static void ChangeAccountOwnerCSVBatch(){
        Triggerhandler.bypass('AccountTriggerHandler');
      	Triggerhandler.bypass('OpportunityTriggerHandler');
        

        Profile p = [
          SELECT Id
          FROM Profile
          WHERE Name IN ('Gerente de ventas (Motos)')
          LIMIT 1
        ];
        User u = new User(
          Alias = 'standt',
          Email = 'standarduser@testorg.com',
          EmailEncodingKey = 'UTF-8',
          LastName = 'Integraciones',
          LanguageLocaleKey = 'en_US',
          LocaleSidKey = 'en_US',
          ProfileId = p.Id,
          TimeZoneSidKey = 'America/Los_Angeles',
          UserName = 'standarduser@testorg.com.fanalcasandbox'
            ,ManagerId= UserInfo.getUserId()
        );
            insert u;
            
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountJuridica, 1);
        
        Contact c = new Contact(LastName ='TestLN1',FirstName='TestFN1',AccountId=TestDataUtilityClass.mapClientesMotosJuridico.get(1).Id);
        insert c;
        
        Miembro_de_Concesionario__c mc = new Miembro_de_Concesionario__c();
        mc.Concesionario__c = TestDatautilityClass.mapConcesionarios.get(1).Id;
        mc.Nombre_de_asesor__c = u.Id;
        insert mc;
        
       
        String strCSV = 'numeroDocumento'+ Label.changeAccountOwnerCSVSeparator +'NewOwner';
        
        strCSV += (+ '\n' + TestDAtaUtilityClass.mapClientesMotosJuridico.get(1).AM_Numero_de_documento__c + Label.changeAccountOwnerCSVSeparator + u.userName );
        system.debug(strCSV);
        Blob bodyBlob=Blob.valueOf(strCSV); 
            
        ContentVersion contentVersion_1 = new ContentVersion(
            Title='SampleTitle', 
            PathOnClient ='SampleTitle.jpg',
            VersionData = bodyBlob, 
            origin = 'H'
        );
        insert contentVersion_1;
        
        ContentVersion objVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ID =:contentVersion_1.Id];
        
        list<ChangeAccountOwnerCSV.accountOwnerChangesData> lstDatosCuentas = ChangeAccountOwnerCSV.readCSVFile(objVersion.ContentDocumentId);
        ChangeAccountOwnerCSV.processAccounts(lstDatosCuentas);

        List<Log__c> logs = [SELECT Id FROM Log__c];
        System.assert(logs.size() == 0, true);
        
    }
}