public class MilestoneUtils {
    public static void completeMilestone(List<Id> caseIds, DateTime complDate) {  
    List<CaseMilestone> cmsToUpdate = [select Id, completionDate
            from CaseMilestone cm
            where caseId in :caseIds 
            and completionDate = null limit 1];
        if (cmsToUpdate.isEmpty() == false){
            for (CaseMilestone cm : cmsToUpdate){ cm.completionDate = complDate; }  update cmsToUpdate;
        }
    }
}