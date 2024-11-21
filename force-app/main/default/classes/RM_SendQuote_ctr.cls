/**
* Fanalca
* @author           Raul Mora
* Description:      Controller class to send quote by mail.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     17/01/2019      Raul Mora (RM)          Class definition.
* @version  1.1     01/06/2019      Andres Oliva (AO)       Modified constructor  in order to set a visualforce page called AO_cotizacionAutosRenting_pag used for renting cars.
*********************************************************************************************************/
public class RM_SendQuote_ctr {
    
    private final AM_Oportunidad__c objOp;
    public String strURL {get;set;}
    
    public RM_SendQuote_ctr( ApexPages.StandardController stdController ) {
        this.objOp = [ Select Id, AM_Usuario_motocicleta__r.PersonEmail, AM_Tipo_de_cotizacion__c, Owner.Email
                       From AM_Oportunidad__c
                       Where Id =: apexpages.currentpage().getparameters().get('id') ];
        
        // AO START 01/06/2019  strURL = objOp.AM_Tipo_de_cotizacion__c == 'Usados' ? '/apex/RM_CotizacionFinanciacionUsados_pag?id=' + objOp.Id : '/apex/RM_CotizacionFinanciacion_pag?id=' + objOp.Id;
        
        if( string.IsNotBlank( objOp.AM_Tipo_de_cotizacion__c ) && objOp.AM_Tipo_de_cotizacion__c == 'Usados')
        {
            strURL  = '/apex/RM_CotizacionFinanciacionUsados_pag?id=' + objOp.Id ;
        }    
        else if( string.IsNotBlank( objOp.AM_Tipo_de_cotizacion__c ) && objOp.AM_Tipo_de_cotizacion__c == 'Renting')
        {
            strURL  = '/apex/AO_cotizacionAutosRenting_pag?id=' + objOp.Id ;
        }
        else
        {
             strURL  = '/apex/RM_CotizacionFinanciacion_pag?id=' + objOp.Id;
        }
        // AO END 01/06/2019 

    }
    
    /**
  * @Method:     sendEmail
  * @Description: Send email with attached quote and attachments related on the quote.
  * @author     Raul Mora - 17-01-2019
  */
    public Pagereference sendEmail() {
        //Return main page.
        PageReference prReturn = new PageReference( '/' + objOp.Id );
        
        system.debug('\n\n--> test ');
        //Variable to store the Quote PDF.
        Blob blbBody;
        try {            
            //Visualforce that will contain the structure of the PDF.
            PageReference prTemplate = new PageReference( strURL );
            //Obtain the page content as PDF in a variable.
            if( Test.isRunningTest() ) {
                //Test class purpose.
                blbBody = Blob.valueOf('foo');
            } else {
                blbBody = prTemplate.getContentAsPDF();
            }
            //20-03-2019 Include logic to capture other attachments.
            List<Messaging.EmailFileAttachment> lstAtt = new List<Messaging.EmailFileAttachment>();
            Set<String> stOrderAttch = new Set<String>();
            List<ContentDocumentLink> lstOtherAtt = [ Select Id, ContentDocumentId  
                                                      From ContentDocumentLink
                                                      Where LinkedEntityId =: objOp.Id ];
            if( !lstOtherAtt.isEmpty() ) {
               
                for( ContentDocumentLink objCD : lstOtherAtt ) {
                    stOrderAttch.add( objCD.ContentDocumentId );                    
                }
                
                List<ContentVersion> lstConVer = [ Select Id, VersionData, FileType, PathOnClient 
                                                   From ContentVersion 
                                                   Where ContentDocumentId IN: stOrderAttch ];
                if( !lstConVer.isEmpty() ) {
                    Messaging.EmailFileAttachment emailAttTemp = new  Messaging.EmailFileAttachment(); 
                    for( ContentVersion objCV : lstConVer ) {
                        emailAttTemp = new  Messaging.EmailFileAttachment(); 
                        emailAttTemp.setFileName( objCV.PathOnClient );
                        emailAttTemp.setBody( objCV.VersionData );
                        emailAttTemp.setContentType( obtainContentType( objCV.FileType ) );                        
                        lstAtt.add( emailAttTemp );
                    }
                }
                
            }
            system.debug('\n\n--> lstAtt '+lstAtt);
            EmailTemplate objEmail = [ Select Id, Body, Subject
                                       From EmailTemplate
                                       Where DeveloperName ='RM_SendQuote' ];
            
            List<String> lstAdd = new List<String>();    
            //20-03-2019 Include quote owner email. 
            lstAdd.add( objOp.Owner.Email );
            lstAdd.add( objOp.AM_Usuario_motocicleta__r.PersonEmail );
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject( objEmail.Subject );
            email.setToAddresses( lstAdd );
            email.setPlainTextBody( objEmail.Body );
            Messaging.EmailFileAttachment emailAtt = new  Messaging.EmailFileAttachment();
            emailAtt.setFileName('Cotizacion.pdf');
            emailAtt.setBody( blbBody );
            emailAtt.setContentType('application/pdf');
            lstAtt.add( emailAtt );
            system.debug('\n\n--> lstAtt after '+lstAtt);
            email.setFileAttachments( lstAtt );
            Messaging.SendEmailResult [] emailRes = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            
        } catch (exception e) {            
            system.debug('-->\n\n Error sending email ' + e);
            
        }
        prReturn.setRedirect( true );
        return prReturn;
    }
    
    /**
  * @Method:     obtainContentType
  * @param:     String
  * @Description: Set content type based on content from file.
  * @author     Raul Mora - 20-03-2019
  */
    public String obtainContentType( String strContent ) {
        system.debug('\n\n--> strContent '+strContent);
        map<String,String> mpValue = new map<String,String>();
        mpValue.put( 'PNG', 'image/png' );
        mpValue.put( 'JPEG', 'image/jpeg' );
        mpValue.put( 'JPG', 'image/jpeg' );
        mpValue.put( 'PDF', 'application/pdf' );
       String strReturn = mpValue.containsKey( strContent ) ? mpValue.get( strContent ) : ( strContent.contains( 'WORD' ) || strContent.contains( 'word' ) ? 'application/msword' : ( strContent.contains( 'POWER' ) || strContent.contains( 'power' ) ? 'application/vnd.ms-powerpoint' : '' ) );
        return strReturn;
    }

}