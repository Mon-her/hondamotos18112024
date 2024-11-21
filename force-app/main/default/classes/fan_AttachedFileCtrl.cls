public with sharing class fan_AttachedFileCtrl {

    @AuraEnabled(cacheable=true)
    public static List<Id> getRelatedFiles(Id recordId) {

        List<Id> fileIds = new List<Id>();

        for (ContentDocumentLink cdl: [ 
            SELECT ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId =: recordId 
        ] ) {
            fileIds.add(cdl.ContentDocument.LatestPublishedVersionId);
        }
        return fileIds;
    }
}