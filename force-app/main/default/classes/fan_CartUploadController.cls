/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class fan_CartUploadController {

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getInfo(String userId, String effectiveAccountId, String communityId, String webstoreId) {

        System.debug('effectiveAccountId: ' + effectiveAccountId);

        Map<String, Object> responseMap = new Map<String, Object>();

        if(webstoreId == null) {
            webstoreId = fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);
        }

        String cartId = null;
        
        if(Test.isRunningTest() == false) {
            // Call the Connect Apex API

            if(effectiveAccountId != null && effectiveAccountId != '000000000000000'){
                ConnectApi.CartSummary cart = ConnectApi.CommerceCart.getOrCreateActiveCartSummary(webstoreId, effectiveAccountId, 'active');
                cartId = cart.cartId;
            }

        }

        responseMap.put('cartId', cartId);
        responseMap.put('webstoreId', webstoreId);

        responseMap.put('maxUploadRows', fan_B2BAddToCartUtil.MAX_UPLOAD_ROWS);

        return responseMap;

    }

    @AuraEnabled
    public static Map<String, Object> processData(
        String userId, 
        List<String> rows, 
        String webstoreId, 
        String effectiveAccountId, 
        String cartId, 
        Boolean hasHeaderRow, 
        Boolean ignoreInvalidSkus,
        Boolean emailResults,
        Boolean defaultBackorder) {

        System.debug('begin processData()');

        Long startTime = System.now().getTime();

        Map<String, Object> responseMap = new Map<String, Object>();

        Set<String> invalidSkuSet = new Set<String>();

        List<fan_B2BAddToCartUtil.ImportItem> itemsList = new List<fan_B2BAddToCartUtil.ImportItem>();
        Map<String, list<fan_B2BAddToCartUtil.ImportItem>> itemsByStatus = new Map<String, list<fan_B2BAddToCartUtil.ImportItem>>();

        System.debug('userId >>> ' + userId);
        System.debug('webstoreId >>> ' + webstoreId);
        System.debug('effectiveAccountId >>> ' + effectiveAccountId);
        System.debug('cartId >>> ' + cartId);
        System.debug('hasHeaderRow >>> ' + hasHeaderRow);
        System.debug('rows >>> ' + rows);
        System.debug('ignoreInvalidSkus >>> ' + ignoreInvalidSkus);
        System.debug('emailResults >>> ' + emailResults);

        //Savepoint sp = Database.setSavepoint();

        try {

            String activeCartOrId = cartId;

            List<ConnectApi.CartItemInput> linesToAdd = new List<ConnectApi.CartItemInput>();

            List<ConnectApi.BatchInput> batchInputList = new List<ConnectApi.BatchInput>();

            ConnectApi.BatchResult[] batchResults = null;

            fan_CartUploadService cartUploadService = getCartUploadService(webstoreId);
            itemsList = createItemList(rows, hasHeaderRow, defaultBackorder, cartUploadService);
            itemsByStatus = getItemsByStatus(itemsList);
          
            if (itemsByStatus.get('valid').isEmpty() && !verifyItems(itemsList)) {
                throw new fan_B2BAddToCartUtil.CustomException(Label.fan_B2B_CU_Invalid_SKUs_found);
            }

            System.debug('itemsList size = ' + itemsList.size());

            if (itemsList.size() > fan_B2BAddToCartUtil.MAX_UPLOAD_ROWS) {

                System.debug('Too many rows error');

                fan_B2BAddToCartUtil.addMessage(new fan_B2BAddToCartUtil.Message(
                    Label.fan_B2B_Cart_Upload_Processing_Error, 
                    Label.fan_B2B_CU_Max_Upload_Rows_Exceeded.replace('{0}', fan_B2BAddToCartUtil.MAX_UPLOAD_ROWS.format()), 
                    fan_B2BAddToCartUtil.ERROR), 
                    0, responseMap);

                fan_B2BAddToCartUtil.updateResponseMapTotalValue('totErrors', 1, responseMap);

                throw new fan_B2BAddToCartUtil.CustomException('Too many rows');
            }

            itemsList = itemsByStatus.get('valid');
            invalidSkuSet = verifySkus(itemsList, responseMap, webstoreId, effectiveAccountId);

            System.debug('invalidSkuSet size = ' + invalidSkuSet.size());

            if (invalidSkuSet.size() > 0) {

                // Invalid SKUs aren't included in subsequent processing, so totErrors is updated here.
                fan_B2BAddToCartUtil.updateResponseMapTotalValue('totErrors', invalidSkuSet.size(), responseMap);

                if (!ignoreInvalidSkus)
                    fan_B2BAddToCartUtil.addMessage(new fan_B2BAddToCartUtil.Message(
                        Label.fan_B2B_CU_Invalid_SKUs_found, 
                        Label.fan_B2B_CU_Please_correct_the_invalid_SKUs_and_resubmit, 
                        fan_B2BAddToCartUtil.ERROR), 
                        0, responseMap);
            }

            linesToAdd = cartUploadService.createCartItems(cartId, effectiveAccountId, itemsList, responseMap);

            System.debug('linesToAdd size = ' + linesToAdd.size());

            batchInputList = createBatchInputLines(linesToAdd, responseMap);

            System.debug('batchInputList size = ' + batchInputList.size());

            if(batchInputList.size() <= fan_B2BAddToCartUtil.ADD_TO_CART_MAX) {

                if(Test.isRunningTest() == false) {

                    // This will only work if there are less than 100 items in the input file.
                    // If the cart will contain more than 500 items, an error will be thrown.
                    batchResults = fan_B2BAddToCartUtil.addItemsToCart(webstoreId, effectiveAccountId, activeCartOrId, batchInputList);

                    System.debug('batchResults: ' + JSON.serialize(batchResults));

                    System.debug('batchResults size = ' + batchResults.size());

                    fan_B2BAddToCartUtil.processBatchResults(batchResults, itemsList, responseMap);

                    responseMap.put('totItems', batchInputList.size());
                }
                else {

                    fan_B2BAddToCartUtil.processBatchResults(batchResults, itemsList, responseMap);

                    // Pretend we called the Connect Api
                    responseMap.put('totItems', linesToAdd.size());
                }

            } else {
                itemsList = addItemsToCartInBatches(webstoreId, effectiveAccountId, activeCartOrId, batchInputList, itemsList, responseMap);
            }
            fan_B2BAddToCartUtil.updateCartItemsAfterInsert(itemsList);

            Integer totErrors = (Integer)responseMap.get('totErrors');
            if(totErrors > 0) {
                processAddToCartErrors(itemsList, responseMap);
            }

        }
        catch (fan_B2BAddToCartUtil.CustomException ce) {

            Set<String> handledCustomExceptions = new Set<String> {
                Label.fan_invalidBackorder,
                Label.fan_invalidQuantity,
                Label.fan_invalidCPACode
            };

            System.debug(Label.fan_B2B_Cart_Upload_Processing_Error + ': ' + ce.getMessage());
            System.debug('Line #: ' + ce.getLineNumber());
            System.debug(ce.getStackTraceString());

            if(handledCustomExceptions.contains(ce.getMessage())) {
                fan_B2BAddToCartUtil.addMessage(new fan_B2BAddToCartUtil.Message(
                        Label.fan_B2B_Cart_Upload_Processing_Error, 
                        ce.getMessage(),
                        fan_B2BAddToCartUtil.ERROR,
                        false), 
                        0, responseMap);
                fan_B2BAddToCartUtil.updateResponseMapTotalValue('totErrors', 1, responseMap);
            }
        }
        catch (Exception err) {

            //System.debug('rolling back transactions');
            //Database.rollback(sp);

            System.debug(Label.fan_B2B_Cart_Upload_Processing_Error + ': ' + err.getMessage());
            System.debug('Line #: ' + err.getLineNumber());
            System.debug(err.getStackTraceString());

            fan_B2BAddToCartUtil.addMessage(new fan_B2BAddToCartUtil.Message(
                    Label.fan_B2B_Cart_Upload_Processing_Error, 
                    err.getMessage(),
                    fan_B2BAddToCartUtil.ERROR), 
                    0, responseMap);

            fan_B2BAddToCartUtil.updateResponseMapTotalValue('totErrors', 1, responseMap);

        } finally {
            fan_B2BAddToCartUtil.ImportItem[] itemsWithErrors = (itemsByStatus.get('errors') == null)? new fan_B2BAddToCartUtil.ImportItem[]{} : itemsByStatus.get('errors');
            fan_B2BAddToCartUtil.ImportItem[] itemsSummarised = itemsList;
            if (!itemsWithErrors.isEmpty()) {
                itemsList.addAll(itemsWithErrors);
                itemsSummarised = summariseItems(itemsList);
            }
            ErrorRowsResponse errorRowsResponse = getRowsWithError(itemsSummarised);
            String totalRowsWithError =  errorRowsResponse.getTotal().format();
            String rowsWithErrorMessage = errorRowsResponse.getRowsByItemsMessage();
            set<String> errorRowMessages = errorRowsResponse.getErrorMessages(); 

            Integer totErrors = (Integer)responseMap.get('totErrors');
            Integer totSuccess = (Integer)responseMap.get('totSuccess');

            if(errorRowsResponse.getTotal() > 0) {

                for (String errorMessage : errorRowMessages) {
                    fan_B2BAddToCartUtil.addMessage(new fan_B2BAddToCartUtil.Message(
                        Label.fan_B2B_Cart_Upload_Processing_Error, 
                        errorMessage,
                        fan_B2BAddToCartUtil.ERROR,
                        false), 
                        0, responseMap);
                }

                fan_B2BAddToCartUtil.addMessage(new fan_B2BAddToCartUtil.Message(
                    Label.fan_B2B_Cart_Upload_Processing_Error, 
                    Label.fan_B2B_Items_not_added_to_cart.replace('{0}',totalRowsWithError).replace('{1}', rowsWithErrorMessage), 
                    fan_B2BAddToCartUtil.ERROR,
                    true), 
                    0, responseMap);
            }

            if(totSuccess > 0) {

                fan_B2BAddToCartUtil.addMessage(new fan_B2BAddToCartUtil.Message(
                    Label.fan_B2B_Add_to_cart_processing_complete, 
                    Label.fan_B2B_Items_added_to_cart_successfully.replace('{0}', totSuccess.format()), 
                    fan_B2BAddToCartUtil.SUCCESS,
                    true), 
                    0, responseMap);
            }

            List<fan_B2BAddToCartUtil.Message> retMessages = (List<fan_B2BAddToCartUtil.Message>)responseMap.get('messages');

            String messagesJson = JSON.serialize(retMessages);
            System.debug('messagesJson: ' + messagesJson);
            responseMap.put('messagesJson', messagesJson);

            if(emailResults) {
                sendEmailSummary(itemsList, responseMap, userId);
            }

            Long endTime = System.now().getTime();

            Long milliseconds = endTime - startTime;
            Long seconds = milliseconds / 1000;
            Long minutes = seconds / 60;
            Long hours = minutes / 60;
            Long days = hours / 24;

            System.debug('execution time: ' + (days > 0 ? days + ' days, ' : '') + (hours > 0 ? hours + ' hours, ' : '') + (minutes > 0 ? minutes + ' minutes, ' : '') + (seconds > 0 ? seconds + ' seconds, ' : '') + milliseconds + ' milliseconds');


            System.debug('--- processData() exit');
        }

        return responseMap;

    }

    private static ErrorRowsResponse getRowsWithError(List<fan_B2BAddToCartUtil.ImportItem> rows){
        RowError[] rowsError = new List<RowError>();
        RowError rowError;
        for (fan_B2BAddToCartUtil.ImportItem row : rows) {
            if (String.isNotBlank(row.errorMsg)) {
                rowError = new RowError();
                rowError.row = row.row;
                rowError.error = row.errorMsg;
                rowsError.add(rowError);
            }
        }
        ErrorRowsResponse response = new ErrorRowsResponse(rowsError);

        return response;
    }

    class ErrorRowsResponse{
        private Integer total {get; set;}
        private RowError[] rows {get; set;}

        public ErrorRowsResponse(RowError[] rows) {
            this.total = rows.isEmpty() ? 0 : rows.size();
            this.rows = rows;
        }

        public Integer getTotal() {
            return total;
        }

        public set<String> getErrorMessages() {
            Set<String> errorMessages = new Set<String>();
            for(RowError rowError : rows) {
                errorMessages.add(rowError.error);
            }
            return errorMessages;
        }

        public String getRowsByItemsMessage() {
            String message = '';
            Integer index = 0;
            Integer maxToShow = 10;
            for (RowError item : rows) {

                if (index == maxToShow) {
                    message +='+('+(total - maxToShow)+')';
                    break;
                }

                if (total > 1 && total <= maxToShow && (total - index) == 1) {
                    message +=' y '+item.row + '.'; 
                    break;
                } 

                message += item.row + ((total == 1 || (total - index) == 1) ? '': ', ');
                
                index++;
            }
            return message;
        }    
    }
    
    class RowError {
        private Integer row {get; set;}
        private String error {get; set;}
    }
    /*
        Process each line uploaded by the user.
        Creates an ImportItem object for each line.
        Returns a list of ImportItem objects.
    */
    private static List<fan_B2BAddToCartUtil.ImportItem> createItemList(
        List<String> lines,
        Boolean hasHeaderRow,
        Boolean defaultBackorder,
        fan_CartUploadService cartUploadService
      ) {
          Integer row = 0;
          if (hasHeaderRow) {
            row++;
            lines.remove(0);
          }

          String[] references = fan_B2BAddToCartUtil.getValueByLines(lines, 0);
        
          Map<String, String> skuByReference = fan_B2BAddToCartUtil.getProductSkuByReference(
          new Set<String>(references)
          );

          fan_B2BAddToCartUtil.ImportItem[] itemsList = cartUploadService.buildItemList(
            lines,
            row,
            defaultBackorder,
            skuByReference
          );
    
          System.debug('createItemList itemsList >>> ' + JSON.serialize(itemsList));
          return itemsList;
      }

    /**
    * @description Allows us to know whether items are valid (true) or not (false).
    * @author Kevin Vega H | 05-30-2024 
    * @param itemsList 
    * @return Boolean 
    **/
    public static Boolean verifyItems(List<fan_B2BAddToCartUtil.ImportItem> itemsList) {
        for (fan_B2BAddToCartUtil.ImportItem item : itemsList) {
            if (String.isNotBlank(item.errorMsg)) {
                return false;
            }
        }
        return true;
    }

    /**
    * @description allows us to get the first elements found in a item list with non unique rows.
    * @author Kevin Vega H | 06-10-2024 
    * @param itemsList 
    * @return fan_B2BAddToCartUtil.ImportItem[] 
    **/
    public static fan_B2BAddToCartUtil.ImportItem[] summariseItems(List<fan_B2BAddToCartUtil.ImportItem> itemsList){
        Map<Integer,fan_B2BAddToCartUtil.ImportItem> itemsSummarised = new Map<Integer,fan_B2BAddToCartUtil.ImportItem>();
        for (fan_B2BAddToCartUtil.ImportItem item : itemsList) {
            if (itemsSummarised.containsKey(item.row)) {
                continue;
            }
            itemsSummarised.put(item.row, item);   
        }
        return itemsSummarised.values();
    }

    /**
    * @description allows us to get sku items by status.
    * @author Kevin Vega H | 06-07-2024 
    * @param itemsList 
    * @return Map<String, list<fan_B2BAddToCartUtil.ImportItem>> 
    **/
    private static Map<String, list<fan_B2BAddToCartUtil.ImportItem>> getItemsByStatus(List<fan_B2BAddToCartUtil.ImportItem> itemsList) {
        Map<String, list<fan_B2BAddToCartUtil.ImportItem>> itemsByStatus = new Map<String, list<fan_B2BAddToCartUtil.ImportItem>>();

        list<fan_B2BAddToCartUtil.ImportItem> errors = new list<fan_B2BAddToCartUtil.ImportItem>();
        list<fan_B2BAddToCartUtil.ImportItem> valid = new list<fan_B2BAddToCartUtil.ImportItem>();
        for (fan_B2BAddToCartUtil.ImportItem item : itemsList) {
            if (String.isNotBlank(item.errorMsg)) {
                errors.add(item);
            }else{
                valid.add(item);
            }
        }

        itemsByStatus.put('valid', valid);
        itemsByStatus.put('errors', errors);

        return itemsByStatus;
    }

    /*
        Verifies that each SKU in the input is contained in the product search index.
        This does not take into account data changes within the org that have not yet been reflected in the product search index.
    */
    private static Set<String> verifySkus(List<fan_B2BAddToCartUtil.ImportItem> itemsList, Map<String, Object> responseMap, String webstoreId, String effectiveAccountId) {
        List<String> skuList = new List<String>();
        Set<String> invalidSkuSet = new Set<String>();

        Map<String, Object> fetchInputData = new Map<String, Object>();

        // Get all SKUs from the items List

        for(fan_B2BAddToCartUtil.ImportItem item : itemsList) {
            skuList.add(item.sku);
        }

        Map<String, String> validSkuMap = fan_B2BProductEntitlementCheck.productSearch(skuList, webstoreId, effectiveAccountId);

        // Verify each SKU in the item List has a matching Product2 record.
        String sku, msg;
        for(fan_B2BAddToCartUtil.ImportItem item : itemsList) {
            sku = item.sku;

            if(validSkuMap.containsKey(sku)) {
                item.isValid = true;
                item.productId = validSkuMap.get(sku);
            }
            else {
                invalidSkuSet.add(sku);
                msg = 'Invalid SKU: ' + sku;
                item.isSuccess = false;
                item.errorMsg = Label.fan_B2B_SKU_is_not_valid;
            }
        }

        responseMap.put('totUniqueSkus', validSkuMap.size());
        responseMap.put('totInvalidSkus', invalidSkuSet.size());

        return invalidSkuSet;
    }
    
    private static void processAddToCartErrors(List<fan_B2BAddToCartUtil.ImportItem> itemsList, Map<String, Object> responseMap) {
        
        for(fan_B2BAddToCartUtil.ImportItem item : itemsList) {
        
            // Only add an error message when the SKU was valid.
            
            if(item.isValid && item.isSuccess == false) {

                fan_B2BAddToCartUtil.addMessage(new fan_B2BAddToCartUtil.Message(
                    Label.fan_B2B_Add_to_cart_error, 
                    item.sku + ': ' + item.errorMsg, 
                    fan_B2BAddToCartUtil.ERROR,
                    false), 
                    0, responseMap);
            }
        }
    }

    /*
        Creates a BatchInput object for each CartInputItem.
        Returns a list of BatchInput objects.
    */
    private static List<ConnectApi.BatchInput> createBatchInputLines(List<ConnectApi.CartItemInput> linesToAdd, Map<String, Object> responseMap) {
        List<ConnectApi.BatchInput> batchInputList = new List<ConnectApi.BatchInput>();
        for (ConnectApi.CartItemInput item : linesToAdd) {
            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(item);
            batchInputList.add(batchInput);
        }

        return batchInputList;
    }

    /*
        Adds the items to the cart synchronously, in bundles of 100 items.
    */
    private static List<fan_B2BAddToCartUtil.ImportItem> addItemsToCartInBatches(String webstoreId, String effectiveAccountId, String activeCartOrId, List<ConnectApi.BatchInput> batchInputList, List<fan_B2BAddToCartUtil.ImportItem> itemsList, Map<String, Object> responseMap) {

        List<fan_B2BAddToCartUtil.ImportItem> processedItemsList = fan_B2BAddToCartUtil.processBatchInputItems(webstoreId, effectiveAccountId, activeCartOrId, batchInputList, itemsList, responseMap);

        Integer totBatches = (Integer)responseMap.get('totBatches');

        responseMap.put('batchCount', totBatches);

        return processedItemsList;

    }

    private static void sendEmailSummary(List<fan_B2BAddToCartUtil.ImportItem> itemsList, Map<String, Object> responseMap, String userId) {

        String emailBody = '';

        Integer totErr = 0;
        Integer totProc = itemsList.size();

        List<fan_B2BAddToCartUtil.Message> messages = (List<fan_B2BAddToCartUtil.Message>)responseMap.get('messages');

        for(fan_B2BAddToCartUtil.Message msg : messages) {
            emailBody += '<p>' + msg.message + '</p>';
        }

        String subject = Label.fan_B2B_Add_to_cart_subject;

        String emailAddress = fan_B2BAddToCartUtil.getUserEmailAddress(userId);

        fan_B2BAddToCartUtil.sendEmailMsg(subject, emailBody, emailAddress);

    }

    static fan_CartUploadService getCartUploadService(String webstoreId) {

        fan_CartUploadService cartUploadService;

        fan_IdTienda__mdt idTiendaMdt = fan_B2BUtils.getIdTiendaMdt(webstoreId, fan_IdTienda__mdt.fan_IdTienda__c);
        if(idTiendaMdt.DeveloperName == fan_Constants.StoreDeveloperName.MOTOS.name()) {
            cartUploadService = new fan_MotosCartUploadService();
        } else if(idTiendaMdt.DeveloperName == fan_Constants.StoreDeveloperName.POSVENTA.name()) {
            cartUploadService = new fan_PosventaCartUploadService();
        } else {
            throw new CartUploadServiceNotFoundException(Label.fan_CartUploadServiceNotFoundVM);
        }
        return cartUploadService;
    }
    
    public class CartUploadServiceNotFoundException extends Exception {}
}