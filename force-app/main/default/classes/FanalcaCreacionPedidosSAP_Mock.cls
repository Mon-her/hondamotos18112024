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
global class FanalcaCreacionPedidosSAP_Mock implements WebServiceMock {
    public static Integer option {get; set;}
    public FanalcaCreacionPedidosSAP_Mock (integer opcion){
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
        FanalcaCreacionPedidosSAP.DT_RESPONSE_SALES_ORDER response_x = 
            new FanalcaCreacionPedidosSAP.DT_RESPONSE_SALES_ORDER();
               switch on option {
                   when 1 {	
                       response_x.TYPE_x ='S';
                       response_x.NUMBER_x ='100';       
                       response_x.MSSGS ='Pedido creado de forma exitosamente';
                       response_x.VBELN ='0202406079';
                       response_x.BSTKD ='Pedido test SF 1';
                   }
                   when 2 {
                       response_x.TYPE_x = null;                       
                   }
               }
           
        // end
        response.put('response_x', response_x); 
   }

}