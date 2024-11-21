global class fan_FlowStep2LoopOrderItem {
    
    
    @InvocableMethod(label='Process and build information to create order')
    global static List<Response> getAvailability(List<Request> request){
        /*
        String currentGroup = '';
        for(OrderItemSummary each : request[0].lstOrderItem){
            System.debug('each size ' + request.size());
            System.debug('each ' + each);
            if(each.Type != 'Delivery Charge'){
                currentGroup=each.fan_OrderSegmentationGroup__c;
            }
        }
        */
        List<Response> lstResponse = new List<Response>();
        for(Request r : request){
            Response res = new Response();
            Map<String, SKUQuantity> mapSKUQuanty = new Map<String, SKUQuantity>();
            Map<String, SKUQuantity> mapSKUQuantyCopy = new Map<String, SKUQuantity>();
            
            Map<String, List<fan_RelatedProducts__c>> mapSustituteProducts = new Map<String, List<fan_RelatedProducts__c>>();
            
            //Part 1 Loop_Order_Items_for_originals  
            List<OrderItemSummary> lstOrderItem = r.lstOrderItem;
            List<SKUQuantity> SKUQuantityList = r.SKUQuantityList;
            
            for(SKUQuantity skuList : SKUQuantityList){
                mapSKUQuanty.put(skuList.SKU, skuList);
            }
            
            List<String> lstTargetId = new List<String>();
            if(r.originalProductIds?.isEmpty() == false){
                for(fan_RelatedProducts__c sustitute : [SELECT fan_Source__c, fan_Target__r.StockKeepingUnit FROM fan_RelatedProducts__c
                                                        WHERE fan_RelationType__c = '3' AND fan_Source__c = :r.originalProductIds]){
                    if(mapSustituteProducts.containsKey(sustitute.fan_Source__c)) {
                        List<fan_RelatedProducts__c> lst_terr = mapSustituteProducts.get(sustitute.fan_Source__c);
                        lst_terr.add(sustitute);
                        mapSustituteProducts.put(sustitute.fan_Source__c,lst_terr); 
                    }   
                    else {
                        mapSustituteProducts.put(sustitute.fan_Source__c, new List<fan_RelatedProducts__c> {sustitute});
                    }
                    lstTargetId.add(sustitute.fan_Target__c);
                }
            }
            
            
            List<Product2> lstProductTarget = [SELECT Id, StockKeepingUnit, Name FROM Product2 WHERE Id =:lstTargetId];
            Map<ID, Product2> mapTargetSKU = new Map<ID, Product2>(lstProductTarget);
            
            res.lstOrderItemIdRemove = new List<String>();
            res.lstSKUQuantityCopy = new List<SkuQuantity>();
            res.SKUQuantityList = new List<SkuQuantity>();
            res.OrderItemSummaryQtyList = new List<OrderItemSummaryQty>();
            res.OrderItemSustituteQtyList = new List<OrderItemSustituteQty>();
            
            for(OrderItemSummary ois : lstOrderItem){
                
                system.debug('ee: '+ois.StockKeepingUnit);
                system.debug('ee: '+mapSKUQuanty);
                
                if(mapSKUQuanty.containsKey(ois.StockKeepingUnit)){
                    SKUQuantity SKUValue = mapSKUQuanty.get(ois.StockKeepingUnit);
                    
                    system.debug('SKU; '+ois.StockKeepingUnit+'   eeee: '+(SKUValue.Quantity >= ois.QuantityAvailableToFulfill));
                    
                    if(SKUValue.Quantity >= ois.QuantityAvailableToFulfill){
                        SKUValue.Quantity = SKUValue.Quantity - ois.QuantityAvailableToFulfill;
                        res.lstOrderItemIdRemove.add(ois.Id);
                        res.lstSKUQuantityCopy.add(SKUValue);
                        mapSKUQuantyCopy.put(SKUValue.SKU, SKUValue);
                        mapSKUQuanty.put(ois.StockKeepingUnit, SKUValue);
                    }else{
                        
                        if(SKUValue.Quantity > 0){
                            res.lstSKUQuantityCopy.add(SKUValue);
                            mapSKUQuantyCopy.put(SKUValue.SKU, SKUValue);
                        }
                        
                        OrderItemSummaryQty oItem = new OrderItemSummaryQty();
                        oItem.OrderItemSummaryId = ois.Id;
                        oItem.Quantity = SKUValue.Quantity;
                        oItem.OrderItemQuantity = ois.QuantityAvailableToFulfill;
                        oItem.OrderSummaryId = ois.OrderSummaryId;
                        oItem.hasBackorder = ois.fan_IsBackorder__c;
                        SKUValue.Quantity = 0;
                        
                        mapSKUQuanty.put(ois.StockKeepingUnit, SKUValue);
                        
                        res.OrderItemSummaryQtyList.add(oItem);
                    }
                }
            }
            
            //Part 2 Loop_SKUQuantityList_To_Add_To_Copy 
            for(SKUQuantity skuList : SKUQuantityList){
                if(!mapSKUQuantyCopy.containsKey(skuList.SKU)){
                    res.lstSKUQuantityCopy.add(skuList);
                }
            }
            
            system.debug('eee: '+res.OrderItemSummaryQtyList.size());
            
            //Part 3 sustitute 
            
            Map<String, List<OrderItemSummaryQty>> mapOrderItemSummaryQ = new Map<String, List<OrderItemSummaryQty>>();
            for(OrderItemSummaryQty oqty : res.OrderItemSummaryQtyList){
                if(mapOrderItemSummaryQ.containsKey(oqty.OrderItemSummaryId)) {
                    List<OrderItemSummaryQty> lst_terr = mapOrderItemSummaryQ.get(oqty.OrderItemSummaryId);
                    lst_terr.add(oqty);
                    mapOrderItemSummaryQ.put(oqty.OrderItemSummaryId,lst_terr); 
                }   
                else {
                    mapOrderItemSummaryQ.put(oqty.OrderItemSummaryId, new List<OrderItemSummaryQty> {oqty});
                }
            }
            
            for(OrderItemSummary ois : lstOrderItem){
                
                if(mapSustituteProducts.containsKey(ois.Product2Id)){
                    List<fan_RelatedProducts__c> lstSustite = mapSustituteProducts.get(ois.Product2Id);
                    for(fan_RelatedProducts__c sus : lstSustite){
                        for(SKUQuantity skuC : res.lstSKUQuantityCopy){
                            if(skuC.SKU == mapTargetSKU.get(sus.fan_Target__c).StockKeepingUnit ){
                                
                                
                                List<OrderItemSummaryQty> lstProc = mapOrderItemSummaryQ.get(ois.Id);
                                if(lstProc != null){
                                    for(OrderItemSummaryQty ordISu : lstProc){
                                        
                                        OrderItemSustituteQty oItem = new OrderItemSustituteQty();
                                        oItem.OrderItemSummaryId = ois.Id;
                                        oItem.OrderItemQty = ordISu.OrderItemQuantity;   
                                        oItem.SustituteSKU = skuC.SKU;
                                        oItem.SKUSustituteQty = skuC.Quantity;
                                        oItem.OrderItemQtyATF = ois.QuantityAvailableToFulfill;
                                        oItem.OrderItemSummary = ois;
                                        oItem.SustituteId = mapTargetSKU.get(sus.fan_Target__c).Id;
                                        oItem.SustituteName = mapTargetSKU.get(sus.fan_Target__c).Name;
                                        res.OrderItemSustituteQtyList.add(oItem);
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                
            }
            
            lstResponse.add(res);
            
        }
        
        system.debug('eee: '+lstResponse.size());
    
        return lstResponse;
    }
    
    global class Request {
        @InvocableVariable global List<OrderItemSummary> lstOrderItem; //Items_to_Route
        @InvocableVariable global List<SkuQuantity> SKUQuantityList;
        @InvocableVariable global List<String> originalProductIds;
    }
    
    global class Response {
        @InvocableVariable global List<String> lstOrderItemIdRemove;
        @InvocableVariable global List<SkuQuantity> lstSKUQuantityCopy;
        @InvocableVariable global List<SkuQuantity> SKUQuantityList;
        @InvocableVariable global List<OrderItemSummaryQty> OrderItemSummaryQtyList;
        @InvocableVariable global List<OrderItemSustituteQty> OrderItemSustituteQtyList;
    }
    
    
    
}