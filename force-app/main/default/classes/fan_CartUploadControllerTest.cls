/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
/*
    Lessons learned:
        Must use an existing WebStore, as only that will be associated to an community.
        The test user must be assigned to a profile that is associated with the store/community.
        The preferred way to create a cart is using the Api.
            You cannot do DML before doing an HTTP callout.
            Create the cart using the API as the system admin
            Then change the owner to the store user as the system admin.
            Then add items to the cart as the store user.

        ConnectApi.ConnectApiException: Argument: account '001B000001LC89B' does not belong to webstore '0ZEB00000008Q2e
            Make sure the test store user has access to the store.  The profile associated with the user must be included as a community member.
*/
@IsTest
public with sharing class fan_CartUploadControllerTest {

    private static Id userId = null;
    private static Id accountId = null;
    private static Id storeId;
    private static Id cartId;
    private static User storeUser;
    private static Id productId;
    private static List<Product2> productList;

    private static void setupTestData(Boolean createProducts) {

        System.debug('begin setupTestData()');

        accountId = fan_B2BCartUploadTestUtils.createAccount();

        //System.debug('accountId: ' + accountId);

        Id contactId = fan_B2BCartUploadTestUtils.createContact(accountId);
        
        // 2020-08-12 the test storefront user must be associated with a profile that has access to the store/community
        userId = fan_B2BCartUploadTestUtils.createUser(null);

        System.debug('userId: ' + userId);

        storeUser = fan_B2BCartUploadTestUtils.getUser(userId);

        Id pricebookId = fan_B2BCartUploadTestUtils.createPricebook();

        
        if(createProducts) {
            
            productId =  fan_B2BCartUploadTestUtils.createProduct2('Sample Product', '999AAA000111', '');

                System.debug('productId: ' + productId);

            List<String> productIdList = new List<String>();
            productIdList.add(productId);

            productList = fan_B2BCartUploadTestUtils.getProducts(productIdList);

            fan_B2BCartUploadTestUtils.createStandardPricebookEntry(productId);

            fan_B2BCartUploadTestUtils.createPricebookEntry(pricebookId, productId);

        }
        fan_B2BTestDataFactory.createServiceEndpoint('batch', Url.getOrgDomainURL() + '/services/data/v54.0/connect/batch');
    }

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = false
        ignoreInvalidSkus = true
        emailResults = true
        motosDefaultBackorder = true;
    */
    public static void testCode1() {

        System.debug('begin testCode1()');

        User adminUser = fan_B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(true);
        }

        Test.setMock(HttpCalloutMock.class, new fan_CartUploadProductSearchRestApiMock(productList));

        List<String> rows = new List<String>();
        rows.add('999AAA000111,1,S');  // This is a valid SKU
        rows.add('111000AAA999,2,S');  // This is an invalid SKU

        String webstoreId = fan_IdTienda__mdt.getInstance(fan_Constants.StoreDeveloperName.POSVENTA.name().toLowerCase()).fan_IdTienda__c;
        String effectiveAccountId = accountId;
        Boolean hasHeaderRow = false;
        Boolean ignoreInvalidSkus = true;
        Boolean emailResults = true;
        Boolean motosDefaultBackorder = true;

        Map<String, Object> responseMap = null;

        Test.startTest();

        System.runAs(storeUser) {

            // Don't do any DML prior to making this call:

            responseMap = fan_CartUploadController.processData(
                userId, 
                rows, 
                webstoreId, 
                effectiveAccountId, 
                cartId, 
                hasHeaderRow, 
                ignoreInvalidSkus,
                emailResults,
                motosDefaultBackorder);

        }

        Test.stopTest();

        String successMsg = null;
        String errorMsg = null;

        System.debug('responseMap: ' + JSON.serialize(responseMap));

        String messagesJson = (String)responseMap.get('messagesJson');

        System.debug('messagesJson: ' + messagesJson);

        List<Object> messagesList = (List<Object>)JSON.deserializeUntyped(messagesJson);

        if(messagesList != null) {

            for(Object obj : messagesList) {
                Map<String, Object> messageMap = (Map<String, Object>)obj;

                String severity = (String)messageMap.get('severity');
                String message = (String)messageMap.get('message');

                if(severity == 'success') {
                    successMsg = message;
                }

                if(severity == 'error') {
                    errorMsg = message;
                }
            }

        }

        System.debug('successMsg: ' + successMsg);
        System.debug('errorMsg: ' + errorMsg);

        Integer totItems = (Integer)responseMap.get('totItems');

        System.assertEquals(1, totItems);

    }

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = true
        ignoreInvalidSkus = false
        emailResults = false
        motosDefaultBackorder = true;
    */
    public static void testCode2() {

        System.debug('begin testCode2()');

        User adminUser = fan_B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(true);
        }

        Test.setMock(HttpCalloutMock.class, new fan_CartUploadProductSearchRestApiMock(productList));

        List<String> rows = new List<String>();
        rows.add('SKU,QTY,BACKORDER');  // This is the header row
        rows.add('999AAA000111,1,S');  // This is a valid SKU
        rows.add('111000AAA999,2,N');  // This is an invalid SKU

        String webstoreId = storeId;
        String effectiveAccountId = accountId;
        Boolean hasHeaderRow = true;
        Boolean ignoreInvalidSkus = false;
        Boolean emailResults = false;
        Boolean motosDefaultBackorder = true;

        Map<String, Object> responseMap = null;

        Test.startTest();

        System.runAs(storeUser) {

            // Don't do any DML prior to making this call:

            responseMap = fan_CartUploadController.processData(
                userId, 
                rows, 
                webstoreId, 
                effectiveAccountId, 
                cartId, 
                hasHeaderRow, 
                ignoreInvalidSkus,
                emailResults,
                motosDefaultBackorder);

        }

        Test.stopTest();

        String successMsg = null;
        String errorMsg = null;

        System.debug('responseMap: ' + JSON.serialize(responseMap));

        String messagesJson = (String)responseMap.get('messagesJson');

        System.debug('messagesJson: ' + messagesJson);

        List<Object> messagesList = (List<Object>)JSON.deserializeUntyped(messagesJson);

        if(messagesList != null) {

            for(Object obj : messagesList) {
                Map<String, Object> messageMap = (Map<String, Object>)obj;

                String severity = (String)messageMap.get('severity');
                String message = (String)messageMap.get('message');

                if(severity == 'success') {
                    successMsg = message;
                }

                if(severity == 'error') {
                    errorMsg = message;
                }
            }

        }

        System.debug('successMsg: ' + successMsg);
        System.debug('errorMsg: ' + errorMsg);

        Integer totItems = (Integer)responseMap.get('totItems');
        Integer totErrors = (Integer)responseMap.get('totErrors');
        Integer totSuccess = (Integer)responseMap.get('totSuccess');

        System.debug('totItems: ' + totItems);
        System.debug('totErrors: ' + totErrors);
        System.debug('totSuccess: ' + totSuccess);

        System.assertEquals(1, totErrors);

    }

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = true
        ignoreInvalidSkus = false
        emailResults = false
        motosDefaultBackorder = true;

        Handle some corner cases:
            Duplicate SKUs in the input
            Empty line in the input
            No qty supplied in the input
    */
    public static void testCode3() {

        System.debug('begin testCode3()');

        User adminUser = fan_B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(true);
        }

        Test.setMock(HttpCalloutMock.class, new fan_CartUploadProductSearchRestApiMock(productList));

        List<String> rows = new List<String>();
        rows.add('SKU,QTY,BACKORDER');  // This is the header row
        rows.add('999AAA000111,1,N');  // This is a valid SKU
        rows.add('999AAA000111,1,N');  // Duplicate valid SKU
        rows.add('999AAA000111');  // No qty supplied
        rows.add('');  // Empty line
        rows.add('111000AAA999,2,N');  // This is an invalid SKU

        String webstoreId = storeId;
        String effectiveAccountId = accountId;
        Boolean hasHeaderRow = true;
        Boolean ignoreInvalidSkus = false;
        Boolean emailResults = false;
        Boolean motosDefaultBackorder = true;

        Map<String, Object> responseMap = null;

        Test.startTest();

        System.runAs(storeUser) {

            // Don't do any DML prior to making this call:

            responseMap = fan_CartUploadController.processData(
                userId, 
                rows, 
                webstoreId, 
                effectiveAccountId, 
                cartId, 
                hasHeaderRow, 
                ignoreInvalidSkus,
                emailResults,
                motosDefaultBackorder);

        }

        Test.stopTest();

        String successMsg = null;
        String errorMsg = null;

        System.debug('responseMap: ' + JSON.serialize(responseMap));

        String messagesJson = (String)responseMap.get('messagesJson');

        System.debug('messagesJson: ' + messagesJson);

        List<Object> messagesList = (List<Object>)JSON.deserializeUntyped(messagesJson);

        if(messagesList != null) {

            for(Object obj : messagesList) {
                Map<String, Object> messageMap = (Map<String, Object>)obj;

                String severity = (String)messageMap.get('severity');
                String message = (String)messageMap.get('message');

                if(severity == 'success') {
                    successMsg = message;
                }

                if(severity == 'error') {
                    errorMsg = message;
                }
            }

        }

        System.debug('successMsg: ' + successMsg);
        System.debug('errorMsg: ' + errorMsg);

        Integer totItems = (Integer)responseMap.get('totItems');
        Integer totErrors = (Integer)responseMap.get('totErrors');
        Integer totSuccess = (Integer)responseMap.get('totSuccess');

        System.debug('totItems: ' + totItems);
        System.debug('totErrors: ' + totErrors);
        System.debug('totSuccess: ' + totSuccess);

        System.assertEquals(1, totErrors);

    }

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = true
        ignoreInvalidSkus = false
        emailResults = false
        motosDefaultBackorder = true;

        Handle some corner cases:
            Too many rows
    */
    public static void testCode4() {

        System.debug('begin testCode4()');

        User adminUser = fan_B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(true);
        }

        Test.setMock(HttpCalloutMock.class, new fan_CartUploadProductSearchRestApiMock(productList));

        List<String> rows = new List<String>();
        rows.add('SKU,QTY,BACKORDER');  // This is the header row
        rows.add('999AAA000111,1,S');  // This is a valid SKU

        // Add more than the max allowed in the code
        for(Integer i = 0; i < fan_B2BAddToCartUtil.MAX_UPLOAD_ROWS; i++) {
            rows.add('PROD-' + i + ',1');  // This is a dummy SKU
        }

        String webstoreId = storeId;
        String effectiveAccountId = accountId;
        Boolean hasHeaderRow = true;
        Boolean ignoreInvalidSkus = false;
        Boolean emailResults = false;
        Boolean motosDefaultBackorder = true;

        Map<String, Object> responseMap = null;

        Test.startTest();

        System.runAs(storeUser) {

            // Don't do any DML prior to making this call:

            responseMap = fan_CartUploadController.processData(
                userId, 
                rows, 
                webstoreId, 
                effectiveAccountId, 
                cartId, 
                hasHeaderRow, 
                ignoreInvalidSkus,
                emailResults,
                motosDefaultBackorder);

        }

        Test.stopTest();

        String successMsg = null;
        String errorMsg = null;

        System.debug('responseMap: ' + JSON.serialize(responseMap));

        String messagesJson = (String)responseMap.get('messagesJson');

        System.debug('messagesJson: ' + messagesJson);

        List<Object> messagesList = (List<Object>)JSON.deserializeUntyped(messagesJson);

        if(messagesList != null) {

            for(Object obj : messagesList) {
                Map<String, Object> messageMap = (Map<String, Object>)obj;

                String severity = (String)messageMap.get('severity');
                String message = (String)messageMap.get('message');

                if(severity == 'success') {
                    successMsg = message;
                }

                if(severity == 'error') {
                    errorMsg = message;
                }
            }

        }

        System.debug('successMsg: ' + successMsg);
        System.debug('errorMsg: ' + errorMsg);

        Integer totItems = (Integer)responseMap.get('totItems');
        Integer totErrors = (Integer)responseMap.get('totErrors');
        Integer totSuccess = (Integer)responseMap.get('totSuccess');

        System.debug('totItems: ' + totItems);
        System.debug('totErrors: ' + totErrors);
        System.debug('totSuccess: ' + totSuccess);

        System.assertEquals(1, totErrors);

    }

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = true
        ignoreInvalidSkus = false
        emailResults = false
        motosDefaultBackorder = true;

        Handle some corner cases:
            Throw an Exception by supplying an invalid qty value
    */
    public static void testCode5() {

        System.debug('begin testCode5()');

        User adminUser = fan_B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(true);
        }

        Test.setMock(HttpCalloutMock.class, new fan_CartUploadProductSearchRestApiMock(productList));

        List<String> rows = new List<String>();
        rows.add('SKU,QTY,BACKORDER');  // This is the header row
        rows.add('999AAA000111,ABCDEFG,S');  // This is a valid SKU

        String webstoreId = storeId;
        String effectiveAccountId = accountId;
        Boolean hasHeaderRow = true;
        Boolean ignoreInvalidSkus = false;
        Boolean emailResults = false;
        Boolean motosDefaultBackorder = true;

        Map<String, Object> responseMap = null;

        Test.startTest();

        System.runAs(storeUser) {

            // Don't do any DML prior to making this call:

            responseMap = fan_CartUploadController.processData(
                userId, 
                rows, 
                webstoreId, 
                effectiveAccountId, 
                cartId, 
                hasHeaderRow, 
                ignoreInvalidSkus,
                emailResults,
                motosDefaultBackorder);

        }

        Test.stopTest();

        String successMsg = null;
        String errorMsg = null;

        System.debug('responseMap: ' + JSON.serialize(responseMap));

        String messagesJson = (String)responseMap.get('messagesJson');

        System.debug('messagesJson: ' + messagesJson);

        List<Object> messagesList = (List<Object>)JSON.deserializeUntyped(messagesJson);

        if(messagesList != null) {

            for(Object obj : messagesList) {
                Map<String, Object> messageMap = (Map<String, Object>)obj;

                String severity = (String)messageMap.get('severity');
                String message = (String)messageMap.get('message');

                if(severity == 'success') {
                    successMsg = message;
                }

                if(severity == 'error') {
                    errorMsg = message;
                }
            }

        }

        System.debug('successMsg: ' + successMsg);
        System.debug('errorMsg: ' + errorMsg);

        Integer totItems = (Integer)responseMap.get('totItems');
        Integer totErrors = (Integer)responseMap.get('totErrors');
        Integer totSuccess = (Integer)responseMap.get('totSuccess');

        System.debug('totItems: ' + totItems);
        System.debug('totErrors: ' + totErrors);
        System.debug('totSuccess: ' + totSuccess);

        System.assertEquals(1, totErrors);

    }

    @IsTest
    /*
        one valid SKU
        hasHeaderRow = false
        ignoreInvalidSkus = false
        emailResults = false
        motosDefaultBackorder = false;
    */
    public static void testCode6() {

        System.debug('begin testCode6()');

        User adminUser = fan_B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(true);
        }

        String testWebStoreId = fan_B2BTestDataFactory.createWebStore('WebStore').Id;
        String testCartId = fan_B2BCartCtrlTestUtils.createWebCart(accountId, testWebStoreId).Id;

        Test.setMock(HttpCalloutMock.class, new fan_CartUploadProductSearchRestApiMock(productList));

        List<String> rows = new List<String>();
        rows.add('999AAA000111,1,CPA-Motos-1');  // This is a valid SKU, a valid quantiy and non-existing CPACode.

        String webstoreId = storeId;
        String effectiveAccountId = accountId;
        Boolean hasHeaderRow = false;
        Boolean ignoreInvalidSkus = false;
        Boolean emailResults = false;
        Boolean motosDefaultBackorder = false;

        Map<String, Object> responseMap = null;

        Test.startTest();

        System.runAs(storeUser) {

            // Don't do any DML prior to making this call:

            responseMap = fan_CartUploadController.processData(
                userId, 
                rows, 
                webstoreId, 
                effectiveAccountId, 
                testCartId, 
                hasHeaderRow, 
                ignoreInvalidSkus,
                emailResults,
                motosDefaultBackorder);
        }

        Test.stopTest();

        String successMsg = null;
        String errorMsg = null;

        System.debug('responseMap: ' + JSON.serialize(responseMap));

        String messagesJson = (String)responseMap.get('messagesJson');

        System.debug('messagesJson: ' + messagesJson);

        List<Object> messagesList = (List<Object>)JSON.deserializeUntyped(messagesJson);

        if(messagesList != null) {

            for(Object obj : messagesList) {
                Map<String, Object> messageMap = (Map<String, Object>)obj;

                String severity = (String)messageMap.get('severity');
                String message = (String)messageMap.get('message');

                if(severity == 'success') {
                    successMsg = message;
                }

                if(severity == 'error') {
                    errorMsg = message;
                }
            }

        }

        System.debug('successMsg: ' + successMsg);
        System.debug('errorMsg: ' + errorMsg);

        Integer totItems = (Integer)responseMap.get('totItems');
        Integer totErrors = (Integer)responseMap.get('totErrors');
        Integer totSuccess = (Integer)responseMap.get('totSuccess');

        System.debug('totItems: ' + totItems);
        System.debug('totErrors: ' + totErrors);
        System.debug('totSuccess: ' + totSuccess);

        System.assertEquals(1, totErrors);
    }

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = true
        ignoreInvalidSkus = false
        emailResults = false
        motosDefaultBackorder = true;
    */
    public static void testGetInfo() {

        System.debug('begin testGetInfo()');

        User adminUser = fan_B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(false);
        }

        Map<String, Object> responseMap = null;

        Test.startTest();

        System.runAs(storeUser) {

            // Don't do any DML prior to making this call:

            responseMap = fan_CartUploadController.getInfo(userId, accountId, null, storeId);

        }

        Test.stopTest();

        System.debug('responseMap: ' + JSON.serialize(responseMap));

        Integer maxUploadRows = (Integer)responseMap.get('maxUploadRows');

        System.assertEquals(fan_B2BAddToCartUtil.MAX_UPLOAD_ROWS, maxUploadRows);

    }

    @isTest
    static void testVerifyItemsWithErrors() {
        List<fan_B2BAddToCartUtil.ImportItem> itemsList = new List<fan_B2BAddToCartUtil.ImportItem>();
        
        // Add a valid item (errorMsg is null)
        fan_B2BAddToCartUtil.ImportItem validItem = new fan_B2BAddToCartUtil.ImportItem();
        validItem.errorMsg = null;
        itemsList.add(validItem);
        
        // Add an invalid item (errorMsg is not blank)
        fan_B2BAddToCartUtil.ImportItem invalidItem = new fan_B2BAddToCartUtil.ImportItem();
        invalidItem.errorMsg = 'Some error';
        itemsList.add(invalidItem);
        
        // Add another valid item (errorMsg is blank)
        fan_B2BAddToCartUtil.ImportItem anotherValidItem = new fan_B2BAddToCartUtil.ImportItem();
        anotherValidItem.errorMsg = '';
        itemsList.add(anotherValidItem);
        
        // Run the verifyItems method
        Boolean result = fan_CartUploadController.verifyItems(itemsList);
        
        // Assert that the result is false because there's at least one item with an error
        System.assertEquals(false, result, 'List contains an item with an error, should return false');
    }

    @isTest
    static void testSummariseItems() {
        List<fan_B2BAddToCartUtil.ImportItem> itemsList = new List<fan_B2BAddToCartUtil.ImportItem>();
        
        fan_B2BAddToCartUtil.ImportItem item1 = new fan_B2BAddToCartUtil.ImportItem();
        item1.row = 1;
        item1.sku = 'SKU1';
        itemsList.add(item1);
        
        fan_B2BAddToCartUtil.ImportItem item2 = new fan_B2BAddToCartUtil.ImportItem();
        item2.row = 2;
        item2.sku = 'SKU2';
        itemsList.add(item2);
        
        fan_B2BAddToCartUtil.ImportItem item3 = new fan_B2BAddToCartUtil.ImportItem();
        item3.row = 1; // Duplicate row
        item3.sku = 'SKU3';
        itemsList.add(item3);
        
        fan_B2BAddToCartUtil.ImportItem item4 = new fan_B2BAddToCartUtil.ImportItem();
        item4.row = 3;
        item4.sku = 'SKU4';
        itemsList.add(item4);
        
        // Run the summariseItems method
        List<fan_B2BAddToCartUtil.ImportItem> summarisedItems = fan_CartUploadController.summariseItems(itemsList);
        
        // Assert the size of the returned list is 3 (unique rows)
        System.assertEquals(3, summarisedItems.size(), 'There should be 3 unique items based on row number');
        
        // Assert that the correct items are included in the summarised list
        Set<Integer> expectedRows = new Set<Integer>{1, 2, 3};
        for (fan_B2BAddToCartUtil.ImportItem item : summarisedItems) {
            System.assert(expectedRows.contains(item.row), 'Summarised items should contain the expected rows');
            expectedRows.remove(item.row);
        }
        
        // Assert that the duplicate row was ignored
        System.assertNotEquals('SKU3', summarisedItems[0].sku, 'Duplicate row should be ignored');
    }
    
}