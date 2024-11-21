// This must implement the sfdc_checkout.CartInventoryValidation interface
// in order to be processed by the checkout flow and used for your Check Inventory integration.
global with sharing class B2BCheckInventorySample implements sfdc_checkout.CartInventoryValidation {
    global sfdc_checkout.IntegrationStatus startCartProcessAsync(sfdc_checkout.IntegrationInfo jobInfo, ID cartId) {
        sfdc_checkout.IntegrationStatus integStatus = new sfdc_checkout.IntegrationStatus();
        try {
            WebCart cart = [SELECT fan_FormaPago__c, WebStore.fan_LocationGroupReference__c,fan_EsAnticipo__c FROM WebCart WHERE Id = :cartId];

            Set<String> stockKeepingUnits = new Set<String>();
            CartItem[] cartItems = new List<CartItem>();
            for (CartItem cartItem : [SELECT Sku, Quantity, CartDeliveryGroup.DeliverToCity, fan_IsBackorder__c FROM CartItem WHERE CartId = :cartId AND Type = :fan_Constants.CartItemType.PRODUCT.name() WITH SECURITY_ENFORCED ORDER BY Product2Id]) {
                if (String.isBlank(cartItem.Sku)) {
                    String errorMessage = 'The SKUs for all products in your cart must be defined.';
                    return integrationStatusFailedWithCartValidationOutputError(
                        integStatus,
                        errorMessage,
                        jobInfo,
                        cartId
                    );
                }
                stockKeepingUnits.add(cartItem.Sku);
                cartItems.add(cartItem);
            }

            // Stop checkout if there are no items in the cart
            if (cartItems.isEmpty()) {
                String errorMessage = 'Looks like your cart is empty.';
                return integrationStatusFailedWithCartValidationOutputError(
                    integStatus,
                    errorMessage,
                    jobInfo,
                    cartId
                );
            }

            Map<String, Decimal> elegibleQuantity = new fan_InventoryHandler().getElegibleQuantity(cart.WebStore, cartItems);
            if(cart.fan_EsAnticipo__c){
                for(CartItem cartItem : cartItems) {

                    cartItem.fan_quantityAvailable__c = cartItem.fan_IsBackorder__c ? cartItem.Quantity : elegibleQuantity.get(cartItem.Id);

                    cartItem.fan_QuantityOrdered__c = cartItem.fan_quantityAvailable__c;
                }
            }
            else if(cart.fan_FormaPago__c == fan_Constants.FormaPago.CREDITO.name()) {
                for(CartItem cartItem : cartItems) {
                    cartItem.fan_quantityAvailable__c = cartItem.fan_IsBackorder__c ? cartItem.Quantity : elegibleQuantity.get(cartItem.Id);
                    cartItem.fan_QuantityOrdered__c = cartItem.Quantity;
                }
            } else if(cart.fan_FormaPago__c == fan_Constants.FormaPago.CONTADO.name()) {
                for(CartItem cartItem : cartItems) {
                    cartItem.fan_quantityAvailable__c = elegibleQuantity.get(cartItem.Id);
                    cartItem.fan_QuantityOrdered__c = cartItem.fan_quantityAvailable__c;
                }
            }
            System.debug(' CartItems to update >>> ' + cartItems);
            UPDATE cartItems;

            integStatus.status = sfdc_checkout.IntegrationStatus.Status.SUCCESS;

        } catch(Exception e) {
            // For testing purposes, this example treats exceptions as user errors, which means they are displayed to the buyer user.
            // In production you probably want this to be an admin-type error. In that case, throw the exception here
            // and make sure that a notification system is in place to let the admin know that the error occurred.
            // See the readme section about error handling for details about how to create that notification.
            return integrationStatusFailedWithCartValidationOutputError(
                integStatus,
                'An exception of type ' + e.getTypeName() + ' has occurred: ' + e.getMessage(),
                jobInfo,
                cartId
            );
        }
        return integStatus;
    }

    private sfdc_checkout.IntegrationStatus integrationStatusFailedWithCartValidationOutputError(
        sfdc_checkout.IntegrationStatus integrationStatus, String errorMessage, sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
            integrationStatus.status = sfdc_checkout.IntegrationStatus.Status.FAILED;
            // To propagate the error to the user, we need to add a new CartValidationOutput record.
            // The following fields must be populated:
            // BackgroundOperationId: Foreign Key to the BackgroundOperation
            // CartId: Foreign key to the WebCart that this validation line is for
            // Level (required): One of the following - Info, Error, or Warning
            // Message (optional): Message displyed to the user
            // Name (required): The name of this CartValidationOutput record. For example CartId:BackgroundOperationId
            // RelatedEntityId (required): Foreign key to WebCart, CartItem, CartDeliveryGroup
            // Type (required): One of the following - SystemError, Inventory, Taxes, Pricing, Shipping, Entitlement, Other
            CartValidationOutput cartValidationError = new CartValidationOutput(
                BackgroundOperationId = jobInfo.jobId,
                CartId = cartId,
                Level = 'Error',
                Message = errorMessage.left(255),
                Name = (String)cartId + ':' + jobInfo.jobId,
                RelatedEntityId = cartId,
                Type = 'Inventory'
            );
            insert(cartValidationError);
            return integrationStatus;
    }
}