@isTest
global class FanalcaCrearModificarClientesSAP_Mock implements WebServiceMock {
    public static Integer option {get; set;}
    public FanalcaCrearModificarClientesSAP_Mock (integer opcion){
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
        FanalcaCrearModificarClientesSAP.DT_RESPONSE response_x = 
            new FanalcaCrearModificarClientesSAP.DT_RESPONSE();
        
        switch on option {
            when 1 {		//1 ok
                response_x.TYPE_x ='S';
                response_x.NUMBER_x ='000';       
                response_x.MSSGS ='Modificación de Deudor Exitosa';
                response_x.KUNNR ='0010692738';    
            }	
            when 2 {		
                response_x.TYPE_x ='E';
                response_x.NUMBER_x ='000';       
                response_x.MSSGS ='Algún Error';
                response_x.KUNNR ='0';    
            }
            when 3 {		
                
            }
            when else {		  
                
            }
        }
           
        // end
        response.put('response_x', response_x); 
   }

}