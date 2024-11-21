/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
@IsTest
global class fan_CartUploadProductSearchRestApiMock implements HttpCalloutMock {
    
    public String responseStr {get; set;}
    final Integer MAX_PRODUCT_CHUNCK = 100;

    public fan_CartUploadProductSearchRestApiMock(List<Product2> productObjList) {

        Map<String, Object> responseMap = new Map<String, Object>();

        responseMap.put('hasErrors', false);

        List<Object> resultsList = new List<Object>();

        Map<String, Object> resultsMap = new Map<String, Object>();

        Map<String, Object> resultMap = new Map<String, Object>();

        List<Object> productsList = new List<Object>();
        Integer productsCounter = 0;

        for (Product2 productObj : productObjList) {

            productsCounter++;
            
            Map<String, Object> productMap = new Map<String, Object>();

            productMap.put('id', productObj.Id);
            productMap.put('sku', productObj.StockKeepingUnit);
            productMap.put('fields', new Map<String, String> {
                'StockKeepingUnit' => productObj.StockKeepingUnit
            });
            productMap.put('success', true);

            productsList.add(productMap);

            if(productsCounter == MAX_PRODUCT_CHUNCK) {

                resultMap.put('products', productsList);
                resultMap.put('total', productsList.size());

                resultsMap.put('statusCode', 201);
                resultsMap.put('result', resultMap);

                resultsList.add(resultsMap);

                productsList = new List<Object>();
                resultMap = new Map<String, Object>();
                resultsMap = new Map<String, Object>();
                productsCounter = 0;
            }
        }

        if(!productsList.isEmpty()) {

            resultMap.put('products', productsList);
            resultMap.put('total', productsList.size());

            resultsMap.put('statusCode', 201);
            resultsMap.put('result', resultMap);

            resultsList.add(resultsMap);
        }

        responseMap.put('results', resultsList);

        responseStr = JSON.serialize(responseMap);

    }

    global HttpResponse respond(HttpRequest req) {

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.responseStr);
        res.setStatusCode(200);

        return res;
    }

}