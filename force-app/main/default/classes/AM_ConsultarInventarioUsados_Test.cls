@isTest
public class AM_ConsultarInventarioUsados_Test {
    public static testmethod void testear(){
        try{
        	AM_ConsultarInventarioUsados.consultar(120, 150, '', 2020, 15000, 'óó\'');
        }catch(Exception ex){
            
        }
    }
}