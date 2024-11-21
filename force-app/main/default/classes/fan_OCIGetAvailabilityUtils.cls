public class fan_OCIGetAvailabilityUtils {

    public static Map<String, Set<String>> getRelatedProductGroupepBySource(String[] productSkus) {
        Map<String, Set<String>> relatedProducts = new Map<String, Set<String>>();
        for (fan_RelatedProducts__c relatedProduct : [SELECT fan_Source__r.StockKeepingUnit, fan_Target__r.StockKeepingUnit FROM fan_RelatedProducts__c WHERE fan_RelationType__c = '3' AND fan_Source__r.StockKeepingUnit IN :productSkus]) {
            String source = relatedProduct.fan_Source__r.StockKeepingUnit;
            String target = relatedProduct.fan_Target__r.StockKeepingUnit;
            if(relatedProducts.containsKey(source)) {
                relatedProducts.get(source).add(target);
            } else {
                relatedProducts.put(source, new Set<String> { target });
            }
        }
        for (String sku : productSkus) {
            if(!relatedProducts.containsKey(sku)) {
                relatedProducts.put(sku, new Set<String>());
            }
        }
        return relatedProducts;
    }

    public static Map<String, Decimal> addSubstitutesAvailability(Map<String, Decimal> stockBySku, Map<String, Set<String>> relatedProductSkus) {
        Map<String, Decimal> stockBySkuWithSubstitutes = new Map<String, Decimal>();
        for(String sourceSku : relatedProductSkus.keySet()){
            Decimal available = stockBySku.get(sourceSku);
            for (String targetSku : relatedProductSkus.get(sourceSku)) {
                available += stockBySku.get(targetSku);
            }
            stockBySkuWithSubstitutes.put(sourceSku, available);
        }
        return stockBySkuWithSubstitutes;
    }

    public static Map<String, Decimal> calculateSkuAvailability(fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation[] stockKeepingUnitsLocations, Map<String, Set<String>> relatedProductSkus) {
        Map<String, Decimal> stockBySku = new Map<String, Decimal>();
        for(fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation stockKeepingUnitsLocation : stockKeepingUnitsLocations){
            Decimal available = stockKeepingUnitsLocation.availableToFulfill;
            // Validate if the map already contains the sku
            if (stockBySku.containsKey(stockKeepingUnitsLocation.stockKeepingUnit)) {
                available = available + stockBySku.get(stockKeepingUnitsLocation.stockKeepingUnit);
            }
            stockBySku.put(stockKeepingUnitsLocation.stockKeepingUnit, available);
        }
        return addSubstitutesAvailability(stockBySku, relatedProductSkus);
    }

    public virtual class StockKeepingUnitsResult {
        @AuraEnabled
        public List<StockKeepingUnitsLocation> lstLocationGroup {get; set;}
        @AuraEnabled
        public List<StockKeepingUnitsLocation> lstLocation {get; set;}
        
        public StockKeepingUnitsResult(){
            lstLocationGroup = new List<StockKeepingUnitsLocation>();
            lstLocation = new List<StockKeepingUnitsLocation>();
        }  
    }

    public class StockKeepingUnitsResultWithRelatedProduct {
        @AuraEnabled
        public List<StockKeepingUnitsLocationWithRelatedProduct> lstLocationGroup {get; set;}
        @AuraEnabled
        public List<StockKeepingUnitsLocationWithRelatedProduct> lstLocation {get; set;}
        
        public StockKeepingUnitsResultWithRelatedProduct(){
            lstLocationGroup = new List<StockKeepingUnitsLocationWithRelatedProduct>();
            lstLocation = new List<StockKeepingUnitsLocationWithRelatedProduct>();
        }

        public StockKeepingUnitsResultWithRelatedProduct(StockKeepingUnitsResult skuWithoutRelatedProduct, Map<String, Integer> skuWithRelatedProductsCount){
            lstLocation = stockKeepingUnitsLocationWithRelatedProductWrapper(skuWithoutRelatedProduct.lstLocation, skuWithRelatedProductsCount);
            lstLocationGroup = stockKeepingUnitsLocationWithRelatedProductWrapper(skuWithoutRelatedProduct.lstLocationGroup, skuWithRelatedProductsCount);
        }

        public List<StockKeepingUnitsLocationWithRelatedProduct> stockKeepingUnitsLocationWithRelatedProductWrapper(List<StockKeepingUnitsLocation> lstSkulWithoutRelProd, Map<String, Integer> skuWithRelatedProductsCount){
            List<StockKeepingUnitsLocationWithRelatedProduct> lstSkul = new List<StockKeepingUnitsLocationWithRelatedProduct>();

            for (StockKeepingUnitsLocation itemWithoutRelProd : lstSkulWithoutRelProd) {
                StockKeepingUnitsLocationWithRelatedProduct item = new StockKeepingUnitsLocationWithRelatedProduct();
                item.ubicacion = itemWithoutRelProd.ubicacion;
                item.concessionaire = itemWithoutRelProd.concessionaire;
                item.description = itemWithoutRelProd.description;
                item.reference = itemWithoutRelProd.reference;
                item.agencia = itemWithoutRelProd.agencia;
                item.modelLine = itemWithoutRelProd.modelLine;
                item.color = itemWithoutRelProd.color;
                item.model = itemWithoutRelProd.model;
                item.availableToFulfill = itemWithoutRelProd.availableToFulfill;
                item.availableToOrder = itemWithoutRelProd.availableToOrder;
                item.onHand = itemWithoutRelProd.onHand;
                item.reserved = itemWithoutRelProd.reserved;
                item.safetyStockCount = itemWithoutRelProd.safetyStockCount;
                item.stockKeepingUnit = itemWithoutRelProd.stockKeepingUnit;
                item.hasRelatedProduct = skuWithRelatedProductsCount.get(item.stockKeepingUnit) > 0;
                
                lstSkul.add(item);
            }
            return lstSkul;
        }
    }

    public virtual class StockKeepingUnitsLocation {
        @AuraEnabled
        public String ubicacion {get;set;}
        @AuraEnabled
        public String concessionaire {get;set;}
        @AuraEnabled
        public String description {get;set;}
        @AuraEnabled
        public String reference {get;set;}
        @AuraEnabled
        public String agencia {get;set;}
        @AuraEnabled
        public String modelLine {get;set;}
        @AuraEnabled
        public String color {get;set;}
        @AuraEnabled
        public String model {get;set;}

        @AuraEnabled
        public Decimal availableToFulfill  {get;set;}
        @AuraEnabled
        public Decimal availableToOrder  {get;set;}
        @AuraEnabled
        public Decimal onHand  {get;set;}
        @AuraEnabled
        public Decimal reserved  {get;set;}
        @AuraEnabled
        public Decimal safetyStockCount {get;set;}
        @AuraEnabled
        public String stockKeepingUnit  {get;set;}
        
        public StockKeepingUnitsLocation(){
            
        }
        
    }

    public class StockKeepingUnitsLocationWithRelatedProduct extends StockKeepingUnitsLocation{
        @AuraEnabled
        public Boolean hasRelatedProduct {get;set;}

        public StockKeepingUnitsLocationWithRelatedProduct(){

        }
    }
    
}