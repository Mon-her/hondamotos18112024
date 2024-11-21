@IsTest
public with sharing class UserOppGoalsScheduler_Test {
  @IsTest
  static void execute() {
    Test.starttest();
    UserOppGoalsScheduler schedulable = new UserOppGoalsScheduler();
    String chron = '0 0 23 * * ?';
    System.schedule('Test Sched', chron, schedulable);
    Test.stopTest();
  }
}