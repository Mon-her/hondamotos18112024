@isTest
public class MotosSendAccountToSAP_Test {
    
    static testmethod void testearOkCrearClienteNatural(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesSAP_Mock(1));
        // Call the method that invokes a callout
        MotosSendAccountToSAP.SendAccount(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id, 'C');
        Test.stopTest();
    }
    
    static testmethod void testearOkModificarClienteNatural(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesSAP_Mock(1));
        // Call the method that invokes a callout
        MotosSendAccountToSAP.SendAccount(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id, 'M');
        Test.stopTest();
    }
    
    static testmethod void testearErrorModificarClienteNatural(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesSAP_Mock(2));
        // Call the method that invokes a callout
        MotosSendAccountToSAP.SendAccount(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id, 'M');
        Test.stopTest();
    }
    
    static testmethod void testearOkCrearClienteJuridico(){
        system.debug('Mira por acá');
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountJuridica, 1);
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesSAP_Mock(1));
        // Call the method that invokes a callout
        MotosSendAccountToSAP.SendAccount(TestDataUtilityClass.mapClientesMotosJuridico.get(1).Id, 'C');
        Test.stopTest();
    }
    
    static testmethod void testearError(){
        try{
        	//TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
            Test.startTest();
            // This causes a fake response to be generated
            Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesSAP_Mock(1));
            // Call the method that invokes a callout
            MotosSendAccountToSAP.SendAccount('0011F00000kxC0ZQAU', 'M');
            Test.stopTest();    
        }catch(Exception ex){
            
        }
        
    }
    
    static testmethod void testearOkSendAccountOrderNatural(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesSAP_Mock(1));
        // Call the method that invokes a callout
        MotosSendAccountToSAP.SendAccountOrder(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id, 'C');
        Test.stopTest();
    }
    
    static testmethod void testearOkSendAccountOrderJuridico(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountJuridica, 1);
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesSAP_Mock(1));
        // Call the method that invokes a callout
        MotosSendAccountToSAP.SendAccountOrder(TestDataUtilityClass.mapClientesMotosJuridico.get(1).Id, 'C');
        Test.stopTest();
    }
    
    static testmethod void testearErrorSendAccountOrder(){
        try{
        	//TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
            Test.startTest();
            // This causes a fake response to be generated
            Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesSAP_Mock(1));
            // Call the method that invokes a callout
            MotosSendAccountToSAP.SendAccountOrder('0011F00000kxC0ZQAU', 'M');
            Test.stopTest();    
        }catch(Exception ex){
            
        }
        
    }

}