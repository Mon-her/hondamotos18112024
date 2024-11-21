global with sharing class SkillController {
    @InvocableMethod(label='Get skill by Name' description='Return Ids of Skills by DeveloperName') 
    global static List<List<Id>> getSkillsIds(List<String>SkillName){
        system.debug('El nombre de la habilidad que se quiere es : '+SkillName);
    List<Id> skillsIds = new List<Id> ();
        for(Skill s : [Select ID FROM Skill WHERE DeveloperName IN : SkillName Limit 1]){
            skillsIds.add(s.Id);
    
        }
        system.debug('El ID de habilidad es : ' + skillsIds[0]);
        return new List<List<Id>> {skillsIds};
    }  
}