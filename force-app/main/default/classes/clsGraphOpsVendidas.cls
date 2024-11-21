public with sharing class clsGraphOpsVendidas {
    @auraEnabled(cacheable=true)
    public static Integer getOpsVendidas(){
        //List<AggregateResult> AggregateResultList = [SELECT count() from Opportunity where StageName='Vendida' and closeDate=this_Month with SECURITY_ENFORCED];
        Integer n = [SELECT count() from Opportunity where StageName='Vendida' and closeDate=this_Month and ownerId=:UserInfo.getUserId() with SECURITY_ENFORCED];
        //system.debug('n: ' + n);
        return n;
    }
    
    /*
    //Obtiene la cantidad de usuarios entre los rangos definidos en el label GraphSegmentosOpsVendidos
    @auraEnabled(cacheable=true)
    public static list<Integer> getUsuariosXSegmento(){
        try{
            list<String> lstSegmentos = Label.GraphSegmentosOpsVendidos.split(';');
            list<Integer> lstResultados = new list<Integer>();
            
            //Obtener el total de oportunidades vendidas agrupadas por usuario
            AggregateResult[] agrupados=[select count(Id) cantidad, Owner.Name usuario from Opportunity where StageName='Vendida' and closeDate=this_Month  group by owner.Name  ];
            for (AggregateResult ar : agrupados){
                system.debug('ar' + ar); //TODO: despues lo borro es solo para propositos academicos
            }
            
            //inserta los valores obtenidos en la aggregate result en una lista de Resultados que indica la cantidad de usuarios con ventas comprendidas entre los rangos definidos
            Integer minRango, maxRango, cantidadVendidaUsuario, usuariosRango;
            for (integer i=0;i<lstSegmentos.size();i++){
                if (i==0){
                    minRango = -1; //Se pone menos uno, para que el primer rango pueda incluir al 0, ya que es una comparación con > no con >=   
                }else{
                    minRango = Integer.valueof(lstSegmentos[i-1]);
                }
                maxRango = Integer.valueof(lstSegmentos[i]);
                
                //Se buscan los usuarios con cantidades vendidas comprendidas dentro del rango correspondiente
                usuariosRango = 0;
                for (AggregateResult ar : agrupados){
                    cantidadVendidaUsuario = Integer.valueOf(ar.get('cantidad'));
                    if (cantidadVendidaUsuario > minRango && cantidadVendidaUsuario<=maxRango){
                        usuariosRango += 1;//cantidadVendidaUsuario; 
                    }
                }
                
                lstResultados.add(usuariosRango);
            }
            system.debug('lstResultados: ' + lstResultados);
            return lstResultados;
        }catch(Exception ex){ system.debug(ex.getMessage()); return new list<Integer>{0,0,0,0,0,0};}
        
       
        
        //return new list<Integer>{2,3,5,8,10,4};
    }*/
    private static Decimal TotalUsuariosACargo = 0;
    
    @auraEnabled(cacheable=true)
    public static Decimal getTotalUsuarios(){//{return TotalUsuariosACargo;}
    	//Obtener los Concesionarios a Cargo, para obtener el total de asesores a cargo
        list<Concesionario__c> lstConcesionarios = new list<Concesionario__c>();
        set<Id> setConcesionarios = new set<Id>();
        String Rol = [select UserRole.Name from User where Id=:UserInfo.getUserId() limit 1].UserRole.Name;
        system.debug(Rol);
        switch on Rol {
            when 'Gerente de Zona Centro Norte' {		// Zona Centro Norte
                lstConcesionarios = [select Id, Name,Numero_de_Asesores__c from Concesionario__c where Zona__c = 'Centro Norte' with SECURITY_ENFORCED];
            }	
            when 'Gerente de Zona Sur' {		// Zona Sur
                lstConcesionarios = [select Id, Name,Numero_de_Asesores__c from Concesionario__c where Zona__c = 'Sur'];
            }
            when else {		  // si no es de los gerentes de zona, entonces halar solo los concesionarios donde es miembro
                
                for (Miembro_de_Concesionario__c mc: [select Concesionario__c from Miembro_de_Concesionario__c where Nombre_de_asesor__c=:UserInfo.getUserId() with SECURITY_ENFORCED]){
                    setConcesionarios.add(mc.Concesionario__c);
                }
                lstConcesionarios = [select Id, Name,Numero_de_Asesores__c from Concesionario__c where Id in:setConcesionarios with SECURITY_ENFORCED];
            }
        } 
        
        
        for (Concesionario__c c: lstConcesionarios){ 
            TotalUsuariosACargo+= c.Numero_de_Asesores__c;
        }
        system.debug('TotalUsuariosACargo: ' + TotalUsuariosACargo);
        
        return TotalUsuariosACargo;
    }
    @auraEnabled(cacheable=true)
    public static list<Integer> getUsuariosXSegmento(){
        try{
            list<String> lstSegmentos = Label.GraphSegmentosOpsVendidos.split(';');
            list<Integer> lstResultados = new list<Integer>();
            
            //Obtener los Concesionarios a Cargo, para obtener el total de asesores a cargo
            list<Concesionario__c> lstConcesionarios = new list<Concesionario__c>();
            set<Id> setConcesionarios = new set<Id>();
            String Rol = [select UserRole.Name from User where Id=:UserInfo.getUserId() limit 1].UserRole.Name;
            system.debug(Rol);
            switch on Rol {
                when 'Gerente de Zona Centro Norte' {		// Zona Centro Norte
                    lstConcesionarios = [select Id, Name,Numero_de_Asesores__c from Concesionario__c where Zona__c = 'Centro Norte' with SECURITY_ENFORCED];
                }	
                when 'Gerente de Zona Sur' {		// Zona Sur
                    lstConcesionarios = [select Id, Name,Numero_de_Asesores__c from Concesionario__c where Zona__c = 'Sur'];
                }
                when else {		  // si no es de los gerentes de zona, entonces halar solo los concesionarios donde es miembro
                    
                    for (Miembro_de_Concesionario__c mc: [select Concesionario__c from Miembro_de_Concesionario__c where Nombre_de_asesor__c=:UserInfo.getUserId() with SECURITY_ENFORCED]){
                        setConcesionarios.add(mc.Concesionario__c);
                    }
                    lstConcesionarios = [select Id, Name,Numero_de_Asesores__c from Concesionario__c where Id in:setConcesionarios with SECURITY_ENFORCED];
                }
            } 
            
            setConcesionarios = new set<Id>(); //Resetea el set de concesionarios, para que guarde para cualquier rol el set de concesionarios que le corresponde
            for (Concesionario__c c: lstConcesionarios){ 
                system.debug('Concesionario: ' + c);
                setConcesionarios.add(c.Id);
                TotalUsuariosACargo+= c.Numero_de_Asesores__c;
            }
            system.debug('TotalUsuariosACargo: ' + TotalUsuariosACargo);
            
            
            //Obtener el total de oportunidades vendidas agrupadas por usuario
                //AggregateResult[] agrupados=[select count(Id) cantidad, Owner.Name usuario from Opportunity where StageName='Vendida' and closeDate=this_Month  group by owner.Name  ];
                //for (AggregateResult ar : agrupados){
                //    system.debug('ar' + ar); //TODO: despues lo borro es solo para propositos academicos
                //}
            AggregateResult[] agrupados;
            switch on Rol {
                when 'Gerente de Zona Centro Norte','Gerente de Zona Sur' {		// Zona Centro Norte
                    agrupados=[select count(Id) cantidad, Owner.Name usuario from Opportunity where StageName='Vendida' and closeDate=this_Month and Concesionario__c in:setConcesionarios and Owner.Profile.Name ='Asesores motos' group by owner.Name  ];
                }	
                when else {
                    agrupados=[select count(Id) cantidad, Owner.Name usuario from Opportunity where StageName='Vendida' and closeDate=this_Month and Owner.Profile.Name ='Asesores motos' group by owner.Name  ];
                }
            } 
            
            //inserta los valores obtenidos en la aggregate result en una lista de Resultados que indica la cantidad de usuarios con ventas comprendidas entre los rangos definidos
            Integer minRango, maxRango, cantidadVendidaUsuario, usuariosRango;
            for (integer i=0;i<lstSegmentos.size();i++){
                if (i==0){
                    minRango = -1; //Se pone menos uno, para que el primer rango pueda incluir al 0, ya que es una comparación con > no con >=   
                }else{
                    minRango = Integer.valueof(lstSegmentos[i-1]);
                }
                maxRango = Integer.valueof(lstSegmentos[i]);
                
                //Se buscan los usuarios con cantidades vendidas comprendidas dentro del rango correspondiente
                usuariosRango = 0;
                for (AggregateResult ar : agrupados){
                    cantidadVendidaUsuario = Integer.valueOf(ar.get('cantidad'));
                    if (cantidadVendidaUsuario > minRango && cantidadVendidaUsuario<=maxRango){
                        usuariosRango += 1;//cantidadVendidaUsuario; 
                    }
                }
                
                lstResultados.add(usuariosRango);
            }
            system.debug('lstResultados: ' + lstResultados);
            return lstResultados;
        }catch(Exception ex){ system.debug(ex.getMessage()); return new list<Integer>{0,0,0,0,0,0};}
        
       
        
        //return new list<Integer>{2,3,5,8,10,4};
    }
    
    /*
    public static void getConcesionarios(String idUsuario){
        //list<String> lstConcesionarios = new list<String>();
        list<Concesionario__c> lstConcesionarios = new list<Concesionario__c>();
        String Rol = [select UserRole.Name from User where Id=:idUsuario limit 1].UserRole.Name;
        system.debug(Rol);
        switch on Rol {
            when 'Gerente de Zona Centro Norte' {		// Zona Centro Norte
                lstConcesionarios = [select Id, Name,Numero_de_Asesores__c from Concesionario__c where Zona__c = 'Zona Centro Norte' with SECURITY_ENFORCED];
            }	
            when 'Gerente de Zona Sur' {		// Zona Sur
                lstConcesionarios = [select Id, Name,Numero_de_Asesores__c from Concesionario__c where Zona__c = 'Zona Sur'];
            }
            when else {		  // si no es de los gerentes de zona, entonces halar solo los concesionarios donde es miembro
                set<Id> setConcesionarios = new set<Id>();
                for (Miembro_de_Concesionario__c mc: [select Concesionario__c from Miembro_de_Concesionario__c where Nombre_de_asesor__c=:idUsuario with SECURITY_ENFORCED]){
                    setConcesionarios.add(mc.Concesionario__c);
                }
                lstConcesionarios = [select Id, Name,Numero_de_Asesores__c from Concesionario__c where Id in:setConcesionarios with SECURITY_ENFORCED];
            }
        } 
        
        for (Concesionario__c c: lstConcesionarios){ 
            system.debug('Concesionario: ' + c);
            TotalUsuariosACargo+= c.Numero_de_Asesores__c;
        }
        system.debug('TotalUsuariosACargo: ' + TotalUsuariosACargo);
        //return lstConcesionarios;
    }
*/
}