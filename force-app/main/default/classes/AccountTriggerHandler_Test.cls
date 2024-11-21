@isTest
public class AccountTriggerHandler_Test {
    public static testmethod void testearMotos(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesSAP_Mock(1));
        // Call the method that invokes a callout
        MotosSendAccountToSAP.SendAccount(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id, 'C');
            
        Test.stopTest();
        
        TestDataUtilityClass.mapClientesMotosNatural.get(1).Actualizar_Concesionario__c= true;
        update TestDataUtilityClass.mapClientesMotosNatural.get(1);
    }
     public static testmethod void testearMotos2(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesSAP_Mock(1));
        // Call the method that invokes a callout
        MotosSendAccountToSAP.SendAccount(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id, 'C');
            
        Test.stopTest();
        
        update TestDataUtilityClass.mapClientesMotosNatural.get(1);
    }
       
    public static testmethod void testearAutos(){
        TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        TestDataUtilityClass.mapClientesAutosNatural.get(0).Codigo_UNOEE__c= '123456';
        update TestDataUtilityClass.mapClientesAutosNatural.get(0);
        
    }    
    public static testmethod void testearAutos2(){
        TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        TestDataUtilityClass.mapClientesAutosNatural.get(0).Codigo_UNOEE__c= '123456';
        TestDataUtilityClass.mapClientesAutosNatural.get(0).FirstName= 'New Name';
        //TestDataUtilityClass.mapClientesAutosNatural.get(0).MC_Autoriza_tratardatos_personales__c= 'Si';
        update TestDataUtilityClass.mapClientesAutosNatural.get(0);
        
    }  
    
    public static testmethod void testearGteAutos(){
        
        try{
            User thisUser = [select Id from user where Id=:UserInfo.getUserId()];
        
            System.runAs(thisUser){
                // Create a unique UserName
                String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
                // This code runs as the system user
                Profile p = [SELECT Id FROM Profile WHERE Name in ('GERENCIA GENERAL AUTOS') order by Name desc limit 1];//'Standard User'];
                UserRole r = [SELECT Id FROM UserRole WHERE Name='GERENTE NACIONAL DE VENTAS HONDA AUTOS'];
                User u = new User(UserRoleId= r.Id,Alias = 'standt', Email='standarduser@testorg.com',
                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                    LocaleSidKey='en_US', ProfileId = p.Id,
                    TimeZoneSidKey='America/Los_Angeles',
                     UserName=uniqueUserName);
                insert u;
         
                TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
                TestDataUtilityClass.mapClientesAutosNatural.get(0).Codigo_UNOEE__c= '123456';
                TestDataUtilityClass.mapClientesAutosNatural.get(0).FirstName= 'New Name';
               
                //Give access to u to the account
                AccountShare accountShare = new AccountShare();
                accountShare.AccountId = TestDataUtilityClass.mapClientesAutosNatural.get(0).Id;
                accountShare.UserOrGroupId = u.Id;
                accountShare.AccountAccessLevel = 'Edit';
                accountShare.OpportunityAccessLevel = 'Read';
                insert accountShare;
                
                System.runAs(u) {
                    update TestDataUtilityClass.mapClientesAutosNatural.get(0);
                 }    
            }
        }catch (Exception ex){
            system.debug(ex.getMessage());
        }
    } 
    
    public static testmethod void testearJuridico(){
        TestDataUtilityClass.crearCuentasAutos(1,Label.AutosRecordTypeDevNameAccountJuridica); 
        TestDataUtilityClass.mapClientesAutosJuridico.get(0).Codigo_UNOEE__c= '123456';
        update TestDataUtilityClass.mapClientesAutosJuridico.get(0);
        
    }   
    
}