@isTest
public class InventarioDeUsadosTriggerHandler_Test {
    @isTest
    private static void testSetup() {
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Opportunity> oppList;
        List<Account> cuentaPN;
       
        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        
      
        
        Pricebook2 pb = New Pricebook2();
        pb.Name = 'Precios Usados';
        pb.IsActive = true;
        insert pb;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
    
        Product2 producto = new Product2();
        producto.Name = 'Honda CRV Test';
        producto.ProductCode = '001';
        producto.IsActive = true;
        producto.Placa__c = 'abc123';
        producto.RecordTypeId = rtProductoAutos.Id;
        insert producto; 
        /*
        List<Opportunity> oppList;
        List<Account> cuentaPN;
        RecordType rt = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = :Label.RTOportunidadAutos
        ];*/
/*
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
*/        /*
        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);*/
        //oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Administrativo autos'];
        User u = new User(Alias = 'standt', Email='standarduser@fanalca.test',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName);

        System.runAs(u) {
            Asset a = New Asset();
            a.AccountId = cuentaPN[0].Id;
            a.Name = 'hola';
            a.Placa__c = 'abc123';
            insert a;

            RecordType rt = [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE DeveloperName = :Label.RTOportunidadAutos
            ];
            Inventario_de_Usados__c i = New Inventario_de_Usados__c();
            i.Ano__c = '2021';
            i.Caja__c = 'AT';
            i.Cilindraje__c = 1.1;
            i.Color__c = '123';
            i.Estado_Del_Vehiculo__c = 'DISPONIBLE';
            i.Linea__c = '1';
            i.Marca__c = '123';
            i.Nombre_De_Producto__c = '123';
            i.Placas__c = 'abc123';
            i.Tipo_de_Combustible__c = 'DIESEL';
            i.Traccion__c = '2WD';
            i.Version__c = '1';
            i.Kilometraje__c = '123';
            i.Precio_Venta__c = 123;
            i.Vin__c = '123';
            insert i;
            
            Opportunity op = new Opportunity();
            op.Name = 'Opp ';
            op.AccountId = cuentaPN[0].Id;
            op.Tipo_de_cliente__c = 'Cliente Honda';
            op.CloseDate = system.today();
            op.Tipo_de_Pago__c = '101';
            op.Temperatura_de_la_Compra__c = 'Media';
            op.StageName = '-P0';
            op.RecordTypeId = rt.Id;
            op.CloseDate = Date.newInstance(2010, 12, 30);
            op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
            op.Fecha_de_validez__c = Date.today() + 10;
            op.Tipo_de_Pago__c = '101';
            op.OwnerId = Userinfo.getUserId();
            op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
            op.Averigu_sobre_otras_marcas__c = 'No';
            op.Tipo_de_cliente__c = 'Cliente Honda';
            op.Temperatura_de_la_Compra__c = 'Media';
            op.Amount = 1.1;
            op.Tipo_de_Oportunidad__c = 'Nuevos';
            op.Order_Generated__c = false;
            op.Concesionario__c = [Select Id from Concesionario__c Limit 1].Id;
            op.Registro_Migrado__c = true;
            op.Vehiculo__c = a.id;
            op.Usado_Separado__c = i.id;
            op.Vehiculo_con_blindaje__c ='NO';
            op.StageName = 'PU';
            op.Vehiculo_Anterior_MarcaLineaModelo__c ='X300';
            op.Posee_vehiculo_de_otra_marca__c = 'Si';
            op.Es_un_HONDA_adicional__c = 'No';
            op.MarcaLineaModelo__c = 'AUDI';
            op.MarcaLineaModelo1__c = 'AUDI';
            op.Linea_Modelo__c = 'A5';
            op.Otra_Marca_Considero_Opcion_1__c = 'BMW';
            op.Otra_Marca_Considero_Opcion_2__c = 'CHEVROLET';
            op.Linea_Modelo_Marca_Considero_1__c = 'BMW'; 
            op.VIN__c ='VH-78958';    
            op.Linea_Modelo_Marca_Considero_2__c ='AUDI';       
            insert op;
           
            
            
            //update op;
            
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.OpportunityId = op.Id;
            oli.Product2Id = [Select Id from Product2 Limit 1].Id;
            oli.PricebookEntryId = [Select Id from PricebookEntry Limit 1].Id;
            oli.Quantity = 132;
            oli.Valor_soat__c = '2343902';
            oli.Valor_matrcula__c = 12334;
            oli.Cuota_Inicial__c = 12334;
            oli.Valor_seguro_robo__c = 12334;
            oli.Descuento_Valor__c = 23;
            oli.UnitPrice = 12334;
            insert oli; 

            quote oQuote = new quote();
            oQuote.OpportunityId = op.id;
            oQuote.Name = 'Quote test';
            insert oQuote;
                
     
            op.Usado_Separado__c = i.id;
            update op;
            i.Estado_Del_Vehiculo__c = 'CONSIG. RETIRADO';
            i.Traccion__c = '4WD';
            update i;
            
            delete i;
        }
         
    }
}