/******************************************************************************************************************************
*   @Class          :   AFOG_BypassTrigger_ctr
*   @Author         :   Andrés Oliva andresolivag@gmail.com
*   @Created        :   14/01/2022
*   @Description    :   Esta clase se encarga de utiliza para hacer el bypass en triggers
*
*      Author                   Date                     Description
*      Andrés Oliva             31/01/2022               Creación de clase
*******************************************************************************************************************************/
public with sharing class AFOG_BypassTrigger_ctr {    
    /***************************************************************************************************************************  
    * @Method          :   byPassTrigger
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   31/01/2022
    * @Description     :   Returna true cuando se debe hacer el bypass de un trigger, se debe debe llamar antes de ejecutar la 
                           acción DML 
    ****************************************************************************************************************************/   

    public static Map<String,Boolean> mapTriggerNameBypassed = new Map<String,Boolean>();

    public static void ByPass(String triggerName){
        mapTriggerNameBypassed.put(triggerName,true);
    }
    public static Boolean isByPassed(String triggerName){
        return mapTriggerNameBypassed.containsKey(triggerName) && mapTriggerNameBypassed.get(triggerName);
    }
}