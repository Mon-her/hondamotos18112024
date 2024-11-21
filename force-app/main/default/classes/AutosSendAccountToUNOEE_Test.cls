//This class covers AutosSendAccountToUNOEE and FanalcaCrearModificarClientesSAP, use FanalcaCrearModificarClientesUNOEE_Mock

@isTest
public class AutosSendAccountToUNOEE_Test {
	static testmethod void testearOkCrearClienteNatural(){
        TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesUNOEE_Mock(1));
        // Call the method that invokes a callout
        AutosSendAccountToUNOEE.SendAccount(TestDataUtilityClass.mapClientesAutosNatural.get(0).Id);
        Test.stopTest();
         AutosSendAccountToUNOEE.SendAccountFacturar(TestDataUtilityClass.mapClientesAutosNatural.get(0).Id, 500);
    }
    
    static testmethod void testearErrorModificarClienteNatural(){
        TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesUNOEE_Mock(2));
        // Call the method that invokes a callout
        AutosSendAccountToUNOEE.SendAccount(TestDataUtilityClass.mapClientesAutosNatural.get(0).Id);
        Test.stopTest();
        
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesUNOEE_Mock(3));
        // Call the method that invokes a callout
        AutosSendAccountToUNOEE.SendAccount(TestDataUtilityClass.mapClientesAutosNatural.get(0).Id);
    }
    
    static testmethod void testearErrorModificarClienteNaturalFacturar(){
        TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesUNOEE_Mock(2));
        // Call the method that invokes a callout
        AutosSendAccountToUNOEE.SendAccountFacturar(TestDataUtilityClass.mapClientesAutosNatural.get(0).Id,100);
        Test.stopTest();
        
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesUNOEE_Mock(3));
        // Call the method that invokes a callout
        AutosSendAccountToUNOEE.SendAccountFacturar(TestDataUtilityClass.mapClientesAutosNatural.get(0).Id,100);
    }
    
    static testmethod void testearOkCrearClienteJuridico(){
        system.debug('Mira por acá');
        TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountJuridica);
        TestDataUtilityClass.mapClientesAutosJuridico.get(0).AM_Orientacion_via_secundaria__c = 'Este nombre del barrio debe tener más de cuarenta caracteres para que llegue a enviarse también el valor de dirección 2';
        update TestDataUtilityClass.mapClientesAutosJuridico.get(0);
        
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesUNOEE_Mock(1));
        // Call the method that invokes a callout
        AutosSendAccountToUNOEE.SendAccount(TestDataUtilityClass.mapClientesAutosJuridico.get(0).Id);
        Test.stopTest();
        AutosSendAccountToUNOEE.SendAccountFacturar(TestDataUtilityClass.mapClientesAutosJuridico.get(0).Id,500);
    }
    /*
    static testmethod void testearOkModificarClienteNatural(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesSAP_Mock(1));
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
*/
}