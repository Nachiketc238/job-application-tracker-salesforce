/**
 * ApplicantTrigger - Fires on Applicant_Name__c INSERT, UPDATE, DELETE
 * WHEN: Before Delete, After Insert, After Update
 * Delegates logic to ApplicantTriggerHandler
 */
trigger ApplicantTrigger on Applicant_Name__c (before delete, after insert, after update) {
    if (Trigger.isBefore && Trigger.isDelete) {
        ApplicantTriggerHandler.handleBeforeDelete(Trigger.old);
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ApplicantTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            ApplicantTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
