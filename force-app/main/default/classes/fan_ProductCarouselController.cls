public class fan_ProductCarouselController {
    
    @AuraEnabled
    public static List<String> getRelatedProductsBySourceId(String productSourceId, String relatedProduct){
        List<String> lstReturn = new List<String>();
        
        List<fan_RelatedProducts__c> lstRelatedProduct = [SELECT Id, fan_Target__r.StockKeepingUnit 
                                                          FROM fan_RelatedProducts__c 
                                                          WHERE fan_Source__c =: productSourceId
                                                          AND fan_RelationType__c =: relatedProduct];
        
        for(fan_RelatedProducts__c related : lstRelatedProduct){
            if(!String.isBlank(related.fan_Target__r.StockKeepingUnit)){
                lstReturn.add(related.fan_Target__r.StockKeepingUnit);
            }
        }
        
        return lstReturn;
    }
    
    @AuraEnabled
    public static List<PickListValue> getRelatedProductPickListValue(){        
        List<PickListValue> options = new List<PickListValue>();
        Schema.DescribeFieldResult fieldResult = fan_RelatedProducts__c.fan_RelationType__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            PickListValue pl = new PickListValue();
            pl.label = f.getLabel();
            pl.value = f.getValue();
            options.add(pl);
        }     
        return options;
    }
    
    public class PickListValue {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }
        
        public PickListValue(){}
    }  

}