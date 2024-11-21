public with sharing class fan_CartSummaryCalculator {

    @TestVisible
    static Decimal getProductTaxRate(Product2 product, Account account, Map<String, fan_Impuesto__mdt> taxesTypes) {
        Decimal tax = 0;
        if(account.fan_aplicaIVA__c && product.fan_aplicaIVA__c) {
            tax = taxesTypes.get('Impuesto_IVA').fan_Valor__c;
        }
        if(account.fan_aplicaIVAC__c && product.fan_aplicaIVAC__c) {
            tax += taxesTypes.get('Impuesto_IVAC').fan_Valor__c;
        }
        return tax / 100;
    }

    @TestVisible
    // The totals will be calculated based on the availability of the products.
    static CartSummary getCartSummaryForCashPaymentCondition(WebCart cart) {
        CartSummary cartSummary = new CartSummary();
        Map<String,fan_Impuesto__mdt> taxesTypes = fan_Impuesto__mdt.getAll();
        CartItem[] cartItems = [SELECT Sku, Quantity, Product2.fan_aplicaIVA__c, Product2.fan_aplicaIVAC__c, ListPrice, UnitAdjustedPrice, CartDeliveryGroup.DeliverToCity FROM CartItem WHERE CartId = :cart.Id AND Type = :fan_Constants.CartItemType.PRODUCT.name() WITH SECURITY_ENFORCED ORDER BY Product2Id];
        Map<String, Decimal> elegibleQuantity = new fan_InventoryHandler().getElegibleQuantity(cart.WebStore, cartItems);

	    for (CartItem cartItem : cartItems) {
            Decimal quantity = elegibleQuantity.get(cartItem.Id);
            Decimal subtotal = cartItem.UnitAdjustedPrice * quantity;
            Decimal grossValue = cartItem.ListPrice * quantity;
            Decimal taxRate = getProductTaxRate(cartItem.Product2, (Account) cart.Account, taxesTypes);
            Decimal taxAmount = subtotal * taxRate;

            cartSummary.grossValue += grossValue;
            cartSummary.discounts += grossValue - subtotal;
            cartSummary.subtotal += subtotal;
            cartSummary.IVA += taxAmount;
            cartSummary.totalToPay += subtotal + taxAmount;
	    }
	    return cartSummary;
    }

    @TestVisible
    // The totals will be calculated without taking into account the availability of the products.
    static CartSummary getCartSummaryForCreditPaymentCondition(WebCart cart) {
        Map<String,fan_Impuesto__mdt> taxesTypes = fan_Impuesto__mdt.getAll();
        CartItem[] cartItems = [SELECT Product2.fan_aplicaIVA__c, Product2.fan_aplicaIVAC__c, TotalPrice FROM CartItem WHERE CartId = :cart.Id AND Type = :fan_Constants.CartItemType.PRODUCT.name() WITH SECURITY_ENFORCED];
        CartSummary cartSummary = new CartSummary();
        cartSummary.grossValue = cart.TotalListAmount;
        cartSummary.subtotal = cart.TotalProductAmount;
        cartSummary.discounts = -cart.TotalAdjustmentAmount;

	    for (CartItem cartItem : cartItems) {
            Decimal taxRate = getProductTaxRate(cartItem.Product2, (Account) cart.Account, taxesTypes);
            cartSummary.IVA += cartItem.TotalPrice * taxRate;
	    }
        cartSummary.totalToPay = cartSummary.subtotal + cartSummary.IVA;
        cartSummary.valueToFinance = cartSummary.totalToPay;
        return cartSummary;
    }

    @TestVisible
    // The totals will be calculated based on the availability of the products.
    static CartSummary getCartSummaryForAnticipoPaymentCondition(WebCart cart) {
        CartSummary cartSummary = new CartSummary();
        Map<String,fan_Impuesto__mdt> taxesTypes = fan_Impuesto__mdt.getAll();
        CartItem[] cartItems = [SELECT Sku, Quantity, Product2.fan_aplicaIVA__c, Product2.fan_aplicaIVAC__c, ListPrice, UnitAdjustedPrice, CartDeliveryGroup.DeliverToCity, fan_IsBackorder__c  FROM CartItem WHERE CartId = :cart.Id AND Type = :fan_Constants.CartItemType.PRODUCT.name() WITH SECURITY_ENFORCED ORDER BY Product2Id];
        Map<String, Decimal> elegibleQuantity = new fan_InventoryHandler().getElegibleQuantity(cart.WebStore, cartItems);

	    for (CartItem cartItem : cartItems) {
            Decimal quantity = cartItem.fan_IsBackorder__c ? cartItem.quantity : elegibleQuantity.get(cartItem.Id);
            Decimal subtotal = cartItem.UnitAdjustedPrice * quantity;
            Decimal grossValue = cartItem.ListPrice * quantity;
            Decimal taxRate = getProductTaxRate(cartItem.Product2, (Account) cart.Account, taxesTypes);
            Decimal taxAmount = subtotal * taxRate;

            cartSummary.grossValue += grossValue;
            cartSummary.discounts += grossValue - subtotal;
            cartSummary.subtotal += subtotal;
            cartSummary.IVA += taxAmount;
            cartSummary.totalToPay += subtotal + taxAmount;
	    }
	    return cartSummary;
    }

    public static CartSummary getCartTotals(String cartId) {
        WebCart cart = [SELECT
                                TYPEOF Account
                                WHEN Account THEN fan_aplicaIVA__c, fan_aplicaIVAC__c
                                END,
                            TotalListAmount,
                            TotalProductAmount,
                            TotalAdjustmentAmount,
                            fan_FormaPago__c,
                            WebStore.fan_LocationGroupReference__c,
                            fan_EsAnticipo__c 
                            FROM WebCart WHERE Id = :cartId];

        CartSummary cartSummary = new CartSummary();
        cartSummary.paymentCondition = cart.fan_FormaPago__c;

        if(cart.fan_EsAnticipo__c){
            cartSummary = getCartSummaryForAnticipoPaymentCondition(cart);
        }
        else if(cart.fan_FormaPago__c == fan_Constants.FormaPago.CREDITO.name()) {
            cartSummary = getCartSummaryForCreditPaymentCondition(cart);
        } else if(cart.fan_FormaPago__c == fan_Constants.FormaPago.CONTADO.name()) {
            cartSummary = getCartSummaryForCashPaymentCondition(cart);
        }
        return cartSummary;
    }

	public class CartSummary {
		@AuraEnabled
		public Decimal grossValue = 0;
		@AuraEnabled
		public Decimal freight = 0;
		@AuraEnabled
		public Decimal subtotal = 0;
		@AuraEnabled
		public Decimal discounts = 0;
		@AuraEnabled
		public Decimal IVA = 0;
		@AuraEnabled
		public String paymentCondition;
		@AuraEnabled
		public Decimal valueToFinance = 0;
		@AuraEnabled
		public Decimal totalToPay = 0;
    }
}