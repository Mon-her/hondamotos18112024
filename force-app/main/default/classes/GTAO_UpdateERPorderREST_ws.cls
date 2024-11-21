/*************************************************************************************************************
 * @name			GTAO_UpdateERPorderREST_ws
 * @author			Andres Oliva <andresolivag@gmail.com>
 * @created			01 / 11 / 2021
 * @description		Description of your code
 *
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 * 				No.		Date			Author					Description
 * 				----	------------	--------------------	----------------------------------------------
 * @version		1.0		2021-11-01		Andres Oliva			web service to update ERP order number
 *
**************************************************************************************************************/
//@RestResource(urlMapping='/ERPorder/*')
global class GTAO_UpdateERPorderREST_ws {
    
    global class RequestERP {
		webService String  OpportunityNumber;
        webService String  ERPorderId;        
    }
    global class ResponseERP{
        webService String   OpportunityNumber;
        webService String   SFDC_Id;
        webService String   StatusCode; 
		webService String   StatusMessage;
        webService list< String >   StatusMessageDetails;
    }
   // @HttpPost
    webservice static list<list<ResponseERP >> updateERPorder(list< RequestERP > lstRequestERP ){
        map< string, list< ResponseERP > > mapResponse = GTAO_UpdateERPorder_ctr.callUpdateOrderERP( lstRequestERP );
        return  mapResponse.values();        
    }
}