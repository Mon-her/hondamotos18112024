/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class fan_B2BProductEntitlementCheck {

    static final Integer MAX_SEARCH_SKUS = 20;
    static final Integer MAX_SUBREQUESTS = 25;

    public static Map<String, String> productSearch(List<String> skus, String webstoreId, String effectiveAccountId) {

        Map<String, String> validSkuMap = new Map<String, String>();

        //Make sure your Salesforce instance URL is added in remote site settings

        String restAPIURL = '/v54.0/commerce/webstores/' + webStoreId + '/products';

        String batchRestAPIURL = [SELECT url__c FROM fan_ServiceEndpoint__c WHERE nombre__c = 'batch'].url__c;

        if(effectiveAccountId != null) {
            restAPIURL += '?effectiveAccountId=' + effectiveAccountId;
        }

        System.debug(LoggingLevel.DEBUG, 'productSearch restAPIURL >>> ' + restAPIURL);
        System.debug(LoggingLevel.DEBUG, 'productSearch batchRestAPIURL >>> ' + batchRestAPIURL);

        Map<String, Object> batchRequest = new Map<String, Object>();

        System.debug('searchSkusWords size = ' + skus.size());

        // Create a batch request for each set of 20 search skus words

        Integer count = 0;

        Set<String> searchSkus = new Set<String>();

        List<Object> batchRequestList = new List<Object>();

        for(String sku : skus) {
            count++;

            searchSkus.add(sku);

            if(searchSkus.size() == MAX_SEARCH_SKUS) {
                Map<String, Object> searchRequest = createSearchRequest(searchSkus, 'GET', restAPIURL);

                batchRequestList.add(searchRequest);

                searchSkus = new Set<String>();
            }

            if(batchRequestList.size() >= MAX_SUBREQUESTS) {

                String response = submitBatchrequest(batchRestAPIURL, batchRequestList);

                Map<String, String> temp = processBatchResults(response);

                validSkuMap.putAll(temp);

                batchRequestList = new List<Object>();

            }
        }

        // Process whatever search skus that remain

        if(searchSkus.size() > 0) {

            Map<String, Object> searchRequest = createSearchRequest(searchSkus, 'GET', restAPIURL);
            batchRequestList.add(searchRequest);
        }

        // Process the search requests that remain

        if(batchRequestList.size() > 0) {
            String response = submitBatchrequest(batchRestAPIURL, batchRequestList);

            Map<String, String> temp = processBatchResults(response);

            validSkuMap.putAll(temp);
        }

        System.debug('validSkus: ' + JSON.serialize(validSkuMap));

        // List<String> skuList = new List<String>();
        // skuList.addAll(validSkus);

        // System.debug('skuList size: ' + skuList.size());

        return validSkuMap;

    }

    private static String submitBatchrequest(String batchRestAPIURL, List<Object> batchRequestList) {

        String response = '';

        Set<String> validSkus = new Set<String>();

        Map<String, Object> batchInput = new Map<String, Object>();

        batchInput.put('batchRequests', batchRequestList);

        HttpRequest httpRequest = new HttpRequest();  
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        httpRequest.setEndpoint(batchRestAPIURL);

        String requestBody = JSON.serialize(batchInput);

        System.debug(LoggingLevel.DEBUG, 'requestBody >>> ' + requestBody);

        httpRequest.setBody(requestBody);

        try {
            Http http = new Http();
            HttpResponse httpResponse = http.send(httpRequest);

            System.debug('httpResponse.getStatusCode(): ' + httpResponse.getStatusCode());

            if (httpResponse.getStatusCode() == 200 || httpResponse.getStatusCode() == 201 ) {

                //System.debug('body: ' + httpResponse.getBody());

                response = httpResponse.getBody();

            } else {
                System.debug(LoggingLevel.ERROR, 'httpResponse >>> ' + httpResponse.getBody() );
                throw new CalloutException( httpResponse.getBody() );
            }
        } catch( System.Exception e) {
                System.debug(LoggingLevel.ERROR, 'ERROR: '+ e.getMessage());
        }

        System.debug(' ** response ** : ' + response );

        return response;

    }

    private static Map<String, String> processBatchResults(String response) {

        Map<String, String> validSkuMap = new Map<String, String>();

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response);

        Boolean hasErrors = (Boolean)responseMap.get('hasErrors');

        List<Object> resultsList = (List<Object>)responseMap.get('results');

        for(Object obj : resultsList) {

            Map<String, Object> resultsMap = (Map<String, Object>)obj;

            if(hasErrors == false) {

                Map<String, Object> result = (Map<String, Object>)resultsMap.get('result');

                List<Object> products = (List<Object>)result.get('products');

                Iterator<Object> productsIterator = products.iterator();

                while(productsIterator.hasNext()) {
                    
                    Map<String, Object> product = (Map<String, Object>) productsIterator.next();

                    Boolean success = Boolean.valueOf(product.get('success'));

                    if(!success) continue;
                    
                    String productId = String.valueOf(product.get('id'));
                    String sku = String.valueOf(product.get('sku'));

                    validSkuMap.put(sku, productId);
                }

            }
            else {

                List<Object> results = (List<Object>)resultsMap.get('result');

                for(Object obj3 : results) {
                    Map<String, Object> result = (Map<String, Object>)obj3;

                    String message = (String)result.get('message');

                    System.debug(message);
                }

            }

        }

        return validSkuMap;

    }

    /*
        Creates a products search batch request.
        Maximum of 20 skus words separate with comma.
        More about this request: https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_commerce_webstore_products.htm
    */
    private static Map<String, Object> createSearchRequest(Set<String> skusSet, String method, String url) {

        Map<String, Object> batchRequest = new Map<String, Object>();
        batchRequest.put('method', method);

        Set<String> fieldsSet = new Set<String> {
            'StockKeepingUnit'
        };

        Boolean excludeMedia = true;
        Boolean excludePrices = true;
        String fields = String.join(new List<String>(fieldsSet), ',');
        String skus = String.join(new List<String>(skusSet), ',');

        List<String> requestParameters = new List<String> {
            String.valueOf(excludeMedia),
            String.valueOf(excludePrices),
            fields,
            skus
        };

        System.debug('searchSkus: ' + skus);

        String unifiedParameters = String.format('&excludeMedia={0}&excludePrices={1}&fields={2}&skus={3}', requestParameters);
        batchRequest.put('url', url + unifiedParameters);

        return batchRequest;
    }

}