trigger LeadTrigger on Lead ( after insert) {//(before update, before insert, after insert, after update) {
	new LeadTriggerHandler().run();
}