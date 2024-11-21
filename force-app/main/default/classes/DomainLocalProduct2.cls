/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-19-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class DomainLocalProduct2 {
    
    public static List<Database.UpsertResult> upsertProducts(List<Product2> products, Schema.SObjectField externalIDField) {
        return Database.upsert(products, externalIDField, false);
    }

}