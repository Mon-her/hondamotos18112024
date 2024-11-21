public without sharing class fan_PromotionCtrl {

    @AuraEnabled
    public static PriceAdjustmentTier[] getPriceAdjustmentTiers(String effectiveAccountId, String productId){
        try {
            Set<String> buyerGroupIds = new Set<String>();

            for(BuyerGroupMember buyerGroupMember : [SELECT BuyerGroupId FROM BuyerGroupMember WHERE BuyerId =: effectiveAccountId]) {
	            buyerGroupIds.add(buyerGroupMember.BuyerGroupId);
            }
            String priceAdjustmentScheduleName = getPriceAdjustmentScheduleName(productId, buyerGroupIds);

            return [SELECT PriceAdjustmentScheduleId, LowerBound, UpperBound, TierType, TierValue FROM PriceAdjustmentTier
                    WHERE PriceAdjustmentSchedule.Name = :priceAdjustmentScheduleName ORDER BY TierValue ASC];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @TestVisible
    static String getPriceAdjustmentScheduleName(String productId, Set<String> buyerGroupIds) {
        Date currentDate = Date.today();
        Integer day = currentDate.day();  
        Product2 product = [SELECT fan_Category__c, fan_Brand__c, fan_ProductType__c FROM Product2 WHERE Id =: productId ];
        fan_ConfiguracionRangoPrecio__c priceRangeConfigurationToReturn = null;

        for (fan_ConfiguracionRangoPrecio__c priceRangeConfiguration : [SELECT Name, fan_Marca__c, fan_Tipo_de_producto__c FROM fan_ConfiguracionRangoPrecio__c WHERE
                                                                        fan_Activo__c = true
                                                                        AND fan_Condicion_pago_en_carrito__c INCLUDES (:fan_Constants.FormaPago.CONTADO.name())
                                                                        AND fan_Catalogo_referencias__c =: product.fan_Category__c
                                                                        AND fan_Grupo_de_compradores__c IN :buyerGroupIds
                                                                        AND fan_FechaInicio__c <= :currentDate AND fan_FechaFin__c >= :currentDate
                                                                        AND fan_Dia_Inicial__c <= :day AND fan_Dia_Final__c >= :day 
                                                                        ORDER BY fan_Tipo_de_producto__c, fan_Marca__c NULLS FIRST]) {
            if (priceRangeConfiguration.fan_Tipo_de_producto__c != null && priceRangeConfiguration.fan_Tipo_de_producto__c == product.fan_ProductType__c) 
                priceRangeConfigurationToReturn = priceRangeConfiguration;
            else if (priceRangeConfiguration.fan_Tipo_de_producto__c == null && priceRangeConfiguration.fan_Marca__c != null && priceRangeConfiguration.fan_Marca__c == product.fan_Brand__c)
                priceRangeConfigurationToReturn = priceRangeConfiguration;
            else if (priceRangeConfiguration.fan_Tipo_de_producto__c == null && priceRangeConfiguration.fan_Marca__c == null)
                priceRangeConfigurationToReturn = priceRangeConfiguration;
        }
        return priceRangeConfigurationToReturn != null ? priceRangeConfigurationToReturn.Name : null;
    }
}