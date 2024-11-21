@isTest
public class lwcHojaVidaVehiculo_Test {
    private static testmethod void testear(){
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaSalesForceGetVehiculoSFC2Sap_Mock(1));
        // Call the method that invokes a callout
        lwcHojaVidaVehiculo.getVehiculo('123456789', '');
            
        Test.stopTest();
        
        try{
            Test.setMock(WebServiceMock.class, new FanalcaSalesForceGetVehiculoSFC2Sap_Mock(3));
            // Call the method that invokes a callout
            lwcHojaVidaVehiculo.getVehiculo('123456789', '');   
        }catch (Exception ex){
            system.debug(ex.getMessage());
        }
         
        lwcHojaVidaVehiculo.getNoDocumento('005123456789012345');
        lwcHojaVidaVehiculo.getNoDocumento('');
    }
}