@isTest
public class clsEliminarQuotePdfs_Test {
    public static testmethod void testear(){
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        TestDatautilityClass.crearOportunidadMotos(1);
        TestDataUtilityClass.crearQuoteMotos(1);
        
        //Id templateId  = '3D0EH1N000002eNUv Hola';//[select Id from Quote limit 1].ID;
        //PageReference pr = new PageReference('/quote/quoteTemplateDataViewer.apexp?id=' + recordId + '&summlid=' + templateId); 
		//PageReference pr = new PageReference('/quote/quoteTemplateDataViewer.apexp?id=' + TestDataUtilityClass.mapQuotesMotos.get(1).Id + '&summlid=' + templateId);  
        QuoteDocument qd = new QuoteDocument(); 
        Blob b = Blob.valueOf('Cadena cualquiera');//pr.getContentAsPDF();
    
        qd.Document = b;
        qd.QuoteId = TestDataUtilityClass.mapQuotesMotos.get(1).Id;
        insert qd;
        
        Datetime mesPasado = Datetime.now().addMonths(-1);
		Test.setCreatedDate(qd.Id, mesPasado);
        
        Id batchInstanceId = Database.executeBatch(new clsEliminarQuotePdfs());
    }
}