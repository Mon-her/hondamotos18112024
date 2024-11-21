public class clsScheduleEliminarQuotePdfs implements Schedulable{
	public void execute(SchedulableContext ctx) {
      clsEliminarQuotePdfs p = new clsEliminarQuotePdfs();
      database.executeBatch(p,500);
        
        /*
        //De esta manera se manda a programar esta clase
        clsScheduleEliminarQuotePdfs reminder = new clsScheduleEliminarQuotePdfs();
        // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String sch = '0 0 2 1 * ?'; //it runs at 1 a.m. every first day of month
        String jobID = System.schedule('Eliminar Quote Pdfs de Meses Pasados', sch, reminder);
		*/
   } 
}