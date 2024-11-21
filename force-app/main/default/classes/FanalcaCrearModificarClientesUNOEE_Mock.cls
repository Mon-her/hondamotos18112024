@isTest
global class FanalcaCrearModificarClientesUNOEE_Mock implements WebServiceMock{
	public static Integer option {get; set;}
    public FanalcaCrearModificarClientesUNOEE_Mock (Integer opcion){
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
        FanalcaCrearModificarClientesUNOEE.DT_GenericResponse response_x = 
            new FanalcaCrearModificarClientesUNOEE.DT_GenericResponse();
        
        //if (error)            
            //throw new System.CalloutException('Error de Callout');        
        //    throw new Exception('Error general');        
		//else
        //	response_x.id ='200';
        
        switch on option {
        	when 1 {		//1 ok
            	response_x.id ='200';  
            }	
            when 2 {		
            	throw new System.CalloutException('Error de Callout');
            }
            when 3 {		
            	throw new System.NullPointerException();            
            }
            when else {		  
                       
            }
        }
        // end
        response.put('response_x', response_x); 
   }
}