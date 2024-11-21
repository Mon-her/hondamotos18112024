@IsTest
class fan_MotosCartUploadServiceTest {

    @TestSetup
    static void makeData(){
        
        Account account = fan_B2BCartCtrlTestUtils.createAccount();
        fan_B2BCartCtrlTestUtils.createContactPointAddress(account.Id, 'Shipping', 'TEST-CPA-1', false);
        fan_B2BCartCtrlTestUtils.createContactPointAddress(account.Id, 'Shipping', 'TEST-CPA-2', false);

        Webstore webstore = fan_B2BTestDataFactory.createWebStore('Webstore'); 
        WebCart cart = fan_B2BTestDataFactory.createWebCart(webstore.Id, account.Id, 'credito');

        fan_B2BCartCtrlTestUtils.createCartDeliveryGroup(cart.Id, null);
    }

    @IsTest
    static void buildItemList() {

        String[] lines = new String[] {
            'REFERENCE-1,1,BRANCH-1',
            'REFERENCE-2,2,BRANCH-2',
            'REFERENCE-2,2,BRANCH-2'
        };
        Map<String, String> skuReference = new Map<String, String> {
            'REFERENCE-1' => 'SKU-1',
            'REFERENCE-2' => 'SKU-2'
        };

        fan_MotosCartUploadService motosCartUploadService = new fan_MotosCartUploadService();
        fan_B2BAddToCartUtil.ImportItem[] importItems = motosCartUploadService.buildItemList(lines, 0, true, skuReference);

        Assert.areEqual('SKU-1', importItems[0].sku, 'The sku of the first product line is not as expected.');
        Assert.areEqual(1, importItems[0].qty, 'The qty of the first product line is not as expected.');
        Assert.isTrue(importItems[0].bo, 'The bo of the first product line is not as expected.');
        Assert.areEqual(1, importItems[0].row, 'The row of the first product line is not as expected.');

        Assert.areEqual('SKU-2', importItems[1].sku, 'The sku of the second product line is not as expected.');
        Assert.areEqual(4, importItems[1].qty, 'The qty of the second product line is not as expected.');
        Assert.isTrue(importItems[1].bo, 'The bo of the second product line is not as expected.');
        Assert.areEqual(2, importItems[1].row, 'The row of the second product line is not as expected.');
    }

    @IsTest
    static void createCartItems() {
        
        String cartId = [SELECT Id FROM Webcart].Id;
        String effectiveAccountId = [SELECT Id FROM Account].Id;

        fan_B2BAddToCartUtil.ImportItem importItem1 = new fan_B2BAddToCartUtil.ImportItem();
        importItem1.isValid = true;
        importItem1.cpaCode = 'TEST-CPA-1';
        importItem1.qty = 1;

        fan_B2BAddToCartUtil.ImportItem importItem2 = new fan_B2BAddToCartUtil.ImportItem();
        importItem2.isValid = true;
        importItem2.cpaCode = 'TEST-CPA-2';
        importItem2.qty = 5;

        fan_B2BAddToCartUtil.ImportItem[] importItems = new fan_B2BAddToCartUtil.ImportItem[]{
            importItem1,
            importItem2
        };
        Map<String, Object> responseMap = new Map<String, Object>();

        fan_MotosCartUploadService motosCartUploadService = new fan_MotosCartUploadService();
        ConnectApi.CartItemInput[] cartItemInputs = motosCartUploadService.createCartItems(cartId, effectiveAccountId, importItems, responseMap);

        Map<String, CartDeliveryGroup> cartDeliveryGroupById = new Map<String, CartDeliveryGroup>([SELECT fan_CPACode__c FROM CartDeliveryGroup]);
        Assert.areEqual('1', cartItemInputs[0].quantity, 'The quantity of the first cart item input is not as expected.');
        Assert.areEqual(importItem1.cpaCode, cartDeliveryGroupById.get(cartItemInputs[0].cartDeliveryGroupId).fan_CPACode__c, 'The cartDeliveryGroupId of the first cart item input is not as expected.');

        Assert.areEqual('5', cartItemInputs[1].quantity, 'The quantity of the second cart item input is not as expected.');
        Assert.areEqual(importItem2.cpaCode, cartDeliveryGroupById.get(cartItemInputs[1].cartDeliveryGroupId).fan_CPACode__c, 'The cartDeliveryGroupId of the second cart item input is not as expected.');
    }

    @IsTest
    static void createCartItemsShouldThrowAnException() {

        String cartId = [SELECT Id FROM Webcart].Id;
        String effectiveAccountId = [SELECT Id FROM Account].Id;
        
        fan_B2BAddToCartUtil.ImportItem importItem = new fan_B2BAddToCartUtil.ImportItem();
        importItem.isValid = true;
        importItem.cpaCode = 'TEST-CPA-3';
        importItem.qty = 1;

        fan_B2BAddToCartUtil.ImportItem[] importItems = new fan_B2BAddToCartUtil.ImportItem[]{ importItem };
        Map<String, Object> responseMap = new Map<String, Object>();

        try {
            fan_MotosCartUploadService motosCartUploadService = new fan_MotosCartUploadService();
            motosCartUploadService.createCartItems(cartId, effectiveAccountId, importItems, responseMap);
            Assert.fail('An exception was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, fan_B2BAddToCartUtil.CustomException.class, 'The exception type is not expected.');
            Assert.areEqual(Label.fan_cpaCodesNotFound, e.getMessage(), 'The message of the exception is not as expected.');
        }
    }
}