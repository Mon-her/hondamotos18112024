@isTest
public class ChangeAccountOwnerCSV_Test {
    private static testmethod void testearErrorReadCSV(){
        try{
            ContentVersion contentVersion_1 = new ContentVersion(
                Title='SampleTitle', 
                PathOnClient ='SampleTitle.jpg',
                VersionData = Blob.valueOf('anything'), 
                origin = 'H'
            );
            insert contentVersion_1;
            ChangeAccountOwnerCSV.readCSVFile(contentVersion_1.Id); //generará un error en el método, ya que espera un contentdocumentid   
        }catch(Exception ex){
            system.debug(ex.getMessage());
        }
         
    }
    private static testmethod void testear(){
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
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 2);
        TestDatautilityClass.crearOportunidadMotos(1);
        
        Miembro_de_Concesionario__c mc = new Miembro_de_Concesionario__c();
        mc.Concesionario__c = TestDatautilityClass.mapConcesionarios.get(1).Id;
        mc.Nombre_de_asesor__c = u.Id;
        insert mc;
        
        Relacion_de_Cuenta__c rc = new Relacion_de_Cuenta__c();
        rc.Cuenta_Principal__c = TestDAtaUtilityClass.mapClientesMotosNatural.get(1).Id;
        rc.Cuenta_Relacionada__c = TestDAtaUtilityClass.mapClientesMotosNatural.get(2).Id;
        rc.Tipo_de_Relacion_Directa__c = 'Cónyuge';
        rc.Tipo_de_Relacion_Inversa__c = 'Cónyuge';
        rc.Depende_economicamente_de_usted__c = 'No';
        insert rc;
        
        TAsk tareaAcc = new TAsk();
        tareaAcc.WhatId = TestDAtaUtilityClass.mapClientesMotosNatural.get(1).Id;
        tareaAcc.Status = 'Programada';
        tareaAcc.ActivityDate = System.today().addDays(1);
        tareaAcc.Description = 'Algo';
        tareaAcc.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Tareas Motos').getRecordTypeId();
        insert tareaACc;
        
        String strCSV = 'numeroDocumento'+ Label.changeAccountOwnerCSVSeparator +'NewOwner';
        //for (Account a: [select Id, AM_Numero_de_documento__c from Account]){
        //    strCSV += (+ '\n' + a.AM_Numero_de_documento__c + Label.changeAccountOwnerCSVSeparator + u.userName );
        //}
        strCSV += (+ '\n' + TestDAtaUtilityClass.mapClientesMotosNatural.get(1).AM_Numero_de_documento__c + Label.changeAccountOwnerCSVSeparator + u.userName );
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
        
        //system.runAs(u){
        //    ChangeAccountOwnerCSV.processAccounts(lstDatosCuentas);
        //}
    }
	
    
    private static testmethod void testearContactos(){
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
        
    }
}