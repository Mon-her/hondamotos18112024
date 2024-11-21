@IsTest
public class fan_B2BProductCtrlTest {

    @TestSetup
    static void makeData(){

        Product2 variantParent = new Product2(
            Name = 'Parent Product',
            StockKeepingUnit = 'PARENT-SKU',
            ProductCode = 'PARENT-ProductCode',
	        Type = 'Base'
        );
        INSERT variantParent;

        Product2 variantChild = new Product2(
            Name = 'Child Product',
            StockKeepingUnit = 'CHILD-SKU',
            ProductCode = 'CHILD-ProductCode',
            fan_BaseColor__c = 'AZUL',
            fan_swatch__c = 'https://blue.png'
        );
        INSERT variantChild;

        INSERT new ProductAttributeSetProduct(
	        ProductAttributeSetId = [SELECT Id FROM ProductAttributeSet WHERE DeveloperName = 'Motos_Color'].Id,
	        ProductId = variantParent.Id
        );
        ProductAttribute productAttribute = new ProductAttribute(
            ProductId = variantChild.Id,
            fan_Color__c = 'AZUL',
            VariantParentId = variantParent.Id
        );
        INSERT productAttribute;

        INSERT new WebStore(
            Name = 'Test WebStore',
            fan_HasLimitedQuantityProduct__c = true
        );
    }

    @IsTest
    static void getProductTest() {

        ConnectApi.ProductMedia testProductMedia = new ConnectApi.ProductMedia();
        testProductMedia.title = 'image';
        testProductMedia.alternateText = 'any image';
        testProductMedia.url =  'http://image.png';

        ConnectApi.ProductDetail testProductDetail = new ConnectApi.ProductDetail();
        testProductDetail.productClass = ConnectApi.ProductClass.SIMPLE;
        testProductDetail.fields = new Map<String, String>{
            'Description' => 'Nothing'
        };
        testProductDetail.defaultImage = testProductMedia;

        fan_B2BProductCtrl.testProductDetail = testProductDetail;
        ConnectApi.ProductDetail productDetail = fan_B2BProductCtrl.getProduct('', '', '');

        System.assertEquals(ConnectApi.ProductClass.SIMPLE, productDetail.productClass);
        System.assertEquals(1, productDetail.fields.size());
        System.assertEquals('image', productDetail.defaultImage.title);
        System.assertEquals('any image', productDetail.defaultImage.alternateText);
        System.assertEquals('http://image.png', productDetail.defaultImage.url);
    }

    @IsTest
    static void getProductPrice() {

        ConnectApi.ProductPrice testProductPrice = new ConnectApi.ProductPrice();
        testProductPrice.currencyIsoCode = 'COP';
        testProductPrice.listPrice = '25.00';
        testProductPrice.unitPrice = '20.00';

        fan_B2BProductCtrl.testProductPrice = testProductPrice;
        ConnectApi.ProductPrice productPrice = fan_B2BProductCtrl.getProductPrice('', '', '');

        System.assertEquals('COP', productPrice.currencyIsoCode);
        System.assertEquals('25.00', productPrice.listPrice);
        System.assertEquals('20.00', productPrice.unitPrice);
    }
    
    @IsTest
    static void getProducts(){
        ConnectApi.ProductOverviewCollection testProductCollection = new ConnectApi.ProductOverviewCollection();
        testProductCollection.products = new List<ConnectApi.ProductOverview>();
        testProductCollection.total = 0;
        
        fan_B2BProductCtrl.testProductCollection = testProductCollection;
        ConnectApi.ProductOverviewCollection products = fan_B2BProductCtrl.getProducts('', '', new List<String>(), new List<String>());
        
        System.assertEquals(0, products.total);
    }

    @IsTest
    static void getProductVariationTest(){
        
        ConnectApi.ProductDetail testProductVariationParentDetail = new ConnectApi.ProductDetail();
        testProductVariationParentDetail.productClass = ConnectApi.ProductClass.VARIATIONPARENT;
        testProductVariationParentDetail.fields = new Map<String, String>{
            'Description' => 'NothingParent'
        };
        
        ConnectApi.ProductDetail testProductVariationDetail = new ConnectApi.ProductDetail();
        testProductVariationDetail.productClass = ConnectApi.ProductClass.VARIATION;
        testProductVariationDetail.fields = new Map<String, String>{
            'Description' => 'NothingChild'
        };
        testProductVariationDetail.variationParentId = testProductVariationParentDetail.Id;

        fan_B2BProductCtrl.testProductDetail = testProductVariationDetail;
        ConnectApi.ProductDetail productVariationDetail = fan_B2BProductCtrl.getProductVariations('', '', '');

        System.assertEquals(ConnectApi.ProductClass.VARIATION, testProductVariationDetail.productClass);
        System.assertEquals(1, testProductVariationDetail.fields.size());
        System.assertEquals(testProductVariationDetail.variationParentId, testProductVariationParentDetail.Id);
    }

    @IsTest
    static void testGetAvailabilityMapped(){
        fan_B2BProductCtrl.getAvailabilityMapped();
    }
    
    @IsTest
    static void testGetWebStoreInformation(){
        fan_B2BUtils.testWebStoreId = [SELECT Id FROM WebStore].Id;
        WebStore webStore = fan_B2BProductCtrl.getWebStoreInformation('');

        Assert.isTrue(webStore.fan_HasLimitedQuantityProduct__c, 'The fan_HasLimitedQuantityProduct__c of the WebStore is not as expected.');
    }

    @IsTest
    static void getProductAttributes() {

        String variationParentId = [SELECT Id FROM Product2 WHERE StockKeepingUnit = 'PARENT-SKU'].Id;

        List<ProductAttribute> productAttributes = fan_B2BProductCtrl.getProductAttributes(variationParentId);

        ProductAttribute productAttribute = productAttributes[0];

        Assert.areEqual('https://blue.png', productAttribute.Product.fan_swatch__c, 'The fan_swatch__c of the Product2 is not as expected.');
        Assert.areEqual('AZUL', productAttribute.fan_Color__c, 'The fan_Color__c of the ProductAttribute is not as expected.');
    }

    @IsTest
    static void getProductAttributesWithError() {
        try {
            fan_B2BProductCtrl.throwExeption = true;
            fan_B2BProductCtrl.getProductAttributes('');
            Assert.fail('An AuraHandledException was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'The exception type is not as expected.');
        }
    }
}