@IsTest
class fan_PosventaShippingCalculatorTest {
    @TestSetup
    static void makeData(){
        Account account = fan_B2BTestDataFactory.createAccount('1537786428', 'NIT');
        fan_B2BTestDataFactory.createBuyerAccount(account.Id);
        WebStore webStore = fan_B2BTestDataFactory.createWebStore('WebStore');

        BuyerGroup buyerGroup = fan_B2BTestDataFactory.createBuyerGroup('BuyerGroup');
        fan_B2BTestDataFactory.createBuyerGroupMember(account.Id, buyerGroup.Id);
        fan_B2BTestDataFactory.createWebStoreBuyerGroup(buyerGroup.Id, webStore.Id);

        Product2 product = fan_B2BTestDataFactory.createProduct('SKU-1', 'P1', null);
        ProductCatalog productCatalog = fan_B2BTestDataFactory.createProductCatalog('Verano');
        ProductCategory productCategory = fan_B2BTestDataFactory.createProductCategory('Bujias', productCatalog.Id, 'verano');
        fan_B2BTestDataFactory.createProductCategoryProduct(productCategory.Id, product.Id);

        fan_LogicaFletes__c freightLogic = new fan_LogicaFletes__c(
            fan_Prioridad__c = 1,
            fan_BuyerGroup__c = buyerGroup.Id,
            fan_DatoValidacion__c = '2', // Quantity
            fan_CantidadValidar__c = 1,
            fan_SimboloValidacion__c = '>=',
            fan_TipoValor__c = '3', // Cost per producto
            fan_ValorFlete__c = 3.7
        );
        INSERT freightLogic;

        INSERT new fan_CategoriaFlete__c(
            fan_Flete__c = freightLogic.Id,
            fan_Categoria__c = productCategory.Id
        );
    }

    @IsTest
    static void calculateShipping() {

        Account account = [SELECT Id FROM Account];
        WebStore webStore = [SELECT Id FROM WebStore];
        Product2 product2 = [SELECT Id FROM Product2];

        fan_ShippingCalculator.Product product = new fan_ShippingCalculator.Product();
        product.id = product2.Id;
        product.quantity = 1;
        product.totalAmount = 12;

        Map<String, Decimal> shippingCosts = new fan_PosventaShippingCalculator()
        .calculateShipping(account.Id, webStore.Id, new Set<String> { product2.Id }, new fan_ShippingCalculator.Product[] { product });

        Assert.areEqual(3.7, shippingCosts.values()[0], 'The shipping cost is not as expected.');
    }
}