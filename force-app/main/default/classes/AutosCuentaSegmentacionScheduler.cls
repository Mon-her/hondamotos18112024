/**
 * Fanalca
 * @author           Juan Ansaldi
 * Description:      Class that executes every day the batch AutosCuentaSegmentacionBatch.
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     12/15/2021      Juan Ansaldi             Class definition.
 *********************************************************************************************************/
global class AutosCuentaSegmentacionScheduler implements Schedulable {
  global void execute(SchedulableContext SC) {
    AutosCuentaSegmentacionBatch batchable = new AutosCuentaSegmentacionBatch();
    Database.executebatch(batchable, 20);
  }
}