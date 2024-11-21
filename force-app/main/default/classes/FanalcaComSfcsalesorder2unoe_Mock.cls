/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Mock Class for FanalcaComSfcsalesorder2unoe
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     15/03/2021      Juan Ansaldi            Class definition.
* @version  1.1     15/03/2020      Juan Ansaldi            Mock class finished
*********************************************************************************************************/
@isTest
global class FanalcaComSfcsalesorder2unoe_Mock implements WebServiceMock {
    
    public FanalcaComSfcsalesorder2unoe_Mock (){
        
    }
    global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
               FanalcaComSalesforcecustomer2unoe.DT_GenericResponse response_x = new FanalcaComSalesforcecustomer2unoe.DT_GenericResponse();
               response_x.id = '200';
               response.put('response_x', response_x); 
   }

}