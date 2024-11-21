//Made by me, June 2021
@isTest
global class ProlibuProposalMetrics_Mock implements HttpCalloutMock{
private integer indicador; //1 ok, 3 Call out error
    public ProlibuProposalMetrics_Mock(Integer ind){
        this.indicador = ind;
    }
    global HTTPResponse respond(HTTPRequest request) {
      	//Inicializar response con respuesta por defecto
      	HttpResponse response = new HttpResponse();
      	response.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setMethod('Get');
      	response.setStatusCode(200);
        
        switch on indicador {
            when 1 {
                map<String, Quote> mapQuotes = new map<String, Quote>();
                for (Quote q: [select QuoteNumber, Id from Quote where Creado_Prolibu__c=true and Opportunity.isClosed=false]){
                    mapQuotes.put(q.QuoteNumber, q);
                }
                String idQuote1 = mapQuotes.values().size()>0 ? mapQuotes.values()[0].QuoteNumber  : '090392-T90';
                String idQuote2 = mapQuotes.values().size()>1 ? mapQuotes.values()[1].QuoteNumber  : 'JWKKYI';
                //response.setBody('[{"proposalNumber":"090392-T90","rating":"Cold","lastSeen":"2021-05-27T11:47:30.619Z","views":1,"id":"0Q0010000009HIaCAM"},{"proposalNumber":"JWKKYI","rating":"Cold","id":"0Q0010000009HIaCAM"},{"proposalNumber":"ATSKPM","rating":"Cold","lastSeen":"2021-05-27T11:54:24.044Z","views":1,"id":"0Q0010000009HIaCAM"}]'); 
                response.setBody('[{"proposalNumber":"'+ idQuote1 +'","rating":"Cold","lastSeen":"2021-05-27T11:47:30.619Z","views":1,"id":"0Q0010000009HIaCAM"},{"proposalNumber":"'+ idQuote2 +'","rating":"Cold","id":"0Q0010000009HIaCAM"},{"proposalNumber":"ATSKPM","rating":"Cold","lastSeen":"2021-05-27T11:54:24.044Z","views":1,"id":"0Q0010000009HIaCAM"}]'); 
            }	
            when 2{
				response.setStatusCode(400);
            }
            when 2300{
				response.setStatusCode(300);
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