// This must implement the sfdc_checkout.CartShippingCharges interface
// in order to be processed by the checkout flow for the "Shipping" integration
// THIS CLASS GETS THE SHIPPING COST, SET THIS TO A CART DELIVERY GROUP METHOD, AND CREATE A CART ITEM FOR THIS CHARGE
global with sharing class B2BDeliverySample implements sfdc_checkout.CartShippingCharges {
    global sfdc_checkout.IntegrationStatus startCartProcessAsync(sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
        sfdc_checkout.IntegrationStatus integStatus = new sfdc_checkout.IntegrationStatus();
        try {
            // We need to get the ID of the cart delivery group in order to create the order delivery groups.
            List<Id> cartDeliveryGroupIds = getCartDeliveryGroups(cartId);
            // Get account Id from webcart to validate if account has shipping exception
            WebCart cart = [SELECT TYPEOF Account WHEN Account THEN fan_condicionPago__c END, WebStoreId FROM WebCart WHERE Id = :cartId];

            // On re-entry of the checkout flow delete all previous CartDeliveryGroupMethods for the given cartDeliveryGroupId
            List<CartDeliveryGroupMethod> cartDeliveryMethods = [SELECT Id FROM CartDeliveryGroupMethod WHERE CartDeliveryGroupId in :cartDeliveryGroupIds AND isDeleted = false];
            if (cartDeliveryMethods.size() > 0) { DELETE cartDeliveryMethods; }

            // Get the order delivery method default or create a new one
            Id orderDeliveryMethodId = getOrderDeliveryMethod();  
            Set<String> productIds = new Set<String>();
            fan_ShippingCalculator.Product[] products = buildProducts(cartId, productIds);

            // Shipping Logic for Motos store
            // The metadata "fan_IdTienda" stores the id from both stores
            String idMotosStore = [SELECT fan_IdTienda__c FROM fan_IdTienda__mdt WHERE DeveloperName = 'motos' LIMIT 1].fan_IdTienda__c;
            if (cart.webStoreId == idMotosStore) {

                Map<String, Decimal> cartDeliveryGroupShippingCosts = new fan_MotosShippingCalculator().calculateShipping(cart.AccountId, cart.WebStoreId, productIds, products);

                // Create a CartDeliveryGroupMethod record every shipping charge
                populateAllCartDeliveryGroupsMethodWithShippingOptions(cartDeliveryGroupShippingCosts, orderDeliveryMethodId, cartId, cartDeliveryGroupIds);
                // Create a cart item for every cart delivery group for this shipping Charge
                generateCartItemsForEveryShippingCharge(cartDeliveryGroupShippingCosts, cart, orderDeliveryMethodId);
            } else {
                Map<String, Decimal> shippingCosts = new fan_PosventaShippingCalculator().calculateShipping(cart.AccountId, cart.WebStoreId, productIds, products);

                // If already exists a shipping charge, delete it
                DELETE [SELECT Id FROM CartItem WHERE CartId = :cartId AND Type = :fan_Constants.CartItemType.CHARGE.name()];

                createShippingCharges(cartId, cartDeliveryGroupIds[0], orderDeliveryMethodId, shippingCosts);
            }
            // If everything works well, the charge is added to the cart and our integration has been successfully completed.
            integStatus.status = sfdc_checkout.IntegrationStatus.Status.SUCCESS;

        // For testing purposes, this example treats exceptions as user errors, which means they are displayed to the buyer user.
        } catch (DmlException de) {
            // Catch any exceptions thrown when trying to insert the shipping charge to the CartItems
            Integer numErrors = de.getNumDml();
            String errorMessage = 'There were ' + numErrors + ' errors when trying to insert the charge in the CartItem: ';
            for(Integer errorIdx = 0; errorIdx < numErrors; errorIdx++) {
                errorMessage += 'Field Names = ' + de.getDmlFieldNames(errorIdx);
                errorMessage += 'Message = ' + de.getDmlMessage(errorIdx);
                errorMessage += ' , ';
            }

            return integrationStatusFailedWithCartValidationOutputError(
                integStatus,
                errorMessage,
                jobInfo,
                cartId
            );
        } catch(Exception e) {
            return integrationStatusFailedWithCartValidationOutputError(
                integStatus,
                'An exception of type ' + e.getTypeName() + ' has occurred: ' + e.getMessage(),
                jobInfo,
                cartId
            );
        }
        return integStatus;
    }

    private List<Id> getCartDeliveryGroups(String cartId){
        List<CartDeliveryGroup> cartDeliveryGroups = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cartId WITH SECURITY_ENFORCED];
        List<Id> cartDeliveryGroupIds = new List<Id>();
        for (CartDeliveryGroup CDG : cartDeliveryGroups) {
            cartDeliveryGroupIds.add(CDG.Id);
        }
        return cartDeliveryGroupIds;
    }

    // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service
    private void populateCartDeliveryGroupMethod(Decimal finalShippingOption, String cartDeliveryGroupId, Id deliveryMethodId, Id webCartId){

        String defaultCarrierName = fan_InfoFletes__mdt.getInstance('proveedor').Label;

        INSERT new CartDeliveryGroupMethod(
            CartDeliveryGroupId = cartDeliveryGroupId,
            DeliveryMethodId = deliveryMethodId,
            ExternalProvider = defaultCarrierName,
            Name = defaultCarrierName,
            ShippingFee = finalShippingOption,
            WebCartId = webCartId
        );
    }

    private Id getOrderDeliveryMethod() {
        // Use a Custom Metadata for store the name of the Delivery Object
        String defaultDeliveryMethodName = [SELECT Label FROM fan_InfoFletes__mdt WHERE DeveloperName = 'envio' LIMIT 1].Label;
        String defaultCarrierName = [SELECT Label FROM fan_InfoFletes__mdt WHERE DeveloperName = 'proveedor' LIMIT 1].Label;
        Id product2IdForThisDeliveryMethod = getDefaultShippingChargeProduct2Id();

        // Check to see if a default OrderDeliveryMethod already exists.
        // If it doesn't exist, create one.
        Id orderDeliveryMethodId;
        Integer i = 1;

        List<OrderDeliveryMethod> odms = [SELECT Id, ProductId, Carrier, ClassOfService FROM OrderDeliveryMethod 
                                          WHERE Name = :defaultDeliveryMethodName WITH SECURITY_ENFORCED];
        System.debug(LoggingLevel.DEBUG, 'getOrderDeliveryMethod .. Order Delivery Methods >>> '+odms);
        // This is the case in which an Order Delivery method does not exist.
        if (odms.isEmpty()) {
            OrderDeliveryMethod defaultOrderDeliveryMethod = new OrderDeliveryMethod(
                Name = defaultDeliveryMethodName,
                Carrier = defaultCarrierName,
                isActive = true,
                ProductId = product2IdForThisDeliveryMethod,
                ClassOfService = defaultCarrierName
            );
            INSERT(defaultOrderDeliveryMethod);
            orderDeliveryMethodId = defaultOrderDeliveryMethod.Id;
        } else {
            // This is the case in which an Order Delivery method exists.
            // If the OrderDeliveryMethod doesn't have a Product2 associated with it, assign one
            // We can always pick the 0th orderDeliveryMethod since we queried based off the name.
            OrderDeliveryMethod existingodm = odms[0];
            // This is for reference implementation purposes only.
            // This is the if statement that checks to make sure that there is a product carrier and class of service
            // associated to the order delivery method.
            if (existingodm.ProductId == null || existingodm.Carrier == null || existingodm.ClassOfService == null) {
                existingodm.ProductId = product2IdForThisDeliveryMethod;
                existingodm.Carrier = defaultCarrierName;
                existingodm.ClassOfService = defaultCarrierName;
                UPDATE(existingodm);
            }
            orderDeliveryMethodId = existingodm.Id;
        }
        return orderDeliveryMethodId;
    }

    private Id getDefaultShippingChargeProduct2Id() {
        // In this example we will name the product representing shipping charges 'Shipping Charge for this delivery method'.
        // Check to see if a Product2 with that name already exists. If it doesn't exist, create one.
        String shippingChargeProductCode = [SELECT Label FROM fan_InfoFletes__mdt WHERE DeveloperName = 'producto' LIMIT 1].Label;
        List<Product2> shippingChargeProducts = [SELECT Id FROM Product2 WHERE ProductCode = :shippingChargeProductCode WITH SECURITY_ENFORCED];

        return shippingChargeProducts[0].Id;
    }

    void createShippingCharges(String cartId, String cartDeliveryGroupId, String orderDeliveryMethodId, Map<String, Decimal> shippingCosts){

        Decimal totalShippingCost = 0;
        CartItem[] shippingCharges = new List<CartItem>();
        OrderDeliveryMethod orderDeliveryMethod = [SELECT ProductId, Product.Name FROM OrderDeliveryMethod WHERE Id = :orderDeliveryMethodId];

        for (String identifier : shippingCosts.keySet()) {
            // Format OrderSegmentationGroup:PaymentCondition
            String[] params = identifier.split(':');

            Decimal shippingCost = shippingCosts.get(identifier);
            totalShippingCost += shippingCost;

            shippingCharges.add(new CartItem(
                Name = orderDeliveryMethod.Product.Name,
                Product2Id = orderDeliveryMethod.ProductId,
                Quantity = 1,
                fan_OrderSegmentationGroup__c = params[0],
                fan_PaymentCondition__c = params[1],
                Type = fan_Constants.CartItemType.CHARGE.name(),
                ListPrice = shippingCost,
                TotalPrice = shippingCost,
                SalesPrice = shippingCost,
                TotalListPrice = shippingCost,
                TotalLineAmount = shippingCost,
                UnitAdjustedPrice = shippingCost,
                CartId = cartId,
                CartDeliveryGroupId = cartDeliveryGroupId
            ));
        }
        System.debug(LoggingLevel.DEBUG, 'generateCartItemForShippingCharge .. Cart shipping cost >>> ' + shippingCharges);

        // Create a CartDeliveryGroupMethod record for the final shipping option 
        populateCartDeliveryGroupMethod(totalShippingCost, cartDeliveryGroupId, orderDeliveryMethodId, cartId);
        INSERT shippingCharges;
    }

    // Motos: Fill cart delivery groups methods with the shipping logics 
    private void populateAllCartDeliveryGroupsMethodWithShippingOptions(Map<String, Decimal> cartDeliveryGroupShippingCosts,
                                                                        Id deliveryMethodId, Id webCartId, List<Id> cartDeliveryGroups){
        List<CartDeliveryGroupMethod> CDGMs = new List<CartDeliveryGroupMethod>();
        String defaultCarrierName = [SELECT Label FROM fan_InfoFletes__mdt WHERE DeveloperName = 'proveedor' LIMIT 1].Label;
        for (Id cdgId : cartDeliveryGroups) {
            Decimal shippingCost = cartDeliveryGroupShippingCosts.containsKey(cdgId) ? cartDeliveryGroupShippingCosts.get(cdgId) : 0;
            CartDeliveryGroupMethod cartDeliveryGroupMethod = new CartDeliveryGroupMethod(
                CartDeliveryGroupId = cdgId,
                DeliveryMethodId = deliveryMethodId,
                ExternalProvider = defaultCarrierName,
                Name = defaultCarrierName,
                ShippingFee = shippingCost,
                WebCartId = webCartId
            );
            CDGMs.add(cartDeliveryGroupMethod);
            System.debug(LoggingLevel.DEBUG, 'cartDeliveryGroupMethods to insert >>> '+CDGMs);
        }
        INSERT CDGMs;
    }

    // Motos: Add a cart item to cart delivery groups for every shipping option
    private void generateCartItemsForEveryShippingCharge(Map<String, Decimal> cartDeliveryGroupShippingCosts,
                                                        WebCart cart, String orderDelieveryMethodId){
        OrderDeliveryMethod deliveryData = [SELECT ProductId, Product.Name FROM OrderDeliveryMethod WHERE Id = :orderDelieveryMethodId];
        // If already exists a shipping charge, delete it
        List<CartItem> shippingCharges = [SELECT Id, Type FROM CartItem WHERE Type = 'Charge' AND CartId = :cart.Id ];
        if (shippingCharges.size() > 0){ DELETE shippingCharges; }
        // Store cart items charge to insert
        List<CartItem> cartItemsToInsert = new List<CartItem>();

        for (String cartDeliveryGroupId : cartDeliveryGroupShippingCosts.keySet()) {
            Decimal shippingCost = cartDeliveryGroupShippingCosts.get(cartDeliveryGroupId);
            CartItem newShippingCharge = new CartItem(
                Name = deliveryData.Product.Name,
                Product2Id = deliveryData.ProductId,
                Quantity = 1,
                Type = 'Charge',
                ListPrice = shippingCost,
                TotalPrice = shippingCost,
                SalesPrice = shippingCost,
                TotalListPrice = shippingCost,
                TotalLineAmount = shippingCost,
                UnitAdjustedPrice = shippingCost,
                CartId = cart.Id,
                CartDeliveryGroupId = cartDeliveryGroupId,
                fan_PaymentCondition__c = ((Account) cart.Account).fan_condicionPago__c
            );
            cartItemsToInsert.add(newShippingCharge);
            System.debug(LoggingLevel.DEBUG, 'Cart shipping cost to insert >>> ' + newShippingCharge);
        }
        INSERT cartItemsToInsert;
    }

    private sfdc_checkout.IntegrationStatus integrationStatusFailedWithCartValidationOutputError(
        sfdc_checkout.IntegrationStatus integrationStatus, String errorMessage, sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
            integrationStatus.status = sfdc_checkout.IntegrationStatus.Status.FAILED;
            CartValidationOutput cartValidationError = new CartValidationOutput(
                BackgroundOperationId = jobInfo.jobId,
                CartId = cartId,
                Level = 'Error',
                Message = errorMessage.left(255),
                Name = (String)cartId + ':' + jobInfo.jobId,
                RelatedEntityId = cartId,
                Type = 'Shipping'
            );
            insert(cartValidationError);
            return integrationStatus;
    }

    fan_ShippingCalculator.Product[] buildProducts(String cartId, Set<String> productIds) {

        fan_ShippingCalculator.Product[] products = new List<fan_ShippingCalculator.Product>();

        for (CartItem cartItem : [SELECT Product2.fan_OrderSegmentationGroup__c, fan_quantityAvailable__c,
                                    UnitAdjustedPrice, fan_PaymentCondition__c, CartDeliveryGroupId
                                    FROM CartItem WHERE CartId = :cartId AND Type = :fan_Constants.CartItemType.PRODUCT.name()]) {
            productIds.add(cartItem.Product2Id);
            products.add(new fan_ShippingCalculator.Product(cartItem));
        }
        return products;
    }
}