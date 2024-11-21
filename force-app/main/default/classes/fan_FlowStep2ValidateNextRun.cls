global class fan_FlowStep2ValidateNextRun {

    @TestVisible
    static OrderItemSummary[] testOrderItemSummaries;
    
    @InvocableMethod(label='Process and build information to Re Schedule')
    global static void processRoutingSchedule(List<Request> request){
        for(Request r : request){
            List<OrderItemSummary> lstOrderItem = Test.isRunningTest() ? testOrderItemSummaries : [SELECT Id, FAN_Processing_Date__c, OrderSummaryId FROM OrderItemSummary WHERE Id =: r.lstOrderItem];
            if(lstOrderItem.size() > 0){
                
                for(OrderItemSummary ois : lstOrderItem){
                    ois.FAN_Processing_Date__c = date.today();
                }
                
                if(!Test.isRunningTest()) update lstOrderItem;
            }           
        }
        
        
    }
    
    global class Request {
        @InvocableVariable global List<OrderItemSummary> lstOrderItem; //Items_to_Route
        @InvocableVariable global OrderSummaryRoutingSchedule orderSummaryRoutingSchedule;        
    }
    
    global class Response {
        @InvocableVariable global List<OrderItemSummary> lstOrderItem;
        @InvocableVariable global List<String> lstOrderItemIdRemove;
        @InvocableVariable global List<SkuQuantity> lstSKUQuantityCopy;
        @InvocableVariable global List<SkuQuantity> SKUQuantityList;
        @InvocableVariable global List<OrderItemSummaryQty> OrderItemSummaryQtyList;
        @InvocableVariable global List<OrderItemSustituteQty> OrderItemSustituteQtyList;
    }
    
}