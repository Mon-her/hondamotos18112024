public without sharing class fan_B2BPriceHandler {

	static final String DEFAULT_POSVENTA_PRICEBOOK_NAME = 'RMT';
	static final String DISCOUNT_PRICE_BOOK_NAME = 'DISTRIBUIDOR';
	@TestVisible
	static final String GENERAL_PROMOTION_NAME = 'Descuentos aplicados'; // For the difference between CartItem.Listprice - CartItem.Salesprice.
	@TestVisible
	static final String B2B_PROMOTION_NAME = 'Promoción B2B'; // For the number of cart items per category.

	public static void applyPricesToMotosCartItems(WebCart cart, CartItem[] cartItems, Set<String> productIds) {

		Map<String, ProductPrice> productPrices = new Map<String, ProductPrice>();
		Map<String, Integer> priorityByPriceBookId = new Map<String, Integer>();
		String listPriceBookId = cart.Webstore.StrikethroughPricebookId;

		PricebookEntry[] pricebookEntries = getMotosPricebookEntries(cart, listPriceBookId, productIds, priorityByPriceBookId);
		for (PricebookEntry pricebookEntry : pricebookEntries) {
			String productId = pricebookEntry.Product2Id;
			Integer priority = priorityByPriceBookId.get(pricebookEntry.Pricebook2Id);
			if(!productPrices.containsKey(productId)) {
				productPrices.put(productId, new ProductPrice());
			}
			productPrices.get(productId)
			.updatePrice(pricebookEntry, listPriceBookId, priority);
		}
    	INSERT applyPricesToCartItems(cart, cartItems, productPrices).values();
	}

	public static void applyPricesToPosventaCartItems(WebCart cart, String pricebookName, CartItem[] cartItems, Set<String> productIds) {

		Map<String, ProductPrice> productPrices = getPosventaProductPrices(pricebookName, productIds);

		Map<String, CartItemPriceAdjustment> cartItemPriceAdjustments = applyPricesToCartItems(cart, cartItems, productPrices);

		// Creation of promotions only for RMT_Normal orders.
		if(fan_Constants.OrderType.RMT_NORMAL.name() == cart.fan_TipoPedido__c) { 
			validatePromotions(cart, cartItems, cartItemPriceAdjustments);
		}
		INSERT cartItemPriceAdjustments.values();
	}

	@TestVisible
	static Map<String, CartItemPriceAdjustment> applyPricesToCartItems(WebCart cart, CartItem[] cartItems, Map<String, ProductPrice> productPrices) {
		String promotionId = [SELECT Id FROM Promotion WHERE Name = :GENERAL_PROMOTION_NAME LIMIT 1].Id;
		Set<String> cartItemIds = new Set<String>();
		Map<String, CartItemPriceAdjustment> cartItemPriceAdjustments = new Map<String, CartItemPriceAdjustment>();

		for (CartItem cartItem : cartItems) {
			cartItemIds.add(cartItem.Id);
			ProductPrice productPrice = productPrices.get(cartItem.Product2Id);

			cartItem.fan_PaymentCondition__c = ((Account) cart.Account).fan_condicionPago__c;
			calculatePrices(cartItem, productPrice?.listPrice?.value, productPrice?.salesPrice?.value);
			Decimal adjustmentValue = cartItem.ListPrice - cartItem.SalesPrice;
			if(adjustmentValue > 0) {
				AdjustmentInput adjustmentInput = new AdjustmentInput(promotionId, fan_Constants.AdjustmentSource.DISCRETIONARY, fan_Constants.AdjustmentType.ADJUSTMENT_AMOUNT, adjustmentValue);
				cartItemPriceAdjustments.put(cartItem.Id, buildCartItemPriceAdjustment(cartItem, adjustmentInput));
			}
		}
		DELETE [SELECT Id FROM CartItemPriceAdjustment WHERE CartItemId IN :cartItemIds];
		return cartItemPriceAdjustments;
	}

	@Testvisible
	static PricebookEntry[] getMotosPricebookEntries(WebCart cart, String listPriceBookId, Set<String> productIds, Map<String, Integer> priorityByPriceBookId) {
		Set<String> priceBookIds = new Set<String> { listPriceBookId };
		Set<String> buyerGroupIds = new Set<String>();
		String formaPago = cart.fan_EsAnticipo__c == true? 'contado' : cart.fan_FormaPago__c;
		String priceBooksToSearch = '%' + formaPago + '%';

		for (WebStoreBuyerGroup webStoreBuyerGroup : [SELECT BuyerGroupId FROM WebStoreBuyerGroup WHERE WebstoreId = :cart.WebstoreId
														AND BuyerGroupId IN (SELECT BuyerGroupId FROM BuyerGroupMember WHERE BuyerId = :cart.AccountId)]) {
			buyerGroupIds.add(webStoreBuyerGroup.BuyerGroupId);
		}

		for (BuyerGroupPricebook buyerGroupPricebook : [SELECT Pricebook2Id, Priority FROM BuyerGroupPricebook
														WHERE IsActive = true AND BuyerGroupId IN :buyerGroupIds AND Pricebook2.IsActive = true AND Pricebook2.Name LIKE :priceBooksToSearch ORDER BY Priority]) {
			priorityByPriceBookId.put(buyerGroupPricebook.Pricebook2Id, buyerGroupPricebook.Priority);
		}
		priceBookIds.addAll(priorityByPriceBookId.keySet());

		return [SELECT PriceBook2Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id IN :productIds AND Pricebook2Id IN :priceBookIds ORDER BY Product2Id];
	}

	/**
	* @description Get pricebook entries related to the specified products and pricebook name.
	* @param pricebookName The name of the pricebook to search.
	* @param productIds A set of product id's.
	* @return A map of products with prices.
	*/
	@TestVisible
	static Map<String, ProductPrice> getPosventaProductPrices(String pricebookName, Set<String> productIds){

		// productPrices stores the two prices of the product (listPrice y unitAdjustedPrice) from both list prices.
		Map<String, ProductPrice> productPrices = new Map<String, ProductPrice>();

		String pricebookNameToSearch =  pricebookName + '%';
		PricebookEntry[] pricebookEntries = [SELECT Product2Id, Pricebook2.Name, UnitPrice FROM PricebookEntry WHERE Product2Id IN: productIds AND Pricebook2.Name Like :pricebookNameToSearch];

		// Query for pricebookEntries
		for(PricebookEntry pricebookEntry : pricebookEntries) {
			String productId = pricebookEntry.Product2Id;

			if(!productPrices.containsKey(productId)) {
				productPrices.put(productId, new ProductPrice());
			}
			productPrices.get(productId)
			.updatePrice(pricebookEntry, pricebookName);
		}
		System.debug(LoggingLevel.DEBUG, 'getProductPrices productPrices to return >>> '+productPrices);
		return productPrices;
	}

	@TestVisible
	static void validatePromotions(WebCart cart, List<CartItem> cartItems, Map<String, CartItemPriceAdjustment> cartItemPriceAdjustments) {
		Date currentDate = Date.today();
		Integer currentDay = currentDate.day();
		Set<String> buyerGroupIds = new Set<String>();
		Set<String> categoriesInCart = new Set<String>();

		for(BuyerGroupMember buyerGroupMember : [SELECT BuyerGroupId FROM BuyerGroupMember WHERE BuyerId = :cart.AccountId]) {
			buyerGroupIds.add(buyerGroupMember.BuyerGroupId);
		}
		for (CartItem cartItem : cartItems) {
			categoriesInCart.add(cartItem.Product2.fan_Category__c);
		}
		fan_ConfiguracionRangoPrecio__c[] priceRangeConfigurations = [SELECT Name, fan_Catalogo_referencias__c, fan_Marca__c, fan_Tipo_de_producto__c, fan_PaymentCondition__c 
																																		FROM fan_ConfiguracionRangoPrecio__c WHERE fan_Activo__c = true
                                                                		AND fan_Condicion_pago_en_carrito__c INCLUDES (:cart.fan_FormaPago__c)
                                                                		AND fan_Catalogo_referencias__c IN :categoriesInCart
                                                                		AND fan_Grupo_de_compradores__c IN :buyerGroupIds
                                                                		AND fan_FechaInicio__c <= :currentDate AND fan_FechaFin__c >= :currentDate
                                                                		AND fan_Dia_Inicial__c <= :currentDay AND fan_Dia_Final__c >= :currentDay WITH SECURITY_ENFORCED
																																		ORDER BY fan_Tipo_de_producto__c, fan_Marca__c NULLS LAST]; // Null values on brand and product type will be the lasts
		// Types of configuration: 1. Catalog-brand-type, 2. Catalog-brand, 3. Catalog only.
		Map<String, ProductDiscount> productDiscounts = resolveAndApplyPriceAdjustments(priceRangeConfigurations, cartItems);
		applyPromotions(productDiscounts, cartItemPriceAdjustments);
	}

	@TestVisible // Loops the configurations to select only the ones that match with the brands and product types of cart itemss
	static Map<String, ProductDiscount>  resolveAndApplyPriceAdjustments (fan_ConfiguracionRangoPrecio__c[] priceRangeConfigurations, List<CartItem> cartItems) {
		Map<String, String> applicableConfigurations = new Map<String, String>();
		Set<String> brandsWithPromos = new Set<String>();
		Set<String> productTypesWithPromos = new Set<String>();

		for (fan_ConfiguracionRangoPrecio__c priceRangeConfiguration : priceRangeConfigurations) {
			String brandTypeName = priceRangeConfiguration.fan_Catalogo_referencias__c+'-'+priceRangeConfiguration.fan_Marca__c+'-'+priceRangeConfiguration.fan_Tipo_de_producto__c;
			// Save the brand of the productType that the promotions have 
			if (priceRangeConfiguration.fan_Marca__c != null) {
				if (priceRangeConfiguration.fan_Tipo_de_producto__c != null) {
					productTypesWithPromos.add(priceRangeConfiguration.fan_Tipo_de_producto__c);
				} else {
					brandsWithPromos.add(priceRangeConfiguration.fan_Marca__c);
				}
			}
			applicableConfigurations.put(brandTypeName, priceRangeConfiguration.Name);
		}

		Map<String, fan_ConfiguracionRangoPrecio__c> priceRangeConfigurationByName = getPriceRangeConfigurationByName(priceRangeConfigurations, applicableConfigurations);

		Map<String, Decimal> productQuantitiesCategory = new Map<String, Decimal>();
		Map<String, Decimal> productQuantitiesBrand = new Map<String, Decimal>();
		Map<String, Decimal> productQuantitiesType = new Map<String, Decimal>();
		Map<String, CartItem[]> cartItemsByCategory = new Map<String, CartItem[]>();
		Map<String, CartItem[]> cartItemsByBrand = new Map<String, CartItem[]>();
		Map<String, CartItem[]> cartItemsByProductType = new Map<String, CartItem[]>();

		for (CartItem cartItem : cartItems) {
			String category = cartItem.Product2.fan_Category__c;
			String brand = cartItem.Product2.fan_Brand__c;
			String type = cartItem.Product2.fan_ProductType__c;

			// Select the cart items that have a product type or brand that match with the values in the range configurations of the category
			if (type != null && productTypesWithPromos.size() > 0 && productTypesWithPromos.contains(type)) {
				List<CartItem> productTypeItems = cartItemsByProductType.containsKey(type) ? (List<CartItem>) cartItemsByProductType.get(type) : new List<CartItem>();
				productTypeItems.add(cartItem);
				cartItemsByProductType.put(type, productTypeItems);
				Decimal previousQuantityType = productQuantitiesType.containsKey(type) ? productQuantitiesType.get(type) : 0;
				productQuantitiesType.put(type, cartItem.Quantity + previousQuantityType);
			} else if (brand != null && brandsWithPromos.size() > 0 && brandsWithPromos.contains(brand)) {
				List<CartItem> brandItems = cartItemsByBrand.containsKey(brand) ? (List<CartItem>) cartItemsByBrand.get(brand) : new List<CartItem>();
				brandItems.add(cartItem);
				cartItemsByBrand.put(brand, brandItems);
				Decimal previousQuantityBrand = productQuantitiesBrand.containsKey(brand) ? productQuantitiesBrand.get(brand) : 0;
				productQuantitiesBrand.put(brand, cartItem.Quantity + previousQuantityBrand);
			} else {
				// If the cart item brand and product type doesnt match with the data of the configurations, save them in this list for apply a general category discount if exists
				List<CartItem> categoryItems = cartItemsByCategory.containsKey(category) ? (List<CartItem>) cartItemsByCategory.get(category) : new List<CartItem>();
				categoryItems.add(cartItem);
				cartItemsByCategory.put(category, categoryItems);
				Decimal previousQuantity = productQuantitiesCategory.containsKey(category) ? productQuantitiesCategory.get(category) : 0;
				productQuantitiesCategory.put(category, cartItem.Quantity + previousQuantity);
			}
		}

		System.debug('productQuantitiesCategory >>> '+productQuantitiesCategory);
		System.debug('productQuantitiesBrand >>> '+productQuantitiesBrand);
		System.debug('productQuantitiesType >>> '+productQuantitiesType);

		Map<String, ProductDiscount> productDiscounts = getProductDiscounts(priceRangeConfigurationByName, cartItemsByCategory, cartItemsByBrand, cartItemsByProductType,
																										 productQuantitiesBrand, productQuantitiesType, productQuantitiesCategory);
		return productDiscounts;
	}

	@TestVisible // Gets the names and records of configurations that were filter on searchApplicableConfigurations
	static Map<String, fan_ConfiguracionRangoPrecio__c> getPriceRangeConfigurationByName(fan_ConfiguracionRangoPrecio__c[] priceRangeConfigurations, Map<String, String> applicableConfigurations) {
		// Stores the names of the price range configurations associated with a certain category and the number of null fields they have.
		Map<String, fan_ConfiguracionRangoPrecio__c> priceRangeConfigurationByName = new Map<String, fan_ConfiguracionRangoPrecio__c>();

		// Can be multiple fan_ConfiguracionRangoPrecio__c for same category, but the difference can be the brand or product type
		for (fan_ConfiguracionRangoPrecio__c priceRangeConfiguration : priceRangeConfigurations) {
			if (applicableConfigurations.values().contains(priceRangeConfiguration.Name)) {
				priceRangeConfigurationByName.put(priceRangeConfiguration.Name, priceRangeConfiguration);
			}
		}

		return priceRangeConfigurationByName;
	}

	@TestVisible
	static Map<String, ProductDiscount> getProductDiscounts(Map<String, fan_ConfiguracionRangoPrecio__c> priceRangeConfigurationByName, Map<String, CartItem[]> cartItemsByCategory, 
		Map<String, CartItem[]> cartItemsByBrand, Map<String, CartItem[]> cartItemsByProductType, Map<String, Decimal> productQuantitiesBrand, 
		Map<String, Decimal> productQuantitiesType, Map<String, Decimal> productQuantitiesCategory
	) {
		Map<String, ProductDiscount> productDiscounts = new Map<String, ProductDiscount>();

		// Gets the adjustments using the applicable price configurations names and sets the value based on the cuantity applicable by category, brand or type
		for (String configName : priceRangeConfigurationByName.keySet()) {
			fan_ConfiguracionRangoPrecio__c priceRangeConfiguration = priceRangeConfigurationByName.get(configName);
			Decimal quantity = 0;
			String discountName = priceRangeConfiguration.fan_Catalogo_referencias__c;
			List<CartItem> cartItemsToApply = new List<CartItem>();
			// If has product type, has brand and category too
			if (priceRangeConfiguration.fan_Tipo_de_producto__c != null) {
				quantity = productQuantitiesType.get(priceRangeConfiguration.fan_Tipo_de_producto__c);
				discountName += '-'+priceRangeConfiguration.fan_Marca__c+'-'+priceRangeConfiguration.fan_Tipo_de_producto__c;
				cartItemsToApply = cartItemsByProductType.get(priceRangeConfiguration.fan_Tipo_de_producto__c);
			} else if (priceRangeConfiguration.fan_Marca__c != null) {
				quantity = productQuantitiesBrand.get(priceRangeConfiguration.fan_Marca__c);
				discountName += '-'+priceRangeConfiguration.fan_Marca__c;
				cartItemsToApply = cartItemsByBrand.get(priceRangeConfiguration.fan_Marca__c);
			} else {
				quantity = productQuantitiesCategory.get(priceRangeConfiguration.fan_Catalogo_referencias__c);
				cartItemsToApply = cartItemsByCategory.get(priceRangeConfiguration.fan_Catalogo_referencias__c);
			}

			System.debug('Current quantity >>> '+quantity);
			System.debug('Current priceRangeConfiguration >>> '+priceRangeConfiguration);
			if (quantity == null) continue;
			// Get the tier with the highest discount value
			List<PriceAdjustmentTier> tierToApply = [SELECT PriceAdjustmentSchedule.Name, LowerBound, UpperBound, TierType, TierValue FROM PriceAdjustmentTier
																				 WHERE PriceAdjustmentSchedule.Name = :configName AND LowerBound <= :quantity AND UpperBound >= :quantity];
			System.debug('tierToApply >>> '+tierToApply);
			if(tierToApply.size() > 0) {
				productDiscounts.put(discountName, new ProductDiscount(tierToApply[0].TierValue, priceRangeConfiguration.fan_PaymentCondition__c, cartItemsToApply));
			}
		}
		return productDiscounts;
	}

	@TestVisible
	static void applyPromotions(Map<String, ProductDiscount> productDiscounts, Map<String, CartItemPriceAdjustment> cartItemPriceAdjustments) {
		String promotionId = [SELECT Id FROM Promotion WHERE Name = :B2B_PROMOTION_NAME LIMIT 1].Id;

		for (ProductDiscount productDiscount : productDiscounts.values()) {
			for(CartItem cartItem : productDiscount.cartItemsToApply) {

				if(productDiscount.paymentCondition != null && cartItem.fan_PaymentCondition__c != productDiscount.paymentCondition) {
					cartItem.fan_PaymentCondition__c = productDiscount.paymentCondition;
				}
				applyPromotion(cartItem, productDiscount.value);

				AdjustmentInput adjustmentInput = new AdjustmentInput(promotionId, fan_Constants.AdjustmentSource.PROMOTION, fan_Constants.AdjustmentType.ADJUSTMENT_AMOUNT, -cartItem.UnitAdjustmentAmount);
				// Prioritize the B2B_PROMOTION over the GENERAL_PROMOTION.
				cartItemPriceAdjustments.put(cartItem.Id, buildCartItemPriceAdjustment(cartItem, adjustmentInput));
			}
		}
	}

	@TestVisible
	static void calculatePrices(CartItem cartItem, Decimal listPrice, Decimal salesPrice) {
		listPrice = listPrice == null ? 0 : listPrice;
		salesPrice = salesPrice == null ? listPrice : salesPrice;

		cartItem.ListPrice = listPrice;
		cartItem.SalesPrice = salesPrice;
		cartItem.UnitAdjustedPrice = salesPrice;

		cartItem.TotalListPrice = listPrice * cartItem.Quantity;
		cartItem.TotalLineAmount = salesPrice * cartItem.Quantity;
		cartItem.TotalPrice = cartItem.UnitAdjustedPrice * cartItem.Quantity;

		cartItem.UnitAdjustmentAmount = salesPrice - listPrice;
		cartItem.AdjustmentAmount = cartItem.UnitAdjustmentAmount * cartItem.Quantity;
		cartItem.TotalAdjustmentAmount = cartItem.AdjustmentAmount;
	}

	@TestVisible
	static void applyPromotion(CartItem cartItem, Decimal adjustmentValue) {
		// Apply PriceAdjustmentSchedule to the original public price of the cart item

		cartItem.UnitAdjustmentAmount = cartItem.ListPrice * -adjustmentValue / 100;
		cartItem.AdjustmentAmount = cartItem.UnitAdjustmentAmount * cartItem.Quantity;
		cartItem.TotalAdjustmentAmount = cartItem.AdjustmentAmount;

		cartItem.UnitAdjustedPrice = cartItem.ListPrice + cartItem.UnitAdjustmentAmount;

		cartItem.TotalPrice = cartItem.UnitAdjustedPrice * cartItem.Quantity;
	}

	@TestVisible
	static CartItemPriceAdjustment buildCartItemPriceAdjustment(CartItem cartItem, AdjustmentInput adjustmentInput) {
		return new CartItemPriceAdjustment(
			// Picklist: Cart (DistributedAdjustmentAmount y el totalAmount queda igual), Item (ItemizedAdjustmentAmount y se le suma al totalAmount)
			AdjustmentTargetType = 'Cart',
			// Picklist: AdjustmentAmount, AdjustmentPercentage
			AdjustmentType = adjustmentInput.type,
			// Picklist: Unit, Total
			AdjustmentAmountScope = 'Total',
			CartItemId = cartItem.Id,
			PriceAdjustmentCauseId = adjustmentInput.causeId,
			// Save the cart item Id, qty to apply y total promo to identify groups of promotions 
			Description = cartItem.Id,
			Name = cartItem.Id,
			// Picklist: Discretionary (apply by an specific person), Promotion, System
			AdjustmentSource = adjustmentInput.source,
			AdjustmentValue = adjustmentInput.value,
			TotalAmount = adjustmentInput.value * cartItem.Quantity
		);
	}

	@TestVisible
	class AdjustmentInput {
		String causeId;
		String type;
		String source;
		Decimal value;

		public AdjustmentInput(String causeId, fan_Constants.AdjustmentSource source, fan_Constants.AdjustmentType type, Decimal value)  {
			this.causeId = causeId;
			this.source = source.name();
			this.type = type.name().replace('_', '');
			this.value = value;
		}
	}

	@TestVisible
	class ProductDiscount {
		@TestVisible
		Decimal value;
		String paymentCondition;
		// Stores the cart items that have this discount
		List<CartItem> cartItemsToApply = new List<CartItem>();

		public ProductDiscount(Decimal value, String paymentCondition, List<CartItem> cartItemsToApply) {
			this.value = value;
			this.paymentCondition = paymentCondition;
			this.cartItemsToApply.addAll(cartItemsToApply);
		}
	}

	class Price {
		Integer priority;
		Decimal value;

		Price(Decimal value) {
			this.value = value;
		}

		Price(Decimal value, Integer priority) {
			this.value = value;
			this.priority = priority;
		}
	}

	class ProductPrice {
		Price listPrice;	
		Price salesPrice;

		// For motos
		void updatePrice(PricebookEntry pricebookEntry, String listPriceBookId, Integer priority) {
			if(pricebookEntry.Pricebook2Id == listPriceBookId) {
				listPrice = new Price(pricebookEntry.UnitPrice);
			} else if(salesPrice == null || salesPrice.priority > priority) {
				salesPrice = new Price(pricebookEntry.UnitPrice, priority);
			}
		}

		// For Posventa
		void updatePrice(PricebookEntry pricebookEntry, String listPriceBookName) {
			String pricebookEntryName = pricebookEntry.Pricebook2.Name;
			if(pricebookEntryName == listPriceBookName) {
				listPrice = new Price(pricebookEntry.UnitPrice);
			} else if(pricebookEntryName.startsWith(listPriceBookName) && pricebookEntryName.endsWithIgnoreCase(DISCOUNT_PRICE_BOOK_NAME)) {
				salesPrice = new Price(pricebookEntry.UnitPrice);
			}
		}
	}
}