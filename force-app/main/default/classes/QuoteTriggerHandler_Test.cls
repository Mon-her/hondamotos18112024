@isTest
public class QuoteTriggerHandler_Test {
    public static testmethod void testear(){
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        TestDatautilityClass.crearOportunidadMotos(1);
        TestDataUtilityClass.crearQuoteMotos(1);
        
        update TestDatautilityClass.mapQuotesMotos.get(1);
    }
    
    
    
}