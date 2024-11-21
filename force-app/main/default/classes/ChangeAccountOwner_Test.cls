@isTest
public class ChangeAccountOwner_Test {
    private static testmethod void testear(){
        //Create account
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearCuentasAutos(2,Label.AutosRecordTypeDevNameAccountNatural);
        TestDatautilityClass.crearOportunidadAutos(1);
                
        Relacion_de_Cuenta__c relacion = new  Relacion_de_Cuenta__c();
        relacion.Cuenta_Principal__c = TestDataUtilityClass.mapClientesAutosNatural.get(0).Id;
        relacion.Cuenta_Relacionada__c = TestDataUtilityClass.mapClientesAutosNatural.get(1).Id;
        relacion.Depende_economicamente_de_usted__c = 'SI';
        relacion.Tipo_de_Relacion_Directa__c = 'Cónyuge';
        relacion.Tipo_de_Relacion_Inversa__c = 'Cónyuge';
        insert relacion;
        
        //Create a user
        Profile p = [SELECT Id FROM Profile WHERE Name in ('System Administrator','Administrador del Sistema') order by Name desc limit 1];
         String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
             UserName=uniqueUserName);
        insert u;
        
        ChangeAccountOwner.changeOwner(TestDataUtilityClass.mapClientesAutosNatural.get(0).Id, u.Id);
        
    }
    
    private static testmethod void testearCtaMoto(){
       
                
        //Create a user
        Profile p = [SELECT Id FROM Profile WHERE Name in ('Gerente de ventas (Motos)') order by Name desc limit 1];
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
             UserName=uniqueUserName);
        insert u;
        
        system.runAs(u) {
             //Create account
            TestDataUtilityClass.crearConcesionarios(1);
            TestDataUtilityClass.crearMiembroConcesionarios(1);
            TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural,1);
            TestDatautilityClass.crearOportunidadMotos(1);
            ChangeAccountOwner.changeOwner(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id, u.Id);   
        }
         
        
    }
    
    private static testmethod void testearError(){
        try{
            ChangeAccountOwner.changeOwner(null, null);
        }catch (Exception ex){
            
        }
    }
    
    private static testmethod void testearAutosJuridico(){
        //Create account
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearCuentasAutos(1,Label.AutosRecordTypeDevNameAccountJuridica);
        //TestDatautilityClass.crearOportunidadAutos(1);
        
        Contact c = new Contact();
        c.FirstName = 'fName';
        c.LastName = 'lName';
        c.AM_Tipo_de_documento_Contacto__c = 'Cédula de ciudadanía';
        c.AM_Numero_de_documento_contacto__c = '12365478';
        c.AccountId = TestDatautilityClass.mapClientesAutosJuridico.get(0).Id;
        insert c;
     
        
        //Create a user
        Profile p = [SELECT Id FROM Profile WHERE Name in ('System Administrator','Administrador del Sistema') order by Name desc limit 1];
         String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
             UserName=uniqueUserName);
        insert u;
        
        ChangeAccountOwner.changeOwner(TestDataUtilityClass.mapClientesAutosJuridico.get(0).Id, u.Id);
        
    }
}