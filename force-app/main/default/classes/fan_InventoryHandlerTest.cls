@IsTest
class fan_InventoryHandlerTest {

    @TestSetup
    static void makeData(){
        Account account = fan_B2BTestDataFactory.createAccount('123456789', 'NIT');

        Product2[] products = new Product2[] {
            fan_B2BTestDataFactory.buildProduct('SKU-1', 'ProductCode-1', null),
            fan_B2BTestDataFactory.buildProduct('SKU-1.1', 'ProductCode-1.1', null)
        };
        INSERT products;

        fan_B2BTestDataFactory.createRelatedProduct(products[0].Id, products[1].Id, '3');

        setupMotosStore(account.Id, products[0]);
        setupPosventaStore(account.Id, products[0]);
    }

    @IsTest
    static void getElegibleQuantityForMotos() {
        WebStore webStore = [SELECT fan_LocationGroupReference__c FROM WebStore WHERE Name = 'Motos'];
        CartItem[] cartItems = [SELECT Sku, Quantity, CartDeliveryGroup.DeliverToCity FROM CartItem WHERE Cart.WebStoreId = :webStore.Id];

        fan_B2BUtils.testWebStoreId = webStore.Id;
        fan_InventoryHandler.testOutputRepresentation = fan_B2BTestDataFactory.generateOCIGetInventoryAvailability(webStore.fan_LocationGroupReference__c, '002536', new String[] { 'SKU-1' });
        Map<String, Decimal> elegibleQuantity = new fan_InventoryHandler().getElegibleQuantity(webStore, cartItems);

        Assert.areEqual(100, elegibleQuantity.get(cartItems[0].Id), 'The elegible quantity is not as expected.');
    }

    @IsTest
    static void getElegibleQuantityForPosventa() {
        WebStore webStore = [SELECT fan_LocationGroupReference__c FROM WebStore WHERE Name = 'Posventa'];
        CartItem[] cartItems = [SELECT Sku, Quantity, CartDeliveryGroup.DeliverToCity FROM CartItem WHERE Cart.WebStoreId = :webStore.Id];

        fan_B2BUtils.testWebStoreId = webStore.Id;
        fan_InventoryHandler.testOutputRepresentation = fan_B2BTestDataFactory.generateOCIGetInventoryAvailability(webStore.fan_LocationGroupReference__c, '002536', new String[] { 'SKU-1', 'SKU-1.1' });
        Map<String, Decimal> elegibleQuantity = new fan_InventoryHandler().getElegibleQuantity(webStore, cartItems);

        Assert.areEqual(200, elegibleQuantity.get(cartItems[0].Id), 'The elegible quantity is not as expected.');
    }

    static void setupMotosStore(String accountId, Product2 product) {
        Schema.Location location = fan_B2BTestDataFactory.createLocation('Location', '00535', true);
        fan_B2BTestDataFactory.createCityLocation(location.Id, 'City');

        WebStore webStore = new WebStore(
            Id = fan_IdTienda__mdt.getInstance('motos').fan_IdTienda__c,
            Name = 'Motos'
        );
        UPDATE webStore;
        WebCart webCart = fan_B2BTestDataFactory.createWebCart(webStore.Id, accountId, null);

        CartDeliveryGroup cartDeliveryGroup = fan_B2BTestDataFactory.createCartDeliveryGroup('CartDeliveryGroup', webCart.Id);
        fan_B2BTestDataFactory.createCartItem(product, 'Product', 267, 64, webCart.Id, cartDeliveryGroup.Id);
    }

    static void setupPosventaStore(String accountId, Product2 product) {
        LocationGroup locationGroup = fan_B2BTestDataFactory.createLocationGroup('Motos', 'B2B_Posventa');
        WebStore webStore = new WebStore(
            Id = fan_IdTienda__mdt.getInstance('posventa').fan_IdTienda__c,
            Name = 'Posventa',
            fan_LocationGroup__c = locationGroup.Id
        );
        UPDATE webStore;
        WebCart webCart = fan_B2BTestDataFactory.createWebCart(webStore.Id, accountId, null);

        CartDeliveryGroup cartDeliveryGroup = fan_B2BTestDataFactory.createCartDeliveryGroup('CartDeliveryGroup', webCart.Id);
        fan_B2BTestDataFactory.createCartItem(product, 'Product', 267, 64, webCart.Id, cartDeliveryGroup.Id);
    }
}