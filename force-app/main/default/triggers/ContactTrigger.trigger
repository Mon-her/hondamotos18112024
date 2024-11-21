//Created on July 2021, by JP
trigger ContactTrigger on Contact (before update) {
	new ContactTriggerHandler().run();
}