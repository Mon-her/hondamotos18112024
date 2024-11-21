@isTest
public class clsScheduleEliminarQuotePdfs_Test {
    public static String CRON_EXP = '0 0 0 15 3 ?';
    public static testmethod void testear(){
        String jobId = System.schedule('ScheduledApexTest',
            CRON_EXP,
            new clsScheduleEliminarQuotePdfs());
    }
}