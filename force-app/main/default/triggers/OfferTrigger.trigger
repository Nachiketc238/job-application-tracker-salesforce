/**
 * OfferTrigger - Fires on Offer__c INSERT, UPDATE, DELETE
 * WHEN: Before/After Insert, Before/After Update, Before Delete
 * Delegates logic to OfferTriggerHandler
 */
trigger OfferTrigger on Offer__c (before insert, after insert, before update, after update, before delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            OfferTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            OfferTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            OfferTriggerHandler.handleBeforeDelete(Trigger.old);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OfferTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            OfferTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
