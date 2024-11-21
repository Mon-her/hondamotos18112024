/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Mock Class for FanalcaConsultaPreciosDescuentos
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     09/12/2020      Juan Ansaldi            Class definition.
* @version  1.1     10/12/2020      Juan Ansaldi            Mock class finished
*********************************************************************************************************/
@isTest
global class FanalcaConsultaPreciosDescuentos_Mock implements WebServiceMock {
    public static Integer option {get; set;}
    public FanalcaConsultaPreciosDescuentos_Mock (integer opcion){
        option = opcion;
    }
    global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
        // start - specify the response you want to send
        FanalcaConsultaPreciosDescuentos.DT_P_D_RESPONSE response_x = 
            new FanalcaConsultaPreciosDescuentos.DT_P_D_RESPONSE();
               List<FanalcaConsultaPreciosDescuentos.Row_element> listRow = new List<FanalcaConsultaPreciosDescuentos.Row_element>();
               FanalcaConsultaPreciosDescuentos.Row_element row = new FanalcaConsultaPreciosDescuentos.Row_element();              
               switch on option {
                   when 1 {		//1 ok
                       row.MATNR = '123';
                       row.MENGE = '13';
                       row.NETWR = '13';
                       row.VSOAT = '13';
                       row.VMATR = '13';
                       row.VCINI = '23';
                       row.VSEGR = '13';
                       row.MKTXT = '13';
                       row.ZPR0 = '23';
                       row.ZIC1 = '23';
                       row.ZIC2 = '23';
                       row.ZIC4 = '13';
                       row.ZSUB1 = '23';
                       row.ZSUB2 = '23';
                       row.ZD01 = '23';
                       row.ZD02 = '23';
                       row.ZD03 = '23';
                       row.ZD04 = '23';
                       row.ZD05 = '23';
                       row.ZD06 = '23';
                       row.ZD07 = '23';
                       row.ZV01 = '23';
                       row.ZV02 = '23';
                       row.ZV11 = '23';
                       row.ZV16 = '23';
                       row.ZZ01 = '23';
                       row.ZZA2 = '13';
                       row.ZZ03 = '23';
                       row.ZZ04 = '20';
                       listRow.add(row);
                       response_x.Row = listRow;    
                   }	
                   when 2 {		
                       row.MATNR = '1265963';
                       row.MENGE = '13';
                       row.NETWR = '13';
                       row.VSOAT = '13';
                       row.VMATR = '13';
                       row.VCINI = '23';
                       row.VSEGR = '13';
                       row.MKTXT = '13';
                       row.ZPR0 = '23';
                       row.ZIC1 = '23';
                       row.ZIC2 = '23';
                       row.ZIC4 = '13';
                       row.ZSUB1 = '23';
                       row.ZSUB2 = '23';
                       row.ZD01 = '23';
                       row.ZD02 = '23';
                       row.ZD03 = '23';
                       row.ZD04 = '23';
                       row.ZD05 = '23';
                       row.ZD06 = '';
                       row.ZD07 = '23';
                       row.ZV01 = '23';
                       row.ZV02 = '23';
                       row.ZV11 = '23';
                       row.ZV16 = '23';
                       row.ZZ01 = '23';
                       row.ZZA2 = '13';
                       row.ZZ03 = '23';
                       row.ZZ04 = '20';
                       listRow.add(row);
                       response_x.Row = listRow;
                   }
                   when 3 {		
                       row.MATNR = '';
                       row.MENGE = '';
                       row.NETWR = '';
                       row.VSOAT = '';
                       row.VMATR = '';
                       row.VCINI = '';
                       row.VSEGR = '';
                       row.MKTXT = '';
                       row.ZPR0 = '';
                       row.ZIC1 = '';
                       row.ZIC2 = '';
                       row.ZIC4 = '';
                       row.ZSUB1 = '';
                       row.ZSUB2 = '';
                       row.ZD01 = '';
                       row.ZD02 = '';
                       row.ZD03 = '';
                       row.ZD04 = '';
                       row.ZD05 = '';
                       row.ZD06 = '';
                       row.ZD07 = '';
                       row.ZV01 = '';
                       row.ZV02 = '';
                       row.ZV11 = '';
                       row.ZV16 = '';
                       row.ZZ01 = '';
                       row.ZZA2 = '';
                       row.ZZ03 = '';
                       row.ZZ04 = '';
                       listRow.add(row);
                       response_x.Row = listRow;
                   }
               }
           
        // end
        response.put('response_x', response_x); 
   }

}