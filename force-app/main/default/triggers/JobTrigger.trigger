/**
 * JobTrigger - Fires on Job__c INSERT and UPDATE
 * WHEN: Before/After Insert, Before/After Update
 * Delegates logic to JobTriggerHandler
 */
trigger JobTrigger on Job__c (before insert, after insert, before update, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            JobTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            JobTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            JobTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            JobTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
