trigger InventarioDeUsadosTrigger on Inventario_de_Usados__c (before insert, before update, after insert, after update, before delete) {
	new InventarioDeUsadosTriggerHandler().run();
}