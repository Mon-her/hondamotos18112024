trigger CaseTrigger on Case (before update, before insert, after update) {
    system.debug('Entrando al Case Trigger');
    system.debug('is Before' + Trigger.isBefore);
    system.debug('is after' + Trigger.isAFter);
    new CaseTriggerHandler().run();
}

/*trigger CompleteResolutionTimeMilestone on Case (after update) {
        DateTime completionDate = System.now(); 
            List<Id> updateCases = new List<Id>();
            for (Case c : Trigger.new){
                    if (c.Escalar_Caso__c == true)
        updateCases.add(c.Id);
        }
    if (updateCases.isEmpty() == false)
        milestoneUtils.completeMilestone(updateCases, 'Test', completionDate);
}*/