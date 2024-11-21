@IsTest
class fan_MotosShippingCalculatorTest {

    @TestSetup
    static void makeData(){
        Account account = fan_B2BTestDataFactory.createAccount('1537786428', 'NIT');
        fan_B2BTestDataFactory.createBuyerAccount(account.Id);
        WebStore webStore = fan_B2BTestDataFactory.createWebStore('WebStore');

        BuyerGroup buyerGroup = fan_B2BTestDataFactory.createBuyerGroup('BuyerGroup');
        fan_B2BTestDataFactory.createBuyerGroupMember(account.Id, buyerGroup.Id);
        fan_B2BTestDataFactory.createWebStoreBuyerGroup(buyerGroup.Id, webStore.Id);

        fan_LogicaFletes__c freightLogic = new fan_LogicaFletes__c(
            fan_Prioridad__c = 1,
            fan_BuyerGroup__c = buyerGroup.Id,
            fan_ValorFlete__c = 12
        );
        INSERT freightLogic;

        Product2 variantParent = fan_B2BTestDataFactory.createProduct('VariantParent-SKU', 'VariantParent-ProductCode', 'Base');
        Product2 variantChild = fan_B2BTestDataFactory.createProduct('VariantChild-SKU-1', 'VariantChild-ProductCode1', null);
        INSERT new fan_ProductoFlete__c(
            fan_FleteProducto__c = freightLogic.Id,
            fan_Producto__c = variantParent.Id
        );

        INSERT new ProductAttributeSetProduct(
            ProductAttributeSetId = [SELECT Id FROM ProductAttributeSet WHERE DeveloperName = 'Motos_Color'].Id,
            ProductId = variantParent.Id
        );
        fan_B2BTestDataFactory.createProductAttribute(variantParent.Id, variantChild.Id, ProductAttribute.fan_Color__c, 'ROJO');
    }

    @IsTest
    static void calculateShipping() {

        Account account = [SELECT Id FROM Account];
        WebStore webStore = [SELECT Id FROM WebStore];
        Product2 product2 = [SELECT Id FROM Product2 WHERE StockKeepingUnit = 'VariantChild-SKU-1'];

        fan_ShippingCalculator.Product product = new fan_ShippingCalculator.Product();
        product.id = product2.Id;
        product.quantity = 1;

        Map<String, Decimal> shippingCosts = new fan_MotosShippingCalculator()
        .calculateShipping(account.Id, webStore.Id, new Set<String> { product2.Id }, new fan_ShippingCalculator.Product[] { product });

        Assert.areEqual(12, shippingCosts.values()[0], 'The shipping cost is not as expected.');
    }
}