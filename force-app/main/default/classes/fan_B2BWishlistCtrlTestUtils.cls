@IsTest
public with sharing class fan_B2BWishlistCtrlTestUtils {

    public static Account createAccount() {

        AM_Municipio__c testMunicipio = new AM_Municipio__c();
        testMunicipio.Name = 'Nombre Municipio';
        testMunicipio.AM_Nombre_departamento__c = 'Nombre Departamento';
        testMunicipio.AM_Codigo_DANE_municipio__c = 'Municipio';
        testMunicipio.AM_Codigo_DANE_departamento__c = 'Departa';
        testMunicipio.AM_Codigo_SIPRES_departamento__c = 'Departamento SIPRES';
        testMunicipio.AM_Codigo_SIPRES_municipio__c = 'Municipio SIPRES';
        insert testMunicipio;

        Account testAccount = new Account(
            Name = 'Account Test',
            Phone = '38974521698',
            AM_Tipo_de_documento__c = 'NIT',
            AM_Numero_de_documento__c = '1',
            AM_Ciudad__c = testMunicipio.Id,
            AM_Estado__c = 'Activo'
        );
        insert testAccount;

        return testAccount;
    }

    public static Product2 createProduct() {
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TestProduct'
        );
        insert testProduct;
        return testProduct;
    }

    public static WebCart createWebCart(String accountId, String webstoreId) {
        WebCart cartTest = new WebCart(
            Name = 'Test Cart',
            AccountId = accountId,
            WebStoreId = webstoreId,
            Status = 'Active'
        );
        insert cartTest;
        return cartTest;
    }

    public static WebStore createWebStore() {
        WebStore testWebStore = new WebStore(
            Name = 'Test WebStore'
            );
        insert testWebStore;
        return testWebStore;
    }

    public static Wishlist createWishlist(Id webStoreId, Id accountId) {

        Wishlist testWishlist = new Wishlist(
            Name = 'Test Wishlist',
            WebStoreId = webStoreId,
            AccountId = accountId
        );
        insert testWishlist;
        return testWishlist;
    }

    public static WishlistItem createWishlistItem(Id wishlistId, Product2 product) {

        WishlistItem testWishlistItem = new WishlistItem(
            WishlistId = wishlistId,
            Product2Id = product.Id,
            Name = product.Name
        );
        insert testWishlistItem;
        return testWishlistItem;
    }
}