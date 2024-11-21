public with sharing class fan_B2BCartCtrl {

    // For unit test
    public static ConnectApi.CartSummary testCartSummary;
    public static ConnectApi.CartItem testCartItem;
    public static ConnectApi.CartItemCollection testCartItemCollection;

  /**
   * @description Demonstrates how to call ConnectApi.CommerceCart.getCartSummary
   * @param  communityId The Id of the community from which the call originated
   * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
   */
    @AuraEnabled
    public static ConnectApi.CartSummary getCartSummary(
        String communityId,
        String effectiveAccountId
    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId = fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
        return fan_B2BCartCtrlUtils.getCurrentCartSummary(webstoreId, effectiveAccountId);
    }

    @AuraEnabled
    public static void addToCart(
        String communityId,
        String effectiveAccountId,
        String contactPointAddressCode,
        CartItem cartItem
    ) {
      try {
        String webstoreId = fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);
        String OrderSegmentation = [SELECT fan_OrderSegmentationGroup__c FROM  Product2 WHERE id =: cartItem.product2Id].fan_OrderSegmentationGroup__c;
		    ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();
		    cartItemInput.productId = cartItem.product2Id;
		    cartItemInput.quantity = String.valueOf(cartItem.quantity);
		    cartItemInput.type = ConnectApi.CartItemType.PRODUCT;

        if(String.isBlank(contactPointAddressCode)) {
          fan_B2BCartCtrlUtils.addToCart(webstoreId, effectiveAccountId, cartItemInput, new CartItem(
            fan_IsBackorder__c = cartItem.fan_IsBackorder__c,fan_OrderSegmentationGroup__c=OrderSegmentation
          ));
        } else {
		      System.debug(LoggingLevel.DEBUG, 'addToCart .. CPA Info >>> ' + contactPointAddressCode);

          fan_B2BCartCtrlUtils.addToCart(webstoreId, effectiveAccountId, cartItemInput, cartItem, contactPointAddressCode);
        }
        fan_B2BCartCtrlUtils.validateEmptyCDG(webstoreId, effectiveAccountId);
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    }

    @TestVisible
    static void updateCartItemBackorder(ConnectApi.AbstractCartItem abstractCartItem, Boolean backorder) {
        
        if(abstractCartItem != null) {
            String cartItemId = abstractCartItem.cartItemId;
            try {
                CartItem ci = [SELECT Id FROM CartItem WHERE Id =: cartItemId];
                ci.fan_IsBackOrder__c = backorder == true;
                update ci;
            } catch (Exception e) {
                throw new AuraHandledException(e.getStackTraceString());
            }
        }
    }

    @AuraEnabled
    public static void updateCartItemsBackorder(List<CartItem> cartItemsList) {
      try {
        update cartItemsList;
      } catch (Exception e) {
        throw new AuraHandledException(e.getStackTraceString());
      }
    }

  /**
   * @description Demonstrates how to call ConnectApi.CommerceCart.getCartItems
   * @param  communityId The Id of the community from which the call originated
   * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
   * @param activeCartOrId ID of the cart, active, or current.
   * @param pageParam Specifies the page token to be used to view a page of information.
   * @param sortParam Sort order for items in a cart.
   * @return fan_B2BCartCtrlUtils.CartItemCollectionWrapper A collection of cart items
   */
  @AuraEnabled
  public static fan_B2BCartCtrlUtils.CartItemCollectionWrapper getCartItems(
    String communityId,
    String effectiveAccountId,
    String activeCartOrId,
    String pageParam,
    Integer pageSize,
    String sortParam
  ) {
    String fields = 'Referencia__c';

    // Get the ConnectApi.CartItemSortOrder enum value from string.
    // For the list of possible values, see:
    // see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/connectAPI_enums.htm#cartItemSortOrderEnum
    ConnectApi.CartItemSortOrder resolvedSortParam = fan_B2BUtils.resolveSortParam(
      sortParam
    );

    Webcart cart = [SELECT WebStoreId, fan_TipoPedido__c, AccountId FROM WebCart WHERE Id =: activeCartOrId];

    // Validate order type and update cart item prices.
    fan_B2BOrderTypeValidation orderTypeValidation = fan_B2BCartCtrlUtils.resolveOrderTypeAndPrices(cart.AccountId, cart);

    // For more details, see:
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
    ConnectApi.CartItemCollection cartItemCollection = Test.isRunningTest() ? testCartItemCollection : ConnectApi.CommerceCart.getCartItems(cart.webstoreId, cart.AccountId, activeCartOrId, fields, pageParam, pageSize, resolvedSortParam);

    Map<Id, CartItem> cartItems = fan_B2BCartCtrlUtils.extractAndGetCartItems(cartItemCollection.cartItems);

    List<fan_B2BCartCtrlUtils.CartItemResultWrapper> cirwList = fan_B2BCartCtrlUtils.mapCartItemResult(cartItemCollection.cartItems, cartItems);

    // Build CartItemCollectionWrapper and serialize it.
    fan_B2BCartCtrlUtils.CartItemCollectionWrapper cartItemCollectionWrapper = new fan_B2BCartCtrlUtils.CartItemCollectionWrapper(cirwList, cartItemCollection.cartSummary, cartItemCollection.nextPageToken);
    cartItemCollectionWrapper.orderTypeValidation = orderTypeValidation;
    System.debug(LoggingLevel.DEBUG, 'getCartItems Cart Items to return >>> '+cartItemCollectionWrapper);
    return cartItemCollectionWrapper;
  }

  /**
   * @return The cart item with updated price.
   */
  @AuraEnabled
  public static Map<String, CartItem> updateCartItemQuantity(
    String cartId,
    String cartItemId,
    Decimal quantity
  ) {
    try {
      String category = [SELECT Product2.fan_Category__c FROM CartItem WHERE Id =: cartItemId].Product2.fan_Category__c;

      Map<String, CartItem> cartItems = new Map<String, CartItem>([SELECT Product2.fan_Category__c, Product2.fan_Brand__c, Product2.fan_ProductType__c, Quantity FROM CartItem
                                                                  WHERE CartId = :cartId AND Product2.fan_Category__c = :category]);
      CartItem cartItem = cartItems.get(cartItemId);
      cartItem.Quantity = quantity;

      fan_B2BCartCtrlUtils.updateCartItemPrices(cartId, cartItems.values());
      return new Map<String, CartItem>(cartItems);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @description Demonstrates how to call ConnectApi.CommerceCart.createCart
   * @param  communityId The Id of the community from which the call originated
   * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
   */
  @AuraEnabled
  public static ConnectApi.CartSummary createCart(
    String communityId,
    String effectiveAccountId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = Test.isRunningTest() ? null : fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);
    ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
    cartInput.effectiveAccountId = effectiveAccountId;
    // For more details, see:
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
    return Test.isRunningTest() ? testCartSummary : ConnectApi.CommerceCart.createCart(webstoreId, cartInput);
  }

  /**
   * @description Demonstrates how to call ConnectApi.CommerceCart.deleteCartItem
   * @param  communityId The Id of the community from which the call originated
   * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
   * @param cartId ID of the cart.
   * @param cartItemId ID of the cart item to be deleted.
   */
  @AuraEnabled
  public static Map<String, CartItem> deleteCartItem(
    String communityId,
    String effectiveAccountId,
    String cartId,
    String cartItemId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = Test.isRunningTest() ? null : fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

    // CartItem to delete.
    CartItem cartItem = [SELECT CartDeliveryGroupId, Product2.fan_Category__c FROM CartItem WHERE Id =: cartItemId];

    // For more details, see:
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
    if(!Test.isRunningTest()) {
      ConnectApi.CommerceCart.deleteCartItem(webstoreId, effectiveAccountId, cartId, cartItemId); //1. This method from the CommerceCart Class is deleting all CartItemPriceAdjustments in the cart
    } else {
      DELETE cartItem;
    }
    // Delete or update a cartDeliveryGroup if it is only related with to the cartItem to be deleted.
    fan_B2BCartCtrlUtils.handleDeleteCartDeliveryGroup(cartId, cartItem.CartDeliveryGroupId, webstoreId, effectiveAccountId);

    CartItem[] cartItems = [SELECT Product2.fan_Category__c, Product2.fan_Brand__c, Product2.fan_ProductType__c, Quantity 
                            FROM CartItem WHERE CartId = :cartId ]; //2. Thats why I deleted the query that just brought the cartItems with the same product_category__c and now it creates all cartItemPriceAdjustments again. 
    fan_B2BCartCtrlUtils.updateCartItemPrices(cartId, cartItems);
    return new Map<String, CartItem>(cartItems);
  }

  /**
   * @description Demonstrates how to call ConnectApi.CommerceCart.deleteCart
   * @param  communityId The Id of the community from which the call originated
   * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
   * @param activeCartOrId ID of the cart, active, or current.
   */
  @AuraEnabled
  public static void deleteCart(
    String communityId,
    String effectiveAccountId,
    String activeCartOrId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = Test.isRunningTest() ? null : fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

    // For more details, see:
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
    if(!Test.isRunningTest()) ConnectApi.CommerceCart.deleteCart(webstoreId, effectiveAccountId, activeCartOrId);
  }

  /**
   * @description Update WebCart fan_TipoPedido__c.
   * @param cart The cart with the Id, fan_TipoPedido__c and WebStoreId.
   * @return A fan_B2BOrderTypeValidation with the validation result and fan_TipoPedido__c updated.
   */
  @AuraEnabled
  public static fan_B2BOrderTypeValidation updateOrderType(WebCart cart){

    fan_B2BOrderTypeValidation orderTypeValidation = new fan_B2BOrderTypeValidation();

    try {
      if(!String.isBlank(cart.fan_TipoPedido__c))
          orderTypeValidation = fan_B2BCartCtrlUtils.resolveOrderType(cart);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }

    return orderTypeValidation;
  }

  /**
   * @param cartId the cart id to update.
   * @param codigoVIN the codigo VIN value to update.
   */
  @AuraEnabled
  public static void updateCodigoVIN(String cartId, String codigoVIN){
    try {
      fan_B2BCartCtrlUtils.updateField(cartId, new Map<SObjectField, Object> {
        WebCart.fan_CodigoVIN__c => codigoVIN
      });
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @description update payment condition given a cart id and payment condition value.
   * @param cartId the cart id to update.
   * @param paymentCondition the payment condition value to update.
   */
  @AuraEnabled
  public static void updatePaymentCondition(String cartId, String paymentCondition){
    try {
      if(!String.isBlank(paymentCondition))
        fan_B2BCartCtrlUtils.updateField(cartId, new Map<SObjectField, Object> {
          WebCart.fan_FormaPago__c => paymentCondition
        });
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * @return A list of cart items with updated prices.
   */
  @AuraEnabled
  public static Map<String, CartItem> updateCartItemPrices(String cartId){
    try {
      CartItem[] cartItems = fan_B2BCartCtrlUtils.updateCartItemPrices(cartId);

      return new Map<String, CartItem>(cartItems);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void deleteCartCheckoutSession(String cartId) {
    List<CartCheckoutSession> currentCheckout = [SELECT Id FROM CartCheckoutSession WHERE WebCartId = :cartId];
    List<CartItem> deleteCarrier = [SELECT Id FROM CartItem WHERE CartId = :cartId AND Type = 'Charge'];
    if (currentCheckout.size() > 0) { DELETE currentCheckout; }
    if (deleteCarrier.size() > 0) { DELETE deleteCarrier; }
  }

  /**
   * @description Get a list of CartDeliveryGroups related to an Cart id.
   * If an OrderSummary id is provided, then the Cart id related to the orderSummary will be fetched.
   * @param orderSummaryOrCartId The OrderSummary or Cart Id.
   * @return A list of CartDeliveryGroups related to the Cart.
   */
  @AuraEnabled
  public static List<CartDeliveryGroup> getCartDeliveryGroups(String orderSummaryOrCartId){

    List<CartDeliveryGroup> cartDeliveryGroups = new List<CartDeliveryGroup>();

    try {
      String cartId = fan_B2BCartCtrlUtils.resolveCartId(orderSummaryOrCartId);

      if(String.isNotBlank(cartId)) {
        cartDeliveryGroups = fan_B2BCartCtrlUtils.getCartDeliveryGroups(cartId);
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return cartDeliveryGroups;
  }

  /**
  * @param cartId The Id of the WebCart.
  * @return A fan_CartSummaryCalculator.CartSummary with the results of calculations.
  */
  @AuraEnabled
  public static fan_CartSummaryCalculator.CartSummary getCartTotals(String cartId){
    try {
      return fan_CartSummaryCalculator.getCartTotals(cartId);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void updateMetodoPago(String cartId, String metodoPago){
    try {
      fan_B2BCartCtrlUtils.updateField(cartId, new Map<SObjectField, Object> {
        WebCart.fan_MetodoPago__c => metodoPago
      });
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
  @AuraEnabled
  public static void setAnticipo(Boolean anticipo, String cartId){
    try {
      System.debug('----------------------------INCIA ESANTICIPO--------------------------------');
      WebCart cart = [SELECT Id,fan_EsAnticipo__c FROM WebCart WHERE Id =: cartId ][0];
      cart.fan_EsAnticipo__c = anticipo;
      UPDATE cart;
      System.debug('----------------------------TERMINA ESANTICIPO--------------------------------');
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}