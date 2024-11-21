/**
* Fanalca
* @author           Raul Mora
* Description:      Account trigger to manage all events.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     06/12/2018      Raul Mora (RM)          Trigger definition.
*********************************************************************************************************/
trigger RM_Account_tgr on Account (before insert, before update) {
    
    if( Trigger.isBefore && Trigger.isInsert && RM_AccountTriggerHandler_cls.blnFirstRun ){
        RM_AccountTriggerHandler_cls.accountBeforeInsert( Trigger.new );
        RM_AccountTriggerHandler_cls.blnFirstRun=false;
    }
    if( Trigger.isBefore && Trigger.isUpdate && ( RM_AccountTriggerHandler_cls.blnFirstRun || Test.isRunningTest() ) ){
        RM_AccountTriggerHandler_cls.accountBeforeUpdate( Trigger.new, Trigger.oldMap );
        RM_AccountTriggerHandler_cls.blnFirstRun=false;
        AFOG_AccountTriggerHanler_cls.updateAccountOppConcesionario(Trigger.newMap, Trigger.OldMap );
    }        
}