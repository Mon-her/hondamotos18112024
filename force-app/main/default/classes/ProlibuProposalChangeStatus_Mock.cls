@isTest
global class ProlibuProposalChangeStatus_Mock implements HttpCalloutMock{
	private integer indicador; //1 Email ok, 3 Call out error
    public ProlibuProposalChangeStatus_Mock(Integer ind){
        this.indicador = ind;
    }
    global HTTPResponse respond(HTTPRequest request) {
      	//Inicializar response con respuesta por defecto
      	HttpResponse response = new HttpResponse();
      	response.setHeader('Content-Type', 'text/html; charset=utf-8');
      	response.setStatusCode(200);
        
        switch on indicador {
            when 1 {	
                response.setBody('OK'); 
            }	
			when 3{
                CalloutException e = (CalloutException)CalloutException.class.newInstance();
                e.setMessage('Unauthorized endpoint, please check Setup->Security->Remote site settings.');
                throw e;
            }
            when else {		  
                
            }
        }
        
        
        return response;  
    }
}