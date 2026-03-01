/**
 * StudentTrigger - Fires on Student__c INSERT, UPDATE, DELETE
 * WHEN: Before Insert, Before Update, Before Delete
 * Delegates logic to StudentTriggerHandler
 */
trigger StudentTrigger on Student__c (before insert, before update, before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            StudentTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            StudentTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            StudentTriggerHandler.handleBeforeDelete(Trigger.old);
        }
    }
}
