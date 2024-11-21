public with sharing class fan_PosventaCartUploadService implements fan_CartUploadService {
  public fan_B2BAddToCartUtil.ImportItem[] buildItemList(
    String[] lines,
    Integer row,
    Boolean defaultBackorder,
    Map<String, String> skuReference
  ) {
    fan_B2BAddToCartUtil.ImportItem[] importItems = new fan_B2BAddToCartUtil.ImportItem[]{};
    Map<String, fan_B2BAddToCartUtil.ImportItem> skuMap = new Map<String, fan_B2BAddToCartUtil.ImportItem>();
    fan_B2BAddToCartUtil.ImportItem[] lineWithError = new List<fan_B2BAddToCartUtil.ImportItem>();

    for (String singleLine : lines) {
      row++;
      String[] values = singleLine.split(',');
      System.debug('Line to process Values >>> ' + values);

      if (values.isEmpty()) {
        continue;
      }
      String sku = skuReference.get(values[0]);
      Decimal qty = (values.size() == 1 ||
        String.isBlank(values[1]) ||
        !values[1].isNumeric())
        ? null
        : Decimal.valueOf(values[1].trim());
      Boolean bo = (values.size() < 3 ||
        String.isBlank(values[2]) ||
        (!values[2].trim().equals('S') && !values[2].trim().equals('N')))
        ? null
        : values[2].trim() == 'S';

      String cpaCode;
      fan_B2BAddToCartUtil.ImportItem item;

      if (String.isBlank(sku)) {
        fan_B2BAddToCartUtil.ImportItem invalidItem = new fan_B2BAddToCartUtil.ImportItem();
        invalidItem.row = row;
        invalidItem.sku = sku;
        invalidItem.errorMsg = Label.fan_B2B_SKU_is_not_valid;
        importItems.add(invalidItem);
      }

      if (qty == null || bo == null) {
        item = new fan_B2BAddToCartUtil.ImportItem();
        item.row = row;
        
        if (qty == null) {
          item.errorMsg = Label.fan_invalidQuantity;
        } else if (bo == null) {
          item.errorMsg = Label.fan_invalidBackorder;
        }

        lineWithError.add(item);
        continue;
      }

      if (String.isNotBlank(sku)) {
        item = skuMap.get(sku);
        if (item == null) {
            item = new fan_B2BAddToCartUtil.ImportItem();
            item.row = row;
            item.sku = sku;
            item.qty = qty;
            item.bo = bo;
            item.cpaCode = cpaCode;
        } else {
            item.qty += qty;
        }
        skuMap.put(sku, item);
      }
    }

    if (!lineWithError.isEmpty()) {
      return lineWithError;
    }

    importItems.addAll(skuMap.values());

    System.debug(
      'createItemList importItems >>> ' + JSON.serialize(importItems)
    );
    return importItems;
  }

  public ConnectApi.CartItemInput[] createCartItems(
    String cartId,
    String effectiveAccountId,
    fan_B2BAddToCartUtil.ImportItem[] itemsList,
    Map<String, Object> responseMap
  ) {
    ConnectApi.CartItemInput[] cartItemInputs = new List<ConnectApi.CartItemInput>();

    for (fan_B2BAddToCartUtil.ImportItem item : itemsList) {
      if (item.isValid) {
        ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();

        cartItemInput.productId = item.productId;
        cartItemInput.quantity = item.qty.toPlainString();
        cartItemInput.type = ConnectApi.CartItemType.Product;
        cartItemInputs.add(cartItemInput);
      }
    }
    return cartItemInputs;
  }
}