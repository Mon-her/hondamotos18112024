global class scheduleMarketingJourneys implements Schedulable {
   global void execute(SchedulableContext sc) {
      	batchMarketingJourneys batchable = new batchMarketingJourneys();
		Database.executebatch(batchable);   
   }
}