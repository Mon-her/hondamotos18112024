// This must implement the sfdc_checkout.CartTaxCalculations interface
// in order to be processed by the checkout flow and used for your Taxes integration.
global with sharing class B2BTaxSample implements sfdc_checkout.CartTaxCalculations {

    @TestVisible
    Boolean throwException = false;

    global sfdc_checkout.IntegrationStatus startCartProcessAsync(sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
        sfdc_checkout.IntegrationStatus integStatus = new sfdc_checkout.IntegrationStatus();
        try {
            Map<String, fan_Impuesto__mdt> taxesTypes = fan_Impuesto__mdt.getAll();
            Account account = (Account) [SELECT
                                            TYPEOF Account
                                            WHEN Account THEN fan_aplicaIVA__c, fan_aplicaIVAC__c
                                            END
                                        FROM WebCart WHERE Id = :cartId].Account;
            System.debug(LoggingLevel.DEBUG, 'B2BTaxSample .. accountTaxData >>> '+ account);  
            // If there are taxes from a previously cancelled checkout, delete them.
            DELETE [SELECT Id FROM CartTax WHERE CartId = :cartId WITH SECURITY_ENFORCED];

            // The total tax is automatically rolled up to TotalLineTaxAmount in the corresponding CartItem line.
            CartTax[] cartTaxes = new List<CartTax>();
            Date taxCalculationDate = Date.today();
            for (CartItem cartItem : [SELECT Sku, TotalPrice, Type, Product2.fan_aplicaIVA__c, Product2.fan_aplicaIVAC__c, fan_totalItemOrdered__c FROM CartItem WHERE CartId = :cartId WITH SECURITY_ENFORCED]) {
                Decimal ivaValue = 0, taxAmount;
                Decimal totalPrice = cartItem.fan_totalItemOrdered__c;
                // If the product is the shipping cost, assign tax type Flete
                if (cartItem.Type == fan_Constants.CartItemType.PRODUCT.name()) {
                    if(account.fan_aplicaIVA__c && cartItem.Product2.fan_aplicaIVA__c) {
                        ivaValue = taxesTypes.get('Impuesto_IVA').fan_Valor__c;
                    }
                    if(account.fan_aplicaIVAC__c && cartItem.Product2.fan_aplicaIVAC__c) {
                        ivaValue += taxesTypes.get('Impuesto_IVAC').fan_Valor__c;
                    }
                } else {
                    ivaValue = taxesTypes.get('Impuesto_flete').fan_Valor__c; 
                    totalPrice = cartItem.TotalPrice;
                }
                ivaValue /= 100;
                taxAmount = totalPrice * ivaValue;

                // The following fields from CartTax can be filled in:
                // Amount (required): Calculated tax amount.
                // CartItemId (required): ID of the cart item.
                // Description (optional): Description of CartTax.
                // Name (required): Name of the tax.
                // TaxCalculationDate (required): Calculation date for this tax line.
                // TaxRate (optional): The percentage value of the tax. Null if the tax is a flat amount.
                // TaxType (required): The type of tax, e.g. Actual or Estimated.
                if(taxAmount > 0) {
                    CartTax cartTax = new CartTax( 
                        Amount = taxAmount,
                        CartItemId = cartItem.Id,
                        Name = cartItem.Id + ':' + cartItem.Sku,
                        TaxCalculationDate = taxCalculationDate,
                        TaxRate = ivaValue,
                        TaxType = 'Actual'
                    );
                    cartTaxes.add(cartTax);
                    System.debug(LoggingLevel.DEBUG, 'B2BTaxSample .. tax to insert >>> '+cartTax);  
                }
            }
            INSERT cartTaxes;

            if(Test.isRunningTest() && throwException) jobInfo.jobId = jobInfo.jobId.split('')[0];
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
            // For the error to be propagated to the user, we need to add a new CartValidationOutput record.
            // The following fields must be populated:
            // BackgroundOperationId: Foreign Key to the BackgroundOperation
            // CartId: Foreign key to the WebCart that this validation line is for
            // Level (required): One of the following - Info, Error, or Warning
            // Message (optional): Message displayed to the user (maximum 255 characters)
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
                Type = 'Taxes'
            );
            insert(cartValidationError);
            return integrationStatus;
    }
}