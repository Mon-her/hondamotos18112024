global without sharing class fan_loadClientSchedule implements Schedulable {
  global void execute(SchedulableContext sc) {
    Database.executeBatch(new fan_loadClientBatch(), 200);
  }
}