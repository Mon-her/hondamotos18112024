public with sharing class clsMotosVentasMesPasado {
    /*
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOppsLastMonth(){
        try {
            return [Select Id, Owner.Name, StageName, Agencia__c, Agencia2__c,Concesionario__c, Concesionario2__c,Account.Name, Name, Amount,Probability, CloseDate, CreatedDate from Opportunity limit 100];    
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    */
    /*
    @AuraEnabled(cacheable=true)
    public static Integer getTotalOppsLastMonth(){
        try {
            return 777;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    */
    //Get the total opps and the concesionarios autonumeric field to filter the report
    @AuraEnabled(cacheable=true)
    public static string getDatos(){
        try {
            //Obtener los Concesionarios en los que está el usuario logueado
            set<String> setConcesionarios = new set<String>();
            String Rol = [select UserRole.Name from User where Id=:UserInfo.getUserId() limit 1].UserRole.Name;
            system.debug(Rol);
            switch on Rol {
                when 'Gerente de Zona Centro Norte' {		// Zona Centro Norte
                    for (Miembro_de_Concesionario__c mc: [select Concesionario__r.Autonumerico__c from Miembro_de_Concesionario__c where Concesionario__r.Zona__c = 'Centro Norte' with SECURITY_ENFORCED]){
                        setConcesionarios.add(mc.Concesionario__r.Autonumerico__c);
                    }
                }	
                when 'Gerente de Zona Sur' {		// Zona Sur
                    for (Miembro_de_Concesionario__c mc: [select Concesionario__r.Autonumerico__c from Miembro_de_Concesionario__c where Concesionario__r.Zona__c = 'Sur' with SECURITY_ENFORCED]){
                        setConcesionarios.add(mc.Concesionario__r.Autonumerico__c);
                    }
                }
                when else {		  // si no es de los gerentes de zona, entonces halar solo los concesionarios donde es miembro
                    
                    for (Miembro_de_Concesionario__c mc: [select Concesionario__r.Autonumerico__c from Miembro_de_Concesionario__c where Nombre_de_asesor__c=:UserInfo.getUserId() with SECURITY_ENFORCED]){
                        setConcesionarios.add(mc.Concesionario__r.Autonumerico__c);
                    }
                }
            } 
            system.debug('concesionarios'+ setConcesionarios);
            Integer total = [select count() from Opportunity where Concesionario__r.Autonumerico__c in:setConcesionarios and IsWon=true and CloseDate=LAST_MONTH];
            system.debug('total'+ total);

            DatosOppsLastMonth datos = new DatosOppsLastMonth();
            datos.totalOppsLM = total;
            //datos.codigosConcesionariosUsuario = new List<String>{'Florencia','Ceiba'};
            datos.codigosConcesionariosUsuario = new List<String>(setConcesionarios);
            return JSON.serialize(datos);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class DatosOppsLastMonth{
        public  Integer totalOppsLM;
        public  list<String> codigosConcesionariosUsuario;
    }
    
}