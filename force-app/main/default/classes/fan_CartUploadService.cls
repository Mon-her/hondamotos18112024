public interface fan_CartUploadService {

    // Map product line to fan_B2BAddToCartUtil.ImportItem.
    fan_B2BAddToCartUtil.ImportItem[] buildItemList(String[] lines, Integer row, Boolean defaultBackorder, Map<String, String> skuReference);

    // Creates a CartItemInput object for each item.
    ConnectApi.CartItemInput[] createCartItems(String cartId, String effectiveAccountId, fan_B2BAddToCartUtil.ImportItem[] itemsList, Map<String, Object> responseMap);
}