@istest
public  class AFOG_OpportunityHandlerMotos_test {
    
    public static string sOppId ;
    /*********************************************************************************************************
    * @name            createAccount
    * @author          AFOG
    * @created         19/05/2023
    * @description     Description of your code
    * @param           String param : Explanation
    * @return          Explanation of the return value
   **********************************************************************************************************/
   public static account createAccount( Boolean isInsert , string sName, string iDocumentNumber){
       Account objAcc  = new Account(); 
       objAcc.Phone                             = '8624597';
       objAcc.FirstName                         ='test';
       objAcc.LastName                          = sName;
       objAcc.Salutation                        = 'Sra.';
       objAcc.AM_Como_se_entero_de_la_marca__c  = 'Radio';
       objAcc.AM_Genero__pc                     = 'Masculino';
       objAcc.PersonEmail                       = sName+'test@test.com';
       objAcc.AM_Numero_de_documento__c         = iDocumentNumber;
       objAcc.AM_Tipo_de_documento__c           ='Cédula de ciudadanía';
       objAcc.AM_Estado_civil__pc                = 'Soltero';
       objAcc.Tiene_hijos__pc                   = '2';
       objAcc.Nivel_de_ingresos__c              = 'Entre 1 - 2 SMMLV';       
       objAcc.PersonBirthdate                   = system.today().addDays(-7220);
       objAcc.Grado_de_Escolaridad__pc          = 'Universitario';
       objAcc.Grado_de_escolaridad__c           = 'Universitario';
       objAcc.AM_Nivel_Socioeconomico__c        = '3';
       objAcc.AM_Deporte_que_prefiere__pc       = 'Ciclismo;Equitacion;Equitación';
       objAcc.Que_actividad_realiza_en_tiempo_libre__pc = 'T.V;Teatro;Finca'; 

       if( isInsert ){
           insert objAcc;
       }
       return objAcc;            
   }
    /*********************************************************************************************************
    * @name            createConcesionatio
    * @author          AFOG
    * @created         19/05/2023
    * @description     Description of your code
    * @param           String param : Explanation
    * @return          Explanation of the return value
   **********************************************************************************************************/
    public static Concesionario__c createConcesio( Boolean isInsert, string name){
        Concesionario__c objConcesi = new Concesionario__c();
        objConcesi.Agencia__c   = name;
        objConcesi.Name         = name;
        if( isInsert ){
            insert objConcesi;
        }
        return objConcesi;
    }


   /*********************************************************************************************************
    * @name            createAccount
    * @author          AFOG
    * @created         19/05/2023
    * @description     Description of your code
    * @param           String param : Explanation
    * @return          Explanation of the return value
   **********************************************************************************************************/
   public static opportunity createOpportunity( Boolean isInsert , id accountId ,id concesiId, id recortype ){
       opportunity objOpp              = new opportunity();
       objOpp.recordtypeId                              = recortype;
       objOpp.Name                                      = 'Opp test';
       objOpp.AccountId                                 = accountId;
       objOpp.CloseDate                                 = system.today().addDays( 10 );
       objOpp.Propietario_vehiculo__c                   = accountId;
       objOpp.Forma_de_pago__c                          = 'Contado';
       objOpp.LeadSource                                = 'Actividades comerciales';
       objOpp.StageName                                 = 'P2';
       objOpp.Realizo_Best_Drive__c                     = 'No';
       objOpp.Subcategoria_fuente_de_prospecci_n__c     = 'Colegios/Universidades';
       objOpp.Probability                               =   30;
       objOpp.Es_un_HONDA_adicional__c                  = 'No';
       objOpp.Linea_Modelo__c                           =  'N/A';
       objOpp.MarcaLineaModelo1__c                      =  'N/A';
       objOpp.Otra_Marca_Considero_Opcion_1__c          = 'DODGE';
       objOpp.Linea_Modelo_Marca_Considero_1__c         = 'DURANGO';
       objOpp.Posee_vehiculo_de_otra_marca__c           = 'NO';
       objOpp.MarcaLineaModelo__c                       = 'NO';
       objOpp.Tipo_de_Oportunidad__c                    = 'Renting';
       objOpp.Vehiculo_de_interes__c                    = 'ACCORD';
       objOpp.Vitrina_de_despacho__c                    = concesiId;
       objOpp.Facturar_a_nombre_de__c                   = accountId;
       objOpp.VIN__c                                    = 'VH-08001';
       objOpp.Vehiculo_con_blindaje__c                  = 'NO';
       objOpp.Vehiculo_Anterior_MarcaLineaModelo__c     =  'CUPRA';
       objOpp.Posee_vehiculo_de_otra_marca__c           =  'Si';
       objOpp.Es_un_HONDA_adicional__c                  =  'Si';
       objOpp.MarcaLineaModelo__c                       = 'N/A';
       objOpp.Otra_Marca_Considero_Opcion_2__c          = 'FORD';
       objOpp.Linea_Modelo_Marca_Considero_2__c         = 'SCAPE';
       objOpp.AM_Cantidad_de_vehiculos__c               = '1';
       objOpp.AM_Numero_de_radicacion__c                = 'aaaa';
       objOpp.Amount                                    =  97990000;
       objOpp.Actividades_a_realizar_en_tiempo_libre__c = 'Salir con la familia';
       objOpp.Usted_prefiere_un_automovil__c            = 'Todoterreno';
       objOpp.Para_comprar_un_automovil_usted_primero__c = 'Busca en internet';
       objOpp.Usted_ve_su_automovil_como__c             = 'Un sello personal';
       objOpp.Frase_con_que_se_identifica_mas__c        = '"No le busca la quinta pata al gato"';
       objOpp.Sus_intereses_giran_en_torno_a__c         = 'Artículos para el hogar, Belleza, Supermercados';
       objOpp.Proteccin_y_seguridad__c                  = '1';
       objOpp.Ecolgica__c                               ='2';
       objOpp.Calidad_y_durabilidad__c                  ='5';
       objOpp.Comodidad_y_conveniencia__c               = '6';
       objOpp.Desempeo_e_ingeniera__c                   = '4';
       objOpp.Marca__c                                  = '6';
       objOpp.Cmo_es_su_comportamiento_DISC__c          =' 5';
       objOpp.Mas_resalta_de_su_vehiculo__c             ='trt';
       objOpp.Tema_mas_importante_marca__c              = 'Condiciones de financiación';
       objOpp.Tema_mas_importante_producto__c           ='Conectividad';
       objOpp.Tema_mas_importante_RespaldoServicio__c   ='Servicio de taller';


       if( isInsert ){
           insert objOpp;
       }
       return objOpp;             
   }
    /*********************************************************************************************************
    * @name            createAccvalidarCreacionTareaSeguimientoRTMotosount
    * @author          AFOG
    * @created         19/05/2023
    * @description     Description of your code
    * @param           String param : Explanation
    * @return          Al crear una oportunidad se debe crear automáticamente su tarea de seguimiento
   **********************************************************************************************************/
  static testMethod void validarCreacionTareaSeguimientoRTMotos () {
        recordtype recordtypeOpp  = [select id,DeveloperName,SobjectType from recordtype where  DeveloperName  in ('Motos_Opportunity_Layout') ];
        account          objAcc              =  createAccount( true , 'Account_Test', '102547845');
        Concesionario__c objConcesionario    =  createConcesio( true, 'AUTOLAUREL');
        opportunity      objOpp ;
        test.StartTest();
                objOpp              =  createOpportunity( true , objAcc.Id, objConcesionario.Id ,recordtypeOpp.id );
                system.debug(' opportunity motos @@@'+ JSON.serialize(objOpp ) + ' RECORDTYPE ,MOTOS @@@' + recordtypeOpp );
        test.StopTest();       
        task otask = [ SELECT Id, whatId, recordtype.name FROM task WHERE whatId =: objOpp.Id];
        System.assertEquals( otask.recordtype.name.contains('Tareas Motos'), true );
       // System.assertEquals( objOpp.AFOG_NoLlamadasSeguimientoProgramadas__c ==1, true );
    }    

}