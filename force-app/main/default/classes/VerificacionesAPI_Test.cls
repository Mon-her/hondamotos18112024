@isTest
public class VerificacionesAPI_Test {
    private static testmethod void testearvalidarTelefonoOk(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountJuridica, 1);
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new VerificacionesAPI_Mock(11));
        VerificacionesAPI.validarTelefono('89777145', 'mensaje');
        test.stopTest();
        
        VerificacionesAPI.removePhone(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id, true);
        
        //Cuenta de tipo jurídica
        VerificacionesAPI.removePhone(TestDataUtilityClass.mapClientesMotosJuridico.get(1).Id, false);

        try{
            //Enviar Id no existente para generar error
            VerificacionesAPI.removePhone(null, true);    
        }catch (Exception ex){
            
        }     
        
    }
    
    private static testmethod void testearvalidarTelefonoErrorNoTelefono(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new VerificacionesAPI_Mock(12));
        VerificacionesAPI.validarTelefono('89777145', 'mensaje');
        test.stopTest();
    }
    
    private static testmethod void testearvalidarTelefonoError500(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new VerificacionesAPI_Mock(13));
        VerificacionesAPI.validarTelefono('89777145', 'mensaje');
        test.stopTest();
    }
    private static testmethod void testearvalidarTelefonoError(){
        test.startTest();
        //Test.setMock(HttpCalloutMock.class, new VerificacionesAPI_Mock(11));
        VerificacionesAPI.validarTelefono('abcdefg', 'mensaje');
        test.stopTest();
    }
    
    private static testmethod void testearvalidarEmailOk(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountJuridica, 1);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new VerificacionesAPI_Mock(21));
        //VerificacionesAPI.validarEmail('jparrales@fastcloudconsulting.com');
        VerificacionesAPI.validarEmail(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id);
        test.stopTest();
        
        VerificacionesAPI.validarEmail(TestDataUtilityClass.mapClientesMotosJuridico.get(1).Id);
    }

 	private static testmethod void testearvalidarEmailErrorNoEmail(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new VerificacionesAPI_Mock(22));
        VerificacionesAPI.validarEmail(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id);
        test.stopTest();
    }    
    private static testmethod void testearvalidarEmailError500(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new VerificacionesAPI_Mock(23));
        VerificacionesAPI.validarEmail(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id);
        test.stopTest();
    }
    
    private static testmethod void testearvalidarEmailInvalido(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new VerificacionesAPI_Mock(24));
        VerificacionesAPI.validarEmail(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id);
        test.stopTest();
    }
    
	private static testmethod void testearvalidarEmailInvalidoJuridico(){
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountJuridica, 1);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new VerificacionesAPI_Mock(24));
        VerificacionesAPI.validarEmail(TestDataUtilityClass.mapClientesMotosJuridico.get(1).Id);
        test.stopTest();
    }        
    private static testmethod void testearvalidarEmailErrorCallout(){
        try{
        	TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new VerificacionesAPI_Mock(3));
            VerificacionesAPI.validarEmail(TestDataUtilityClass.mapClientesMotosNatural.get(1).Id);
            test.stopTest();    
        }catch (Exception ex){
            
        }
        
    }
    
}