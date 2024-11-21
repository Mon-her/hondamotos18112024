public with sharing class fan_B2BWishlistCtrl {

    // For unit test
    public static ConnectApi.WishlistsSummary testWishlistsSummary;
    public static ConnectApi.Wishlist testWishlist;
    public static ConnectApi.WishlistItem testWishlistItem;

    @AuraEnabled
    public static ConnectApi.WishlistsSummary getWishlistSummaries(
        String communityId,
        String effectiveAccountId,
        Boolean includeDisplayedList
        ){

        // Lookup the webstore ID associated with the community
        String webstoreId = Test.isRunningTest() ? null : fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

        // https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_ConnectAPI_CommerceWishlist_static_methods.htm#apex_ConnectAPI_CommerceWishlist_getWishlistSummaries_3
        return Test.isRunningTest() ? testWishlistsSummary : ConnectApi.CommerceWishlist.getWishlistSummaries(webstoreId, effectiveAccountId, includeDisplayedList);
    }

    @AuraEnabled
    public static ConnectApi.Wishlist createAndAddToWishlist(
        String communityId,
        String productId,
        String wishlistName,
        String effectiveAccountId
    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId = Test.isRunningTest() ? null : fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

        // Store the product in a WishlistItemInput to pass to the Wishlist
        ConnectApi.WishlistItemInput wishlistItemInput = new ConnectApi.WishlistItemInput();
        wishlistItemInput.productId = productId;

        //Create a wishlistInput to be created
        ConnectApi.WishlistInput wishlistInput = new ConnectApi.WishlistInput();
        wishlistInput.name = wishlistName;
        wishlistInput.products = new List<ConnectApi.WishlistItemInput>{
          wishlistItemInput
        };

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceWishlist_static_methods.htm#apex_ConnectAPI_CommerceWishlist_static_methods
        return Test.isRunningTest() ? testWishlist : ConnectApi.CommerceWishlist.createWishlist(webstoreId, effectiveAccountId, wishlistInput);
    }

    @AuraEnabled
    public static ConnectApi.Wishlist createAndAllAddToWishlist(
        String communityId,
        ConnectApi.WishlistInput wishlistInput
    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId = Test.isRunningTest() ? null : fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceWishlist_static_methods.htm#apex_ConnectAPI_CommerceWishlist_static_methods
        return Test.isRunningTest() ? testWishlist : ConnectApi.CommerceWishlist.createWishlist(webstoreId, wishlistInput);
    }

    @AuraEnabled
    public static ConnectApi.WishlistItem addToWishlist(
        String communityId,
        String productId,
        String wishlistId
    ){

        // Lookup the webstore ID associated with the community
        String webstoreId = Test.isRunningTest() ? null : fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

        // Store the product in a WishlistItemInput to pass to the Wishlist
        ConnectApi.WishlistItemInput wishlistItemInput = new ConnectApi.WishlistItemInput();
        wishlistItemInput.productId = productId;

        // https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_ConnectAPI_CommerceWishlist_static_methods.htm#apex_ConnectAPI_CommerceWishlist_addItemToWishlist_4
        return Test.isRunningTest() ? testWishlistItem : ConnectApi.Commercewishlist.addItemToWishlist(webstoreId, wishlistId, wishlistItemInput);
    }

    @AuraEnabled
    public static void addAllToWishlist(
        String communityId,
        String wishlistId,
        Map<String, String> products
    ){
        // Lookup the webstore ID associated with the community
        String webstoreId = Test.isRunningTest() ? null : fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

        List<WishlistItem> wishlistItemsList = new List<WishlistItem>();

        try {
            // Resolve wishlist items to insert
            for (WishlistItem wi : [SELECT Product2Id FROM WishlistItem WHERE WishlistId =: wishlistId AND Product2Id IN: products.keySet()])
                products.remove(wi.Product2Id);

            for (String productId : products.keySet())
                wishlistItemsList.add(new WishlistItem(
                    WishlistId = wishlistId,
                    Product2Id = productId,
                    Name = products.get(productId)
                ));

            insert wishlistItemsList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}