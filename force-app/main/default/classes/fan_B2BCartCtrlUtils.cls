public with sharing class fan_B2BCartCtrlUtils {

  // Total number of valid products for emergency orders.
  public static final String EXEMPT_TAX = 'Impuesto_exento';
  static final String DEFAULT_CART_DELIVERY_GROUP_NAME = 'Default Delivery';
	// Developer name for posventa fan_IdTienda_mdt.
	static final String POSVENTA_DEVELOPER_NAME  = 'posventa';
	// Product fan_Category__c.
	static final String ROH_CATEGORY_NAME = 'REPUESTOS ORIGINALES HONDA';

	// For unit tests.
	@TestVisible
	static ConnectApi.CartItem testCartItem;
	@TestVisible
	static ConnectApi.CartSummary testCartSummary;

	public class CartItemCollectionWrapper {
		@AuraEnabled
		public List<CartItemResultWrapper> cartItems;
		@AuraEnabled
		public ConnectApi.CartSummary cartSummary;
		@AuraEnabled
		public String nextPageToken;
		@AuraEnabled
		public fan_B2BOrderTypeValidation orderTypeValidation;

		public CartItemCollectionWrapper(List<CartItemResultWrapper> cartItems, ConnectApi.CartSummary cartSummary, String nextPageToken) {
			this.cartItems = cartItems;
			this.cartSummary = cartSummary;
			this.nextPageToken = nextPageToken;
		}
	}


	public class CartItemResultWrapper {
		@AuraEnabled
		public CartItemWrapper cartItem;

		public CartItemResultWrapper(CartItemWrapper cartItem) {
			this.cartItem = cartItem;
		}
	}

	class SObjectTypeIdException extends Exception {}

	public class cartItemWrapper {
		@AuraEnabled
		public String cartItemId;
		@AuraEnabled
		public String name;
		@AuraEnabled
		public String quantity;
		@AuraEnabled
		public Boolean backorder;
		@AuraEnabled
		public CartDeliveryGroup cartDeliveryGroup;
		@AuraEnabled
		public String listPrice;
		@AuraEnabled
		public String salesPrice;
		@AuraEnabled
		public String unitAdjustedPrice;
		@AuraEnabled
		public String productId;
		@AuraEnabled
		public String totalPrice;
		@AuraEnabled
		public ConnectApi.CartItemProduct productDetails;
	}


	public static CartItemWrapper mapCartItem(ConnectApi.CartItem cartItem, CartItem ci) {
		CartItemWrapper ciw = new CartItemWrapper();
		ciw.cartItemId = cartItem.cartItemId;
		ciw.name = cartItem.name;
		ciw.quantity = cartItem.quantity;
		ciw.backorder = ci.fan_IsBackOrder__c;
		ciw.cartDeliveryGroup = ci.cartDeliveryGroup;
		ciw.listPrice = cartItem.listPrice;
		ciw.salesPrice = cartItem.salesPrice;
		ciw.unitAdjustedPrice = cartItem.unitAdjustedPrice;
		ciw.productId = cartItem.productId;
		ciw.totalPrice = cartItem.totalPrice;
		ciw.productDetails = cartItem.productDetails;
		return ciw;
	}

	public static List<CartItemResultWrapper> mapCartItemResult(List<ConnectApi.CartItemResult> cartItemResultList, Map<Id, CartItem> cartItems) {
		
		List<fan_B2BCartCtrlUtils.CartItemResultWrapper> cirwList = new List<fan_B2BCartCtrlUtils.CartItemResultWrapper>();

		for (ConnectApi.CartItemResult cir : cartItemResultList) {
			fan_B2BCartCtrlUtils.CartItemWrapper ciw = fan_B2BCartCtrlUtils.mapCartItem((ConnectApi.CartItem) cir.cartItem, cartItems.get(cir.cartItem.cartItemId));
			cirwList.add(new fan_B2BCartCtrlUtils.CartItemResultWrapper(ciw));
		}

		return cirwList;
	}

	public static Map<Id, CartItem> extractAndGetCartItems(ConnectApi.CartItemResult[] cartItemResultList) {

		// Obtain cart items ids
		Set<String> cartItemIds = new Set<String>();

		for (ConnectApi.CartItemResult cartItemResult : cartItemResultList) {
			cartItemIds.add(cartItemResult.cartItem.cartItemId);
		}
		return new Map<Id, CartItem>([SELECT CartDeliveryGroup.Name, CartDeliveryGroup.DeliverToCity, fan_IsBackorder__c FROM CartItem WHERE Id IN :cartItemIds]);
	}

	// Get a cart item with added fields
	public static CartItem getCartItem(Id cartItemId) {

		CartItem cartItem;

		try {
			cartItem = [SELECT CartDeliveryGroup.Name, fan_IsBackorder__c
						FROM CartItem
						WHERE Id =: cartItemId];
		} catch (Exception e) {
			throw new AuraHandledException(e.getStackTraceString());
		}
		return cartItem;
	}

	/**
	 * @description Deletes or updates a CartDeliveryGroup associate with the cartItem to be removed.
	 * @param cartId The id of the cart.
	 * @param cartDeliveryGroup The cartDeliveryGroup to work.
	 */
	public static void handleDeleteCartDeliveryGroup(String cartId, String cartDeliveryGroupId, String webstoreId, String effectiveAccountId) {
    Integer commonCartDeliveryGroups = [SELECT COUNT() FROM CartItem WHERE CartDeliveryGroupId =: cartDeliveryGroupId];
		// If there are cartItems that share the cartDeliveryGroup then exit the method.
    if(commonCartDeliveryGroups > 0) return;

    Integer totalCartDeliveryGroups = [SELECT COUNT() FROM CartDeliveryGroup WHERE CartId =: cartId];
		System.debug('totalCartDeliveryGroups >>> '+totalCartDeliveryGroups);
		// If this is the last cartDeliveryGroup, execute ConnectApi deleteCart method to delete cart and create new one with the default CDG
    if (totalCartDeliveryGroups == 1) {
			if (!Test.isRunningTest()) ConnectApi.CommerceCart.deleteCart(webstoreId, effectiveAccountId, cartId);
    } else {
			validateEmptyCDG(webstoreId, effectiveAccountId);
		}
	}

	public static void validateEmptyCDG(String webStoreId, String accountId){
		List<WebCart> carts = [SELECT Id FROM WebCart WHERE AccountId = :accountId AND WebStoreId = :webStoreId AND CreatedById = :UserInfo.getUserId() AND (Status = 'Active' OR Status = 'Checkout')];
		if (carts.size() > 0){
			List<CartDeliveryGroup> emptyDeliveryGroups = [SELECT Id FROM CartDeliveryGroup WHERE CartId =: carts[0].Id AND (TotalAmount = null OR TotalAmount = 0)];
			DELETE emptyDeliveryGroups;
		}
	}

	public static void updateField(String cartId, Map<SObjectField, Object> fields) {
		WebCart cart = new WebCart(Id = cartId);
		for(SObjectField field : fields.keySet()) {
			cart.put(field, fields.get(field));
		}
		UPDATE cart;
	}

	public static CartItem[] updateCartItemPrices(String cartId) {
		CartItem[] cartItems = [SELECT Quantity, Product2.fan_Category__c, Product2.fan_Brand__c, Product2.fan_ProductType__c, SalesPrice, cartId FROM CartItem
								WHERE CartId =: cartId AND Type = :fan_Constants.CartItemType.PRODUCT.name()];

		return cartItems.size() > 0 ? updateCartItemPrices(cartId, cartItems) : cartItems;
	}

	public static CartItem[] updateCartItemPrices(String cartId, CartItem[] cartItems) {
		WebCart cart = [SELECT typeof Account WHEN Account THEN fan_condicionPago__c END, fan_FormaPago__c, fan_TipoPedido__c, Webstore.StrikethroughPricebookId,fan_EsAnticipo__c  
										FROM WebCart WHERE Id = :cartId];

		Set<String> productIds = (Set<String>) fan_B2BUtils.generateSet(CartItem.Product2Id, cartItems, Set<String>.class);
		fan_IdTienda__mdt idTiendaMdt = fan_B2BUtils.getIdTiendaMdt(cart.WebstoreId, fan_IdTienda__mdt.fan_IdTienda__c);
		if(idTiendaMdt.DeveloperName == POSVENTA_DEVELOPER_NAME) {
			String orderType = cart.fan_TipoPedido__c == null ? idTiendaMdt.fan_DefaultOrderType__c : cart.fan_TipoPedido__c;
			String pricebookName = orderType.split('_')[0];
			fan_B2BPriceHandler.applyPricesToPosventaCartItems(cart, pricebookName, cartItems, productIds);
		} else {
			fan_B2BPriceHandler.applyPricesToMotosCartItems(cart, cartItems, productIds);
		}
		UPDATE cartItems;
		return cartItems;
	}

	/**
	 * @description Given a Cart update the fan_TipoPedido__c if required and the prices of yours cart items.
	 * @param effectiveAccountId (For Motos Store) ID of the buyer account or guest buyer profile for which the request is made.
	 * If null, the default value is determined from context.
	 * @param cart The cart with the Id, fan_TipoPedido__c and WebStoreId.
	 * @return A fan_B2Bfan_B2BOrderTypeValidation with the validation result and fan_TipoPedido__c updated.
	 */
	public static fan_B2BOrderTypeValidation resolveOrderTypeAndPrices(String effectiveAccountId, WebCart cart) {

		// Resolve WebCart fan_TipoPedido__c.
		fan_B2BOrderTypeValidation orderTypeValidation = resolveOrderType(cart);
		System.debug(LoggingLevel.DEBUG, 'resolveOrderTypeAndPrices orderType >>> ' + orderTypeValidation.orderType);

		updateCartItemPrices(cart.Id);
		return orderTypeValidation;
	}

	/**
	 * @description Query a Card id related to an OrderSummary.
	 * @param orderSummaryId The OrderSummary id.
	 * @return The Cart id related to the OrderSummary.
	 */
	public static String getCartId(String orderSummaryId) {
		return [SELECT WebCartId FROM CartCheckoutSession
				WHERE OrderId IN (SELECT OriginalOrderId FROM OrderSummary WHERE Id =: orderSummaryId)]?.WebCartId;
	}

	/**
	 * @description Get the Cart id given an OrderSummary or Cart Id.
	 * @param The id of the OrderSummary or the Cart to process.
	 * @return The resolved cart id.
	 */
	public static String resolveCartId(String orderSummaryOrCartId) {

		String cartId;
      	SObjectType sObjectType = Id.valueOf(orderSummaryOrCartId).getSobjectType();

      	if(sObjectType == WebCart.getSobjectType()) {
      	  cartId = orderSummaryOrCartId;
      	} else if(sObjectType == OrderSummary.getSobjectType()) {
      	    cartId = fan_B2BCartCtrlUtils.getCartId(orderSummaryOrCartId);
      	} else {
      	  throw new SObjectTypeIdException('SObjectType Id is not as expected.');
      	}

		return cartId;
	}

	/**
	 * @description Query a CartDeliveryGroups list related to a Cart id.
	 * @param cartId The cart id.
	 * @return A list of cartDeliveryGroups related to a Cart.
	 */
	public static List<CartDeliveryGroup> getCartDeliveryGroups(String cartId) {
		return [SELECT Name, TotalProductAmount, TotalTaxAmount, TotalChargeAmount, GrandTotalAmount, ShippingInstructions FROM CartDeliveryGroup
				WHERE CartId =: cartId];
	}

	static Boolean allBelongToTheCategory(String category, List<CartItem> cartItems)  {
		for (CartItem cartItem : cartItems) {
			if(category != cartItem.Product2.fan_Category__c) {
				return true;
			}
		}
		return false;
	}

	/**
	 * @description Validates the WebCart fan_TipoPedido__c according to business logic.
	 * @param cart The cart with the Id, fan_TipoPedido__c and WebStoreId.
	 * @param cartItems A list of CartItems with the Product2.fan_Category__c field.
	 * @return A fan_B2BOrderTypeValidation with the validation result.
	 */
	public static fan_B2BOrderTypeValidation valitadeOrderType(WebCart cart) {

		String orderTypeValue = cart.fan_TipoPedido__c; // Save last value of the order type
		fan_B2BOrderTypeValidation.Builder orderTypeValidationBuilder = new fan_B2BOrderTypeValidation.Builder(cart.fan_TipoPedido__c);
		fan_IdTienda__mdt idTiendaMdt = fan_B2BUtils.getIdTiendaMdt(cart.WebstoreId, fan_IdTienda__mdt.fan_IdTienda__c);

		List<CartItem> cartItems = [SELECT Product2.fan_Category__c FROM CartItem WHERE CartId =: cart.Id AND Product2.StockKeepingUnit != null];
		fan_OrderTypeSetting__mdt orderTypeSetting = fan_OrderTypeSetting__mdt.getInstance(cart.fan_TipoPedido__c);

		if(cart.fan_TipoPedido__c == null) {
			orderTypeValue = idTiendaMdt.fan_DefaultOrderType__c;
			orderTypeValidationBuilder.setApplied(true);
		} else if(fan_Constants.OrderType.RMT_GARANTIA.name() == cart.fan_TipoPedido__c) {
			orderTypeValidationBuilder.setApplied(true)
			.setPaymentCondition(fan_Constants.FormaPago.CREDITO.name())
			.setIsPaymentConditionChangeable(false);
		} else if(orderTypeSetting?.DeveloperName == cart.fan_TipoPedido__c && cartItems.size() > orderTypeSetting.fan_MaximumProducts__c) {
			orderTypeValue = orderTypeSetting.fan_Fallback__c;
			orderTypeValidationBuilder.setApplied(true)
			.setShow(true)
			.setTitle(Label.fan_ineligibleOrderType)
			.setMessage(String.format(Label.fan_MaximumNumberOfElegibleItems, new List<Integer> { orderTypeSetting.fan_MaximumProducts__c.intValue() }));
		}

		final Set<String> F026OrderTypes = new Set<String> { fan_Constants.OrderType.RMT_GARANTIA.name(), fan_Constants.OrderType.EMM_EMERGENCIA.name()};
		if(F026OrderTypes.contains(orderTypeValue.toUpperCase()) && allBelongToTheCategory(ROH_CATEGORY_NAME, cartItems)) {
			orderTypeValue = idTiendaMdt.fan_DefaultOrderType__c;
			orderTypeValidationBuilder.setApplied(true)
			.setShow(true)
			.setTitle(Label.fan_ineligibleOrderType)
			.setMessage(Label.fan_F026CategoryError)
			.setIsPaymentConditionChangeable(true);
		}
		return orderTypeValidationBuilder.setOrderType(orderTypeValue).build();
	}

	/**
	 * @description Validate and update WebCart fan_TipoPedido__c.
	 * @param cart The cart with the Id, fan_TipoPedido__c and WebStoreId.
	 * @return An fan_B2BOrderTypeValidation with the validation result and fan_TipoPedido__c updated.
	 */
	public static fan_B2BOrderTypeValidation resolveOrderType(WebCart cart) {

		fan_B2BOrderTypeValidation orderTypeValidation = valitadeOrderType(cart);

		Map<SObjectField, Object> fields = new Map<SObjectField, Object> {
			WebCart.fan_TipoPedido__c => orderTypeValidation.orderType
		};
		if(orderTypeValidation.paymentCondition != null) {
			fields.put(WebCart.fan_FormaPago__c, orderTypeValidation.paymentCondition);
		}
		updateField(cart.Id, fields);
		return orderTypeValidation;
	}

	public static ConnectApi.CartSummary getCurrentCartSummary(String webstoreId, String effectiveAccountId) {
		// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_ConnectAPI_CommerceCart_static_methods.htm#apex_ConnectAPI_Commerce_.getCartSummary_1
		return Test.isRunningTest() ? testCartSummary : ConnectApi.Commercecart.getCartSummary(webstoreId, effectiveAccountId, 'current');
	}

    /**
     * @return The registered CartDeliveryGroup Id.
     */
    public static String upsertCartDeliveryGroup(String cartId, String effectiveAccountId, String contactPointAddressCode, String cartDeliveryGroupId) {

		ContactPointAddress contactPointAddress = [SELECT Name, City, Country, Street, State, PostalCode, GeocodeAccuracy, Latitude, Longitude, fan_Code__c
															FROM ContactPointAddress
															WHERE ParentId =: effectiveAccountId AND fan_Code__c =: contactPointAddressCode AND AddressType = 'Shipping'
															WITH SECURITY_ENFORCED];

		CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(
			Id = cartDeliveryGroupId,
			Name = contactPointAddress.Name,
			DeliverToName = contactPointAddress.Name,
			DeliverToStreet = contactPointAddress.Street,
			DeliverToCity = contactPointAddress.City,
			DeliverToCountry = contactPointAddress.Country,
			DeliverToState = contactPointAddress.State,
			DeliverToPostalCode = contactPointAddress.PostalCode,
			DeliverToGeocodeAccuracy = contactPointAddress.GeocodeAccuracy,
			DeliverToLatitude = contactPointAddress.Latitude,
			DeliverToLongitude = contactPointAddress.Longitude,
			fan_CPACode__c = contactPointAddressCode,
			cartid = cartId
		);
		UPSERT cartDeliveryGroup;

		return cartDeliveryGroup.Id;
    }

	/** @description Get the Id of a CartDeliveryGroup if it exists, otherwise create a new one or update the default. */
	static String resolveCartDeliveryGroup(String cartId, String effectiveAccountId, String contactPointAddressCode) {

		Map<String, CartDeliveryGroup> cartDeliveryGroups = new Map<String, CartDeliveryGroup>();
		for(CartDeliveryGroup cartDeliveryGroup : [SELECT fan_CPACode__c FROM CartDeliveryGroup WHERE cartId =: cartId WITH SECURITY_ENFORCED]) {
			cartDeliveryGroups.put(cartDeliveryGroup.fan_CPACode__c, cartDeliveryGroup);
		}

		// Get default CartDeliveryGroup.
		String cartDeliveryGroupId = cartDeliveryGroups.get(null)?.Id;

		if(cartDeliveryGroupId == null) {
			cartDeliveryGroupId = cartDeliveryGroups.get(contactPointAddressCode)?.Id;

			// Create a new one.
			if(cartDeliveryGroupId == null) {
				cartDeliveryGroupId = upsertCartDeliveryGroup(cartId, effectiveAccountId, contactPointAddressCode, null);
			}
		} else {
			// Update default CartDeliveryGroup.
			cartDeliveryGroupId = upsertCartDeliveryGroup(cartId, effectiveAccountId, contactPointAddressCode, cartDeliveryGroupId);
		}
		return cartDeliveryGroupId;
	}

	/** @param cartItemId The id that will be used to fetch cartItem information such as Name, ListPrice and UnitAdjustedPrice.  */
	static void addToCart(String cartItemId, CartItem cartItem) {

        CartItem placeHolder = [SELECT Sku, Name, TotalPrice FROM CartItem WHERE Id =: cartItemId WITH SECURITY_ENFORCED];

		CartItem cartItemToInsert = cartItem.clone();
		cartItemToInsert.Name = placeHolder.Name;
		cartItemToInsert.TotalPrice = placeHolder.TotalPrice;
		cartItemToInsert.Type='Product';
		cartItemToInsert.Sku = placeHolder.Sku;
        INSERT cartItemToInsert;
	}

	/** @return The Id of the added CartItem. */
    static String addToCart(String webStoreId, String effectiveAccountId, ConnectApi.CartItemInput cartItemInput) {
		// https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm#apex_ConnectAPI_CommerceCart_static_methods
		return (Test.isRunningTest()
				? testCartItem
				: ConnectApi.CommerceCart.addItemToCart(webstoreId, effectiveAccountId, 'current', cartItemInput)
				).cartItemId;
    }

	/** @return The Id of the added CartItem. */
    public static String addToCart(String webStoreId, String effectiveAccountId, ConnectApi.CartItemInput cartItemInput, CartItem cartItem) {

		String cartItemId = addToCart(webStoreId, effectiveAccountId, cartItemInput);

		CartItem cartItemToUpdate = cartItem.clone();
		cartItemToUpdate.Id = cartItemId;
		UPDATE cartItemToUpdate;

		return cartItemId;
    }

    public static void addToCart(String webStoreId, String effectiveAccountId, ConnectApi.CartItemInput cartItemInput, CartItem cartItem, String contactPointAddressCode) {

		ConnectApi.CartSummary cartSummary = getCurrentCartSummary(webstoreId, effectiveAccountId);

		Map<String, CartItem> cartItems = new Map<String, CartItem>();
		for(CartItem iterator : [SELECT CartDeliveryGroup.fan_CPACode__c FROM CartItem WHERE CartId =: cartSummary.cartId AND Product2Id =: cartItem.product2Id WITH SECURITY_ENFORCED]) {
			cartItems.put(iterator.CartDeliveryGroup.fan_CPACode__c, iterator);
		}

		// If there are no cart items related the Product Id to insert, then create a new one.
		if(cartItems.isEmpty()) {
			addToCart(webstoreId, effectiveAccountId, cartItemInput, new CartItem(
				fan_IsBackorder__c = cartItem.fan_IsBackorder__c,
				cartDeliveryGroupId = resolveCartDeliveryGroup(cartSummary.cartId, effectiveAccountId, contactPointAddressCode)
			));
		} else {
			handleBranchForCartItems(cartItems, cartItem, new Map<String, String> {
				'cartId' => cartSummary.cartId,
				'effectiveAccountId' => effectiveAccountId,
				'contactPointAddressCode' => contactPointAddressCode
			});
		}
    }

	/**
	 * @description Manages the CartDeliveryGroups to be related to the CartItems.
	 * @param cartItems A map of CartItems with CartDeliveryGroup as key.
	 * @param params Map containing the cartId, effectiveAccountId and contactPointAddressCode.
	 * @param cartItem Container for the fields to upsert (fan_IsBackorder__c, quantity).
	*/
	static void handleBranchForCartItems(Map<String, CartItem> cartItems, CartItem cartItem, Map<String, String> additionalParameters) {
		String cartId = additionalParameters.get('cartId');
		String effectiveAccountId = additionalParameters.get('effectiveAccountId');
		String contactPointAddressCode = additionalParameters.get('contactPointAddressCode');

		// Update Branch with null fan_CPACode__c;
		if(cartItems.containsKey(null)) {
			CartItem cartItemToUpdate = cartItems.get(null);
			cartItemToUpdate.CartDeliveryGroupId = upsertCartDeliveryGroup(cartId, effectiveAccountId, contactPointAddressCode, cartItemToUpdate.CartDeliveryGroupId);
			UPDATE cartItemToUpdate;
			cartItems.remove(null);
			cartItems.put(contactPointAddressCode, cartItemToUpdate);
		}

		// Update existing CartItem in a specific branch.
		if(cartItems.containsKey(contactPointAddressCode)) {
			CartItem cartItemToUpdate = [SELECT Quantity, ListPrice, UnitAdjustedPrice FROM CartItem WHERE Id =: cartItems.get(contactPointAddressCode).Id WITH SECURITY_ENFORCED];
			cartItemToUpdate.Quantity += cartItem.Quantity;
			cartItemToUpdate.fan_IsBackOrder__c = cartItem.fan_IsBackOrder__c;
			UPDATE cartItemToUpdate;
		} else {
			// Insert into a new Branch.
			CartItem cartItemToInsert = cartItem.clone();
			cartItemToInsert.CartId = cartId;
			cartItemToInsert.CartDeliveryGroupId = resolveCartDeliveryGroup(cartId, effectiveAccountId, contactPointAddressCode);
			addToCart(cartItems.values()[0].Id, cartItemToInsert);
		}
	}
}