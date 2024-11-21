@IsTest
public class fan_B2BUtilsTest {

    @TestSetup
    static void makeData(){
        
        Id testRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                            .get('AM_CUE_Cuenta_empresarial')
                            .getRecordTypeId();

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
            AM_Estado__c = 'Activo',
            RecordTypeId = testRecordTypeId,
            AccountNumber = '372865498'
        );
        insert testAccount;

        Account testAccountChild = new Account(
            Name = 'child Account test',
            Phone = '49974521753',
            AM_Tipo_de_documento__c = 'NIT',
            AM_Numero_de_documento__c = '2',
            AM_Ciudad__c = testMunicipio.Id,
            AM_Estado__c = 'Activo',
            RecordTypeId = testRecordTypeId,
            AccountNumber = '372865498213',
            ParentId = testAccount.Id
        );
        insert testAccountChild;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            LastName = 'Contact Test'
            );
        insert testContact;

        Id testProfileId = [SELECT Id FROM Profile WHERE Name = 'Posventa Login User' LIMIT 1].Id;

        User testUser = new User(
            Lastname = 'User test',
            Alias = 'UserTest',
            email = 'usertest7531@usertest.com',
            Username = 'usertest7531@usertest.com',
            ContactId = testContact.Id,
            TimeZoneSidKey = 'America/Bogota',
            LocaleSidKey = 'es_CO',
            EmailEncodingKey = 'ISO-8859-1',
            ProfileId = testProfileId,
            LanguageLocaleKey = 'es'
        );
        insert testUser;
    }

    @IsTest
    static void resolveCommunityIdToWebstoreId() {
        String testWebStoreId = '0ZE000000000000001';

        fan_B2BUtils.testWebStoreId = testWebStoreId;
        String webStoreId = fan_B2BUtils.resolveCommunityIdToWebstoreId('0ZF000000000000001');
        // Enable response caching
        webStoreId = fan_B2BUtils.resolveCommunityIdToWebstoreId('0ZF000000000000001');

        System.assertEquals(testWebStoreId, webStoreId, 'Expected WebStoreId: ' + testWebStoreId);
    }

    @IsTest
    static void resolveSortParam() {
        ConnectApi.CartItemSortOrder testCartItemSortOrder = ConnectApi.CartItemSortOrder.CREATEDDATEASC;

        ConnectApi.CartItemSortOrder cartItemSortOrder = fan_B2BUtils.resolveSortParam('CreatedDateAsc');

        System.assertEquals(testCartItemSortOrder, cartItemSortOrder, 'Expected CartItemSortOrder:' + testCartItemSortOrder);
    }

    @Istest
    static void mapSObject() {
        
        List<CartDeliveryGroup> cartDeliveryGroups = new List<CartDeliveryGroup> {
            new CartDeliveryGroup(
                Name = 'CartDeliveryGroup 1',
                fan_CPACode__c = 'CPACode-1'
            ),
            new CartDeliveryGroup(
                Name = 'CartDeliveryGroup 2',
                fan_CPACode__c = 'CPACode-2'
            )
        };

        Object mappedSObject = fan_B2BUtils.mapSObject('fan_CPACode__c', cartDeliveryGroups, Map<String, CartDeliveryGroup>.class);
        System.assert(mappedSObject instanceof Map<String, CartDeliveryGroup>, 'Expected mappedSObject instance: Map<String, CartDeliveryGroup>');

        Map<String, CartDeliveryGroup> cartDeliveryGroupMap = (Map<String, CartDeliveryGroup>) mappedSObject;

        System.assertEquals(cartDeliveryGroups.size(), cartDeliveryGroupMap.size(), 'Expected map size: ' + cartDeliveryGroups.size());
        System.assertEquals(cartDeliveryGroups[0].Name, cartDeliveryGroupMap.get('CPACode-1').Name, 'Expected CartDeliveryGroup name: ' + cartDeliveryGroups[0].Name);
        System.assertEquals(cartDeliveryGroups[1].Name, cartDeliveryGroupMap.get('CPACode-2').Name, 'Expected CartDeliveryGroup name: ' + cartDeliveryGroups[1].Name);
    }

    @Istest
    static void mapObject() {

        fan_B2BAddToCartUtil.ImportItem importItem1 = new fan_B2BAddToCartUtil.ImportItem();
        ImportItem1.sku = 'SKU-1';
        ImportItem1.cpaCode = 'CPA-1';

        fan_B2BAddToCartUtil.ImportItem importItem2 = new fan_B2BAddToCartUtil.ImportItem();
        ImportItem2.sku = 'SKU-2';
        ImportItem2.cpaCode = 'CPA-2';

        List<fan_B2BAddToCartUtil.ImportItem> importItems = new List<fan_B2BAddToCartUtil.ImportItem> {
            importItem1,
            importItem2
        };

        Object mappedObject = fan_B2BUtils.mapObject('sku', importItems, Map<String, fan_B2BAddToCartUtil.ImportItem>.class);
        System.assert(mappedObject instanceof Map<String, fan_B2BAddToCartUtil.ImportItem>, 'Expected mappedObject instance: Map<String, fan_B2BAddToCartUtil.ImportItem>');

        Map<String, fan_B2BAddToCartUtil.ImportItem> importItemMap = (Map<String, fan_B2BAddToCartUtil.ImportItem>) mappedObject;

        System.assertEquals(importItems.size(), importItemMap.size(), 'Expected map size: ' + importItems.size());
        System.assertEquals(importItems[0].cpaCode, importItemMap.get('SKU-1').cpaCode, 'Expected cpaCode: ' + importItems[0].cpaCode);
        System.assertEquals(importItems[1].cpaCode, importItemMap.get('SKU-2').cpaCode, 'Expected cpaCode: ' + importItems[1].cpaCode);
    }

    @IsTest
    static void generateSet() {

        List<Account> accounts = new List<Account> {
            new Account(Name = 'Account 1'),
            new Account(Name = 'Account 2'),
            new Account(Name = 'Account 2')
        };

        Set<String> accountNames = (Set<String>) fan_B2BUtils.generateSet(Account.Name, accounts, Set<String>.class);

        System.assertEquals(2, accountNames.size(), 'The size is not as expected');
        System.assert(accountNames.contains(accounts[0].Name), 'The names do not match.');
        System.assert(accountNames.contains(accounts[1].Name), 'The names do not match.');
    }

    @IsTest
    static void generateList() {

        List<Product2> products = new List<Product2> {
            new Product2(Name = 'Product 1'),
            new Product2(Name = 'Product 2')
        };

        Object generatedList = fan_B2BUtils.generateList('Name', products, List<String>.class);
        System.assert(generatedList instanceof List<String>, 'Expected generatedList instance: List<String>');

        List<String> productNames = (List<String>) generatedList;

        System.assertEquals(products.size(), productNames.size(), 'Expected list size: ' + products.size());
        System.assertEquals(products[0].Name, productNames[0], 'Expected product name: ' + products[0].Name);
        System.assertEquals(products[1].Name, productNames[1], 'Expected product name: ' + products[1].Name);
    }

    @IsTest
    static void getIdTiendaMdtWithKnownWebStore() {

        fan_IdTienda__mdt defaultIdTiendaMdt = fan_IdTienda__mdt.getAll().values()[0];

        WebStore webStore = new WebStore(
            Id = defaultIdTiendaMdt.fan_IdTienda__c,
            Name = 'WebStore test'
        );
        UPDATE webStore;

        fan_IdTienda__mdt idTiendaMdt = fan_B2BUtils.getIdTiendaMdt(webStore.Id, fan_IdTienda__mdt.fan_IdTienda__c);

        System.assertEquals(defaultIdTiendaMdt.DeveloperName, idTiendaMdt.DeveloperName, 'The fan_IdTienda__mdt DeveloperName is not as expected.');
    }

    @IsTest
    static void getIdTiendaMdtWithoutSupplyingValue() {

        fan_IdTienda__mdt idTiendaMdt = fan_B2BUtils.getIdTiendaMdt(null, fan_IdTienda__mdt.fan_IdTienda__c);

        System.assertEquals(null, idTiendaMdt, 'The fan_IdTienda__mdt is not as expected.');
    }

    @IsTest
    static void resolveAccountNumberParent() {
        String AccId = [SELECT Id FROM Account WHERE AM_Numero_de_documento__c = '1'].Id;
        String rsult = fan_B2BUtils.resolveAccountNumber(AccId);
        Assert.areEqual('372865498', rsult, 'The AccountNumber is not as expected.');
    }

    @IsTest
    static void resolveAccountNumberChild() {
        String AccId = [SELECT Id FROM Account WHERE AM_Numero_de_documento__c = '2'].Id;
        String rsult = fan_B2BUtils.resolveAccountNumber(AccId);
        Assert.areEqual('372865498', rsult, 'The AccountNumber is not as expected.');
    }

    @IsTest
    static void getFieldEntryPointShouldReturnAccountName() {
        Account account = new Account(Name = 'Test Account');
        Contact contact = new Contact(Account = account);
        Object value = fan_B2BUtils.getFieldValue(contact, 'Account.Name');

        Assert.areEqual('Test Account', value, 'The Name of the Account is not as expected.');
    }

    @IsTest
    static void getFieldWithShouldReturnNull() {
        Object value = fan_B2BUtils.getFieldValue(null, 'Account.Name');

        Assert.isNull(value, 'A null value was expected.');
    }

    @IsTest
    static void getFieldShouldReturnAccountSObject() {
        Account account = new Account(Name = 'Test Account');
        Contact contact = new Contact(Account = account);
        Object value = fan_B2BUtils.getFieldValue(contact, new String[] { 'Account' });

        Assert.isInstanceOfType(value, Account.class, 'An Account SObject was expected.');
    }

    @IsTest
    static void getFieldShouldReturnTheAccountName() {
        Account account = new Account(Name = 'Test Account');
        Contact contact = new Contact(Account = account);
        Object value = fan_B2BUtils.getFieldValue(contact, new String[] { 'Account', 'Name'});

        Assert.areEqual('Test Account', value, 'The Name of the Account is not as expected.');
    }

    @IsTest
    static void getFieldShouldThrowSObjectException() {
        try {
            Account account = new Account(Name = 'Test Account');
            Contact contact = new Contact(Account = account);
            fan_B2BUtils.getFieldValue(contact, new String[] { 'Account', 'Something' });
            Assert.fail('An exception was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, SObjectException.class, 'An AuraHandledException was expected.');
        }
    }
}