/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
@IsTest
public with sharing class fan_B2BProductEntitlementCheckTest {
    
    private static Id userId = null;
    private static Id accountId = null;
    private static Id pricebookId;
    private static List<Product2> productList = null;
    private static Id storeId;

    private static Id buyerGroupId;

    private static Id buyerAccountId;

    private static List<String> skus = new List<String>();

    private static void createObjs() {

        accountId = fan_B2BCartUploadTestUtils.createAccount();

        Id contactId = fan_B2BCartUploadTestUtils.createContact(accountId);
        
        userId = fan_B2BCartUploadTestUtils.createUser(null);

    }

    private static void setupTestData(Integer numProducts) {

        System.debug('begin setupTestData()');

        fan_B2BTestDataFactory.createServiceEndpoint('batch', '/services/data/v54.0/connect/batch');

        Id pricebookId = fan_B2BCartUploadTestUtils.createPricebook();

        storeId = null;

        productList = new List<Product2>();

        for(Integer i = 1; i <= numProducts; i++) {

            String sku = fan_B2BCartUploadTestUtils.getGuid();

            Product2 product =  fan_B2BCartUploadTestUtils.createProductBatch('Sample Product', sku, '', 'Sample-Product-Code' + i);

            productList.add(product);

            skus.add(sku);

        }

        insert productList;

        List<PricebookEntry> pbeList1 = new List<PricebookEntry>();
        List<PricebookEntry> pbeList2 = new List<PricebookEntry>();

        for(Product2 product : productList) {
            
            PricebookEntry stdpbe = fan_B2BCartUploadTestUtils.createStandardPricebookEntryBatch(product.Id);
            pbeList1.add(stdpbe);

            PricebookEntry pbe = fan_B2BCartUploadTestUtils.createPricebookEntryBatch(pricebookId, product.Id);
            pbeList2.add(pbe);
        }

        insert pbeList1;
        insert pbeList2;

    }

    @IsTest
    /*
        Tests for one product.
    */
    public static void testCode1() {

        User adminUser = fan_B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            createObjs();
            setupTestData(1);
        }

        MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
        String endpoint = [SELECT url__c FROM fan_ServiceEndpoint__c WHERE Nombre__c = 'batch'].url__c;

        System.debug('--- endpoint: ' + endpoint);

        mock.setStaticResource(endpoint, 'B2B_Product_Search_Results_One_Product');
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        Map<String, String> skuMap = fan_B2BProductEntitlementCheck.productSearch(skus, storeId, null);

        Test.stopTest();

        System.debug('skuMap: ' + JSON.serialize(skuMap));

        Product2 product = productList.get(0);
        System.debug('product: ' + product);

        Boolean validSkuFound = skuMap.containsKey('999AAA000111');

        System.assertEquals(validSkuFound, true, 'SKU not found in response');

    }

    @IsTest
    /*
        Tests for 50 products.
    */
    public static void testCode2() {

        User adminUser = fan_B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            createObjs();
            setupTestData(50);
        }

        MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
        String endpoint = [SELECT url__c FROM fan_ServiceEndpoint__c WHERE Nombre__c = 'batch'].url__c;

        System.debug('--- endpoint: ' + endpoint);

        mock.setStaticResource(endpoint, 'B2B_Product_Search_Results_One_Product');
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        Map<String, String> skuMap = fan_B2BProductEntitlementCheck.productSearch(skus, storeId, null);

        Test.stopTest();

        System.debug('skuMap: ' + JSON.serialize(skuMap));

        Boolean validSkuFound = skuMap.containsKey('999AAA000111');

        System.assertEquals(validSkuFound, true, 'SKU not found in response');

    }

    @IsTest
    /*
        Tests for 201 products.
    */
    public static void testCode3() {

        User adminUser = fan_B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            createObjs();
            setupTestData(201);
        }

        MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
        String endpoint = [SELECT url__c FROM fan_ServiceEndpoint__c WHERE Nombre__c = 'batch'].url__c;

        System.debug('--- endpoint: ' + endpoint);

        mock.setStaticResource(endpoint, 'B2B_Product_Search_Results_One_Product');
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        Map<String, String> skuMap = fan_B2BProductEntitlementCheck.productSearch(skus, storeId, null);

        Test.stopTest();

        System.debug('skuMap: ' + JSON.serialize(skuMap));

        Boolean validSkuFound = skuMap.containsKey('999AAA000111');

        System.assertEquals(validSkuFound, true, 'SKU not found in response');

    }

    @IsTest
    /*
        Tests for 1 product.
    */
    public static void testError() {

        User adminUser = fan_B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            createObjs();
            setupTestData(1);
        }

        MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
        String endpoint = [SELECT url__c FROM fan_ServiceEndpoint__c WHERE Nombre__c = 'batch'].url__c;

        System.debug('--- endpoint: ' + endpoint);

        mock.setStaticResource(endpoint, 'B2B_Product_Search_Results_Error');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        Map<String, String> skuMap = fan_B2BProductEntitlementCheck.productSearch(skus, storeId, null);

        Test.stopTest();

        System.debug('skuMap: ' + JSON.serialize(skuMap));

        System.assertEquals(0, skuMap.size(), 'No valid SKUs should have been returned');

    }

}