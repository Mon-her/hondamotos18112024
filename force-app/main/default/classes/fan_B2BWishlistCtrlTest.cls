@IsTest
public with sharing class fan_B2BWishlistCtrlTest {

    @TestSetup
    static void makeData(){

        WebStore testWebStore = fan_B2BWishlistCtrlTestUtils.createWebStore();

        Account testAccount = fan_B2BWishlistCtrlTestUtils.createAccount();

        WebCart testWebCart = fan_B2BWishlistCtrlTestUtils.createWebCart(testAccount.Id, testWebStore.Id);

        Product2 testProduct = fan_B2BWishlistCtrlTestUtils.createProduct();

        Wishlist testWishlist = fan_B2BWishlistCtrlTestUtils.createWishlist(testWebStore.Id, testAccount.Id);
    
        fan_B2BWishlistCtrlTestUtils.createWishlistItem(testWishlist.Id, testProduct);
    }

    @IsTest
    static void addAllToWishlistTest() {
        // Won't add the product because it already exists
        Wishlist testWishlist = [SELECT Id FROM Wishlist LIMIT 1];
        Product2 testProduct = [SELECT Id, Name FROM Product2 LIMIT 1];
        fan_B2BWishlistCtrl.addAllToWishlist('', testWishlist.Id, new Map<String, String> {
            testProduct.Id => testProduct.Name
        });
        System.assertEquals(1, [SELECT Id FROM WishlistItem].size());

        // Will add the product
        Product2 testNonExistingProduct = new Product2(
            Name = 'Test Product 2',
            ProductCode = 'TestProduct2'
        );
        insert testNonExistingProduct;

        fan_B2BWishlistCtrl.addAllToWishlist('', testWishlist.Id, new Map<String, String> {
            testNonExistingProduct.Id => testNonExistingProduct.Name
        });
        System.assertEquals(2, [SELECT Id FROM WishlistItem].size());
        
        try {
            fan_B2BWishlistCtrl.addAllToWishlist('', '', null);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }
    }

    @IsTest
    static void getWishlistSummariesTest() {

        ConnectApi.WishlistsSummary testWishlistSummary = new ConnectApi.WishlistsSummary();
        testWishlistSummary.wishlistCount = 1;
        testWishlistSummary.summaries = new List<ConnectApi.WishlistSummary>();

        fan_B2BWishlistCtrl.testWishlistsSummary = testWishlistSummary;
        ConnectApi.WishlistsSummary wishlistSummary = fan_B2BWishlistCtrl.getWishlistSummaries('', '', false);

        System.debug(wishlistSummary);
        System.assertEquals(1, wishlistSummary.wishlistCount);
        System.assertEquals(null, wishlistSummary.displayedList);
        System.assertEquals(0, wishlistSummary.summaries.size());
    }

    @IsTest
    static void createAndAllAddToWishlistTest() {

        ConnectApi.WishlistSummary testWishlistSummary = new ConnectApi.WishlistSummary(); 
        testWishlistSummary.name = 'List 1';
        testWishlistSummary.wishlistProductCount = 5;

        ConnectApi.Wishlist testWishlist = new ConnectApi.Wishlist();
        testWishlist.summary = testWishlistSummary;

        fan_B2BWishlistCtrl.testWishlist = testWishlist;
        ConnectApi.Wishlist wishlist = fan_B2BWishlistCtrl.createAndAllAddToWishlist('', new ConnectApi.WishlistInput());

        System.assertEquals('List 1', wishlist.summary.name);
        System.assertEquals(5, wishlist.summary.wishlistProductCount);
    }

    @IsTest
    static void createAndAddToWishlistTest() {

        ConnectApi.WishlistSummary testWishlistSummary = new ConnectApi.WishlistSummary(); 
        testWishlistSummary.name = 'List 1';
        testWishlistSummary.wishlistProductCount = 5;

        ConnectApi.Wishlist testWishlist = new ConnectApi.Wishlist();
        testWishlist.summary = testWishlistSummary;

        fan_B2BWishlistCtrl.testWishlist = testWishlist;
        ConnectApi.Wishlist wishlist = fan_B2BWishlistCtrl.createAndAddToWishlist('', '', '', '');

        System.assertEquals('List 1', wishlist.summary.name);
        System.assertEquals(5, wishlist.summary.wishlistProductCount);
    }

    @IsTest
    static void addToWishlistTest() {
        ConnectApi.CartItemProduct testProductSummary = new ConnectApi.CartItemProduct();
        testProductSummary.name = 'Chain';
        testProductSummary.sku = 'CH1';

        ConnectApi.WishlistItem testWishlistItem = new ConnectApi.WishlistItem();
        testWishlistItem.productSummary = testProductSummary;
        testWishlistItem.currencyIsoCode = 'COP';
        testWishlistItem.listPrice = 25.00;
        testWishlistItem.salesPrice = 20.00;

        fan_B2BWishlistCtrl.testWishlistItem = testWishlistItem;
        ConnectApi.WishlistItem wishlistItem = fan_B2BWishlistCtrl.addToWishlist('', '', '');
        ConnectApi.CartItemProduct productSummary = wishlistItem.productSummary;

        System.assertEquals('Chain', productSummary.name);
        System.assertEquals('CH1', productSummary.sku);
        System.assertEquals(25.00, wishlistItem.listPrice);
        System.assertEquals(20.00, wishlistItem.salesPrice);
    }
}