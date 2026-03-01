/**
 * InterviewTrigger - Fires on Interview__c INSERT, UPDATE, DELETE
 * WHEN: Before/After Insert, Before/After Update, Before Delete
 * Delegates logic to InterviewTriggerHandler
 */
trigger InterviewTrigger on Interview__c (before insert, after insert, before update, after update, before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            InterviewTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            InterviewTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            InterviewTriggerHandler.handleBeforeDelete(Trigger.old);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            InterviewTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            InterviewTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
