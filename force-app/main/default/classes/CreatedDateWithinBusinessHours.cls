public class CreatedDateWithinBusinessHours { 

@InvocableMethod(label = 'Created Date is within BH' description = 'Check if flow record Created Date is within business hours') 
public static List<Results> execute(List<Requests> requestList) {
		system.debug('requestList:'+requestList);
        // Pasa el valor del nombre del BH
        String BusinessHoursName = requestList[0].FlowBusinessHours;
        system.debug('BusinessHoursName:'+BusinessHoursName);
        // Get the default business hours
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name =: BusinessHoursName];
        system.debug('BusinessHours Record:'+bh);
        // Pass the Created Date Time of the flow Record
        Datetime targetTime = requestList[0].inputCreatedDateTime;
		system.debug('targetTime:'+targetTime);
        // Boolean that returns true if date time is within Business hours
        Boolean isWithin = BusinessHours.isWithin(bh.id, targetTime);
		system.debug('isWithin:'+isWithin);
        // Results object that holds the return values
        Results response = new Results();
		
        //Add the return values to the Results object
        response.outputMember = isWithin;

        //Wrap the Results object in a List container 
        List<Results> responseWrapper = new List<Results> ();
        responseWrapper.add(response);
    	system.debug('response:'+response);
        return responseWrapper;
}

public class Requests {
    @InvocableVariable(label = 'FechaHoraChat' description = 'Fecha y hora de recepción del chat' required = false)
    public Datetime inputCreatedDateTime;
    @InvocableVariable(label = 'Horario laboral a usar' description = 'Nombre del horario laboral a utilizar' required = true)
    public String FlowBusinessHours;
    
    /*public Requests(){
        this.inputCreatedDateTime = system.now();
    }*/
}
public class Results {
    @InvocableVariable(label = 'Within Business Hours' description = 'Boolean that returns true if the Created Date is within Business Hours' required = true)
    public Boolean outputMember;
}
}