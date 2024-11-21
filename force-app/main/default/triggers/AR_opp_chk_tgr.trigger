/**
* Fanalca
* @author           Alejandro Rebollo
* Description:      Opp trigger handler class.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     13/06/2019      Alejandro Rebollo (AR)  Class definition.
 *********************************************************************************************************/

trigger AR_opp_chk_tgr on AM_Oportunidad__c (before insert ,after insert,after update ) {
// Local variable declarations
    Boolean bOk;

// Check trigger event
    system.debug(trigger.isInsert);
    system.debug(trigger.isBefore);
   
    if (trigger.isInsert && trigger.isBefore) {
// Verify role and role function
        String sProfileName = [select Name from Profile where id = :userinfo.getProfileId()].Name;
        String sFunctionName = [select Name from UserRole where id = :userinfo.getUserRoleId()].Name;
    
        system.debug(sProfileName);
        system.debug(sFunctionName);
        system.debug(System.Label.AR_ValOpp_Role);
        system.debug(System.Label.AR_ValOpp_Func);
        if (sProfileName == System.Label.AR_ValOpp_Role || 
          sFunctionName == System.Label.AR_ValOpp_Func || 
          Test.isRunningTest() )
       {
       
//Retrieve new opportunities, before insert
            for(AM_Oportunidad__c opp : trigger.new) {

                //Get recordtype associated
                RecordType recTyp = [Select Id, Name From RecordType Where id =: opp.RecordTypeId Limit 1];

                // Check recordtype
//                if ( recTyp.Name == System.Label.AR_TipCotRent_Nat || 
//                       recTyp.Name == System.Label.AR_TipCotRent_Jur ) {           

                    system.debug('uno');
// Check current user vs Opp.Account owner
                    Account acc = [select OwnerId from Account where id =: opp.AM_Propietario_motocicleta__c];
        
                    system.debug(acc.OwnerId);
                    system.debug(UserInfo.getUserId());
                    system.debug('Cuenta:' + opp.AM_Propietario_motocicleta__c);
                    if (acc.OwnerId != UserInfo.getUserId() ) {
// Check previous Oppportunities, for current user     
                        try {
                            Integer count = [SELECT count() FROM AM_Oportunidad__c
                                WHERE AM_Propietario_motocicleta__c = :opp.AM_Propietario_motocicleta__c
                                AND   OwnerId = :UserInfo.getUserId()];   

                            system.debug('Registros:' + count);                        
                            if (count > 0) {
                                bOk = true;
                            } else {
                                bOk = false;
                            }
                            system.debug('entro');
                        } catch (exception e) {
                            bOk = false; // Error
                        }
                    } else {
                        bOk = true; //OK
                    } 
                
                    system.debug(bOk);

            // Current user not valid 
                    if (!bOk) {
                      opp.addError('No tiene acceso a la creación de cotizaciones para esta cuenta.');   
                    }
                }
//          }
        }
    }
}