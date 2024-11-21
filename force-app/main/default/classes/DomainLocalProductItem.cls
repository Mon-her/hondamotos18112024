/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-19-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

public without sharing class DomainLocalProductItem {
    
    public static List<Database.UpsertResult> upsertProductItems(List<ProductItem> productItems) {
        return Database.upsert(productItems, false);
    }

}