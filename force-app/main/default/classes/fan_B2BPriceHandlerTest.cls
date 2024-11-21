@IsTest
private class fan_B2BPriceHandlerTest {

	@TestSetup
	static void makeData(){
		Product2 product = fan_B2BTestDataFactory.buildProduct('SKU-1', 'PC-1', null);
		product.fan_Category__c = 'BUJIAS';
		INSERT product;

		Pricebook2[] pricebooks = new Pricebook2[] {
			fan_B2BTestDataFactory.buildPricebook('RMT', true),
			fan_B2BTestDataFactory.buildPricebook('RMT Distribuidor', true),
			fan_B2BTestDataFactory.buildPricebook('Descuentos Contado', true)
		};
		INSERT pricebooks;

		PricebookEntry[] pricebookEntries = new PricebookEntry[] {
			// Standard pricebook.
			fan_B2BTestDataFactory.buildPricebookEntry(Test.getStandardPricebookId(), product.Id, 23.7),
			// RMT pricebook.
			fan_B2BTestDataFactory.buildPricebookEntry(pricebooks[0].Id, product.Id, 23.7),
			// RMT Distribuidor pricebook
			fan_B2BTestDataFactory.buildPricebookEntry(pricebooks[1].Id, product.Id, 21.2),
			// Descuentos Contado pricebook
			fan_B2BTestDataFactory.buildPricebookEntry(pricebooks[2].Id, product.Id, 19.3)
		};
		INSERT pricebookEntries;

		// Adjustments setup.
		PriceAdjustmentSchedule priceAdjustmentSchedule = new PriceAdjustmentSchedule(
			Name = 'BUJIAS-1',
			AdjustmentMethod = 'Range'
		);
		INSERT priceAdjustmentSchedule;

		String adjustmentPercentage = fan_Constants.AdjustmentType.ADJUSTMENT_PERCENTAGE.name().replace('_', '');

		fan_B2BTestDataFactory.createPriceAdjustmentTier(priceAdjustmentSchedule.Id, 2, 6, adjustmentPercentage, 8);
		fan_B2BTestDataFactory.createPriceAdjustmentTier(priceAdjustmentSchedule.Id, 7, 14, adjustmentPercentage, 10);

		// Buyer setup.
		Account account = fan_B2BTestDataFactory.buildAccount('123456789', 'NIT');
		account.fan_condicionPago__c = '30D';
		INSERT account;
		fan_B2BTestDataFactory.createBuyerAccount(account.Id);

		setupMotosCart(account.Id, product, pricebooks[0].Id, pricebooks[2].Id);
		setupPosventaCart(account.Id, product);

		fan_B2BTestDataFactory.createPromotion(fan_B2BPriceHandler.GENERAL_PROMOTION_NAME);
	}

	@IsTest
	static void applyPricesToMotosCartItems() {

		WebCart cart = [SELECT
							typeof Account
								WHEN Account THEN fan_condicionPago__c
							END,
							fan_FormaPago__c, Webstore.StrikethroughPricebookId, fan_EsAnticipo__c 
							FROM WebCart WHERE Webstore.Name = 'Motos'];
		CartItem cartItem = [SELECT Quantity, Product2Id FROM CartItem WHERE CartId = :cart.Id];

		fan_B2BPriceHandler.applyPricesToMotosCartItems(cart, new CartItem[]{ cartItem }, new Set<String>{ cartItem.Product2Id });

		Assert.areEqual(23.7, cartItem.ListPrice, 'The ListPrice of the CartItem is not as expected.');
		Assert.areEqual(19.3, cartItem.SalesPrice, 'The SalesPrice of the CartItem is not as expected.');
		Assert.areEqual(19.3, cartItem.UnitAdjustedPrice, 'The UnitAdjustedPrice of the CartItem is not as expected.');

		Assert.areEqual(118.5, cartItem.TotalListPrice, 'The TotalListPrice of the CartItem is not as expected.');
		Assert.areEqual(96.5, cartItem.TotalLineAmount, 'The TotalLineAmount of the CartItem is not as expected.');
		Assert.areEqual(96.5, cartItem.TotalPrice, 'The TotalPrice of the CartItem is not as expected.');

		Assert.areEqual(-4.4, cartItem.UnitAdjustmentAmount, 'The UnitAdjustmentAmount of the CartItem is not as expected.');
		Assert.areEqual(-22, cartItem.AdjustmentAmount, 'The AdjustmentAmount of the CartItem is not as expected.');
		Assert.areEqual(-22, cartItem.TotalAdjustmentAmount, 'The TotalAdjustmentAmount of the CartItem is not as expected.');
	}

	@IsTest
	static void applyPricesToPosventaCartItems() {

		WebCart cart = [SELECT
							typeof Account
								WHEN Account THEN fan_condicionPago__c
							END,
						fan_FormaPago__c, fan_TipoPedido__c FROM WebCart WHERE Webstore.Name = 'Posventa'];
		CartItem cartItem = [SELECT Quantity, Product2.fan_Category__c, Product2.fan_Brand__c, Product2.fan_ProductType__c, fan_PaymentCondition__c
							FROM CartItem WHERE CartId = :cart.Id];

		fan_B2BPriceHandler.applyPricesToPosventaCartItems(cart, 'RMT', new CartItem[]{ cartItem }, new Set<String>{ cartItem.Product2Id });

		Assert.areEqual(23.7, cartItem.ListPrice, 'The ListPrice of the CartItem is not as expected.');
		Assert.areEqual(21.2, cartItem.SalesPrice, 'The SalesPrice of the CartItem is not as expected.');
		Assert.areEqual(21.804, cartItem.UnitAdjustedPrice, 'The UnitAdjustedPrice of the CartItem is not as expected.');

		Assert.areEqual(118.5, cartItem.TotalListPrice, 'The TotalListPrice of the CartItem is not as expected.');
		Assert.areEqual(106, cartItem.TotalLineAmount, 'The TotalLineAmount of the CartItem is not as expected.');
		Assert.areEqual(109.02, cartItem.TotalPrice, 'The TotalPrice of the CartItem is not as expected.');

		Assert.areEqual(-1.896, cartItem.UnitAdjustmentAmount, 'The UnitAdjustmentAmount of the CartItem is not as expected.');
		Assert.areEqual(-9.48, cartItem.AdjustmentAmount, 'The AdjustmentAmount of the CartItem is not as expected.');
		Assert.areEqual(-9.48, cartItem.TotalAdjustmentAmount, 'The TotalAdjustmentAmount of the CartItem is not as expected.');
	}

	static void setupMotosCart(String accountId, Product2 product, Id listPriceBook, Id discountPricebook) {

		fan_IdTienda__mdt motos = fan_IdTienda__mdt.getInstance(fan_Constants.StoreDeveloperName.MOTOS.name().toLowerCase());

		Webstore store = new Webstore(
			Id = motos.fan_IdTienda__c,
			Name = motos.DeveloperName,
			StrikethroughPricebookId = listPriceBook
		);
		UPDATE store;

		BuyerGroup buyerGroup = fan_B2BTestDataFactory.createBuyerGroup('Motos BuyerGroup');
		fan_B2BTestDataFactory.createBuyerGroupMember(accountId, buyerGroup.Id);
		fan_B2BTestDataFactory.createWebStoreBuyerGroup(buyerGroup.Id, store.Id);

		fan_B2BTestDataFactory.createBuyerGroupPricebook(buyerGroup.Id, discountPricebook, 1, true);

		WebCart cart = fan_B2BTestDataFactory.buildWebCart(store.Id, accountId, fan_Constants.FormaPago.CONTADO.name());
		cart.Status = 'Active';
		cart.RecordTypeId = SObjectType.WebCart
		.getRecordTypeInfosByDeveloperName()
		.get(motos.DeveloperName)
		.getRecordTypeId();
		INSERT cart;
		CartDeliveryGroup cartDeliveryGroup = fan_B2BTestDataFactory.createCartDeliveryGroup('Motos CartDeliveryGroup', cart.Id);

		fan_B2BTestDataFactory.createCartItem(product, fan_Constants.CartItemType.PRODUCT.name(), 5, 79.99, cart.Id, cartDeliveryGroup.Id);
	}

	static void setupPosventaCart(String accountId, Product2 product) {

		BuyerGroup buyerGroup = fan_B2BTestDataFactory.createBuyerGroup('Posventa Buyer Group');
		fan_B2BTestDataFactory.createBuyerGroupMember(accountId, buyerGroup.Id);

		// Promotions setup.
		fan_ConfiguracionRangoPrecio__c priceRangeConfiguration = fan_B2BTestDataFactory.buildPriceRangeConfiguration('BUJIAS-1', true, buyerGroup.Id, 'BUJIAS');
		priceRangeConfiguration.fan_Condicion_pago_en_carrito__c = fan_Constants.FormaPago.CREDITO.name();
		INSERT priceRangeConfiguration;

		fan_B2BTestDataFactory.createPromotion(fan_B2BPriceHandler.B2B_PROMOTION_NAME);

		fan_IdTienda__mdt posventa = fan_IdTienda__mdt.getInstance(fan_Constants.StoreDeveloperName.POSVENTA.name().toLowerCase());

		WebStore store = new WebStore(
			Id = posventa.fan_IdTienda__c,
			Name = posventa.DeveloperName
		);
		UPDATE store;

		WebCart cart = fan_B2BTestDataFactory.buildWebCart(store.Id, accountId, fan_Constants.FormaPago.CONTADO.name());
		cart.Status = 'Active';
		cart.fan_FormaPago__c = fan_Constants.FormaPago.CREDITO.name();
		cart.RecordTypeId = SObjectType.WebCart
		.getRecordTypeInfosByDeveloperName()
		.get(posventa.DeveloperName)
		.getRecordTypeId();
		INSERT cart;
		CartDeliveryGroup cartDeliveryGroup = fan_B2BTestDataFactory.createCartDeliveryGroup('Posventa CartDeliveryGroup', cart.Id);

		fan_B2BTestDataFactory.createCartItem(product, fan_Constants.CartItemType.PRODUCT.name(), 5, 79.99, cart.Id, cartDeliveryGroup.Id);
	}
}