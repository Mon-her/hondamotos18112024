/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      Class that executes every day the batch that updatesopp goals for every salesperson.
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     12/15/2021      Olvin Abarca            Class definition.
 *********************************************************************************************************/
global with sharing class UserOppGoalsScheduler implements Schedulable {
  global void execute(SchedulableContext SC) {
    UserOppGoalsBatchable batchable = new UserOppGoalsBatchable();
    Database.executebatch(batchable, 20);
  }
}