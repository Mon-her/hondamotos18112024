/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Mock Class for FanalcaCreacionPedidosSAP
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     30/11/2020      Juan Ansaldi            Class definition.
* @version  1.1     02/12/2020      Juan Ansaldi            Mock class finished
*********************************************************************************************************/
@isTest
global class FanalcaConsultaPreciosDescuentos_Test implements WebServiceMock {
    public static Integer option {get; set;}
    public FanalcaConsultaPreciosDescuentos_Test (integer opcion){
        option = opcion;
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
            // start - specify the response you want to send
            FanalcaConsultaPreciosDescuentos.DT_P_D_RESPONSE response_x = new FanalcaConsultaPreciosDescuentos.DT_P_D_RESPONSE();
            List<FanalcaConsultaPreciosDescuentos.Row_element> lstRowElement = new List<FanalcaConsultaPreciosDescuentos.Row_element>();
            
            response_x.Row = lstRowElement;
            
            
            
            // end
            response.put('response_x', response_x); 
        }

}