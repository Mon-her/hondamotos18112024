global without sharing class fan_PricesScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Integer batchSize = 200;
        Database.executeBatch(new fan_PricebookJob(batchSize), batchSize);
    }
}