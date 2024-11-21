global class VerificacionesAPI_Mock implements HttpCalloutMock{
	private integer indicador; //11 Email ok, 12 Email Error, 21 Telefono ok, 22 Telefono Error, 3 Call out error
    public VerificacionesAPI_Mock(Integer ind){
        this.indicador = ind;
    }
    global HTTPResponse respond(HTTPRequest request) {
      	//Inicializar response con respuesta por defecto
      	HttpResponse response = new HttpResponse();
      	response.setHeader('Content-Type', 'application/json');
      	response.setStatusCode(200);
        
        switch on indicador {
            when 11 {	
                response.setBody('{ "Consulta":{"resultado": "1", "mensaje": "Mensaje Enviado Correctamente", "codigo": 123456} }'); 
            }	
            when 12 {		
                response.setBody('{ "Consulta": {"resultado": 50004, "mensaje": "El campo numero no puede estar vacio", "codigo": 0  } }');  
            }
            when 13,23 {		
                response.setStatusCode(500);
                response.setStatus('Internal Server Error');
            }
            when 21 {	
                response.setBody('{ "Consulta":{"resultado": "1", "mensaje": "Email válido"} }'); 
            }	
            when 22 {		
                response.setBody('{ "Consulta":{"resultado": "50003", "mensaje": "El campo api no puede estar vacio", "codigo": 0} }');  
            }
            when 24{
                response.setBody('{    "Consulta": {        "resultado": 50009,        "mensaje": "Email inválido"    }}');
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