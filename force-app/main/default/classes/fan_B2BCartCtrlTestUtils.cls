@IsTest
public with sharing class fan_B2BCartCtrlTestUtils {

    public static WebStore upsertWebStore(String webStoreId) {
        WebStore webStoreTest = new WebStore(
            Id = webStoreId,
            Name = 'WebStore test'
        );
        UPSERT webStoreTest;

        return webStoreTest;
    }

    public static Account createAccount() {

        AM_Municipio__c municipioTest = new AM_Municipio__c();
        municipioTest.Name = 'Nombre Municipio';
        municipioTest.AM_Nombre_departamento__c = 'Nombre Departamento';
        municipioTest.AM_Codigo_DANE_municipio__c = 'Municipio';
        municipioTest.AM_Codigo_DANE_departamento__c = 'Departa';
        municipioTest.AM_Codigo_SIPRES_departamento__c = 'Departamento SIPRES';
        municipioTest.AM_Codigo_SIPRES_municipio__c = 'Municipio SIPRES';
        insert municipioTest;

        Account accountTest = new Account(
            Name = 'Account Test',
            Phone = '38974521698',
            AM_Tipo_de_documento__c = 'NIT',
            AM_Numero_de_documento__c = '1',
            AM_Ciudad__c = municipioTest.Id,
            AM_Estado__c = 'Activo'
        );
        insert accountTest;

        return accountTest;
    }

    public static WebCart createWebCart(String accountId, String webstoreId) {
        WebCart cartTest = new WebCart(
            Name = 'Test Cart',
            AccountId = accountId,
            WebStoreId = webstoreId,
            Status = 'Active',
            fan_FormaPago__c = 'credito'
        );
        insert cartTest;
        return cartTest;
    }

    public static String createCartDeliveryGroup(String cartId, String CPACode) {
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(
            Name = 'Test CartGroup',
            CartId = cartId,
            fan_CPACode__c = CPACode
        );
        INSERT cartDeliveryGroup;

        return cartDeliveryGroup.Id;
    }

    public static Product2 createProduct(String stockKeepingUnit, String productCode) {
        Product2 productTest = new Product2(
            Name = 'Product test',
            StockKeepingUnit = stockKeepingUnit,
            ProductCode = productCode
        );
        insert productTest;

        return productTest;
    }

    public static void createContactPointAddress(string accountId, String addressType, String code, Boolean isDefault) {
        ContactPointAddress contactPointAddress = new ContactPointAddress(
            Name = addressType + code,
            ParentId = accountId,
            AddressType = addressType,
            fan_Code__c = code,
            IsDefault = isDefault
        );
        INSERT contactPointAddress;
    }

    public static PricebookEntry createStandardPricebookEntry(String productId) {

        String pricebookId = Test.getStandardPricebookId();

        PricebookEntry testPricebookEntry = new PricebookEntry(
            IsActive = true,
            Product2Id = productId,
            Pricebook2Id = pricebookId,
            UnitPrice = 0
        );

        INSERT testPricebookEntry;
        return testPricebookEntry;
    }

    public static Pricebook2 createPricebook(String pricebookName) {

        Pricebook2 testPricebook = new Pricebook2(
            Name = pricebookName,
            IsActive = true
        );

        INSERT testPricebook;
        return testPricebook;
    }

    public static PricebookEntry createPricebookEntry(String productId, String pricebookId, Decimal unitPrice) {

        PricebookEntry testPricebookEntry = new PricebookEntry(
            IsActive = true,
            Product2Id = productId,
            Pricebook2Id = pricebookId,
            UnitPrice = unitPrice
        );

        INSERT testPricebookEntry;
        return testPricebookEntry;
    }

    public static void setCartItemPrices(String cartId, Set<String> productsId, String normalPricebookId, String dealerPricebookId) {

        Set<String> pricebookIds = new Set<String> { normalPricebookId, dealerPricebookId };
        List<CartItem> cartItems = [SELECT Product2Id, Quantity FROM CartItem WHERE CartId =: cartId AND Product2Id IN: productsId];

        Map<String, CartItem> cartItemsMap = (Map<String, CartItem>) fan_B2BUtils.mapSObject('Product2Id', cartItems, Map<String, CartItem>.class);

        for (PricebookEntry pricebookEntry : [SELECT Product2Id, Pricebook2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2Id IN: pricebookIds]) {

            CartItem cartItem = cartItemsMap.get(pricebookEntry.Product2Id);
            Decimal unitPrice = pricebookEntry.UnitPrice;
            if(pricebookEntry.Pricebook2Id == normalPricebookId) {
                cartItem.ListPrice = unitPrice;
                cartItem.TotalListPrice = cartItem.ListPrice * cartItem.Quantity;
            } else {
                cartItem.SalesPrice = unitPrice;
                cartItem.TotalLineAmount = cartItem.SalesPrice * cartItem.Quantity;
            }
        }

        for (CartItem cartItem : cartItemsMap.values()) {
            cartItem.UnitAdjustedPrice = cartItem.SalesPrice;
            cartItem.TotalPrice = cartItem.TotalLineAmount;

            cartItem.AdjustmentAmount = (cartItem.SalesPrice - cartItem.ListPrice) * cartItem.Quantity;
            cartItem.TotalAdjustmentAmount = cartItem.AdjustmentAmount;
        }
        UPDATE cartItemsMap.values();
    }

    @TestVisible
    static ConnectApi.PricingResult buildPricingResult(String productId, Decimal unitPrice, Decimal listPrice) {

        ConnectApi.PricingResultLineItem pricingResultLineItem = new ConnectApi.PricingResultLineItem();
        pricingResultLineItem.productId = productId;
        pricingResultLineItem.unitPrice = String.valueOf(unitPrice);
        pricingResultLineItem.listPrice = String.valueOf(listPrice);

        ConnectApi.PricingResult pricingResult = new ConnectApi.PricingResult();
        pricingResult.pricingLineItemResults = new ConnectApi.PricingResultLineItem[] { pricingResultLineItem };
        return pricingResult;
    }
}