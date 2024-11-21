/**
* Fanalca
* @author           Juan Pablo Rodríguez
* Description:      Consume of Web Service class to create/update Account in UNOEE.
*
* Changes (Version)
* -------------------------------------------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     Aug/12/2024   Juan Pablo Rodríguez       Class definition.
*********************************************************************************************************/

public without sharing class InvocableSendAccountUNOEEController {
    
    @InvocableMethod(label='Enviar cuenta a UNOEE' description='Método dedicado a la creación/actualización de registros de cuenta en UNOEE' category='Account' callout=true)
    public static List<Results> sendAccount(List<Requests> requestList) {
        List<Results> resultList = new List<Results>();
        Results res = new Results();
        String answer = ''; 

        Requests req = requestList?.get(0);
        if(req != null) {
            // Callout acount UNOEE
            Id accountId = (Id)req.accountId;
            answer = (!Test.isRunningTest() ? AutosSendAccountToUNOEE.SendAccount(accountId) : '200');

            // Answer evaluation 
            res.message = (answer == '200' ? 'El registro de cuenta fue creada/actualizada con éxito en UNOEE.' : 'Se produjo un error al tratar de crear/actualizar el registro de cuenta en UNOEE, favor contacte al área técnica.');
            res.statusCode = answer;
            resultList.add(res);
        }

        return resultList;
    }

    public class Requests {
        @InvocableVariable(label='Registro de Cuenta' description='Registro de Cuenta de Salesforce' required=true)
        public Id accountId;
    }

    public class Results {
        @InvocableVariable(label='Código de Estado' description='Código de Estado de la Transacción' required=true)
        public String statusCode;
        @InvocableVariable(label='Mensaje de Resultado' description='Mensaje del Resultado de la Transacción en UNOEE' required=true)
        public String message;
    }

}