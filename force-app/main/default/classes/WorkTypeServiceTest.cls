@isTest
public class WorkTypeServiceTest {

    @isTest
    static void testGetWorkTypesByCategories() {
        // Crear algunos registros de WorkType para la prueba
        List<WorkType> workTypes = new List<WorkType>();
        
        workTypes.add(new WorkType(Name = 'Type1', categoriaServicio__c = 'Mantenimiento', EstimatedDuration = 60, NoOperacion__c = '001'));
        workTypes.add(new WorkType(Name = 'Type2', categoriaServicio__c = 'Mantenimiento', EstimatedDuration = 120, NoOperacion__c = '002'));
        workTypes.add(new WorkType(Name = 'Type3', categoriaServicio__c = 'Blindaje', EstimatedDuration = 90, NoOperacion__c = '003'));
        
        insert workTypes;

        // Preparar la solicitud de prueba
        WorkTypeService.WorkTypeRequest request = new WorkTypeService.WorkTypeRequest();
        request.CategoriasAdicionales = 'Mantenimiento;Blindaje';
        
        List<WorkTypeService.WorkTypeRequest> requestList = new List<WorkTypeService.WorkTypeRequest>();
        requestList.add(request);

        // Ejecutar el método invocable
        Test.startTest();
        List<WorkTypeService.WorkTypeResponse> responses = WorkTypeService.getWorkTypesByCategories(requestList);
        Test.stopTest();

        // Verificar los resultados
        System.assertNotEquals(null, responses, 'La lista de respuestas no debe ser nula.');
        System.assertEquals(1, responses.size(), 'Debe haber una respuesta en la lista.');

        WorkTypeService.WorkTypeResponse response = responses[0];
        List<WorkType> resultWorkTypes = response.ListaTiposServicioAdicionales;
        
        System.assertNotEquals(null, resultWorkTypes, 'La lista de WorkTypes en la respuesta no debe ser nula.');
        System.assertEquals(3, resultWorkTypes.size(), 'La lista de WorkTypes debe contener 3 registros.');

        Set<String> resultCategories = new Set<String>();
        for (WorkType wt : resultWorkTypes) {
            resultCategories.add(wt.categoriaServicio__c);
        }

        System.assert(resultCategories.contains('Mantenimiento'), 'La categoría Mantenimiento debe estar presente en los resultados.');
        System.assert(resultCategories.contains('Blindaje'), 'La categoría Blindaje debe estar presente en los resultados.');
    }
}