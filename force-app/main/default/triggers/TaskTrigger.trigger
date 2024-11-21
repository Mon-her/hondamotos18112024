/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      Trigger that delegates everything to handler class
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     12/07/2020      Olvin Abarca            Class definition.
 *********************************************************************************************************/
trigger TaskTrigger on Task(before insert, before update) {
  TaskTriggerHandler handler = new TaskTriggerHandler();
  handler.run();
}