@istest
class scheduleMarketingJourneys_Test {
    static testmethod void test() {
        // This test runs a scheduled job at midnight Sept. 3rd. 2022
	   	String CRON_EXP = '0 0 0 3 9 ? 2022';
        
    	String jobId = System.schedule('agendar Marketing Journeys',CRON_EXP, new scheduleMarketingJourneys());    
        
    }
}