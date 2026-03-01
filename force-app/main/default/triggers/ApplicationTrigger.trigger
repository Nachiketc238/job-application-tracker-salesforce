/**
 * ApplicationTrigger - Fires on Application__c INSERT and UPDATE
 * WHEN: Before/After Insert, Before/After Update
 * Delegates logic to ApplicationTriggerHandler
 */
trigger ApplicationTrigger on Application__c (before insert, after insert, before update, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ApplicationTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            ApplicationTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ApplicationTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            ApplicationTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
