@isTest(SeeAllData=false)
                                
private class AM_Actualizar_Estado_Facturas_Batch_tst{
//RM 14-01-2019. Commented. Not in use 
 /*
    static testmethod void testFacturas_Batch() {
    
        // The query used by the batch job.
        /*
        String etapa = 'Prospectación';
        String etapa2 = 'Facturación';
        String query = 'select name, AM_Etapa__c from AM_Oportunidad__c where AM_Etapa__c IN (:etapa, :etapa2)';

       // RecordType recType = [SELECT Id FROM RecordType WHERE Name = 'Persona natural' ];
        Date myDate = Date.newInstance(1980, 4, 15);
        //RM 14-01-2019. Adjust test class coverage.
        Account acc = new Account();
        acc.Phone = '3102334532';
        acc.FirstName ='test';
        acc.LastName = 'Test';
        acc.Salutation = 'Sra.';
        acc.AM_Genero__pc = 'Masculino';
        acc.PersonEmail = 'test@test.com';
        insert acc;

        AM_Oportunidad__c opp = new AM_Oportunidad__c(
         AM_Usuario_motocicleta__c = acc.Id,
         //RM 14-01-2019. Adjust test class coverage.
         AM_Propietario_motocicleta__c  = acc.Id,
         Forma_de_pago__c = 'Leasing',
         AM_Etapa__c ='P0',
         AM_Canal_de_atencion__c = 'Aviso de prensa');
        insert opp;
        System.debug('etapa inicial ---------------> '+opp.AM_Etapa__c);

          opp.AM_Etapa__c ='P1';
          opp.Uso_de_Motocicleta__c = 'Trabajo';
        update opp;
        System.debug('etapa segunda ---------------> '+opp.AM_Etapa__c);
          opp.AM_Etapa__c ='P2';
        update opp;
        System.debug('etapa tercera ---------------> '+opp.AM_Etapa__c);

       Test.startTest();
       //AM_Actualizar_Estado_Facturas_Batch c = new AM_Actualizar_Estado_Facturas_Batch();
       //Database.executeBatch(c, 100);

       Id batchInstanceId = Database.executeBatch(new AM_Actualizar_Estado_Facturas_Batch(), 100);
       Test.stopTest();

       // Verify merchandise items got deleted 
       /*
       Integer i = [SELECT COUNT() FROM AM_Oportunidad__c];
       System.assertEquals(i, 0);
       
    }
    */
}