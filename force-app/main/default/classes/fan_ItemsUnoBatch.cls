public class fan_ItemsUnoBatch implements Database.batchable<fan_ItemsUnoE.row_element>, Database.AllowsCallouts {
  public Iterable<fan_ItemsUnoE.row_element> start(
    Database.BatchableContext info
  ) {
    return fan_ItemsUnoHandler.getData();
  }
  public void execute(
    Database.BatchableContext info,
    fan_ItemsUnoE.row_element[] rows
  ) {
    Map<String, RecordTypeInfo> recordTypes = SObjectType.Product2.getRecordTypeInfosByDeveloperName();
    Map<String, Product2> variationParentItems = new Map<String, Product2>();
    Map<String, Product2> variantProductItems = new Map<String, Product2>();
    Map<String, String[]> childMetadata = new Map<String, String[]>();

    Map<String, Product2> posventaProducts = new Map<String, Product2>();
    Map<String, Set<String>> substitutesByOriginalItem = new Map<String, Set<String>>();
    Set<String> substituteIdentifiers = new Set<String>();

    for (fan_ItemsUnoE.row_element row : rows) {
      if (String.isNotBlank(row.ITEM)) {
        if (row.ITEM.substring(0, 1) == 'M') {
          String recordTypeId = recordTypes.get(fan_Constants.StoreDeveloperName.MOTOS.name().toLowerCase().capitalize()).getRecordTypeId();

          Product2 parentProduct = fan_ItemsUnoHandler.variationParentFormat(row, recordTypeId);
          variationParentItems.put(parentProduct.IdProductoUNOEE__c, parentProduct);

          Product2 childProduct = fan_ItemsUnoHandler.variantProductFormat(row, recordTypeId);
          variantProductItems.put(childProduct.IdProductoUNOEE__c, childProduct);
          childMetadata.put(row.ITEM, new String[] { parentProduct.IdProductoUNOEE__c, row.EXT_ITEM_COLOR });
        } else {
          String recordTypeId = recordTypes.get(fan_Constants.StoreDeveloperName.POSVENTA.name().toLowerCase().capitalize()).getRecordTypeId();
          posventaProducts.put(row.ITEM, fan_ItemsUnoHandler.variantProductFormat(row, recordTypeId));

          // When ITEM_EQUIVALENTE is equals to preserve there are no substitutes.
          Set<String> substitutes = row.ITEM_EQUIVALENTE == 'preserve' ? new Set<String>() : new Set<String>(row.ITEM_EQUIVALENTE.split(';'));
          substituteIdentifiers.addAll(substitutes);
          substitutesByOriginalItem.put(row.ITEM, substitutes);
        }
      } else {
        System.debug(LoggingLevel.ERROR, 'Invalid ITEM Id');
      }
    }

    if(!posventaProducts.isEmpty()) {
      UPSERT posventaProducts.values() IdProductoUNOEE__c;
      fan_ItemsUnoHandler.validateSubstitutes(posventaProducts, substitutesByOriginalItem, substituteIdentifiers);
    }

    // Temporary deactivation for the Motos Store.
    if(Test.isRunningTest() && !variationParentItems.isEmpty()) {
      fan_ItemsUnoHandler.purgeTypeField(variationParentItems);

      UPSERT variationParentItems.values() IdProductoUNOEE__c;
      UPSERT variantProductItems.values() IdProductoUNOEE__c;

      INSERT fan_ItemsUnoHandler.generateProductAttributeSetProducts(variationParentItems.values());
      INSERT fan_ItemsUnoHandler.generateProductAttributes(variantProductItems.values(), childMetadata, variationParentItems);
    }
  }

  public void finish(Database.BatchableContext info) {}
}