@isTest
public class clsScheduleGetProposalMetrics_Test {
    private static testmethod void testear(){
        //De esta manera se manda a programar esta clase
        clsScheduleGetProposalMetrics reminder = new clsScheduleGetProposalMetrics();
        // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String sch = '0 0 2 1 * ?'; //it runs at 1 a.m. every first day of month
        String jobID = System.schedule('Get Prolibu Proposal Metricas', sch, reminder);
    }
}