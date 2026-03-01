/**
 * ExamTrigger - Fires on Exam__c INSERT, UPDATE, DELETE
 * WHEN: Before/After Insert, Before/After Update, Before Delete
 * Delegates logic to ExamTriggerHandler
 */
trigger ExamTrigger on Exam__c (before insert, after insert, before update, after update, before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ExamTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            ExamTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            ExamTriggerHandler.handleBeforeDelete(Trigger.old);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ExamTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            ExamTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
