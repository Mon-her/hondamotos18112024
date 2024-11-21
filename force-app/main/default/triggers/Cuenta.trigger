/**
 * Fanalca
 * @author           ?
 * Description:      
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.x     12/03/2020      Jonathan            	 CuentaTriggerHandler is no longer called from this trigger. 
 *********************************************************************************************************/
trigger Cuenta on Account(before update, after update, before insert) {
      new AccountTriggerHandler().run();
}