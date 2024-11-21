//********************************************************************************
//*                                  ╔═╗ ┬ ╔╦╗                                   *
//*                                  ║  ┌┼─║║║                                   *
//*                                  ╚═╝└┘ ╩ ╩                                   *
//*                       ╔═╗╔═╗╔╗╔╔═╗╦ ╦╦ ╔╦╗╔═╗╔╗╔╔╦╗╔═╗                       *
//*                       ║  ║ ║║║║╚═╗║ ║║  ║ ╠═╣║║║ ║ ╚═╗                       *
//*                       ╚═╝╚═╝╝╚╝╚═╝╚═╝╩═╝╩ ╩ ╩╝╚╝ ╩ ╚═╝                       *
//* **************************************************************************** *
// ID de Endpoint para consumo
@RestResource(urlMapping='/CreateLeadFromSap/*')
global with sharing class CreateLeadFromSap {

    @HttpPost
    global static void createAccount() {
        // Obtener el objeto RestRequest que contiene el cuerpo de la solicitud
        RestRequest req = RestContext.request;
        
        // Obtener el cuerpo de la solicitud como una cadena (String)
        String jsonInput = req.requestBody.toString();
        
        // Verifica si el cuerpo está vacío
        if (String.isEmpty(jsonInput)) {
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf('{"message": "El cuerpo de la solicitud está vacío", "status": "error"}');
            return;
        }

        // Deserializamos el JSON y tratamos de determinar si es un objeto o una lista de objetos
        Object parsedInput = JSON.deserializeUntyped(jsonInput);
        
        System.debug('Json: ' + parsedInput);

        // Inicializamos una lista para guardar los mensajes de resultado
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        // Si la entrada es un mapa (objeto único)
        if (parsedInput instanceof Map<String, Object>) {
            Map<String, Object> leadFields = (Map<String, Object>) parsedInput;
            // Crear la cuenta a partir del objeto único
            results.add(createLeadFromMap(leadFields));
        } 
        // Si la entrada es una lista (múltiples objetos)
        else if (parsedInput instanceof List<Object>) {
            List<Object> inputList = (List<Object>) parsedInput;
            
            // Recorrer la lista y procesar cada elemento individualmente
            for (Object item : inputList) {
                // Verificar si cada item de la lista es un Map<String, Object>
                if (item instanceof Map<String, Object>) {
                    Map<String, Object> leadFields = (Map<String, Object>) item;
                    // Llamar a la función que crea el lead y maneja errores
                    results.add(createLeadFromMap(leadFields));
                } else {
                    // Si el elemento no es válido, agregar un mensaje de error
                    Map<String, Object> error = new Map<String, Object>();
                    error.put('MESSAGE', 'Registro no válido en la lista.');
                    error.put('CODE', '');
                    error.put('TYPE', 'error');
                    results.add(error);
                }
            }
        } else {
            Map<String, Object> error = new Map<String, Object>();
            error.put('MESSAGE', 'Formato de JSON no válido');
            error.put('CODE', '');   
            error.put('TYPE', 'error');
            results.add(error);
        }

        // Configurar el encabezado para indicar que la respuesta es JSON
        RestContext.response.addHeader('Content-Type', 'application/json');

        // Convertir el resultado en un JSON
        String jsonResponse = JSON.serialize(results);

        // Establecer el cuerpo de la respuesta
        RestContext.response.responseBody = Blob.valueOf(jsonResponse);
    }

    // Método para crear una lead a partir de un mapa de campos
    private static Map<String, Object> createLeadFromMap(Map<String, Object> leadFields) {
        // Crear un mapa para almacenar el resultado
        Map<String, Object> result = new Map<String, Object>();

        // Crear una nueva instancia del Lead 
        Lead newLead = new Lead();

        // Asignamos los campos de cada Lead
        newLead.Salutation 			  		 = (String)leadFields.get('Salutation'); 
        newLead.RecordTypeId 		  		 = '0123l000000oLugAAE'; // ID de record type
        newLead.FirstName 			  		 = (String)leadFields.get('FirstName');
        newLead.LastName 			  		 = (String)leadFields.get('LastName');
        newLead.MobilePhone 		  		 = (String)leadFields.get('MobilePhone');
        newLead.Email 				  		 = (String)leadFields.get('Email');
        newLead.Tipo_de_documento__c  		 = 'Cédula de ciudadanía';
        newLead.Nmero_de_documento__c 		 = (String)leadFields.get('Documento');
        newLead.Producto_de_inter_s_Motos__c = (String)leadFields.get('Producto');
        newLead.Status 					     = 'Pendiente';

        try {
            // Insertar utilizando Database.insert, con control de errores
            Database.SaveResult saveResult = Database.insert(newLead, false);  // false para no hacer "rollback" en caso de error

            // Verificar si la operación fue exitosa
            if (saveResult.isSuccess()) {
                result.put('MESSAGE', 'Lead creado exitosamente con ID: ' + newLead.Id);
                result.put('CODE', 'SUCCESSFUL_INSERTION');   
                result.put('TYPE', 'success');
            } else {
                
                // Agregar detalles de los errores
                Map<String, String> errorDetail = new Map<String, String>();
                for (Database.Error err : saveResult.getErrors()) {
                    result.put('MESSAGE', err.getMessage()); // Agregar el mensaje de detalle
                    result.put('CODE', String.valueOf(err.getStatusCode())); // Convertir StatusCode a String
                    result.put('TYPE', 'error');
                }
            }
        } catch (Exception e) {
            // Manejo de errores generales (otros tipos de excepciones)
            result.put('MESSAGE', 'Error desconocido al crear el Lead: ' + e.getMessage());
            result.put('CODE', ''); 
            result.put('TYPE', 'error');
        }

        return result;
    }
}