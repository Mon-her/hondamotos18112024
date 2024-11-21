global without sharing class fan_ItemsUnoSchedule implements Schedulable {
  global void execute(SchedulableContext sc) {
    Database.executeBatch(new fan_ItemsUnoBatch(), 200);
  }
}