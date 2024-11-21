trigger QuoteTrigger on Quote (before insert, before update) {
	new QuoteTriggerHandler().run();
}