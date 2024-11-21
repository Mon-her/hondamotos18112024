/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class fan_B2BAddToCartUtil {

    public static final Integer ADD_TO_CART_MAX = 100;
    public static final Integer CART_ITEM_MAX = 500;
    public static final Integer MAX_UPLOAD_ROWS = 500;

    /*
        Adds items to the cart in batches of 100.
        The cart adds are done synchronously.
    */
    public static List<fan_B2BAddToCartUtil.ImportItem> processBatchInputItems(String webstoreId, String effectiveAccountId, String activeCartOrId, List<ConnectApi.BatchInput> batchInputList, List<fan_B2BAddToCartUtil.ImportItem> itemsList, Map<String, Object> responseMap) {

        List<ConnectApi.BatchInput> tempBatchList = new List<ConnectApi.BatchInput>();

        List<fan_B2BAddToCartUtil.ImportItem> tempItemsList = new List<fan_B2BAddToCartUtil.ImportItem>();

        List<fan_B2BAddToCartUtil.ImportItem> processedItemsList = new List<fan_B2BAddToCartUtil.ImportItem>();

        Iterator<ImportItem> itemsIterator = itemsList.iterator();
        Integer count = 0;
        Integer totBatches = 0;
        Integer totItems = 0;

        for(ConnectApi.BatchInput bi : batchInputList) {

            tempBatchList.add(bi);

            fan_B2BAddToCartUtil.ImportItem importItem;
            while (itemsIterator.hasNext() && !(importItem = itemsIterator.next()).isValid);
            tempItemsList.add(importItem);

            count++;

            totItems++;

            if(count == ADD_TO_CART_MAX) {

                totBatches++;

                addBatchToCart(webstoreId, effectiveAccountId, activeCartOrId, tempBatchList, tempItemsList, totBatches, responseMap);

                processedItemsList.addAll(tempItemsList);

                count = 0;

                tempBatchList = new List<ConnectApi.BatchInput>();

                tempItemsList = new List<fan_B2BAddToCartUtil.ImportItem>();

            }

        }

        if(tempBatchList.size() > 0) {

            totBatches++;

            addBatchToCart(webstoreId, effectiveAccountId, activeCartOrId, tempBatchList, tempItemsList, totBatches, responseMap);

            processedItemsList.addAll(tempItemsList);

        }

        responseMap.put('batchCount', totBatches);

        if(responseMap.containsKey('totItems')) {
            Integer tempTotItems = (Integer)responseMap.get('totItems');
            tempTotItems += totItems;
            responseMap.put('totItems', tempTotItems);
        }
        else {
            responseMap.put('totItems', totItems);
        }

        return processedItemsList;

    }

    /*
        Adds a batch of 100 or less items to the cart.
    */
    public static void addBatchToCart(String webstoreId, String effectiveAccountId, String activeCartOrId, List<ConnectApi.BatchInput> batchInputList, List<fan_B2BAddToCartUtil.ImportItem> itemsList, Integer batchCount, Map<String, Object> responseMap) {

        ConnectApi.BatchResult[] batchResults = null;

        if(Test.isRunningTest() == false) {
            batchResults = fan_B2BAddToCartUtil.addItemsToCart(webstoreId, effectiveAccountId, activeCartOrId, batchInputList);
        }

        fan_B2BAddToCartUtil.processBatchResults(batchResults, itemsList, responseMap);

    }
    
    public static ConnectApi.BatchResult[] addItemsToCart(String webstoreId, String effectiveAccountId, String activeCartOrId, List<ConnectApi.BatchInput> batchInputList) {

        System.debug('--- addItemsToCart() begin');

        System.debug('batchInputList size = ' + batchInputList.size());

        ConnectApi.BatchResult[] batchResults = ConnectApi.CommerceCart.addItemsToCart(webstoreId, effectiveAccountId, activeCartOrId, batchInputList);

        System.debug('batchResults size = ' + batchResults.size());

        System.debug('--- addItemsToCart() exit');

        return batchResults;
    }

    public static void processBatchResults(ConnectApi.BatchResult[] batchResults, List<ImportItem> itemsList, Map<String, Object> responseMap) {

        System.debug('--- processBatchResults() begin');

        Integer totErrors = 0;
        Integer totSuccess = 0;

        if(batchResults != null) {

            for(Integer i = 0; i < batchResults.size(); i++) {

                ConnectApi.BatchResult batchResult = batchResults[i];
                System.debug('batchResult: ' + JSON.serialize(batchResult));

                ImportItem importItem = itemsList[i];
                ConnectApi.CartItem cartItem;

                if(batchResult.getResult() instanceof ConnectApi.CartItem) {
                    cartItem = (ConnectApi.CartItem)batchResult.getResult();
                }

                if(cartItem != null) {

                    System.debug('cartItem: ' + JSON.serialize(cartItem));

                    if(batchResult.isSuccess == false) {

                        importItem.isSuccess = batchResult.isSuccess;
                        importItem.errorMsg = batchResult.getErrorMessage();

                        totErrors++;

                        System.debug('Error adding product ' + importItem.sku + ': ' + batchResult.getErrorMessage());
                    }
                    else {
                        importItem.isSuccess = true;
                        importItem.cartItemId = cartItem.cartItemId;

                        totSuccess++;
                    }

                }
                else {

                    // Handle add to cart error
                    
                    if(batchResult.isSuccess == false) {

                        importItem.isSuccess = batchResult.isSuccess;
                        importItem.errorMsg = batchResult.getErrorMessage();

                        totErrors++;

                        System.debug('Error adding product ' + importItem.sku + ': ' + batchResult.getErrorMessage());
                    }

                }

            }

        }

        // Modify the itemsList to look like the batchInputList was actually sent to the ConnectApi and processed.
        if(Test.isRunningTest()) {

            for(ImportItem importItem : itemsList) {
                importItem.isSuccess = true;
                totSuccess++;
            }

        }

        System.debug('totSuccess: ' + totSuccess);
        System.debug('totErrors: ' + totErrors);

        updateResponseMapTotalValue('totSuccess', totSuccess, responseMap);

        updateResponseMapTotalValue('totErrors', totErrors, responseMap);

        System.debug('--- processBatchResults() exit');

    }

    public static void sendEmailMsg(String subject, String emailBody, String emailAddress) {

        List<Messaging.SingleEmailMessage> mails =
                new List<Messaging.SingleEmailMessage>();

        Messaging.SingleEmailMessage mail =
                new Messaging.SingleEmailMessage();

        List<String> sendTo = new List<String>();
        sendTo.add(emailAddress);
        mail.setToAddresses(sendTo);

        mail.setSubject(subject);

        mail.setHtmlBody(emailBody);

        mails.add(mail);

        Messaging.sendEmail(mails);
    }

    public static String getUserEmailAddress(String userId) {

        String emailAddress = null;

        if(Schema.sObjectType.User.fields.Id.isAccessible() 
           && Schema.sObjectType.User.fields.Name.isAccessible()
           && Schema.sObjectType.User.fields.Email.isAccessible()){
            List<User> userList = [Select Id, Name, Email from User where Id = :userId];

            User user = userList.get(0);
            emailAddress = user.Email;
        }

        return emailAddress;
    }

    public static void addMessage(Message msg, Integer pos, Map<String, Object> responseMap) {

        List<fan_B2BAddToCartUtil.Message> retMessages = null;

        if(responseMap.containsKey('messages')) {
            retMessages = (List<fan_B2BAddToCartUtil.Message>)responseMap.get('messages');
        }
        else {
            retMessages = new List<fan_B2BAddToCartUtil.Message>();
        }

        if(pos == null) {
            retMessages.add(msg);
        }
        else if(retMessages.size() <= 0) {
            retMessages.add(msg);
        }
        else {
            retMessages.add(pos, msg);
        }

        responseMap.put('messages', retMessages);

    }

    public static void updateResponseMapTotalValue(String key, Integer value, Map<String, Object> responseMap) {

        if(responseMap.containsKey(key)) {
            Integer tempTot = (Integer)responseMap.get(key);
            tempTot += value;
            responseMap.put(key, tempTot);
        }
        else {
            responseMap.put(key, value);
        }

    }

    public class ImportItem {

        public String sku {get; set;}
        public Decimal qty {get; set;}
        public Boolean bo {get; set;}
        public String cpaCode {get; set;}
        public String cartItemId {get; set;}
        public String productId {get; set;}
        public Boolean isValid {get; set;}

        public Integer row {get; set;}

        public Boolean isSuccess {get; set;}
        public String errorMsg {
            set {
                if(value == null) return;

                final Map<String, String> HANDLE_ERRORS = new Map<String, String> {
                    '\'quantity\' [0] in the commerce.cart.AddItemRequest is not currently supported.' => Label.fan_invalidQuantity,
                    'common.exception.ApiException: Numeric Overflow' =>  Label.fan_highQuantity,
                    '\'product\' is not of a valid type \'VariationParent\'' => Label.fan_parentVariationError
                };

                String mappedErrorMsg = value;

                for (String error : HANDLE_ERRORS.keySet()) {
                    if(value.contains(error)) {
                        mappedErrorMsg = HANDLE_ERRORS.get(error);
                        break;
                    }
                }

                errorMsg = mappedErrorMsg;
            }
            
            get;
        }

        public ImportItem() {
            isValid = false;
            isSuccess = false;
        }
    }

    public static final String ERROR = 'error';
    public static final String INFO = 'info';
    public static final String SUCCESS = 'success';
    public static final String WARN = 'warn';

    public class Message {

        public String severity {get; set;}
        public String title {get; set;}
        public String message {get; set;}
        public Boolean toast {get; set;}

        public Message() {
            toast = true;
        }

        public Message(String title, String message, String severity) {
            this();
            this.title = title;
            this.message = message;
            this.severity = severity;
        }

        public Message(String title, String message, String severity, Boolean toast) {
            this();
            this.title = title;
            this.message = message;
            this.severity = severity;
            this.toast = toast;
        }

    }

    /**
    * @description allows us to get a list of a column values from a list of lines.
    * @author Kevin Vega H | 05-29-2024 
    * @param lines
    * @param columnIndex 
    * @return String[] 
    **/
    public static String[] getValueByLines(String[] lines, Integer columnIndex) {
        String[] values = new String[]{};
        String[] lineValues;
        for (String line : lines) {
            lineValues = line.split(',');
            if(!lineValues.isEmpty()) {
                values.add(lineValues[columnIndex].trim());
            }
        }
        return values;
    }
    /**
     * @param lines product rows.
     */
    public static Map<String,String> getProductSkuByReference(Set<String> references) {
        Map<String,String> skuByReference = new Map<String,String>();

        for (Product2 product : [SELECT StockKeepingUnit, Referencia__c FROM Product2 WHERE Referencia__c IN :references]) {
            skuByReference.put(product.Referencia__c, product.StockKeepingUnit);
        }
        return skuByReference;
    }

    public static void updateCartItemsAfterInsert(fan_B2BAddToCartUtil.ImportItem[] importItems) {

        CartItem[] cartItems = new List<CartItem>();
        for (fan_B2BAddToCartUtil.ImportItem importItem : importItems) {
            if(String.isNotBlank(importItem.cartItemId)) {
                cartItems.add(new CartItem(
                    Id = importItem.cartItemId,
                    fan_IsBackorder__c = importItem.bo
                ));
            }
        }
        UPDATE cartItems;
    }

    public class CustomException extends Exception {} 
}