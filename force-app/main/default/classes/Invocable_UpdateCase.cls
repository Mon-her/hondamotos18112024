//Created by Me, On 20220221
//To update the case, only to set milestone
//tested by Invocable_UpdateCase_Test
global class Invocable_UpdateCase {
	@InvocableMethod
    global static void updateCase(List<assignmentParameter> pList) {
        futureUpdate(pLIst[0].recordId);
    }
    
    @future
    private static void futureUpdate(Id ide){
        Case caso = new Case();
        caso.Id = ide;
        update caso;
    }
    
    global class assignmentParameter {
        @InvocableVariable(label='case record Id' required=true)
        global Id recordId;
	}
}