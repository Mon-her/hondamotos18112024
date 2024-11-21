public without sharing class fan_B2BSearchCtrl {

    // For unit tests.
    @TestVisible
    static ConnectApi.ProductSearchResults testProductSearchResults;
    @TestVisible
    static ConnectApi.ManagedContentVersionCollection testManagedContentVersionCollection;
    @TestVisible
    static ConnectApi.SortRulesCollection testSortRulesCollection;
    @TestVisible
    static ConnectApi.ProductCategoryPath testProductCategoryPath;
    @TestVisible
    static ProductMedia[] testProductMedias;

    @AuraEnabled(cacheable=true)
    public static ConnectApi.ProductCategoryData[] getProductCategoryPath(String communityId, String productCategoryId) {
        try {
            String webStoreId = fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

            ConnectApi.ProductCategoryPath productCategoryPath = Test.isRunningTest() ? testProductCategoryPath : ConnectApi.CommerceCatalog.getProductCategoryPath(webstoreId, productCategoryId);

            return productCategoryPath.path;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static ConnectApi.SortRule[] getSortRules(String communityId) {
        try {
            String webStoreId = fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

            ConnectApi.SortRulesCollection sortRulesCollection = Test.isRunningTest() ? testSortRulesCollection : ConnectApi.CommerceSearch.getSortRules(webstoreId);

            return sortRulesCollection.sortRules;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @param communityId The Id of the community from which the call originated
     * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
     * @param productSearchInput A body with either a category ID or search terms.
     */
    @AuraEnabled
    public static ProductSearchResultsWrapper productSearch(
        String communityId,
        String effectiveAccountId,
        String productSearchInputJson
    ) {
        try {
            // Lookup the webstore ID associated with the community
            String webstoreId = fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);
            ConnectApi.ProductSearchInput productSearchInput = (ConnectApi.ProductSearchInput) JSON.deserialize(productSearchInputJson, ConnectApi.ProductSearchInput.class);
            ConnectApi.ProductSearchResults productSearchResults = Test.isRunningTest() ? testProductSearchResults : ConnectApi.CommerceSearch.searchProducts(webstoreId, effectiveAccountId, productSearchInput);

            Set<String> parentVariantIds = getParentVariantIds(productSearchResults.productsPage.products);
            Map<String, ProductAttribute> productAttributes = getProductAttributes(effectiveAccountId, parentVariantIds, productSearchInput.fields);

            Set<String> childVariantIds = productAttributes.keySet();
            Map<String, ConnectApi.ManagedContentVersion> managedContentVersions = getProductImages(communityId, childVariantIds);

            Map<String, ProductSummaryWrapper[]> productSummaries = buildProductSummaries(childVariantIds, productAttributes, managedContentVersions, productSearchInput.fields);
            productSummaries = sortProductSummaries(parentVariantIds, productSummaries);

            ProductSummaryPageWrapper productSummaryPage = new ProductSummaryPageWrapper(productSearchResults.productsPage, productSummaries);
            return new ProductSearchResultsWrapper(productSearchResults, productSummaryPage);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @TestVisible
    static Set<String> getProductAvailablesByAccount(String effectiveAccountId, Set<String> productIds) {

        Set<String> buyerGroupIds = new Set<String>();
        for (BuyerGroupMember buyerGroupMember : [SELECT BuyerGroupId FROM BuyerGroupMember WHERE BuyerId = :effectiveAccountId]) {
            buyerGroupIds.add(buyerGroupMember.BuyerGroupId);
        }

        Set<String> commerceEntitlementPolicyIds = new Set<String>();
        for (CommerceEntitlementBuyerGroup commerceEntitlementBuyerGroup : [SELECT PolicyId FROM CommerceEntitlementBuyerGroup WHERE BuyerGroupId =: buyerGroupIds AND Policy.IsActive = true AND Policy.CanViewProduct = true]) {
            commerceEntitlementPolicyIds.add(commerceEntitlementBuyerGroup.PolicyId);
        }

        Set<String> availableProductIds = new Set<String>();
        for (CommerceEntitlementProduct commerceEntitlementProduct : [SELECT ProductId FROM CommerceEntitlementProduct WHERE PolicyId IN :commerceEntitlementPolicyIds AND ProductId IN :productIds]) {
            availableProductIds.add(commerceEntitlementProduct.ProductId);
        }
        return availableProductIds;
    }

    @TestVisible
    static Map<String, ProductAttribute> getProductAttributes(String effectiveAccountId, Set<String> variantParentIds, String[] fields) {

        Set<String> variantChildIds = new Set<String>();
        Map<String, ProductAttribute> productAttributes = new Map<String, ProductAttribute>();

        String queryFields = 'VariantParentId,fan_Color__c,Product.fan_swatch__c' + (fields.isEmpty() ? '' : ',Product.' + String.join(fields, ',Product.'));

        for (ProductAttribute productAttribute : Database.query('SELECT ' + queryFields + ' FROM ProductAttribute WHERE VariantParentId IN :variantParentIds AND Product.IsActive = true')) {
            productAttributes.put(productAttribute.ProductId, productAttribute);
            variantChildIds.add(productAttribute.ProductId);
        }

        Set<String> availableProductIds = getProductAvailablesByAccount(effectiveAccountId, variantChildIds);
        for (String variantChildId : variantChildIds) {
            if(!availableProductIds.contains(variantChildId)) {
                productAttributes.remove(variantChildId);
            }
        }
        return productAttributes;
    }

    @TestVisible
    static Map<String, ConnectApi.ManagedContentVersion> getProductImages(String communityId, Set<String> productIds) {

        String[] electronicMediaIds = new List<String>();
        Map<String, String> electronicMedias = new Map<String, String>();
        Map<String, ConnectApi.ManagedContentVersion> managedContentVersions = new Map<String, ConnectApi.ManagedContentVersion>();
        ProductMedia[] productMedias = Test.isRunningTest() ? testProductMedias : [SELECT ElectronicMediaId, ProductId FROM ProductMedia WHERE ProductId IN :productIds];

        for (ProductMedia productMedia : productMedias) {
            electronicMedias.put(productMedia.ElectronicMediaId, productMedia.ProductId);
            electronicMediaIds.add(productMedia.ElectronicMediaId);
        }
        ConnectApi.ManagedContentVersionCollection managedContentVersionCollection = Test.isRunningTest() ? testManagedContentVersionCollection : ConnectApi.ManagedContent.getManagedContentByIds(communityId, electronicMediaIds, 0, 250, null, 'cms_image');

        for (ConnectApi.ManagedContentVersion managedContentVersion : managedContentVersionCollection.items) {
            String managedContentId = managedContentVersion.managedContentId;
            String productId = electronicMedias.get(managedContentId);
            managedContentVersions.put(productId, managedContentVersion);
        }
        return managedContentVersions;
    }

    @TestVisible
    static Map<String, ProductSummaryWrapper[]> buildProductSummaries(Set<String> childVariantIds, Map<String, ProductAttribute> productAttributes, Map<String, ConnectApi.ManagedContentVersion> managedContentVersions, String[] fieldsToShow) {

        Map<String, ProductSummaryWrapper[]> products = new Map<String, ProductSummaryWrapper[]>();
        for (String childVariantId : childVariantIds) {

            ProductAttribute productAttribute = productAttributes.get(childVariantId);
            String variantParentId = productAttribute.VariantParentId;

            ProductSummaryWrapper productSummary = new ProductSummaryWrapper(productAttribute, managedContentVersions, fieldsToShow);

            if(products.containsKey(variantParentId)) {
                products.get(variantParentId).add(productSummary);
            } else {
                products.put(variantParentId, new ProductSummaryWrapper[] { productSummary });
            }
        }
        return products;
    }

    @TestVisible
    static Set<String> getParentVariantIds(ConnectApi.ProductSummary[] productSummaries) {
        Set<String> parentVariantIds = new Set<String>();
        for (ConnectApi.ProductSummary productSummary : productSummaries) {
            parentVariantIds.add(productSummary.id);
        }
        return parentVariantIds;
    }

    @TestVisible
    static Map<String, ProductSummaryWrapper[]> sortProductSummaries(Set<String> parentVariantIds, Map<String, ProductSummaryWrapper[]> productSummaryWrappers) {

        Map<String, ProductSummaryWrapper[]> sortedProductSummaries = new Map<String, ProductSummaryWrapper[]>();

        for (String parentVariantId : parentVariantIds) {
            sortedProductSummaries.put(parentVariantId, productSummaryWrappers.get(parentVariantId));
        }
        return sortedProductSummaries;
    }

    @TestVisible
    class ProductSearchResultsWrapper {
        @AuraEnabled
        public ConnectApi.SearchCategory categories;
        @AuraEnabled
        public String locale;
        @AuraEnabled
        public ConnectApi.SearchFacet[] facets;
        @AuraEnabled
	    public ProductSummaryPageWrapper productsPage;

        public ProductSearchResultsWrapper (ConnectApi.ProductSearchResults productSearchResults, ProductSummaryPageWrapper productSummaryPage) {
            this.categories = productSearchResults.categories;
            this.facets = productSearchResults.facets;
            this.locale = productSearchResults.locale;
            this.productsPage = productSummaryPage;
        }
    }

    @TestVisible
    class ProductSummaryPageWrapper {
        @AuraEnabled
        public String currencyIsoCode;
        @AuraEnabled
        public Integer pageSize;
        @AuraEnabled
        public Long total;
        @AuraEnabled
        public Map<String, ProductSummaryWrapper[]> products; 

        public ProductSummaryPageWrapper(ConnectApi.ProductSummaryPage productSummaryPage, Map<String, ProductSummaryWrapper[]> products) {
            this.currencyIsoCode = productSummaryPage.currencyIsoCode;
            this.pageSize = productSummaryPage.pageSize;
            this.products = products;
            this.total = productSummaryPage.total;
        }
    }

    @TestVisible
    class ProductSummaryWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public Swatch swatch;
        @AuraEnabled
        public ProductMediaWrapper defaultImage;
        @AuraEnabled
        public String[] fields;

        public ProductSummaryWrapper() {}

        public ProductSummaryWrapper(ProductAttribute productAttribute, Map<String, ConnectApi.ManagedContentVersion> managedContentVersions, String[] fieldsToShow) {
            this.id = productAttribute.ProductId;
            this.swatch = new Swatch(productAttribute);
            this.defaultImage = buildDefaultImage(productAttribute.ProductId, managedContentVersions);
            this.fields = buildFields(fieldsToShow, productAttribute);
        }

        @TestVisible
        String[] buildFields(String[] fieldsToShow, ProductAttribute productAttribute) {

            String[] fields = new List<String>();

            for (String fieldName : fieldsToShow) {
                Object fieldValue = productAttribute.Product.get(fieldName);
                fields.add(String.valueOf(fieldValue));
            }
            return fields;
        }

        @TestVisible
        ProductMediaWrapper buildDefaultImage(String productId, Map<String, ConnectApi.ManagedContentVersion> managedContentVersions) {

            ProductMediaWrapper productMedia = new ProductMediaWrapper('', '/img/b2b/default-product-image.svg');

            if(managedContentVersions.containsKey(productId)) {
                Map<String, ConnectApi.ManagedContentNodeValue> contentNodes = managedContentVersions.get(productId).contentNodes;
                productMedia.url = ((ConnectApi.ManagedContentMediaSourceNodeValue) contentNodes.get('source')).url;
                productMedia.alternateText = ((ConnectApi.ManagedContentTextNodeValue) contentNodes.get('altText'))?.value;
            }
            return productMedia;
        }
    }

    class Swatch {
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String url;

        public Swatch(ProductAttribute productAttribute) {
            this.title = productAttribute.fan_Color__c;
            this.url = productAttribute.Product.fan_swatch__c;
        }
    }

    @TestVisible
    class ProductMediaWrapper {
        @AuraEnabled
        public String alternateText;
        @AuraEnabled
        public String url;

        public ProductMediaWrapper(String alternateText, String url) {
            this.alternateText = alternateText;
            this.url = url;
        }
    }
}