public with sharing class FSUtilities {
    @AuraEnabled(cacheable=true)
    public static list<WorkOrder> getProductRequiredxWorkType(){
        return [SELECT Subject,  (
                SELECT Product2.Name, Id, tipoTrabajo__c, tipoTrabajo__r.Name, QuantityRequired, QuantityUnitOfMeasure FROM ProductsRequired  )
                FROM WorkOrder
                //WHERE  Id = '' //Work Order Id
                ];
                
    }
}