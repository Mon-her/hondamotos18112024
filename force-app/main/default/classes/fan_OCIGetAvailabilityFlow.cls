/**********************************************************************************
Desarrollado por:   Viseo
Autor:              Simón Way Esalas Young
Descripción:        Clase para obtener información relacionada a inventario.
Cambios (Versiones)
---------------------------------------------------------------------------------
No.     Fecha       Autor                                   Descripción
---------------------------------------------------------------------------------
1.0     01-08-2022  Simón Way Esalas Young                  Creación de la clase
***********************************************************************************/
global class fan_OCIGetAvailabilityFlow extends fan_OCIGetAvailabilityAbstract {
    
    @InvocableMethod(label='Get list of location group Availability')
    global static List<Response> getAvailability(List<Request> request){
        
        List<Response> lstResponse = new List<Response>();
        if(request.size() > 0){
            
            Request requestProcess = request[0];
            List<String> lstSKU = new List<String>();
            fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult lstResultFinal = new fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult();
            
            lstSKU = requestProcess.Stock_keeping_units.split(';');
            
            Map<String, Product2> mapProduct = getProductInformationBySKU(lstSKU);
            Map<String, LocationGroupAssignment> mapLocationAssignment = getLocationGroupAssignments(requestProcess.location_group);
            
            fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult result = getAvaliavility(requestProcess.location_group, lstSKU, mapProduct, mapLocationAssignment, (new String[]{}));
            System.debug(LoggingLevel.DEBUG, 'getAvailability result >>> '+result);
            lstResultFinal.lstLocationGroup = result.lstLocationGroup;
            
            String jsonResult = JSON.serialize(lstResultFinal.lstLocationGroup, false);
            lstResponse = (List<Response>) JSON.deserialize(jsonResult, List<Response>.class);
            
            System.debug(LoggingLevel.DEBUG, 'getAvailability lstResponse >>>' + lstResponse);
        }
        
        return lstResponse;
    }
    
    global class Request {
        @InvocableVariable global String location_group;
        @InvocableVariable global String Stock_keeping_units;
    }
    
    global class Response {
        @InvocableVariable global String ubicacion;
        @InvocableVariable global String description;
        @InvocableVariable global String reference;
        @InvocableVariable global String agencia;
        
        @InvocableVariable global Decimal availableToFulfill;
        @InvocableVariable global Decimal availableToOrder;
        @InvocableVariable global Decimal onHand;
        @InvocableVariable global Decimal reserved;
        @InvocableVariable global Decimal safetyStockCount;
        @InvocableVariable global String stockKeepingUnit;
        
    }
     
}