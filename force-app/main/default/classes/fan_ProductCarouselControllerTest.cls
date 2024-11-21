@IsTest
public class fan_ProductCarouselControllerTest {
    
    @testSetup static void setup() {
        RecordType recordType =
            [SELECT Id, Name FROM RecordType
             WHERE DeveloperName = 'Motos' AND sObjectType = 'Product2'];
        
        List<Product2> testProduct = new List<Product2>();
        for(Integer i=0;i<10;i++) {
            Integer IntrandomNumber = Integer.valueof((Math.random() * 1000));
            
            
            testProduct.add(new Product2(Name = 'TestProduct2'+i, StockKeepingUnit = String.valueOf(i), 
                                         RecordTypeId = recordType.Id,
                                         ProductCode = String.valueOf(i)));
        }
        
        insert testProduct;
        
        Product2 firstRow = testProduct.get(0);
        
        List<fan_RelatedProducts__c> lstRelatedProduct = new List<fan_RelatedProducts__c>();
        for(Product2 product : testProduct){
            lstRelatedProduct.add(new fan_RelatedProducts__c(fan_Source__c = firstRow.Id, fan_Target__c = product.Id, fan_RelationType__c = '1'));
        }
        
        insert lstRelatedProduct;
        
    }
    
    
    @isTest static void getRelatedProductsBySourceIdTest() {
        Product2 prod = [SELECT Id, StockKeepingUnit FROM Product2 WHERE Name='TestProduct20' LIMIT 1];
        Test.startTest();
		List<String> lstRelatedProduct = fan_ProductCarouselController.getRelatedProductsBySourceId(prod.Id, '1');
        Test.stopTest();
    }
    
    @isTest static void getRelatedProductPickListValueTest() {
        Test.startTest();
		fan_ProductCarouselController.getRelatedProductPickListValue();
        Test.stopTest ();
    }
    
}