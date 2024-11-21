@IsTest
class fan_PosventaCartUploadServiceTest {

    @TestSetup
    static void makeData(){
        fan_B2BTestDataFactory.createProduct('SKU-1', 'CODE_SKU-1', null);
    }

    @IsTest
    static void buildItemList() {
        String[] lines = new String[] {
            'REFERENCE-1,7,N',
            'REFERENCE-2,4,S'
        };
        Integer row = 0;
        Boolean defaultBackorder = false;
        Map<String, String> skuReference = new Map<String, String> {
            'REFERENCE-1' => 'SKU-1',
            'REFERENCE-2' => 'SKU-2'
        };
        fan_PosventaCartUploadService posventaCartUploadService = new fan_PosventaCartUploadService();
        fan_B2BAddToCartUtil.ImportItem[] importItems = posventaCartUploadService.buildItemList(lines, row, defaultBackorder, skuReference);

        Assert.areEqual('SKU-1', importItems[0].sku, 'The sku of the first product line is not as expected.');
        Assert.areEqual(7, importItems[0].qty, 'The qty of the first product line is not as expected.');
        Assert.isFalse(importItems[0].bo, 'The bo of the first product line is not as expected.');
        Assert.areEqual(1, importItems[0].row, 'The row of the first product line is not as expected.');

        Assert.areEqual('SKU-2', importItems[1].sku, 'The sku of the second product line is not as expected.');
        Assert.areEqual(4, importItems[1].qty, 'The qty of the second product line is not as expected.');
        Assert.isTrue(importItems[1].bo, 'The bo of the second product line is not as expected.');
        Assert.areEqual(2, importItems[1].row, 'The row of the second product line is not as expected.');
    }

    @IsTest
    static void createCartItems() {
        String cartId;
        String effectiveAccountId;

        fan_B2BAddToCartUtil.ImportItem importItem1 = new fan_B2BAddToCartUtil.ImportItem();
        importItem1.productId = [SELECT Id, StockKeepingUnit FROM Product2].Id;
        importItem1.isValid = true;
        importItem1.qty = 3;

        fan_B2BAddToCartUtil.ImportItem importItem2 = new fan_B2BAddToCartUtil.ImportItem();
        importItem2.isValid = false;
        importItem2.qty = 5;

        fan_B2BAddToCartUtil.ImportItem[] importItems = new fan_B2BAddToCartUtil.ImportItem[]{
            importItem1,
            importItem2
        };
        Map<String, Object> responseMap = new Map<String, Object>();

        fan_PosventaCartUploadService posventaCartUploadService = new fan_PosventaCartUploadService();
        ConnectApi.CartItemInput[] cartItemInputs = posventaCartUploadService.createCartItems(cartId, effectiveAccountId, importItems, responseMap);

        Map<String, Product2> productById = new Map<String, Product2>([SELECT Id, StockKeepingUnit FROM Product2]);
        Assert.areEqual('3', cartItemInputs[0].quantity, 'The quantity of the first cart item input is not as expected.');
        Assert.areEqual('SKU-1', productById.get(cartItemInputs[0].productId).StockKeepingUnit, 'The StockKeepingUnit of the product is not as expected.');
    }
}