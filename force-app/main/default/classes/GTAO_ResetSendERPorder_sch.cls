global class GTAO_ResetSendERPorder_sch implements Schedulable {
   global void execute(SchedulableContext sc) {
      GTAO_ResetSendERPorder b = new GTAO_ResetSendERPorder(); 
      database.executebatch(b);
   }
}