@IsTest
public with sharing class AutosCuentaSegmentacionScheduler_Test {
  @IsTest
  static void execute() {
    Test.starttest();
    AutosCuentaSegmentacionScheduler schedulable = new AutosCuentaSegmentacionScheduler();
    String chron = '0 0 23 * * ?';
    System.schedule('Test Sched', chron, schedulable);
    Test.stopTest();
  }
}