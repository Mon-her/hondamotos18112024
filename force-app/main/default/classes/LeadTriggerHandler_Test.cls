@isTest
public class LeadTriggerHandler_Test {
    public static Integer HorasParaEvento = Integer.valueOf(LABEL.HorasParaEvento);
    public static Date hoy = system.today();
    public static DateTime ahora = system.now();
    public static testmethod void testear30Horas(){
        HorasParaEvento = 30;
        TestDataUtilityClass.crearLeadMotos(Label.RTLeadMotosNatural,1);
    }
    public static testmethod void testear0Horas(){
        HorasParaEvento = 0;
        TestDataUtilityClass.crearLeadMotos(Label.RTLeadMotosNatural,1);
    }
    public static testmethod void testearHoySabado8am12horas(){
        HorasParaEvento = 12;
        String nombreDia = ahora.format('EEEE');
		system.debug('El nombre del Dia es '+nombreDia);
		
        switch on nombreDia {
            when 'Monday' { hoy = hoy.addDays(5); }
            when 'Tuesday' { hoy = hoy.addDays(4); }
            when 'Wednesday' { hoy = hoy.addDays(3); }
            when 'Thursday' { hoy = hoy.addDays(2); }
            when 'Friday' { hoy = hoy.addDays(1); }
            //when 'Saturday' { hoy.addDays(6); }
            when 'Sunday' { hoy = hoy.addDays(6); }
        }
        ahora = DAteTime.newInstance(hoy.year(),hoy.month(),hoy.day(),8,0,0); //8 am local del dia sábado máx próximo en el futuro, o mismo día sábado si hoy es sábado, jajajaja
        TestDataUtilityClass.crearLeadMotos(Label.RTLeadMotosNatural,1);
    }
    public static testmethod void testearHoyDomingo8am12horas(){
        HorasParaEvento = 12;
        String nombreDia = ahora.format('EEEE');
		system.debug('El nombre del Dia es '+nombreDia);
		
        switch on nombreDia {
            when 'Monday' { hoy = hoy.addDays(6); }
            when 'Tuesday' { hoy = hoy.addDays(5); }
            when 'Wednesday' { hoy = hoy.addDays(4); }
            when 'Thursday' { hoy = hoy.addDays(3); }
            when 'Friday' { hoy = hoy.addDays(2); }
            when 'Saturday' { hoy = hoy.addDays(1); }
            //when 'Sunday' { hoy.addDays(6); }
        }
        ahora = DAteTime.newInstance(hoy.year(),hoy.month(),hoy.day(),8,0,0); //8 am local del dia sábado máx próximo en el futuro, o mismo día sábado si hoy es sábado, jajajaja
        TestDataUtilityClass.crearLeadMotos(Label.RTLeadMotosNatural,1);
    }
}