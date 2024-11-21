@isTest
public class clsGraphOpsVendidas_Test {
    public static testmethod void testear(){
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        TestDatautilityClass.crearOportunidadMotos(1);
        TEst.startTest();
        TestDataUtilityClass.mapOpportunitiesMotos.get(1).StageName='Vendida';
        update TestDataUtilityClass.mapOpportunitiesMotos.values();
        clsGraphOpsVendidas.getOpsVendidas();
        clsGraphOpsVendidas.getTotalUsuarios();
        clsGraphOpsVendidas.getUsuariosXSegmento();   
        Test.stopTest();
    }
    
    public static testmethod void testearGerenteNorte(){
        // Create a unique UserName
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name in ('System Administrator','Administrador del Sistema') order by Name desc limit 1];//'Standard User'];
        UserRole r = [SELECT Id FROM UserRole WHERE Name='Gerente de Zona Centro Norte'];
        User u = new User(UserRoleId= r.Id,Alias = 'standt', Email='standarduser@testorg.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
             UserName=uniqueUserName);
 
        //TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        System.runAs(u) {
            TestDataUtilityClass.crearConcesionarios(1);
            TestDataUtilityClass.crearMiembroConcesionarios(1);
            
            //TestDatautilityClass.crearOportunidadMotos(1);
            //TestDataUtilityClass.mapOpportunitiesMotos.get(1).StageName='Vendida';
            //update TestDataUtilityClass.mapOpportunitiesMotos.values();
            clsGraphOpsVendidas.getOpsVendidas();
            clsGraphOpsVendidas.getTotalUsuarios();
            clsGraphOpsVendidas.getUsuariosXSegmento();   
         }
    }
    
    public static testmethod void testearGerenteSur(){
        // Create a unique UserName
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name in ('System Administrator','Administrador del Sistema') order by Name desc limit 1];//'Standard User'];
        UserRole r = [SELECT Id FROM UserRole WHERE Name='Gerente de Zona Sur'];
        User u = new User(UserRoleId= r.Id,Alias = 'standt', Email='standarduser@testorg.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
             UserName=uniqueUserName);
 
        //TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        System.runAs(u) {
            TestDataUtilityClass.crearConcesionarios(1);
            TestDataUtilityClass.crearMiembroConcesionarios(1);
            
            //TestDatautilityClass.crearOportunidadMotos(1);
            //TestDataUtilityClass.mapOpportunitiesMotos.get(1).StageName='Vendida';
            //update TestDataUtilityClass.mapOpportunitiesMotos.values();
            clsGraphOpsVendidas.getOpsVendidas();
            clsGraphOpsVendidas.getTotalUsuarios();
            clsGraphOpsVendidas.getUsuariosXSegmento();   
         }
    }
}