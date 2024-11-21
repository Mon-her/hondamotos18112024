/**
 * @description Util methods for B2B commerce on Lightning Samples
 *
 * @see B2BUtils
 */
public with sharing class fan_B2BUtils {
  // A cache which maps community Ids to WebStore Ids
  private static Map<String, String> communityIdToWebStoreIdCache = new Map<String, String>();

  // A cache to map a string to ConnectApi.CartItemSortOrder
  private static Map<String, ConnectApi.CartItemSortOrder> sortOrderCache = new Map<String, ConnectApi.CartItemSortOrder>();

  // For Unit test
  public static String testWebStoreId;

  /**
   * @description Given a community ID, returns the relavent webstore ID for use in B2B Commerce on lightning
   * @param  communityId The Id of the community from which the call originated
   * @return weStoreId The webStoreId corresponding to the community Id.
   * @example
   * String webStoreId = B2BUtils.resolveCommunityIdToWebstoreId('0DB2D0000004Xz7');
   */
  public static String resolveCommunityIdToWebstoreId(String communityId) {
      if (communityIdToWebStoreIdCache.containsKey(communityId)) {
        return communityIdToWebStoreIdCache.get(communityId);
      } else {
        String webStoreId = Test.isRunningTest() ? testWebStoreId : [ SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId WITH SECURITY_ENFORCED LIMIT 1].WebStoreId;
        communityIdToWebStoreIdCache.put(communityId, webStoreId);
        return webStoreId;
      }
  }

  /**
   * @description Given a sortParam string, return null or the relavent ConnectApi.CartItemSortOrder enum value
   * See https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/connectAPI_enums.htm#cartItemSortOrderEnum for the enum values
   * @param  sortParam A string representing a sort Param.
   * @return resolvedSortParam A ConnectApi.CartItemSortOrder enum value or null
   * @example
   * ConnectApi.CartItemSortOrder sortParam = B2BUtils.resolveSortParam('CreatedDateAsc');
   */
  public static ConnectApi.CartItemSortOrder resolveSortParam(
    String sortParam
  ) {
      if (sortOrderCache.isEmpty()) {
        for (
          ConnectApi.CartItemSortOrder sortOrder : ConnectApi.CartItemSortOrder.values()
        ) {
            sortOrderCache.put(sortOrder.name(), sortOrder);
          }
      }
      return sortOrderCache.get(sortParam);
  }

  @TestVisible
  static Object getFieldValue(SObject value, String fields) {
	  return getFieldValue(value, fields.split('\\.'));
  }

  /** @description Get the value of a SObject recursively. */
  @TestVisible
  static Object getFieldValue(SObject value, String[] fields) {
	  if(value == null || fields.isEmpty()) {
		  return value;
	  }
	  String field = fields.remove(0);
	  try {
		  SObject valueToExtract = value.getSObject(field);
		  return getFieldValue(valueToExtract, fields);
	  } catch(SObjectException e) {
      if(e.getMessage().startsWith('Invalid relationship')) {
        return value.get(field);
      }
      throw e;
	  }
  }

  /**
   * @description Creates a map collection using as key the value obtained from the field and as value a SObject from the list.
   * @param  field A string that will serve as the key .
   * @param  sObjects a list of SObjects that will serve as the values.
   * @param  Type a variable that will be used to type during the map collection.
   * @return An object that will represent the map collection.
   */
  public static Object mapSObject(String field, List<SObject> sObjects, Type type) {
      Map<Object, SObject> mappedList = new Map<Object, SObject>();

      for(SObject so : sObjects) {
        Object key = getFieldValue(so, field);
        mappedList.put(key, so);
      }
      return JSON.deserialize(JSON.serialize(mappedList), type);
  }

  /**
   * @description Creates a map collection using as key the value obtained from the field name and as value an object from the list.
   * @param  fieldName a string from the field that will serve as the key .
   * @param  objects a list of objects that will serve as the values.
   * @param  Type a variable that will be used to type during the map collection.
   * @return An object that will represent the map collection.
   */
  public static Object mapObject(String fieldName, List<Object> objects, Type type) {
      Map<Object, Object> mappedList = new Map<Object, Object>();

      for(Object o : objects) {
        Map<String, Object> deserializedObject = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(o));
        mappedList.put(deserializedObject.get(fieldName), o);
      }

      return JSON.deserialize(JSON.serialize(mappedList), type);
  }

  /**
   * @description Given a fieldName, objectList and type return a map collection.
   * @param  fieldName a string from the field that will serve as the object.
   * @param objects a list of objects from which the field is extracted.
   * @param Type a variable that will be used to type the list collection.
   * @return A list of objects
   */
  public static Object generateList(String fieldName, List<Object> objects, Type type) {

    List<Object> generatedList = new List<Object>();

    for (Object some : objects) {
      Map<String, Object> mappedObject = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(some));
      generatedList.add(mappedObject.get(fieldName));
    }

    return JSON.deserialize(JSON.serialize(generatedList), type);
  }

  /**
   * @description Create a set collection given a field.
   * @param field The SObjectField from which the list will be created.
   * @param sObjects The list of SObjects from which the field is extracted.
   * @param Type The variable that will be used to type the set collection.
   * @return A set of objects.
   */
  public static Object generateSet(SObjectField field, List<SObject> sObjects, Type type) {

    Set<Object> generatedSet = new Set<Object>();

    for (SObject currentSObject : sObjects) {
      generatedSet.add(currentSObject.get(field));
    }

    return JSON.deserialize(JSON.serialize(generatedSet), type);
  }

  /**
   * Gets the first fan_IdTienda__mdt that matches the supplied value.
   * @param value The content to compare.
   * @param field The field of the fan_IdTienda__mdt that has the value to compare with the supplied value.
   * @return The fan_IdTienda__mdt that matched otherwise null.
   */
  public static fan_IdTienda__mdt getIdTiendaMdt(Object value, SObjectField field) {
    for (fan_IdTienda__mdt idTiendaMdt : fan_IdTienda__mdt.getAll().values()) {
      if(value == idTiendaMdt.get(field)) {
        return idTiendaMdt;
      }
    }
    return null;
  }

  public static String resolveAccountNumber(String accountId) {
    Account account = [SELECT AccountNumber, Parent.AccountNumber FROM Account WHERE Id = :accountId];
    return resolveAccountNumber(account);
  }

  public static String resolveAccountNumber(Account account) {
    return account.Parent.AccountNumber ?? account.AccountNumber;
  }
}