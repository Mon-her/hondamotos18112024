@IsTest
class fan_B2BSearchCtrlTest {

	@TestSetup
	static void makeData(){
		Product2 variantParent = fan_B2BTestDataFactory.createProduct('VariantParent-SKU', 'VariantParent-ProductCode', 'Base');
		Product2 variantChild1 = fan_B2BTestDataFactory.createProduct('VariantChild-SKU-1', 'VariantChild-ProductCode1', null);
		Product2 variantChild2 = fan_B2BTestDataFactory.createProduct('VariantChild-SKU-2', 'VariantChild-ProductCode2', null);

		INSERT new ProductAttributeSetProduct(
			ProductAttributeSetId = [SELECT Id FROM ProductAttributeSet WHERE DeveloperName = 'Motos_Color'].Id,
			ProductId = variantParent.Id
		);
		fan_B2BTestDataFactory.createProductAttribute(variantParent.Id, variantChild1.Id, ProductAttribute.fan_Color__c,  'ROJO');
		fan_B2BTestDataFactory.createProductAttribute(variantParent.Id, variantChild2.Id, ProductAttribute.fan_Color__c, 'AZUL');

		Account account = fan_B2BTestDataFactory.createAccount('123456789', 'NIT');
		fan_B2BTestDataFactory.createBuyerAccount(account.Id);
		BuyerGroup buyerGroup = fan_B2BTestDataFactory.createBuyerGroup('Test BuyerGroup');
		fan_B2BTestDataFactory.createBuyerGroupMember(account.Id, buyerGroup.Id);

		CommerceEntitlementPolicy commerceEntitlementPolicy = fan_B2BTestDataFactory.createCommerceEntitlementPolicy('Test CommerceEntitlementPolicy');
		fan_B2BTestDataFactory.createCommerceEntitlementBuyerGroup(buyerGroup.Id, commerceEntitlementPolicy.Id);
		fan_B2BTestDataFactory.createCommerceEntitlementProduct(variantParent.Id, commerceEntitlementPolicy.Id);
		fan_B2BTestDataFactory.createCommerceEntitlementProduct(variantChild1.Id, commerceEntitlementPolicy.Id);
	}

	@IsTest
	static void getProductCategoryPath() {
		ConnectApi.ProductCategoryData testProductCategoryData = new ConnectApi.ProductCategoryData();
		testProductCategoryData.id = 'ProductCategoryDataId';
		testProductCategoryData.name = 'ProductCategoryDataName';
		testProductCategoryData.description = 'ProductCategoryDataDescription';

		ConnectApi.ProductCategoryPath productCategoryPath = new ConnectApi.ProductCategoryPath();
		productCategoryPath.path = new ConnectApi.ProductCategoryData[] { testProductCategoryData };

		fan_B2BSearchCtrl.testProductCategoryPath = productCategoryPath;

		ConnectApi.ProductCategoryData[] path = fan_B2BSearchCtrl.getProductCategoryPath('communityId', 'categoryId');

		ConnectApi.ProductCategoryData productCategoryData = path[0];

		Assert.areEqual(testProductCategoryData.id, productCategoryData.id, 'The id of the ProductCategoryData is not as expected.');
		Assert.areEqual(testProductCategoryData.id, productCategoryData.id, 'The name of the ProductCategoryData is not as expected.');
		Assert.areEqual(testProductCategoryData.id, productCategoryData.id, 'The description of the ProductCategoryData is not as expected.');
	}

	@IsTest
	static void getProductCategoryPathShouldThrowAnException() {
		try {
			fan_B2BSearchCtrl.getProductCategoryPath('', '');
			Assert.fail('An AuraHandledException was expected.');
		} catch (Exception e) {
			Assert.isInstanceOfType(e, AuraHandledException.class, 'An exception was expected.');
		}
	}

	@IsTest
	static void getSortRules() {

		ConnectApi.SortRule testSortRule = new ConnectApi.SortRule();
		testSortRule.label = 'Best match';
		testSortRule.direction = ConnectApi.CommerceSearchSortRuleDirection.DEFAULT;
		testSortRule.nameOrId = 'Best match';
		testSortRule.sortOrder = 1;
		testSortRule.sortRuleId = 'SortRuleId';
		testSortRule.type = ConnectApi.CommerceSearchSortRuleType.RELEVANCY;

		ConnectApi.SortRulesCollection sortRulesCollection = new ConnectApi.SortRulesCollection();
		sortRulesCollection.sortRules = new ConnectApi.SortRule[] { testSortRule };

		fan_B2BSearchCtrl.testSortRulesCollection = sortRulesCollection;

		ConnectApi.SortRule[] sortRules = fan_B2BSearchCtrl.getSortRules('comunnityId');

		ConnectApi.SortRule sortRule = sortRules[0];
		Assert.areEqual(testSortRule.label, sortRule.label, 'The label of the SortRule is not as expected.');
		Assert.areEqual(testSortRule.direction, sortRule.direction, 'The direction of the SortRule is not as expected.');
		Assert.areEqual(testSortRule.nameOrId, sortRule.nameOrId, 'The nameOrId of the SortRule is not as expected.');
		Assert.areEqual(testSortRule.sortOrder, sortRule.sortOrder, 'The sortOrder of the SortRule is not as expected.');
		Assert.areEqual(testSortRule.sortRuleId, sortRule.sortRuleId, 'The sortRuleId of the SortRule is not as expected.');
		Assert.areEqual(testSortRule.type, sortRule.type, 'The type of the SortRule is not as expected.');
	}

	@IsTest
	static void getSortRulesThrowAnException() {
		try {
			fan_B2BSearchCtrl.getSortRules('comunnityId');
			Assert.fail('An AuraHandledException was expected.');
		} catch (Exception e) {
			Assert.isInstanceOfType(e, AuraHandledException.class, 'An exception was expected.');
		}
	}

	@IsTest
	static void productSearch() {
		String accountId = [SELECT Id FROM Account LIMIT 1].Id;
		Set<String> productIds = new Map<String, Product2>([SELECT Id FROM Product2 WHERE ProductClass = 'Variation']).keySet();

		ConnectApi.ProductSearchResults testProductSearchResults = new ConnectApi.ProductSearchResults();
		testProductSearchResults.locale = 'es';

		ConnectApi.ProductSummary productSummary = new ConnectApi.ProductSummary();
		productSummary.id = [SELECT Id FROM Product2 WHERE StockKeepingUnit = 'VariantParent-SKU'].Id;

		ConnectApi.ProductSummaryPage productSummaryPage = new ConnectApi.ProductSummaryPage();
		productSummaryPage.currencyIsoCode = 'COP';
		productSummaryPage.pageSize = 0;
		productSummaryPage.total = 1;

		productSummaryPage.products = new ConnectApi.ProductSummary[] { productSummary };
		testProductSearchResults.productsPage = productSummaryPage;

		ProductMedia[] productMedias = fan_B2BTestDataFactory.generateProductMedias(productIds);

		ConnectApi.ManagedContentVersionCollection managedContentVersionCollection = new ConnectApi.ManagedContentVersionCollection();
		managedContentVersionCollection.items = fan_B2BTestDataFactory.generateManagedContentVersions(productMedias).values();

		fan_B2BSearchCtrl.testProductSearchResults = testProductSearchResults;
		fan_B2BSearchCtrl.testProductMedias = productMedias;
		fan_B2BSearchCtrl.testManagedContentVersionCollection = managedContentVersionCollection;

		fan_B2BSearchCtrl.ProductSearchResultsWrapper productSearchResults = fan_B2BSearchCtrl.productSearch('communityId', accountId, '{ "fields": ["Name"] }');

		Assert.areEqual('es', productSearchResults.locale, 'The locale of the productSearchResultsWrapper is not as expected.');
		Assert.areEqual('COP', productSearchResults.productsPage.currencyIsoCode, 'The currencyIsoCode of the ProductSummaryPageWrapper is not as expected.');
		Assert.areEqual(0, productSearchResults.productsPage.pageSize, 'The pageSize of the ProductSummaryPageWrapper is not as expected.');
		Assert.areEqual(1, productSearchResults.productsPage.total, 'The total of the ProductSummaryPageWrapper is not as expected.');
		Assert.areEqual(1, productSearchResults.productsPage.products.size(), 'The size of the productSummaries is not as expected.');
	}

	@IsTest
	static void productSearchShouldThrowAnException() {
		try {
			fan_B2BSearchCtrl.productSearch('', '', '');
			Assert.fail('An AuraHandledException was expected.');
		} catch (Exception e) {
			Assert.isInstanceOfType(e, AuraHandledException.class, 'An exception was expected.');
		}
	}

	@IsTest
	static void buildFields() {

		ProductAttribute productAttribute = new ProductAttribute();
		productAttribute.Product = new Product2(
			Name = 'ProductName',
			Referencia__c = 'ProductReferencia'
		);
		String[] fieldsToShow = new String[] { 'Name', 'Referencia__c' };

		String[] fields = new fan_B2BSearchCtrl.ProductSummaryWrapper().buildFields(fieldsToShow, productAttribute);

		Assert.areEqual('ProductName', fields[0], 'The first field is not as expected.');
		Assert.areEqual('ProductReferencia', fields[1], 'The second field is not as expected.');
	}

	@IsTest
	static void buildDefaultImage() {

		String productId = [SELECT Id FROM Product2 WHERE StockKeepingUnit = 'VariantChild-SKU-1'].Id;
		ProductMedia[] productMedias = fan_B2BTestDataFactory.generateProductMedias(new Set<String> { productId });
		Map<String, ConnectApi.ManagedContentVersion> managedContentVersions = fan_B2BTestDataFactory.generateManagedContentVersions(productMedias);
		fan_B2BSearchCtrl.ProductMediaWrapper productMediaWrapper = new fan_B2BSearchCtrl.ProductSummaryWrapper().buildDefaultImage(productId, managedContentVersions);

		Assert.areEqual('http://productimage0.png', productMediaWrapper.url, 'The url of the ProductMediaWrapper is not as expected.');
		Assert.areEqual('alternate text 0', productMediaWrapper.alternateText, 'The alternateText of the ProductMediaWrapper is not as expected.');	
	}

	@IsTest
	static void getParentVariantIds() {

		ConnectApi.ProductSummary productSummary = new ConnectApi.ProductSummary();
		productSummary.id = 'productSummaryId';

		ConnectApi.ProductSummary[] productSummaries = new ConnectApi.ProductSummary[] { productSummary };

		Set<String> parentVariantIds = fan_B2BSearchCtrl.getParentVariantIds(productSummaries);

		Assert.isTrue(parentVariantIds.contains(productSummary.id), 'The Id of the ParentVariant is not as expected.');
	}

	@IsTest
	static void sortProductSummaries() {

        Map<String, fan_B2BSearchCtrl.ProductSummaryWrapper[]> productSummaries = new Map<String, fan_B2BSearchCtrl.ProductSummaryWrapper[]> {
			'ParentVariantId1' => null,
			'ParentVariantId3' => null,
			'ParentVariantId2' => null
		};
		Set<String> parentVariantIds = new Set<String> { 'ParentVariantId3', 'ParentVariantId2', 'ParentVariantId1' };

		Map<String, fan_B2BSearchCtrl.ProductSummaryWrapper[]> sortedProductSummaries =  fan_B2BSearchCtrl.sortProductSummaries(parentVariantIds, productSummaries);

		String[] sortedParentVariantIds = new List<String>(sortedProductSummaries.keySet());

		Assert.areEqual('ParentVariantId3', sortedParentVariantIds[0], 'The first ParentVariantId is not as expected.');
		Assert.areEqual('ParentVariantId2', sortedParentVariantIds[1], 'The second ParentVariantId is not as expected.');
		Assert.areEqual('ParentVariantId1', sortedParentVariantIds[2], 'The third ParentVariantId is not as expected.');
	}

	@IsTest
	static void buildProductSummaries() {

		Set<String> childVariantIds = new Set<String>();
		Map<String, ProductAttribute> productAttributes = new Map<String, ProductAttribute>();
		for (ProductAttribute productAttribute : [SELECT VariantParentId, fan_Color__c, Product.Name, Product.fan_swatch__c FROM ProductAttribute]) {
			childVariantIds.add(productAttribute.ProductId);
			productAttributes.put(productAttribute.ProductId, productAttribute);
		}
		ProductMedia[] productMedias = fan_B2BTestDataFactory.generateProductMedias(childVariantIds);
		Map<String, ConnectApi.ManagedContentVersion> managedContentVersions = fan_B2BTestDataFactory.generateManagedContentVersions(productMedias);
		String[] fieldsToShow = new String[] { 'Name' };

		Map<String, fan_B2BSearchCtrl.ProductSummaryWrapper[]> productSummaries = fan_B2BSearchCtrl.buildProductSummaries(childVariantIds, productAttributes, managedContentVersions, fieldsToShow);

		Assert.isFalse(productSummaries.isEmpty(), 'The ProductSummaries is empty.');
		Assert.areEqual(2, productSummaries.values()[0].size(), 'The size of the productSummaries is not as expected.');
	}

	@IsTest
	static void getProductImages() {

		ConnectApi.ManagedContentVersionCollection testManagedContentVersionCollection = new ConnectApi.ManagedContentVersionCollection();

		String productId = [SELECT Id FROM Product2 WHERE StockKeepingUnit = 'VariantChild-SKU-1'].Id;
		ProductMedia[] productMedias = fan_B2BTestDataFactory.generateProductMedias(new Set<String> { productId });

		testManagedContentVersionCollection.items = fan_B2BTestDataFactory.generateManagedContentVersions(productMedias).values();
		fan_B2BSearchCtrl.testProductMedias = productMedias;

		fan_B2BSearchCtrl.testManagedContentVersionCollection = testManagedContentVersionCollection;
        Map<String, ConnectApi.ManagedContentVersion> managedContentVersions = fan_B2BSearchCtrl.getProductImages('communityId', new Set<String> { productId });

		ConnectApi.ManagedContentVersion managedContentVersion = managedContentVersions.get(productId);

		String url = ((ConnectApi.ManagedContentMediaSourceNodeValue) managedContentVersion.contentNodes.get('source')).url;
		String altText = ((ConnectApi.ManagedContentTextNodeValue) managedContentVersion.contentNodes.get('altText')).value;

		Assert.areEqual('http://productimage0.png', url, 'The url of the contentNode is not as expected.');
		Assert.areEqual('alternate text 0', altText, 'The value of the contentNode is not as expected.');
	}

	@IsTest
	static void getProductAttributes() {

		String accountId = [SELECT Id FROM Account LIMIT 1].Id;
		Set<String> productIds = new Set<String> {
			[SELECT Id FROM Product2 WHERE StockKeepingUnit = 'VariantParent-SKU'].Id
		};
		String[] fields = new String[]{ 'Name' };
		Map<String, ProductAttribute> productAttributes = fan_B2BSearchCtrl.getProductAttributes(accountId, productIds, fields);

		Assert.areEqual(1, productAttributes.size(), 'The size of the productAttributes is not as expected.');
	}

	@IsTest
	static void getProductAvailablesByAccount() {

		String accountId = [SELECT Id FROM Account LIMIT 1].Id;
		String productId = [SELECT Id FROM Product2 WHERE StockKeepingUnit = 'VariantParent-SKU'].Id;
		Set<String> availableProductIds = fan_B2BSearchCtrl.getProductAvailablesByAccount(accountId, new Set<String> { productId });

		Assert.isTrue(availableProductIds.contains(productId), 'The product is not available.');
	}
}