public class WorkTypeService {

    @InvocableMethod(label='Obtener WorkTypes por Categorías Adicionales' description='Consulta WorkType según Categorías Adicionales y un Modelo')
    public static List<WorkTypeResponse> getWorkTypesByCategories(List<WorkTypeRequest> requestList) {
        // Crear una lista para almacenar los resultados
        List<WorkTypeResponse> responseList = new List<WorkTypeResponse>();
		List<WorkType> aditionalsWorkTypes = new List<WorkType>();
        
        // Iterar sobre cada solicitud en la lista de solicitudes
        for (WorkTypeRequest request : requestList) {
            // Dividir la cadena de Categorías Adicionales en una lista de valores
            List<String> categoriasAdicionalesList = new List<String>();
            if (String.isNotBlank(request.CategoriasAdicionales)) {
                categoriasAdicionalesList = request.CategoriasAdicionales.split(';');
            }

            // Realizar la consulta para obtener los registros de WorkType
            List<WorkType> queriedWorkTypes = [SELECT Id, Name, EstimatedDuration, NoOperacion__c, categoriaServicio__c
                                               FROM WorkType
                                               WHERE categoriaServicio__c IN :categoriasAdicionalesList ORDER BY categoriaServicio__c ASC];
			aditionalsWorkTypes.addAll(queriedWorkTypes);
            WorkTypeResponse response = new WorkTypeResponse();
            response.ListaTiposServicioAdicionales = aditionalsWorkTypes;
			responseList.add(response);
        }

        // Devolver la lista de respuestas
        return responseList;
    }

    // Clase interna para manejar los parámetros de entrada del método invocable
    public class WorkTypeRequest {
        @InvocableVariable(label='Categorías Adicionales' description='Cadena de texto con valores separados por punto y coma para filtrar los WorkTypes')
        public String CategoriasAdicionales;

        @InvocableVariable(label='Modelo' description='Modelo asociado con la consulta, aunque no se utiliza en este ejemplo')
        public String modelo;
    }

    // Clase interna para la respuesta del método invocable
    public class WorkTypeResponse {
        @InvocableVariable(label='ListaTiposServicioAdicionales' description='Lista de registros WorkType')
        public List<WorkType> ListaTiposServicioAdicionales;
    }
}