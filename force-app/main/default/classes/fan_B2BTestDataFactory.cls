// TO CREATE GENERAL DATA.
@IsTest
public class fan_B2BTestDataFactory {

    public static Account createAccount(String accountNumber, String tipoDeDocumento) {
        Account account = buildAccount(accountNumber, tipoDeDocumento);
        INSERT account;
        return account;
    }

    public static Account buildAccount(String accountNumber, String tipoDeDocumento) {
        return new Account(
            Name = 'Test Account',
            AccountNumber = accountNumber,
            AM_Numero_de_documento__c = accountNumber,
            AM_Tipo_de_documento__c = tipoDeDocumento
        );
    }

    public static void createAlternativePaymentMethod(String accountId) {
        INSERT new AlternativePaymentMethod(
            AccountId = accountId,
            NickName = 'Pse',
            ProcessingMode = 'External',
            Status = 'Active'
        );
    }

    public static void createCartCheckoutSession(String orderId, String cartId) {
        INSERT new CartCheckoutSession(
            Name = 'Test CartCheckoutSession',
            OrderId = orderId,
            WebCartId = cartId,
            State = 'Order Confirmation'
        );
    }

    public static void createCityLocation(String locationId, String city) {
        INSERT new fan_CityLocation__c(
            fan_Location__c = locationId,
            fan_Ciudad__c = city
        );
    }

    public static Contact createContact(String lastName, String accountId) {
        Contact contact = new Contact(LastName = lastName, AccountId = accountId);
        INSERT contact;
        return contact;
    }

    public static fan_PayzenIPNConfig__c createPayzenIPNConfig(String clientId, String clientSecret, String username, String password, String securityToken) {
        fan_PayzenIPNConfig__c payzenIPNConfig = new fan_PayzenIPNConfig__c(
            fan_ClientId__c = clientId,
            fan_ClientSecret__c = clientSecret,
            fan_Username__c = username,
            fan_Password__c = password,
            fan_SecurityToken__c = securityToken
        );
        INSERT payzenIPNConfig;
        return payzenIPNConfig;
    }

    public static void createContactPointAddress(String name, String code, String addressType, String city, String parentId) {
        INSERT new ContactPointAddress(
            Name = name,
            fan_Code__c = code,
            AddressType = addressType,
            City = city,
            ParentId = parentId
        );
    }

    public static Schema.Location createLocation(String name, String externalReference, Boolean shouldSyncWithOci) {
        Schema.Location location = new Schema.Location(
            Name = name,
            ExternalReference = externalReference,
            ShouldSyncWithOci = shouldSyncWithOci
        );
        INSERT location;
        return location;
    }

    public static LocationGroup createLocationGroup(String name, String externalReference) {
        LocationGroup locationGroup = new LocationGroup(
            LocationGroupName = name,
            ExternalReference = externalReference
        );
        INSERT locationGroup;
        return locationGroup;
    }

    public static LocationGroupAssignment createLocationGroupAssignment(String locationId, String locationGroupId) {
        LocationGroupAssignment locationGroupAssignment = new LocationGroupAssignment(
            LocationId = locationId,
            LocationGroupId = locationGroupId
        );
        INSERT locationGroupAssignment;
        return locationGroupAssignment;
    }

    public static Product2 createProduct(String stockKeepingUnit, String productCode, String type) {
        Product2 product = buildProduct(stockKeepingUnit, productCode, type);
        INSERT product;
        return product;
    }

    public static Product2 buildProduct(String stockKeepingUnit, String productCode, String type) {
        return new Product2(
            Name = stockKeepingUnit,
            StockKeepingUnit = stockKeepingUnit,
            ProductCode = productCode,
            Type = type,
            IsActive = true
        );
    }

    public static ProductAttribute createProductAttribute(String variantParentId, String variantChildId, sObjectField field, Object fieldValue) {
        ProductAttribute productAttribute = new ProductAttribute(
            VariantParentId = variantParentId,
            ProductId = variantChildId
        );
        productAttribute.put(field, fieldValue);
        INSERT productAttribute;
        return productAttribute;
    }

    public static ProductCatalog createProductCatalog(String name) {
        ProductCatalog productCatalog = new ProductCatalog(
            Name = name
        );
        INSERT productCatalog;
        return productCatalog;
    }

    public static ProductCategory createProductCategory(String name, String catalogId, String categoryCode) {
        ProductCategory productCategory = new ProductCategory(
            Name = name,
            CatalogId = catalogId,
            fan_CategoryCode__c = categoryCode
        );
        INSERT productCategory;
        return productCategory;
    }

    public static ProductCategoryProduct createProductCategoryProduct(String productCategoryId, String productId) {
        ProductCategoryProduct productCategoryProduct = new ProductCategoryProduct(
            ProductCategoryId = productCategoryId,
            ProductId = productId
        );
        INSERT productCategoryProduct;
        return productCategoryProduct;
    }

    public static BuyerAccount createBuyerAccount(String accountId) {
        BuyerAccount buyerAccount = new BuyerAccount(
	        BuyerId = accountId,
	        Name = 'Test BuyerAccount',
	        IsActive = true
        );
        INSERT buyerAccount;
        return buyerAccount;
    }

    public static BuyerGroup createBuyerGroup(String name) {
        BuyerGroup buyerGroup = new BuyerGroup(Name = name);
        INSERT buyerGroup;
        return buyerGroup;
    }

    public static BuyerGroupMember createBuyerGroupMember(String accountId, String buyerGroupId) {
        BuyerGroupMember buyerGroupMember = new BuyerGroupMember(
	        BuyerId = accountId,
	        BuyerGroupId = buyerGroupId
        );
        INSERT buyerGroupMember;
        return buyerGroupMember;
    }

    public static CartDeliveryGroup createCartDeliveryGroup(String name, String cartId) {
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(
            Name = name,
            CartId = cartId,
            DeliverToName = 'Name',
            DeliverToStreet = 'Street',
            DeliverToCity = 'City',
            DeliverToState = 'State',
            DeliverToPostalCode = 'PostalCode',
            DeliverToCountry = 'Country'
        );
        INSERT cartDeliveryGroup;
        return cartDeliveryGroup;
    }

    public static CartItem createCartItem(Product2 product, String type, Decimal quantity, Decimal price, String cartId, String cartDeliveryGroupId) {
        CartItem cartItem = buildCartItem(product, type, quantity, price, cartId, cartDeliveryGroupId);
        INSERT cartItem;
        return cartItem;
    }

    public static CartItem buildCartItem(Product2 product, String type, Decimal quantity, Decimal price, String cartId, String cartDeliveryGroupId) {
        Decimal adjustmentValue  = price * 5 / 100;
        Decimal adjustmentAmount = -adjustmentValue * quantity;
        Decimal salesPrice = price - adjustmentValue;
        return new CartItem(
            Name = product.Name,
            Product2Id = product.Id,
            Sku = product.StockKeepingUnit,
            Type = type,
            Quantity = quantity,
            ListPrice = price,
            SalesPrice = salesPrice ,
            UnitAdjustedPrice = salesPrice,
            TotalListPrice = price * quantity,
            TotalLineAmount = salesPrice * quantity,
            TotalPrice = salesPrice * quantity,
            AdjustmentAmount = adjustmentAmount,
            TotalAdjustmentAmount = adjustmentAmount,
            CartId = cartId,
            cartDeliveryGroupId = cartDeliveryGroupId
        );
    }

    public static void createCartTax(String cartItemId, Decimal amount, Decimal taxRate) {
        INSERT new CartTax( 
            Amount = amount,
            CartItemId = cartItemId,
            Name = cartItemId,
            TaxRate = taxRate,
            TaxType = 'Actual',
            TaxCalculationDate = Date.today()
        );
    }

    public static CommerceEntitlementPolicy createCommerceEntitlementPolicy(String name) {
        CommerceEntitlementPolicy commerceEntitlementPolicy = new CommerceEntitlementPolicy(
	        Name = name,
	        CanViewPrice = true,
	        CanViewProduct = true,
	        IsActive = true
        );
        INSERT commerceEntitlementPolicy;
        return commerceEntitlementPolicy;
    }

    public static CommerceEntitlementBuyerGroup createCommerceEntitlementBuyerGroup(String buyerGroupId, String commerceEntitlementPolicyId) {
        CommerceEntitlementBuyerGroup commerceEntitlementBuyerGroup = new CommerceEntitlementBuyerGroup(
	        BuyerGroupId = buyerGroupId,
	        PolicyId = commerceEntitlementPolicyId
        );
        INSERT commerceEntitlementBuyerGroup;
        return commerceEntitlementBuyerGroup;
    }

    public static CommerceEntitlementProduct createCommerceEntitlementProduct(String productId, String commerceEntitlementPolicyId) {
        CommerceEntitlementProduct commerceEntitlementProduct = new CommerceEntitlementProduct(
	        ProductId = productId,
	        PolicyId = commerceEntitlementPolicyId
        );
        INSERT commerceEntitlementProduct;
        return commerceEntitlementProduct;
    }

    public static Promotion createPromotion(String name) {
        Promotion promotion = new Promotion(
            Name = name,
            StartDate = Date.today()
        );
        INSERT promotion;
        return promotion;
    }

    public static fan_RelatedProducts__c createRelatedProduct(String sourceId, String targetId, String relationType) {
        fan_RelatedProducts__c relatedProduct = new fan_RelatedProducts__c(
            fan_Source__c = sourceId,
            fan_Target__c = targetId,
            fan_RelationType__c = relationType
        );
        INSERT relatedProduct;
        return relatedProduct;
    }

	public static Map<String, ConnectApi.ManagedContentVersion> generateManagedContentVersions(ProductMedia[] productMedias) {

        Map<String, ConnectApi.ManagedContentVersion> managedContentVersions = new Map<String, ConnectApi.ManagedContentVersion>();

        for (Integer i = 0; i < productMedias.size(); i++) {
            ProductMedia productMedia = productMedias[i];
		    ConnectApi.ManagedContentMediaSourceNodeValue source = new ConnectApi.ManagedContentMediaSourceNodeValue();
		    source.url = 'http://productimage' + i + '.png';

		    ConnectApi.ManagedContentTextNodeValue altText = new ConnectApi.ManagedContentTextNodeValue();
		    altText.value = 'alternate text ' + i;

		    ConnectApi.ManagedContentVersion managedContentVersion = new ConnectApi.ManagedContentVersion();
            managedContentVersion.managedContentId = productMedia.ElectronicMediaId;
		    managedContentVersion.contentNodes = new Map<String, ConnectApi.ManagedContentNodeValue> {
			    'source' => source,
			    'altText' => altText
		    };
            managedContentVersions.put(productMedia.ProductId, managedContentVersion);
        }
		return managedContentVersions;
	}

    public static ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation generateOCIGetInventoryAvailability(String locationGroupIdentifier, String locationIdentifier, String[] skus) {
        ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation inventoryAvailability =
        new ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation();

        List<ConnectApi.OCIInventoryRecordOutputRepresentation> inventoryRecords = new List<ConnectApi.OCIInventoryRecordOutputRepresentation>();
        for (String sku : skus) {
            ConnectApi.OCIInventoryRecordOutputRepresentation inventoryRecord = new ConnectApi.OCIInventoryRecordOutputRepresentation();
            inventoryRecord.availableToFulfill = 100;
            inventoryRecord.availableToOrder = 100;
            inventoryRecord.onHand = 100;
            inventoryRecord.reserved = 0;
            inventoryRecord.safetyStockCount = 0;
            inventoryRecord.stockKeepingUnit = sku;
            inventoryRecords.add(inventoryRecord);
        }
        ConnectApi.OCILocationGroupAvailabilityOutputRepresentation locationGroup = new ConnectApi.OCILocationGroupAvailabilityOutputRepresentation();
        locationGroup.locationGroupIdentifier = locationGroupIdentifier;
        locationGroup.inventoryRecords = inventoryRecords;

        ConnectApi.OCILocationAvailabilityOutputRepresentation location = new ConnectApi.OCILocationAvailabilityOutputRepresentation();
        location.locationIdentifier = locationIdentifier;
        location.inventoryRecords = inventoryRecords;

        inventoryAvailability.locations = new ConnectApi.OCILocationAvailabilityOutputRepresentation[]{location};
        inventoryAvailability.locationGroups = new ConnectApi.OCILocationGroupAvailabilityOutputRepresentation[]{locationGroup};
        return inventoryAvailability;
    }

    public static OrderSummary generateOrderSummary() {

        String keyPrefix = OrderSummary.getSobjectType().getDescribe().getKeyPrefix();
        String id = keyPrefix + '0'.repeat(12); // 12 is to complete the 15 characters of the Id.
        JSONGenerator jsonGenerator = JSON.createGenerator(false);

        jsonGenerator.writeStartObject();
        jsonGenerator.writeStringField('Id', id);
        jsonGenerator.writeNumberField('TotalAdjustedProductAmount', 57);
        jsonGenerator.writeNumberField('TotalAdjDistAmount', -7);
        jsonGenerator.writeNumberField('TotalAdjustedDeliveryAmount', 8);
        jsonGenerator.writeNumberField('TotalTaxAmount', 3);
        jsonGenerator.writeNumberField('GrandTotalAmount', 61);
        jsonGenerator.writeEndObject();

        jsonGenerator.close();
        return (OrderSummary) JSON.deserialize(jsonGenerator.getAsString(), OrderSummary.class);
    }

    public static ProductMedia[] generateProductMedias(Set<String> productIds) {
        ProductMedia[] productMedias = new List<ProductMedia>();
        String[] electronicMediaIds = new String[] {
            '20Y2f0000004PUOEA2', '20Y2f0000004PUYEA2'
        };

        Iterator<String> iterator = productIds.iterator();
        for (Integer i = 0; i < electronicMediaIds.size() && iterator.hasNext(); i++) {
            productMedias.add(new ProductMedia(ProductId = iterator.next(), ElectronicMediaId = electronicMediaIds[i]));
        }
        return productMedias;
    }

    public static Order createOrder(String accountId, String pricebookId) {
        Order order =  new Order(
            Name = 'Order Test',
            AccountId = accountId,
            EffectiveDate = Datetime.now().date(),
            Status = 'Draft',
            Pricebook2Id = pricebookId
        );
        INSERT order;
        return order;
    }

    public static void createOrderItem(String orderId, String productId, String pricebookEntryId, Decimal unitPrice, Decimal totalLineAmount, Decimal quanity) {
        INSERT new OrderItem(
	        OrderId = orderId,
	        Product2Id = productId,
	        PricebookEntryId = pricebookEntryId,
	        UnitPrice = unitPrice,
	        TotalLineAmount = totalLineAmount,
	        Quantity = quanity
        );
    }

    public static void createPayzenConfig() {
        INSERT new fan_PayzenConfig__c(
            fan_CtxMode__c = 'TEST',
            fan_PaymentCards__c = 'VISA;MASTERCARD',
            fan_SiteId__c = '12345678',
            fan_SecretKey__c = 'AEU135',
            fan_SignatureAlgorithm__c = 'hmacSHA256',
            fan_RedirectErrorTimeout__c = 5,
            fan_RedirectSuccessTimeout__c = 3,
            fan_UrlCheck__c = 'https://IPN-listener'
        );
    }

    public static PriceAdjustmentSchedule createPriceAdjustmentSchedule(String name) {
        PriceAdjustmentSchedule priceAdjustmentSchedule = new PriceAdjustmentSchedule(Name = name);
        INSERT priceAdjustmentSchedule;
        return priceAdjustmentSchedule;
    }

    public static PriceAdjustmentTier createPriceAdjustmentTier(String PriceAdjustmentScheduleId, Integer lowerBound, Integer upperBound, String tierType, Decimal tierValue) {
        PriceAdjustmentTier priceAdjustmentTier = new PriceAdjustmentTier(
            LowerBound = lowerBound,
            UpperBound = upperBound,
            TierType = tierType,
            TierValue = tierValue, 
            PriceAdjustmentScheduleId = PriceAdjustmentScheduleId
        );
        INSERT priceAdjustmentTier;
        return priceAdjustmentTier;
    }

    public static fan_ConfiguracionRangoPrecio__c createPriceRangeConfiguration(String name, Boolean active, String buyerGroupId, String category) {
        fan_ConfiguracionRangoPrecio__c priceRangeConfiguration = buildPriceRangeConfiguration(name, active, buyerGroupId, category);
        INSERT priceRangeConfiguration;
        return priceRangeConfiguration;
    }

    public static fan_ConfiguracionRangoPrecio__c buildPriceRangeConfiguration(String name, Boolean active, String buyerGroupId, String category) {
        Date currentDate = Date.today();

        return new fan_ConfiguracionRangoPrecio__c(
            Name = name,
            fan_FechaInicio__c = currentDate,
            fan_FechaFin__c = currentDate.addMonths(8),
            fan_Activo__c = active,
            fan_Catalogo_referencias__c = category,
            fan_Grupo_de_compradores__c = buyerGroupId,
            fan_Dia_Inicial__c = 1,
            fan_Dia_Final__c = Date.daysInMonth(currentDate.year(), currentDate.month())
        );
    }

    public static Pricebook2 buildPricebook(String name, Boolean isActive) {
        return new Pricebook2(
            Name = name,
            IsActive = isActive
        );
    }

    public static PricebookEntry createPricebookEntry(String pricebookId, String productId, Decimal unitPrice) {
        PricebookEntry pricebookEntry = buildPricebookEntry(pricebookId, productId, unitPrice);
        INSERT pricebookEntry;
        return pricebookEntry;
    }

    public static PricebookEntry buildPricebookEntry(String pricebookId, String productId, Decimal unitPrice) {
        return new PricebookEntry(
            IsActive = true,
            Product2Id = productId,
            Pricebook2Id = pricebookId,
            UnitPrice = unitPrice
        );
    }

    public static void createBuyerGroupPricebook(String buyerGroupId, String pricebook2Id, Integer priority, Boolean isActive) {
        INSERT new BuyerGroupPricebook(
            BuyerGroupId = buyerGroupId,
            Pricebook2Id = pricebook2Id,
            Priority = priority,
            IsActive = isActive
        );
    }

    public static void createServiceEndpoint(String name, String url) {
        fan_ServiceEndpoint__c serviceEndpoint = buildServiceEndpoint(name, url, null, null);
        INSERT serviceEndpoint;
    }

    public static fan_ServiceEndpoint__c buildServiceEndpoint(String name, String url, String username, String password) {
        return new fan_ServiceEndpoint__c(
            Nombre__c = name,
            url__c = url,
            usuario__c = username,
            contrasena__c = password
        );
    }

    public static WebCart createWebCart(String webStoreId, String accountId, String formaPago) {
        WebCart webCart = buildWebCart(webStoreId, accountId, formaPago);
        INSERT webCart;
        return webCart;
    }

    public static WebCart buildWebCart(String webStoreId, String accountId, String formaPago) {
        return new WebCart(
            Name = 'WebCart Test',
            AccountId = accountId,
            WebStoreId = webStoreId,
            fan_FormaPago__c = formaPago
        );
    }

    public static WebStore createWebStore(String name) {
        WebStore webStore = new WebStore(Name = name);
        INSERT webStore;
        return webStore;
    }

    public static WebStoreCatalog createWebStoreCatalog(String ProductCatalogId, String webStoreId) {
        WebStoreCatalog webStoreCatalog = new WebStoreCatalog(
            ProductCatalogId = productCatalogId,
            SalesStoreId = webStoreId
        );
        INSERT webStoreCatalog;
        return webStoreCatalog;
    }

    public static void createWebStoreBuyerGroup(String buyerGroupId, String webstoreId) {
        INSERT new WebStoreBuyerGroup(
            WebstoreId = webstoreId,
            BuyerGroupId = buyerGroupId
        );
    }

    public static ConnectApi.PricingResult buildPricingResult(String productId, Decimal listPrice, Decimal unitPrice) {

        ConnectApi.PricingResultLineItem pricingResultLineItem = new ConnectApi.PricingResultLineItem();
        pricingResultLineItem.productId = productId;
        pricingResultLineItem.listPrice = String.valueOf(listPrice);
        pricingResultLineItem.unitPrice = String.valueOf(unitPrice);

        ConnectApi.PricingResult pricingResult = new ConnectApi.PricingResult();
        pricingResult.pricingLineItemResults = new ConnectApi.PricingResultLineItem[] { pricingResultLineItem };
        return pricingResult;
    }

    public static User createUser(String username, String email, String profileId, String contactId) {
        User user = new User(
            Lastname = 'User test',
            Alias = 'UserTest',
            Email = email,
            Username = username,
            ContactId = contactId,
            TimeZoneSidKey = 'America/Bogota',
            LocaleSidKey = 'es_CO',
            EmailEncodingKey = 'ISO-8859-1',
            ProfileId = profileId,
            LanguageLocaleKey = 'es'
        );
        INSERT user;
        return user;
    }

    public static PriceBookEntry createPriceBookEntry2(String productId, String priceBookId, Decimal UnitPrice)
    {
       PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = priceBookId;
        pbe.Product2Id = productId;
        pbe.UnitPrice = UnitPrice;
        pbe.IsActive = true;

       return pbe ;
    }
}