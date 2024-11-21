public with sharing class fan_PosventaShippingCalculator extends fan_ShippingCalculator {

    public override Map<String, Decimal> calculateShipping(String accountId, String webStoreId, Set<String> productIds, Product[] products) {

        Set<String> buyerGroupIds  = getBuyerGroupIds(accountId, webStoreId);
        Map<String, Decimal> shippingCostBySegmentationGroup = new Map <String, Decimal> ();
        Map<String, Set<String>> categoriesByProductId = getCategoriesByProductId(productIds);
        Map<String, Map<String, Product[]>> groupedProducts = groupProducts(products);

        // Search if the account has a shipping logic exception based on the category shipping options
        fan_CuentaFlete__c[] exceptionsAccount = [SELECT fan_ValorFlete__c, fan_Flete__c FROM fan_CuentaFlete__c WHERE fan_Cuenta__c = :accountId];
        // Search if the account has a shipping logic exception based on the category shipping options
        fan_CiudadFlete__c[] exceptionsCity = [SELECT fan_ValorFlete__c, fan_Flete__c, fan_Flete__r.Name FROM fan_CiudadFlete__c WHERE fan_Ciudad__c IN (SELECT AM_Ciudad__c FROM Account WHERE Id = :accountId)];

        for(String segmentationGroup : groupedProducts.keySet()){

            Map<String, Product[]> productsByPaymentCondition = groupedProducts.get(segmentationGroup);
            for (String paymentCondition : productsByPaymentCondition.keySet()) {

                Product[] paymentConditionProducts = productsByPaymentCondition.get(paymentCondition);
                Map<String, CategoryCartItemsItemsData> cartItemsByCategory = getCategoryTotals(paymentConditionProducts, categoriesByProductId);

                // Get Shipping rates searching by the category of cart items
                Map<String,ShippingOptionsAndRates> shippingOptionsAndRates = getShippingOptionsAndRates(buyerGroupIds, cartItemsByCategory);
                // Validate if account has a shipping cost exception
                shippingOptionsAndRates = validateShippingOptionsExceptions(exceptionsAccount, exceptionsCity, shippingOptionsAndRates);
                
                shippingOptionsAndRates = updateCostsByCartItemsCategory(cartItemsByCategory, shippingOptionsAndRates);

                // Get uniq shipping options and update the shipping option with the final cost
                Map<String,ShippingOptionsAndRates> cleanShippingOptions= cleanDataAndValidateCost(shippingOptionsAndRates);
                System.debug(LoggingLevel.DEBUG, 'ShippingOptions After clean and cost Validations >>> '+cleanShippingOptions);

                // SUM ALL THE SHIPPING OPTIONS
                ShippingOptionsAndRates finalShippingCost = getShippingOptionsSummatory(cleanShippingOptions.values());
                if(finalShippingCost.shipFinalCost > 0){
                    shippingCostBySegmentationGroup.put(segmentationGroup + ':' + paymentCondition, finalShippingCost.shipFinalCost);
                }
            }
        }
        return shippingCostBySegmentationGroup;
    }

    Map<String, Map<String, Product[]>> groupProducts(Product[] products) {

        Map<String, Map<String, Product[]>> productsBySegmentationGroup = new Map<String, Map<String, Product[]>>();

        for (Product product : products) {

            String segmentationGroup = product.segmentationGroup;
            String paymentCondition = product.paymentCondition;

            Map<String, Product[]> productsByPaymentCondition = productsBySegmentationGroup.containsKey(segmentationGroup) ? productsBySegmentationGroup.get(segmentationGroup) : new Map<String, Product[]>();

            Product[] paymentConditionProducts = productsByPaymentCondition.containsKey(paymentCondition) ? productsByPaymentCondition.get(paymentCondition) : new List<Product>();
            paymentConditionProducts.add(product);

            productsByPaymentCondition.put(paymentCondition, paymentConditionProducts);
            productsBySegmentationGroup.put(segmentationGroup, productsByPaymentCondition);
        }
        return productsBySegmentationGroup;
    }

    Map<String, Set<String>> getCategoriesByProductId(Set<String> productIds) {

        Map<String, Set<String>> categoriesByProductId = new Map<String, Set<String>>();

        for (ProductCategoryProduct productCategoryProduct : [SELECT ProductCategoryId, ProductId FROM ProductCategoryProduct WHERE ProductId IN :productIds]) {

            String productId = productCategoryProduct.ProductId;

            Set<String> categories = categoriesByProductId.containsKey(productId) ? categoriesByProductId.get(productId) : new Set<String>();
            categories.add(productCategoryProduct.ProductCategoryId);

            categoriesByProductId.put(productId, categories);
        }
        return categoriesByProductId;
    }

    Map<String, CategoryCartItemsItemsData> getCategoryTotals(Product[] products, Map<String, Set<String>> categoriesByProductId){
        // Save categoryId and the items summatory of that category
        Map<String, CategoryCartItemsItemsData> cartItemsByCategory = new Map<String, CategoryCartItemsItemsData>();
        for (Product product : products){
            Decimal quantity = product.quantity;
            Decimal totalAmount = product.totalAmount;
            // Add cart item data to CategoryCartItemsItemsData to save the totals
            Set<String> categories = categoriesByProductId.containsKey(product.id) ? categoriesByProductId.get(product.id) : new Set<String>();
            for (String category : categories) {
                if (cartItemsByCategory.containsKey(category)) {
                    CategoryCartItemsItemsData cartItemSumm = cartItemsByCategory.get(category);
                    cartItemSumm.addQuantity(quantity); 
                    cartItemSumm.addTotal(totalAmount); 
                } else {
                    cartItemsByCategory.put(category, new CategoryCartItemsItemsData(quantity, totalAmount));
                }
            }
        }
        System.debug(LoggingLevel.DEBUG, 'getItemsByCategory .. cartItemsByCategory to return >>> ' + cartItemsByCategory);
        return cartItemsByCategory;
    }

    Map<String,ShippingOptionsAndRates> getShippingOptionsAndRates (Set<String> buyerGroupIds, Map<String,CategoryCartItemsItemsData> cartItemsByCategory) {

        // Get all shippings for the buyer groups of account to validate which shipping logics apply
        List<fan_CategoriaFlete__c> shipmentsBuyerGroup = [SELECT fan_Categoria__c, fan_Categoria__r.Name, fan_Flete__r.Name, fan_Flete__c, fan_Flete__r.fan_DatoValidacion__c, 
                                                           fan_Flete__r.fan_CantidadValidar__c, fan_Flete__r.fan_TipoValor__c, fan_Flete__r.fan_SimboloValidacion__c, 
                                                           fan_Flete__r.fan_ValorFlete__c, fan_Flete__r.fan_Prioridad__c FROM fan_CategoriaFlete__c 
                                                           WHERE fan_Flete__r.fan_BuyerGroup__c IN :buyerGroupIds AND fan_Categoria__c IN :cartItemsByCategory.keySet()];

        // Save the shipping logic id with one of his category results (only to get shipping logic info)
        Map<String, fan_CategoriaFlete__c> shipmentCategoriesData = new Map<String, fan_CategoriaFlete__c>();
        // Save total items of shipping logic of the categories
        Map<String, Decimal> shipmentCategoryItems = new Map<String, Decimal>();
        // Save total cost of shipping logic of the categories
        Map<String, Decimal> shipmentCategoryTotal = new Map<String, Decimal>();
        System.debug(LoggingLevel.DEBUG, 'getShippingOptionsAndRates .. Shipping Options >>> ' + shipmentsBuyerGroup);
        for (fan_CategoriaFlete__c shipOption : shipmentsBuyerGroup) {
            String currentCatId = shipOption.fan_Categoria__c;
            String currentShippingId = shipOption.fan_Flete__c;
            if (shipmentCategoriesData.containsKey(currentShippingId)){ 
                shipmentCategoryItems.put(currentShippingId, shipmentCategoryItems.get(currentShippingId) + cartItemsByCategory.get(currentCatId).totalQuantity);
                shipmentCategoryTotal.put(currentShippingId, shipmentCategoryTotal.get(currentShippingId) + cartItemsByCategory.get(currentCatId).totalAmount);
            } else { 
                shipmentCategoryItems.put(currentShippingId, cartItemsByCategory.get(currentCatId).totalQuantity);
                shipmentCategoryTotal.put(currentShippingId, cartItemsByCategory.get(currentCatId).totalAmount);
            }
            shipmentCategoriesData.put(currentShippingId, shipOption);
            // If the map already has the category, validate which shipping option for that category has the higher priority
            // The map will have only 1 shipping logic per category. We can NOT have a category twice
        }
        System.debug(LoggingLevel.DEBUG, 'getShippingOptionsAndRates .. Shipping options by Category >>> ' + shipmentCategoriesData);
        // Validate which shipping logic will apply.. If no one apply, the map is empty
        for(String shippingId : shipmentCategoryItems.keySet()){
            fan_CategoriaFlete__c shipOption = shipmentCategoriesData.get(shippingId);
            String validationData = shipOption.fan_Flete__r.fan_DatoValidacion__c;
            Decimal validationQty = shipOption.fan_Flete__r.fan_CantidadValidar__c;
            Decimal items = shipmentCategoryItems.get(shippingId);
            Decimal amount = shipmentCategoryTotal.get(shippingId);
            Boolean applyShipCost = false;
            switch on shipOption.fan_Flete__r.fan_SimboloValidacion__c {
                // Check if we validate subtotal or qty of items (ValidationType 1 = Subtotal, 2 = qty items) 
                // Use the validationSymbol (<=, <, >=, >) and the qtyToValidate to check if pay shipping
                when '<=' {
                    applyShipCost = (validationData == '1' ? (amount <= validationQty) : (items <= validationQty));
                }
                when '<' {
                    applyShipCost = (validationData == '1' ? (amount < validationQty) : (items < validationQty));
                }
                when '>=' {
                    applyShipCost = (validationData == '1' ? (amount >= validationQty) : (items >= validationQty));
                }
                when '>' {
                    applyShipCost = (validationData == '1' ? (amount > validationQty) : (items > validationQty));
                }
            }
            // If this shipping logic can NOT be applied, then remove it from saved data 
            if (!applyShipCost) {
                shipmentCategoriesData.remove(shippingId);
            }
        }
        System.debug(LoggingLevel.DEBUG, 'getShippingOptionsAndRates .. Shipping options After Validations >>> ' + shipmentCategoriesData);

        // Store category Id and the object with all shipping data including the shipping Id
        Map<String, ShippingOptionsAndRates> shippingOptionsData = new Map<String, ShippingOptionsAndRates>();
        for (fan_CategoriaFlete__c shipOption : shipmentsBuyerGroup) {
            // If shipmentCategoriesData doesnt have the current flete Id, then skip this record..
            if(!shipmentCategoriesData.keySet().contains(shipOption.fan_Flete__c)) { continue; }
            String categoryId = shipOption.fan_Categoria__c;
            Decimal totalAmount = shipmentCategoryTotal.get(shipOption.fan_Flete__c);
            // Validate if there is a repeated category, and take the one with higher priority
            if (shippingOptionsData.containsKey(categoryId) && (shippingOptionsData.get(categoryId).logicPriority > shipOption.fan_Flete__r.fan_Prioridad__c)){
                // If the category already registered has lower priority, then delete it to put the higher shipping logic
                shippingOptionsData.remove(categoryId);
            } 
            // If the map doesnt have a item with current category, add it.
            if (!shippingOptionsData.containsKey(categoryId)) {
                shippingOptionsData.put(categoryId, new ShippingOptionsAndRates(shipOption.fan_Flete__c, shipOption.fan_Flete__r.Name, 
                                    shipOption.fan_Flete__r.fan_DatoValidacion__c, shipOption.fan_Flete__r.fan_SimboloValidacion__c, shipOption.fan_Flete__r.fan_CantidadValidar__c, 
                                    shipOption.fan_Flete__r.fan_TipoValor__c, shipOption.fan_Flete__r.fan_ValorFlete__c, shipOption.fan_Flete__r.fan_Prioridad__c, totalAmount));
            }
        }
        return shippingOptionsData;
    }

    Map<String,ShippingOptionsAndRates> validateShippingOptionsExceptions(fan_CuentaFlete__c[] exceptionsAccount, fan_CiudadFlete__c[] exceptionsCity, Map<String,ShippingOptionsAndRates> shippingOptions){

        System.debug(LoggingLevel.DEBUG, 'validateShippingOptionsExceptions .. Exceptions Account >>> ' + exceptionsAccount);
        System.debug(LoggingLevel.DEBUG, 'validateShippingOptionsExceptions .. Exceptions City >>> ' + exceptionsCity);

        Set<String> shippingLogicIds = new Set<String>();
        Map<String,Decimal> exceptionShipIds = new Map<String,Decimal>();
        for(ShippingOptionsAndRates shipOption : shippingOptions.values()){
            shippingLogicIds.add(shipOption.shippingLogicId);
        }

        for(fan_CuentaFlete__c exceptionAccount : exceptionsAccount){
            exceptionShipIds.put(exceptionAccount.fan_Flete__c, exceptionAccount.fan_ValorFlete__c); 
        }
        for(fan_CiudadFlete__c exceptionCity : exceptionsCity){
            exceptionShipIds.put(exceptionCity.fan_Flete__c, exceptionCity.fan_ValorFlete__c); 
        }
        for(ShippingOptionsAndRates shippingOpt : shippingOptions.values()){
            // If the current shipping ID is on exceptionShipIds list, then set freeShipping to true
            if (exceptionShipIds.containsKey(shippingOpt.ShippingLogicId)){
                shippingOpt.shipValue = exceptionShipIds.get(shippingOpt.ShippingLogicId);
                if (exceptionShipIds.get(shippingOpt.ShippingLogicId) == 0.0) { shippingOpt.freeShipping = true; }
            }
        }
       
        System.debug(LoggingLevel.DEBUG, 'validateShippingOptionsExceptions .. shippingOptions to return >>> ' + shippingOptions);
        return shippingOptions;
    }

    Map<String,ShippingOptionsAndRates> updateCostsByCartItemsCategory(Map<String,CategoryCartItemsItemsData> cartItemsByCategory, Map<String,ShippingOptionsAndRates> shippingOptions) {
        // For each shipping option, get the cart item data and add to shipping results
        for(String categoryId : shippingOptions.keySet()) {
            CategoryCartItemsItemsData cartItemsData = cartItemsByCategory.get(categoryId);
            if (cartItemsData != null) {
                ShippingOptionsAndRates currentShippingOpt = shippingOptions.get(categoryId);
                currentShippingOpt.addItems(cartItemsData.totalQuantity);
                currentShippingOpt.addTotal(cartItemsData.totalAmount);
            }
        }
        System.debug(LoggingLevel.DEBUG, 'updateCostsByCartItemsCategory .. shippingOptions >>> ' + shippingOptions);
        return shippingOptions;
    }

    Map<String,ShippingOptionsAndRates> cleanDataAndValidateCost(Map<String,ShippingOptionsAndRates> shippingOptionsAndRates) {
        Map<String,ShippingOptionsAndRates> cleanShippingOptions = new Map<String,ShippingOptionsAndRates>();
        for(ShippingOptionsAndRates shipOpt : shippingOptionsAndRates.values()){
            if( shipOpt.items == 0) { continue; }
            if (cleanShippingOptions.containsKey(shipOpt.shippingLogicId) == false){
                cleanShippingOptions.put(shipOpt.shippingLogicId, new ShippingOptionsAndRates(shipOpt.shippingLogicId, shipOpt.shippingLogicName, shipOpt.validationDataType, shipOpt.validationSymbol, 
                                                            shipOpt.qtyToValidate, shipOpt.valueType, shipOpt.shipValue, shipOpt.logicPriority, shipOpt.totalAvailable));
            } 
            cleanShippingOptions.get(shipOpt.shippingLogicId).addItems(shipOpt.items);
            cleanShippingOptions.get(shipOpt.shippingLogicId).addTotal(shipOpt.itemsCost);
            if (shipOpt.freeShipping) cleanShippingOptions.get(shipOpt.shippingLogicId).freeShipping = true;
        }
        System.debug(LoggingLevel.DEBUG, 'cleanDataAndValidateCost .. Clean shipping options data >>> '+cleanShippingOptions);
        return cleanShippingOptions;
    }

    ShippingOptionsAndRates getShippingOptionsSummatory(List<ShippingOptionsAndRates> cleanShippingOptions){
        ShippingOptionsAndRates finalShippingCost = new ShippingOptionsAndRates();
        // Iterate all final shipping options to get the final cost of shipping
        for (ShippingOptionsAndRates shippingOption: cleanShippingOptions) {
            if (finalShippingCost.shippingLogicId == '') {
                finalShippingCost.shippingLogicId = shippingOption.shippingLogicId;
                finalShippingCost.shippingLogicName = shippingOption.shippingLogicName;
            } else {
                finalShippingCost.shippingLogicId = finalShippingCost.shippingLogicId + ',' + shippingOption.shippingLogicId;
                finalShippingCost.shippingLogicName = finalShippingCost.shippingLogicName + ',' + shippingOption.shippingLogicName;
            }
            // If the shipping option is free, dont addit to total cost
            if(!shippingOption.freeShipping){
                // Use valueType (1 = fixed, 2 = percentage, 3 = cost by item) to determinate if shipping has a fixed value or if is a percent 
                // shipValue will have either a percentage or a fixed cost
                Decimal finalCost = 0;
                switch on shippingOption.valueType {
                    when '1' {
                        finalCost = shippingOption.shipValue;
                    }
                    when '2' {
                        // For Percentage, take the availability products total
                        finalCost = shippingOption.totalAvailable * shippingOption.shipValue;
                    } 
                    when '3' {
                        // Cost by cart items
                        finalCost = shippingOption.items * shippingOption.shipValue;
                    }
                }
                finalShippingCost.addToFinalCost(finalCost);
            }
        }
        return finalShippingCost;
    }

    // Class to store the shipping options retrieved from external service.
    class ShippingOptionsAndRates {
        String shippingLogicId; // Shipping logic Id
        String shippingLogicName; // Shipping logic Name
        Decimal logicPriority;
        Boolean freeShipping; // Validate if this shipping option will be free
        Decimal items; // Total items of this shipping option
        Decimal itemsCost; // Total of cart items
        Decimal shipFinalCost;
        Decimal totalAvailable; // Total of items that has availability for the order 
        String cartDeliveryGroupId; // To use in Motos Logic
        // Data of the shipping option
        String validationDataType; // Can be a qty of items or a line item total
        String validationSymbol; // Can be >, =>, <, <=
        Decimal qtyToValidate; // Quantity can be a number of items or a total amout (depends on dataToValidate) 
        String valueType; // Store if value of shipping is a percent o a fixed price
        Decimal shipValue; // Value can be a percent or a fixed price (depends on value type)

        public ShippingOptionsAndRates(){
            shippingLogicId = '';
            shippingLogicName = '';
            shipFinalCost = 0;
        }

        public ShippingOptionsAndRates(String shippingLogic, String name, String valDataType, String valSymbol, Decimal qtyValidate, 
                                       String valueT, Decimal shipVal, Decimal prior, Decimal available) {
            shippingLogicId = shippingLogic;
            shippingLogicName = name;
            logicPriority = prior;
            freeShipping = false;
            items = 0;
            itemsCost = 0;
            shipFinalCost = 0;
            validationDataType = valDataType;
            validationSymbol = valSymbol;
            qtyToValidate = qtyValidate;
            valueType = valueT;
            shipValue = shipVal;
            totalAvailable = available;
        }

        public void addItems(Decimal qty){
            items = items + qty;
        }

        public void addTotal(Decimal total){
            itemsCost = itemsCost + total;
        }

        public void addToFinalCost(Decimal total){
            shipFinalCost = shipFinalCost + total;
        }
    }

    // Class to store totals by category
    class CategoryCartItemsItemsData {
        Decimal totalQuantity = 0;
        Decimal totalAmount = 0;

        CategoryCartItemsItemsData(Decimal qty, Decimal total) {
            totalQuantity = qty;
            totalAmount = total;
        }

        void addQuantity(Decimal qty){
            totalQuantity += qty;
        }

        void addTotal(Decimal total){
            totalAmount += total;
        }
    }
}