//Created by Philip, Jun 21
//Schedule to get the Metrics from Prolibu
//Modified on December '21, to make callouts in a batch, because there were more than 300 quotes to request metrics
global class clsScheduleGetProposalMetrics implements Schedulable{
	global void execute(SchedulableContext ctx) {
      	//ProlibuProposalMetrics.getProposalMetricsFuture();
        ProlibuProposalMetricsBatch batchable = new ProlibuProposalMetricsBatch();
		Database.executebatch(batchable, 200);   
        /* 
        //De esta manera se manda a programar esta clase
        clsScheduleGetProposalMetrics reminder = new clsScheduleGetProposalMetrics();
        // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String sch = '0 0 2 1 * ?'; //it runs at 1 a.m. every first day of month
        String jobID = System.schedule('Get Prolibu Proposal Metrics', sch, reminder);
		*/
   }
}