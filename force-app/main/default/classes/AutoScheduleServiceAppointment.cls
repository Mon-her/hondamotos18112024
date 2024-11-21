/**
* Fanalca
* @author           Me (FCC)
* Description:      Schedule a service appointment, used by the self service scheduling flow available in public experience cloud.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     09/11/2020      Me			            Class definition.

*********************************************************************************************************/
global class AutoScheduleServiceAppointment {
    @InvocableMethod(label='Schedule appointment' description='This method schedule a service appointment')
    global static List<InvocableResponse> scheduleAppointment(List<InvocableRequest> requests) {
        List<InvocableResponse> responses = new List<InvocableResponse>();
        InvocableResponse response = new InvocableResponse();
        try{
            // Iterate through the list of requests and process the inputs
            for (InvocableRequest request : requests) {
                // Custom logic using the input variables
                String policyId = request.policyID;
                String appointmentId = request.serviceAppointmentId;
                
                // Call the scheduling engine
                FSL.ScheduleService.Schedule(policyId, appointmentId);
                //response.result = 'Processed: SA: ' + appointmentId + ' with policyId ' + policyId;
                
            }
        }catch (Exception e){
        	response.result = e.getMessage();
        }
        responses.add(response);
        return responses;
    }
    
     // Inner class to define the inputs (2 variables)
    global class InvocableRequest {
        @InvocableVariable(required=true label='Policy Id')
        global String policyID;

        @InvocableVariable(required=true label='Appointment Id')
        global String serviceAppointmentId;
    }

    // Inner class to define the response
    global class InvocableResponse {
        @InvocableVariable(label='Result' description='The result of scheduling the service appointment')
        global String result;
    }
}