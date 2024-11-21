//Created by Me, December '21
//Send quotes to prolibu and get the metrics to update them in salesforce
public class ProlibuProposalMetricsBatch implements  Database.Batchable<sObject>, Database.AllowsCallouts{
	
    public Database.QueryLocator start(Database.BatchableContext BC) {
    	 return Database.getQueryLocator('select QuoteNumber, Id from Quote where Creado_Prolibu__c=true and Opportunity.isClosed=false');
  	}

    public void execute(Database.BatchableContext BC, List<Quote> scope){
        list<Log__c> lstLogs = new list<Log__c>();
        
        //Enviar todas las cotizaciones que estén creadas en Prolibu
        String IdsQuotes ='';
        
        map<String, Quote> mapQuotes = new map<String, Quote>();
        for (Quote q: scope){
            if (IdsQuotes=='') IdsQuotes = q.QuoteNumber;  else IdsQuotes = IdsQuotes +',' + q.QuoteNumber;
            mapQuotes.put(q.QuoteNumber, q);
        }
        system.debug('IdsQuotes: ' + IdsQuotes);

        try{
   
            // HTTP Request
            HttpRequest req = new HttpRequest();
            // Callout extended by /changeStatus
            req.setEndpoint('callout:Prolibu/metrics?ids=' + idsQuotes);
            req.setMethod('GET');
            req.setTimeout(120000);  
            //req.setHeader('Content-Type', 'application/json');
            // Authentication
            req.setHeader('Authorization', 'Bearer {!$Credential.Password}');
            //req.setBody();
            // send request
            Http http = new Http();
            HTTPResponse res = http.send(req);
            System.debug('Cuerpo de la respuesta...' + res.getBody());
            system.debug('El codigo de respuesta es:'+res.getStatusCode());
            
            switch on res.getStatusCode() {
                when 200,201 {		
                    List<ProposalMetricsResponse> metricas = parseSuccess(res.getBody());
                    list<Quote> quotesUpdate = new list<Quote>();
                    
                    for (ProposalMetricsResponse metric: metricas){
                        system.debug(metric);
                        
                        Quote q;
                        if  (mapQuotes.containsKey(metric.proposalNumber)) q=mapQuotes.get(metric.proposalNumber);
                        if (q!=null){
                            q.Temperatura__c =metric.rating;
                            if (metric.lastSeen!=null){
                                string fechaHora = metric.lastSeen.replace('T',' ');
                                q.UltiFecVisuaCoti__c =  Datetime.valueOfGmt(fechaHora);//Datetime.parse(metric.lastSeen);//Date.parse(metric.lastSeen);    
                            }
                            q.NumVisuaCoti__c =metric.views;
                        }
                    }
                    
                   
                    
                    Database.SaveResult[] results = Database.update(mapQuotes.values(), false);
                    // Iterate SaveResult array
                    for (Database.SaveResult result : results) {
                        if (result.isSuccess()) { System.debug('Quote Updated with Prolibu Information Id is: ' + result.getId());}
                        else {
                            //Handle error
                            for(Database.Error error : result.getErrors()) { 
                                //system.debug('error Database: ' + error); 
                                //system.debug('result: ' + result);
                                System.debug(error.getStatusCode() + ': ' + error.getMessage() + ' Fields that affected the error: ' + error.getFields());
                                Log__c log = new Log__c(Web_Service__c='ProlibuProposalMetricsBatch', Body__c = IdsQuotes, Error_Reasignacion__c = 'Id: ' + result.getId() + '. ' + error.getStatusCode() + ': ' + error.getMessage() + ' Fields that affected the error: ' + error.getFields());
                                lstLogs.add(log);
                                
                            }
                        }
                    }
                    
                    //return 'Cotizaciones Actualizadas con datos obtenidos de Prolibu';
                    
                }	
                when 400,500 {		
                    // code block 2
                    //return res.getStatusCode() + '. '+ res.getStatus();
                    //throw new CalloutException('Status Code: ' + res.getStatusCode() + '. Status: '+ res.getStatus());
                    Log__c log = new Log__c(Web_Service__c='ProlibuProposalMetricsBatch', Body__c = IdsQuotes);
                    log.Response__c = res.getBody();
                    log.Error_Reasignacion__c = 'Status Code: ' + res.getStatusCode() + '. Status: '+ res.getStatus();
                    lstLogs.add(log);
                }
                when else {		  // default block, optional
                    //return res.getStatusCode() + '. '+ res.getStatus();
                    system.debug(res.getStatusCode() + '. '+ res.getStatus());
                }
            }
            
            if (lstLogs.size()>0) insert lstLogs;
            
                    	
        }catch(Exception ex){
            //return ex.getMessage();
            Log__c log = new Log__c(Web_Service__c='ProlibuProposalMetricsBatch',Body__c = IdsQuotes);
            log.Error_Reasignacion__c = 'Line: ' + ex.getLineNumber() + '. Error: ' + ex.getMessage();
            lstLogs.add(log);
            insert lstLogs;
        }
    }
     
    public void finish(Database.BatchableContext BC) {
        
    }
   
    //Clase para parsear la respuesta obtenida en las metricas de Prolibu
    public class ProposalMetricsResponse {
		public String proposalNumber;
		public String rating;
		public String lastSeen;
		public Integer views;
		public String id;
	}

	
	public static List<ProposalMetricsResponse> parseSuccess(String json) {
		return (List<ProposalMetricsResponse>) System.JSON.deserialize(json, List<ProposalMetricsResponse>.class);
	}
}