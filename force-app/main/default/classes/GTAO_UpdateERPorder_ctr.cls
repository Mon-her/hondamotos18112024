/*************************************************************************************************************
 * @name            GTAO_UpdateERPorder_ctr
 * @author          Andres Oliva <andresolivag@gmail.com>
 * @created         31 / 10 / 2021
 * @description     This is a controller class to update ERP order details
 *
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 *              No.     Date            Author                  Description
 *              ----    ------------    --------------------    ----------------------------------------------
 * @version     1.0     2021-10-31      Andres Oliva            Changes desription
 *
**************************************************************************************************************/
public without sharing class GTAO_UpdateERPorder_ctr {

    /*********************************************************************************************************
    * @name             callUpdateOrderERP
    * @author           Andres Oliva <andresolivag@gmail.com>
    * @created          01 / 11 / 2021
    * @description      Return the call out results to update ERP
    * @param            list<GTAO_UpdateERPorderREST_ws.RequestERP>  request of the web service
    * @return           map< string, list<GTAO_UpdateERPorderREST_ws.ResponseERP > > response of the webservice
    **********************************************************************************************************/
    public static  map< string, list<GTAO_UpdateERPorderREST_ws.ResponseERP > > callUpdateOrderERP( list<GTAO_UpdateERPorderREST_ws.RequestERP> lstRequest){
        GTAO_UpdateERPorder_ctr objClass        =   new GTAO_UpdateERPorder_ctr();
        map<string,string>      mapRequest      =   objClass.convertToMap(  lstRequest );
        list< Opportunity >     lstOpportunity  =   objClass.querieOpportunities ( mapRequest );
        
        system.debug('\n request @@@'+ JSON.serializePretty( lstRequest ));
        //system.debug('\n mapRequest @@@@ ' + JSON.serializePretty(mapRequest  ));
        //system.debug('\n lst opportunity Request @@@@ ' + JSON.serializePretty(lstOpportunity  ));

        map< string, GTAO_UpdateERPorderREST_ws.ResponseERP >        mapResponseOrder   = objClass.updateOrders( lstOpportunity, mapRequest  ); 
        //system.debug('\n response order @@@'+ JSON.serializePretty( mapResponseOrder ));
        map< string, GTAO_UpdateERPorderREST_ws.ResponseERP >        mapResponseOpp     = objClass.updateOpportunities( lstOpportunity, mapRequest );
        //system.debug('\n response opportunity @@@'+ JSON.serializePretty( mapResponseOpp ));
        map< string, list<GTAO_UpdateERPorderREST_ws.ResponseERP > > mapResponse        = objClass.storeResponseResults( mapResponseOpp, mapResponseOrder );
        //system.debug('\n final response  @@@'+ JSON.serializePretty( mapResponse ));
        return mapResponse;
    }

    /*********************************************************************************************************
     * @name            storeResponseResults
     * @author          Andres Oliva <andresolivag@gamil.com>
     * @created         01 / 11 / 2021
     * @description     This method return the combination of order and opportunities updates
     * @param           map< string, GTAO_UpdateERPorderREST_ws.ResponseERP > mapOpp => map response opportunity
     * @param           map< string, GTAO_UpdateERPorderREST_ws.ResponseERP > mapOrder=>map response order
     * @return          map< string, list<GTAO_UpdateERPorderREST_ws.ResponseERP > >  map final response
    **********************************************************************************************************/
    private map< string, list<GTAO_UpdateERPorderREST_ws.ResponseERP > > storeResponseResults ( map< string, GTAO_UpdateERPorderREST_ws.ResponseERP > mapOpp, map< string, GTAO_UpdateERPorderREST_ws.ResponseERP > mapOrder){
        map< string, list<GTAO_UpdateERPorderREST_ws.ResponseERP > > mapResponse = new map< string, list<GTAO_UpdateERPorderREST_ws.ResponseERP > > ();       
        for(  string varKey: mapOpp.keySet()){
            if(!mapResponse.containsKey( varKey)){
                list< GTAO_UpdateERPorderREST_ws.ResponseERP > lstResponseOpp = new list< GTAO_UpdateERPorderREST_ws.ResponseERP >(); 
                lstResponseOpp.add( mapOpp.get( varKey) );
                mapResponse.put( varKey, lstResponseOpp );
            }else if( mapResponse.containsKey( varKey)) {
                list< GTAO_UpdateERPorderREST_ws.ResponseERP > lstResponseOpp = mapResponse.get( varKey );
                lstResponseOpp.add(mapOpp.get( varKey )); 
                mapResponse.put( varKey, lstResponseOpp );
            }
        }
        for(  string varKey: mapOrder.keySet()){
            if(!mapResponse.containsKey( varKey)){
                list< GTAO_UpdateERPorderREST_ws.ResponseERP > lstResponseOrd = new list< GTAO_UpdateERPorderREST_ws.ResponseERP >(); 
                lstResponseOrd.add( mapOrder.get( varKey) );
                mapResponse.put( varKey, lstResponseOrd );
            }else if( mapResponse.containsKey( varKey)) {
                list< GTAO_UpdateERPorderREST_ws.ResponseERP > lstResponseOrd = mapResponse.get( varKey );
                lstResponseOrd.add(mapOrder.get( varKey )); 
                mapResponse.put( varKey, lstResponseOrd );
            }         
        } 
        return mapResponse;
    }
   /*********************************************************************************************************
    * @name             convertToMap
    * @author           Andres Oliva <andresolivag@gmail.com>
    * @created          01 / 11 / 2021
    * @description      This method conver the WBS request in a simple map array.
    * @param            list<GTAO_UpdateERPorderREST_ws.RequestERP> lstRequest => request list
    * @return           map<string,string>  map response key    ==> opportunity number
                                                         value  ==> ERP order
   **********************************************************************************************************/
    private   map<string,string> convertToMap( list<GTAO_UpdateERPorderREST_ws.RequestERP> lstRequest ){
        map<string,string> mapRequest = new map<string,string>();       
        for( GTAO_UpdateERPorderREST_ws.RequestERP varRequest: lstRequest ){
            mapRequest.put( varRequest.OpportunityNumber, varRequest.ERPorderId );
        }
        return mapRequest;
   }
   /*********************************************************************************************************
    * @name             querieOpportunities
    * @author           Andres Oliva <andresolivag@gmail.com>
    * @created          31 / 10 / 2021
    * @description      This method return an opportinty list with the opportunity number, ERP order and related 
                        order list.
    * @param            map<string,string> mapOpporByOrderERP
    *                   key     ==> opportunity number
                        value   ==> Order ERP
    * @return           Returns and opportunity list
   **********************************************************************************************************/
    private list< Opportunity >   querieOpportunities ( map<string,string> mapOpporByOrderERP ){
        list< Opportunity > lstOpport = [SELECT Id, 
                                                ID_de_pedido_ERP__c,
                                                Numero_de_Oportunidad__c,
                                                ( SELECT Id,ID_de_pedido_ERP__c  FROM Orders ) 
                                        FROM  Opportunity 
                                        WHERE Numero_de_Oportunidad__c IN : mapOpporByOrderERP.keySet()];
        SYSTEM.DEBUG('\N LIST QUERIE OPP @@@ ' + JSON.serializePretty( lstOpport ));
        return  lstOpport;
    }
    /*********************************************************************************************************
     * @name            updateOpportunities
     * @author          Andres Oliva <andresolivag@gmail.com>
     * @created         31 / 10 / 2021
     * @description     This method update opportunity ID_de_pedido_ERP__c field 
     * @param           list< Opportunity >   lstOpp : opportunity list with ID_de_pedido_ERP__c and 
                        Numero_de_Oportunidad__c fields
     * @param           map< string, string > mapOpporByOrderERP    key => opportunity number
                                                                    value ==> Order ERP   
     * @return          Explanation of the return value
    **********************************************************************************************************/
    private  map< string, GTAO_UpdateERPorderREST_ws.ResponseERP > updateOpportunities( list< Opportunity >   lstOpp, map< string, string > mapOpporByOrderERP ){
        map< string, list< Opportunity > > mapOppToUpdate = new map< string, list< Opportunity > >();
        map<id, string > mapIdOrderNo = new map<id, string > ();
        for( opportunity varOpp: lstOpp ){
            if( mapOpporByOrderERP.containsKey( varOpp.Numero_de_Oportunidad__c ) && 
                ( string.IsBlank( varOpp.ID_de_pedido_ERP__c )|| varOpp.ID_de_pedido_ERP__c !=  
                    mapOpporByOrderERP.get( varOpp.Numero_de_Oportunidad__c ))){
                        list< Opportunity > lstOppUpdate = new list< Opportunity >();
                        mapIdOrderNo.put(varOpp.Id, varOpp.Numero_de_Oportunidad__c);
                        varOpp.ID_de_pedido_ERP__c  =  mapOpporByOrderERP.get( varOpp.Numero_de_Oportunidad__c );
                        lstOppUpdate.add( varOpp );
                        mapOppToUpdate.put( varOpp.Numero_de_Oportunidad__c ,lstOppUpdate );
            }
        }
        map< string, GTAO_UpdateERPorderREST_ws.ResponseERP > mapResults = updateERPsaveResults( mapOppToUpdate, mapIdOrderNo );      
        return mapResults;
    }

    /*********************************************************************************************************
     * @name            updateOrders
     * @author          Andres Oliva <andresolivag@gmail.com>
     * @created         31 / 10 / 2021
     * @description     This method update opportunity ID_de_pedido_ERP__c field 
     * @param           list< Opportunity >   lstOpp : opportunity list with ID_de_pedido_ERP__c and Numero_de_Oportunidad__c fields
     * @param           map< string, string > mapOpporByOrderERP    key => opportunity number
                                                                    value ==> Order ERP   
     * @return          Explanation of the return value
    **********************************************************************************************************/
    private  map< string,  GTAO_UpdateERPorderREST_ws.ResponseERP > updateOrders( list< Opportunity >   lstOpp, map< string, string > mapOpporByOrderERP ){
        map<string, list< order> > mapOrdToUpdate = new map< string, list<order> >();
        map<id, string > mapIdERPorder = new map<id, string >();
        for( opportunity varOpp: lstOpp ){
            if( mapOpporByOrderERP.containsKey( varOpp.Numero_de_Oportunidad__c ) ){
                for(order varord: varOpp.orders ){
                    if( !mapOrdToUpdate.containsKey( varOpp.Numero_de_Oportunidad__c )  ){ // && string.IsBlank(  varord.ID_de_pedido_ERP__c) || varord.ID_de_pedido_ERP__c != mapOpporByOrderERP.get( varOpp.Numero_de_Oportunidad__c )
                        varord.ID_de_pedido_ERP__c  =  mapOpporByOrderERP.get( varOpp.Numero_de_Oportunidad__c );
                        list< order > lstOrder = new list< order >(); 
                        lstOrder.add( varord );
                        mapIdERPorder.put(varord.Id,varOpp.Numero_de_Oportunidad__c);
                        mapOrdToUpdate.put( varOpp.Numero_de_Oportunidad__c , lstOrder );                    
                    }    
                    else if( mapOrdToUpdate.containsKey( varOpp.Numero_de_Oportunidad__c )){
                        varord.ID_de_pedido_ERP__c  =  mapOpporByOrderERP.get( varOpp.Numero_de_Oportunidad__c );
                        list< order > lstOrderN =  mapOrdToUpdate.get( varOpp.Numero_de_Oportunidad__c );
                        lstOrderN.add(varord);
                        mapOrdToUpdate.put( varOpp.Numero_de_Oportunidad__c , lstOrderN ); 
                        mapIdERPorder.put(varord.Id,varOpp.Numero_de_Oportunidad__c); 
                    }               
                }      
            }     
        }
        map< string, GTAO_UpdateERPorderREST_ws.ResponseERP > mapResults = updateERPsaveResults( mapOrdToUpdate, mapIdERPorder );
        return mapResults;
    }
    /*********************************************************************************************************
     * @name            updateERPsaveResults
     * @author          Andres Oliva < andresolivag@gmail.com >
     * @created         01 / 11 / 2021
     * @description     Description of your code
     * @param           String param : Explanation
     * @return          Explanation of the return value
    **********************************************************************************************************/    
    private map< string, GTAO_UpdateERPorderREST_ws.ResponseERP > updateERPsaveResults( map<string, list<SObject> > mapSobject, map<id,string> mapIdorderNumber ){
        map< string, GTAO_UpdateERPorderREST_ws.ResponseERP > mapResponse = new map< string,GTAO_UpdateERPorderREST_ws.ResponseERP >(); 
        list<SObject>  lstObject = new list<SObject> ();
        for( string varKey: mapSobject.keyset() ){
            lstObject.addall( mapSobject.get( varKey ) );
        }       

        Database.SaveResult[] srList = Database.Update( lstObject, false);
        list<String> lstKeySet= new list<String>();
        lstKeySet.addall(mapSobject.keyset());       
     
        for(Integer i=0;i<srList.size();i++){
            GTAO_UpdateERPorderREST_ws.ResponseERP objResponse = new GTAO_UpdateERPorderREST_ws.ResponseERP();
            if (srList.get(i).isSuccess()){  
                objResponse.OpportunityNumber       = mapIdorderNumber.get( srList.get(i).id);            
                objResponse.SFDC_Id                 = srList.get(i).id;           
                objResponse.StatusCode              = 'OK';
                objResponse.StatusMessage           = 'Successfully Update, ID: ' +  srList.get(i).id;
                mapResponse.put(  srList.get(i).id, objResponse); // lstKeySet[i]

            }else if (!srList.get(i).isSuccess()){           
                Database.Error error                = srList.get(i).getErrors().get(0);
                 objResponse.OpportunityNumber      = mapIdorderNumber.get( srList.get(i).id);  
                objResponse.SFDC_Id                 = srList.get(i).id; 
                objResponse.StatusCode              = 'KO';
                objResponse.StatusMessage           = error.getMessage();
                objResponse.StatusMessageDetails    = error.getFields();               
                mapResponse.put( srList.get(i).id, objResponse); // lstKeySet[i]
            }
        }      
        return  mapResponse ;
    }
}