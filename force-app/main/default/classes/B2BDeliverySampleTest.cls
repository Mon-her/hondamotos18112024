@IsTest
class B2BDeliverySampleTest {

    @TestSetup
    static void setup() {
        Account account = fan_B2BTestDataFactory.createAccount('1537786428', 'NIT');
        
        String shippingChargeProductCode = fan_InfoFletes__mdt.getInstance('producto').Label;
        fan_B2BTestDataFactory.createProduct(shippingChargeProductCode, shippingChargeProductCode, null);

        fan_B2BTestDataFactory.createBuyerAccount(account.Id);

        setupMotosStore(account.Id);
        setupPosventaStore(account.Id);
    }

    @IsTest
    static void startCartProcessAsyncForMotos() {

        WebCart webCart = [SELECT Id FROM WebCart WHERE WebStore.Name = 'Motos'];

        sfdc_checkout.IntegrationStatus integrationResult = new B2BDeliverySample().startCartProcessAsync(null, webCart.Id);

        Assert.areEqual(sfdc_checkout.IntegrationStatus.Status.SUCCESS, integrationResult.status, 'The status of the integrationResult is not as expected.');
    }

    @IsTest
    static void startCartProcessAsyncForPosventa() {

        WebCart webCart = [SELECT Id FROM WebCart WHERE WebStore.Name = 'Posventa'];

        sfdc_checkout.IntegrationStatus integrationResult = new B2BDeliverySample().startCartProcessAsync(null, webCart.Id);

        Assert.areEqual(sfdc_checkout.IntegrationStatus.Status.SUCCESS, integrationResult.status, 'The status of the integrationResult is not as expected.');
    }

    @IsTest 
    static void startCartProcessAsyncShouldFail() {

        // To generate a fail.
        String shippingChargeProductCode = fan_InfoFletes__mdt.getInstance('producto').Label;
        DELETE [SELECT Id FROM Product2 WHERE ProductCode = :shippingChargeProductCode];
        WebCart webCart = [SELECT Id FROM WebCart LIMIT 1];

        new B2BDeliverySample().startCartProcessAsync(new sfdc_checkout.IntegrationInfo(), webCart.Id);
        
        CartValidationOutput[] cartValidationOutputs = [SELECT Id FROM CartValidationOutput];
        Assert.isFalse(cartValidationOutputs.isEmpty(), 'There is no cartValidationOutputs.');
    }

    static void setupMotosStore(String accountId) {

        fan_IdTienda__mdt idTiendaMdt = fan_IdTienda__mdt.getInstance('motos');

        WebStore webStore = new WebStore(
            Id = idTiendaMdt.fan_IdTienda__c,
            Name = idTiendaMdt.Label
        );
        UPDATE webStore;

        BuyerGroup buyerGroup = fan_B2BTestDataFactory.createBuyerGroup(idTiendaMdt.Label + ' BuyerGroup');
        fan_B2BTestDataFactory.createBuyerGroupMember(accountId, buyerGroup.Id);
        fan_B2BTestDataFactory.createWebStoreBuyerGroup(buyerGroup.Id, webStore.Id);

        fan_LogicaFletes__c freightLogic = new fan_LogicaFletes__c(
            fan_Prioridad__c = 1,
            fan_BuyerGroup__c = buyerGroup.Id,
            fan_DatoValidacion__c = '2', // Quantity
            fan_CantidadValidar__c = 5,
            fan_SimboloValidacion__c = '>',
            fan_ValorFlete__c = 12
        );
        INSERT freightLogic;

        Product2 variantParent = fan_B2BTestDataFactory.createProduct('VariantParent-SKU', 'VariantParent-ProductCode', 'Base');
        Product2 variantChild = fan_B2BTestDataFactory.createProduct('VariantChild-SKU-1', 'VariantChild-ProductCode1', null);
        INSERT new fan_ProductoFlete__c(
            fan_FleteProducto__c = freightLogic.Id,
            fan_Producto__c = variantParent.Id
        );
        WebCart cart = fan_B2BTestDataFactory.createWebCart(webStore.Id, accountId, null);
        CartDeliveryGroup cartDeliveryGroup = fan_B2BTestDataFactory.createCartDeliveryGroup('Default Delivery 1', cart.Id);

		INSERT new ProductAttributeSetProduct(
			ProductAttributeSetId = [SELECT Id FROM ProductAttributeSet WHERE DeveloperName = 'Motos_Color'].Id,
			ProductId = variantParent.Id
		);
		fan_B2BTestDataFactory.createProductAttribute(variantParent.Id, variantChild.Id, ProductAttribute.fan_Color__c, 'ROJO');

        CartItem cartItem = fan_B2BTestDataFactory.buildCartItem(variantChild, 'Product', 6, 20, cart.Id,  cartDeliveryGroup.Id);
        cartItem.fan_quantityAvailable__c = 6;
        INSERT cartItem;
    }

    static void setupPosventaStore(String accountId) {

        fan_IdTienda__mdt idTiendaMdt = fan_IdTienda__mdt.getInstance('posventa');

        WebStore webStore = new WebStore(
            Id = idTiendaMdt.fan_IdTienda__c,
            Name = idTiendaMdt.Label
        );
        UPDATE webStore;

        BuyerGroup buyerGroup = fan_B2BTestDataFactory.createBuyerGroup(idTiendaMdt.Label + ' BuyerGroup');
        fan_B2BTestDataFactory.createBuyerGroupMember(accountId, buyerGroup.Id);
        fan_B2BTestDataFactory.createWebStoreBuyerGroup(buyerGroup.Id, webStore.Id);

        Product2 product = fan_B2BTestDataFactory.createProduct('SKU-1', 'P1', null);
        ProductCatalog productCatalog = fan_B2BTestDataFactory.createProductCatalog('Verano');
        ProductCategory productCategory = fan_B2BTestDataFactory.createProductCategory('Bujias', productCatalog.Id, 'verano');
        fan_B2BTestDataFactory.createProductCategoryProduct(productCategory.Id, product.Id);

        fan_LogicaFletes__c freightLogic = new fan_LogicaFletes__c(
            fan_Prioridad__c = 1,
            fan_BuyerGroup__c = buyerGroup.Id,
            fan_DatoValidacion__c = '2', // Quantity
            fan_CantidadValidar__c = 5,
            fan_SimboloValidacion__c = '>',
            fan_TipoValor__c = '3', // Cost per producto
            fan_ValorFlete__c = 3.7
        );
        INSERT freightLogic;

        INSERT new fan_CategoriaFlete__c(
            fan_Flete__c = freightLogic.Id,
            fan_Categoria__c = productCategory.Id
        );
        WebCart cart = fan_B2BTestDataFactory.createWebCart(webStore.Id, accountId, null);
        CartDeliveryGroup cartDeliveryGroup = fan_B2BTestDataFactory.createCartDeliveryGroup('Default Delivery 1', cart.Id);

        CartItem cartItem = fan_B2BTestDataFactory.buildCartItem(product, 'Product', 6, 20, cart.Id,  cartDeliveryGroup.Id);
        cartItem.fan_quantityAvailable__c = 6;
        INSERT cartItem;
    }
}