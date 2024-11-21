@isTest
public class fan_ItemsUnoTest {
  @testSetup
  static void setup() {
    fan_ServiceEndpoint__c settings = new fan_ServiceEndpoint__c(
      usuario__c = 'test',
      url__c = 'host',
      Nombre__c = 'Fanalca',
      contrasena__c = '123'
    );
    insert settings;

  }

  public static String CRON_EXP = '0 0 0 15 3 ? 2080';

  @isTest
  static void runSchedule() {
    Test.setMock(WebServiceMock.class, new fan_ItemsUnoMock());

    Test.startTest();

    // Schedule the test job
    String jobId = System.schedule(
      'ScheduledApexTest',
      CRON_EXP,
      new fan_ItemsUnoSchedule()
    );

    Test.stopTest();

    // Get the information from the CronTrigger API object
    CronTrigger ct = [
      SELECT Id, CronExpression, TimesTriggered, NextFireTime
      FROM CronTrigger
      WHERE id = :jobId
    ];

    // Verify the expressions are the same
    System.assertEquals(CRON_EXP, ct.CronExpression);

    // Verify the job has not run
    System.assertEquals(0, ct.TimesTriggered);

    // Verify the next time the job will run
    System.assertEquals('2080-03-15 00:00:00', String.valueOf(ct.NextFireTime));

    System.abortJob(jobId);
  }
}