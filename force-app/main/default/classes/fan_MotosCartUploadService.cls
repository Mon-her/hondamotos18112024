public with sharing class fan_MotosCartUploadService implements fan_CartUploadService {

    public fan_B2BAddToCartUtil.ImportItem[] buildItemList(
        String[] lines,
        Integer row,
        Boolean defaultBackorder,
        Map<String, String> skuReference
      ) {
        fan_B2BAddToCartUtil.ImportItem[] importItems = new List<fan_B2BAddToCartUtil.ImportItem>();
        Map<String, Map<String, fan_B2BAddToCartUtil.ImportItem>> skusByBranch = new Map<String, Map<String, fan_B2BAddToCartUtil.ImportItem>>();
        fan_B2BAddToCartUtil.ImportItem[] lineWithError = new List<fan_B2BAddToCartUtil.ImportItem>();

        for (String singleLine : lines) {
          row++;
          String[] values = singleLine.split(',');
          System.debug('Line to process Values >>> ' + values);
    
          if (values.isEmpty()) {
            continue;
          }

          String sku = skuReference.get(values[0]);
          Decimal qty = ( values.size() == 1 || String.isBlank(values[1]) || !values[1].isNumeric())? null : Decimal.valueOf(values[1].trim());
          String cpaCode = (values.size() < 3 || String.isBlank(values[2])) ? null: values[2].trim();

          if (String.isBlank(sku)) {
            fan_B2BAddToCartUtil.ImportItem invalidItem = new fan_B2BAddToCartUtil.ImportItem();
            invalidItem.row = row;
            invalidItem.sku = sku;
            invalidItem.errorMsg = Label.fan_B2B_SKU_is_not_valid;
            importItems.add(invalidItem);
          }

          if ( qty == null || cpaCode == null) {
            fan_B2BAddToCartUtil.ImportItem item = new fan_B2BAddToCartUtil.ImportItem();
            item.row = row;
            if (qty == null) {
              item.errorMsg = Label.fan_invalidQuantity;
            } else if (cpaCode == null) {
              item.errorMsg = Label.fan_invalidCPACode;
            }
            lineWithError.add(item);
            continue;
          }

          Map<String, fan_B2BAddToCartUtil.ImportItem> skuMap = skusByBranch.get(cpaCode);
          if (skuMap == null) {
              skuMap = new Map<String, fan_B2BAddToCartUtil.ImportItem>();
              skusByBranch.put(cpaCode, skuMap);
          }

          fan_B2BAddToCartUtil.ImportItem item = skuMap.get(sku);
          if (item == null) {
              item = new fan_B2BAddToCartUtil.ImportItem();
              item.row = row;
              item.sku = sku;
              item.qty = qty;
              item.bo = defaultBackorder;
              item.cpaCode = cpaCode;
          } else {
              item.qty += qty;
          }

          skuMap.put(sku, item);
        }

        if (!lineWithError.isEmpty()) {
          return lineWithError;
        }
    
        for (
          Map<String, fan_B2BAddToCartUtil.ImportItem> skus : skusByBranch.values()
        ) {
          importItems.addAll(skus.values());
        }
        System.debug(
          'createItemList importItems >>> ' + JSON.serialize(importItems)
        );
        return importItems;
      }

    public ConnectApi.CartItemInput[] createCartItems(String cartId, String effectiveAccountId, fan_B2BAddToCartUtil.ImportItem[] importItems, Map<String, Object> responseMap) {

        Set<String> cpaCodes = extractCPACodes(importItems);
        Map<String, ContactPointAddress> contactPointAddresses = getShippingAddresses(cpaCodes, effectiveAccountId);

        // Check faulty codes.
        cpaCodes.removeAll(contactPointAddresses.keySet());
        if(!cpaCodes.isEmpty()) {
            processInvalidCPACodes(importItems, cpaCodes, responseMap);
            throw new fan_B2BAddToCartUtil.CustomException(Label.fan_cpaCodesNotFound);
        }
        Map<String, String> cartDeliveryGroupIdByCode = resolveCartDeliveryGroups(cartId, contactPointAddresses);
        return buildCartItemInputs(importItems, cartDeliveryGroupIdByCode);
    }

    ConnectApi.CartItemInput[] buildCartItemInputs(fan_B2BAddToCartUtil.ImportItem[] importItems, Map<String, String> cartDeliveryGroupIdByCode) {
        ConnectApi.CartItemInput[] cartItemInputs = new List<ConnectApi.CartItemInput>();

        for (fan_B2BAddToCartUtil.ImportItem importItem : importItems) {
            if(importItem.isValid) {
                ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();
                cartItemInput.productId = importItem.productId;
                cartItemInput.quantity = importItem.qty.toPlainString();
                cartItemInput.type = ConnectApi.CartItemType.Product;
                cartItemInput.cartDeliveryGroupId = cartDeliveryGroupIdByCode.get(importItem.cpaCode);
                cartItemInputs.add(cartItemInput);
            }
        }
        return cartItemInputs;
    }

    Map<String, ContactPointAddress> getShippingAddresses(Set<String> cpaCodes, String accountId) {
        Map<String, ContactPointAddress> contactPointAddresses = new Map<String, ContactPointAddress>();
        for (ContactPointAddress contactPointAddress : [SELECT fan_Code__c, Name, City, Country, Street, State, PostalCode, GeocodeAccuracy, Latitude, Longitude
                                                            FROM ContactPointAddress
                                                            WHERE ParentId =: accountId
                                                            AND AddressType = :fan_Constants.ContactPointAddressType.SHIPPING.name()
                                                            AND fan_Code__c IN: cpaCodes]) {
            contactPointAddresses.put(contactPointAddress.fan_Code__c, contactPointAddress);
        }
        return contactPointAddresses;
    }

    Map<String, String> getCartDeliveryGroupIdByCode(String cartId, Set<String> contactPointAddressCodes) {

        CartDeliveryGroup[] cartDeliveryGroups = [SELECT fan_CPACode__c FROM CartDeliveryGroup WHERE CartId = :cartId AND fan_CPACode__c IN :contactPointAddressCodes];

        return addCartDeliveryGroupsToCartDeliveryGroupIdByCode(new Map<String, String>(), cartDeliveryGroups);
    }

    Map<String, String> addCartDeliveryGroupsToCartDeliveryGroupIdByCode(Map<String, String> cartDeliveryGroupIdByCode, CartDeliveryGroup[] cartDeliveryGroups) {
        
        Map<String, String> cartDeliveryGroupIdByCodeClone = new Map<String, String>(cartDeliveryGroupIdByCode);

        for (CartDeliveryGroup cartDeliveryGroup : cartDeliveryGroups) { 
            cartDeliveryGroupIdByCodeClone.put(cartDeliveryGroup.fan_CPACode__c, cartDeliveryGroup.Id);
        }
        return cartDeliveryGroupIdByCodeClone;
    }

    // Inserts or updates cartDeliverygroups.
    Map<String, String> resolveCartDeliveryGroups(String cartId, Map<String, ContactPointAddress> contactPointAddresses) {

        Set<String> cpaCodesToQuery = new Set<String>(contactPointAddresses.keySet());
        cpaCodesToQuery.add(null);
        Map<String, String> cartDeliveryGroupIdByCode = getCartDeliveryGroupIdByCode(cartId, cpaCodesToQuery);

        Set<String> enteredCodes = new Set<String>(contactPointAddresses.keySet());
        // Leave only unregistered cart delivery group codes.
        enteredCodes.removeAll(cartDeliveryGroupIdByCode.keySet());
        String[] cpaCodesToCreate = new List<String>(enteredCodes);

        CartDeliveryGroup[] upsertedCartDeliveryGroups = upsertCartDeliveryGroups(cartId, cpaCodesToCreate, contactPointAddresses, cartDeliveryGroupIdByCode);
        return addCartDeliveryGroupsToCartDeliveryGroupIdByCode(cartDeliveryGroupIdByCode, upsertedCartDeliveryGroups);
    }

    CartDeliveryGroup[] upsertCartDeliveryGroups(String cartId, String[] cpaCodesToCreate, Map<String, ContactPointAddress> contactPointAddresses, Map<String, String> cartDeliveryGroupIdByCode) {

        CartDeliveryGroup[] cartDeliveryGroupsToUpsert = new List<CartDeliveryGroup>();

        // Reuse default Cart Delivery Group.
        if(!cpaCodesToCreate.isEmpty() && cartDeliveryGroupIdByCode.containsKey(null)) {
            String firstCPACode = cpaCodesToCreate.remove(0);
            String cartDeliveryGroupId = cartDeliveryGroupIdByCode.remove(null);
            ContactPointAddress contactPointAddress = contactPointAddresses.get(firstCPACode);
            cartDeliveryGroupsToUpsert.add(buildCartDeliveryGroup(cartId, cartDeliveryGroupId, contactPointAddress));
        }

        for(String cpaCode : cpaCodesToCreate) {
            ContactPointAddress contactPointAddress = contactPointAddresses.get(cpaCode);
            cartDeliveryGroupsToUpsert.add(buildCartDeliveryGroup(cartId, null, contactPointAddress));
        }
        UPSERT cartDeliveryGroupsToUpsert;
        return cartDeliveryGroupsToUpsert;
    }

    CartDeliveryGroup buildCartDeliveryGroup(String cartId, String cartDeliveryGroupId, ContactPointAddress contactPointAddress) {
        return new CartDeliveryGroup(
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
            fan_CPACode__c = contactPointAddress.fan_Code__c,
            cartId = cartId
        );
    }

    // Generate validation message for invalid CPA Codes.
    void processInvalidCPACodes(fan_B2BAddToCartUtil.ImportItem[] importItems, Set<String> invalidCPACodes, Map<String, Object> responseMap) {

        String message = Label.fan_cpaCodesNotFound + ' ';
        Integer numberOfInvalidCPACodes = 0;
        Iterator<fan_B2BAddToCartUtil.ImportItem> iterator = importItems.iterator();

        while (iterator.hasNext()) {
            fan_B2BAddToCartUtil.ImportItem importItem = iterator.next();
            String cpaCode = importItem.cpaCode;

            if(invalidCPACodes.contains(cpaCode)) {
                numberOfInvalidCPACodes += importItem.isValid ? 1 : 0;
                message += cpaCode;
                message += iterator.hasNext() ? ', ' : '';
            }
        }
        fan_B2BAddToCartUtil.addMessage(new fan_B2BAddToCartUtil.Message(
                Label.fan_B2B_Cart_Upload_Processing_Error, 
                message,
                fan_B2BAddToCartUtil.ERROR,
                false), 
                0, responseMap);
        fan_B2BAddToCartUtil.updateResponseMapTotalValue('totErrors', numberOfInvalidCPACodes, responseMap);
    }

    Set<String> extractCPACodes(fan_B2BAddToCartUtil.ImportItem[] importItems) {
        Set<String> cpaCodes = new Set<String>();

        for(fan_B2BAddToCartUtil.ImportItem importItem : importItems) {
            if(importItem.isValid) {
                cpaCodes.add(importItem.cpaCode);
            }
        }
        return cpaCodes;
    }
}