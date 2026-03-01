/**
 * OfferTriggerHandler - Handles all business logic for Offer__c records
 * Called by OfferTrigger on Before Insert, After Insert, Before Update, After Update, Before Delete
 */
public with sharing class OfferTriggerHandler {

    /**
     * BEFORE INSERT: Validation
     * Runs when: User creates NEW Offer records
     */
    public static void handleBeforeInsert(List<Offer__c> newList) {
        validateApplicationStatusHired(newList);
        validateOfferAndJoiningDates(newList);
    }

    /**
     * AFTER INSERT: Update Application Status to "Hired"
     * Runs when: Offer records have been successfully inserted
     */
    public static void handleAfterInsert(List<Offer__c> newList) {
        updateApplicationStatusToHired(newList);
    }

    /**
     * BEFORE UPDATE: Validation
     * Runs when: User UPDATES existing Offer records
     */
    public static void handleBeforeUpdate(List<Offer__c> newList, Map<Id, Offer__c> oldMap) {
        validateOfferAndJoiningDates(newList);
    }

    /**
     * AFTER UPDATE: Status cascade - Accepted -> Application "Hired" (final), Rejected -> "Rejected"
     * Runs when: Offer records have been successfully updated
     */
    public static void handleAfterUpdate(List<Offer__c> newList, Map<Id, Offer__c> oldMap) {
        cascadeOfferStatusToApplication(newList, oldMap);
    }

    /**
     * BEFORE DELETE: Prevent deletion if Offer Status = "Accepted"
     * Runs when: User attempts to DELETE Offer records
     */
    public static void handleBeforeDelete(List<Offer__c> oldList) {
        preventDeletionIfOfferAccepted(oldList);
    }

    private static void validateApplicationStatusHired(List<Offer__c> newList) {
        Set<Id> interviewIds = new Set<Id>();
        for (Offer__c o : newList) {
            if (o.Interview__c != null) interviewIds.add(o.Interview__c);
        }
        if (interviewIds.isEmpty()) return;

        Map<Id, Interview__c> intMap = new Map<Id, Interview__c>([
            SELECT Id, Application__r.Status__c FROM Interview__c WHERE Id IN :interviewIds
        ]);

        for (Offer__c o : newList) {
            if (o.Interview__c == null) continue;
            Interview__c i = intMap.get(o.Interview__c);
            if (i != null && i.Application__r.Status__c != 'Hired') {
                o.addError('Offer can only be created if Application Status is Hired.');
            }
        }
    }

    private static void validateOfferAndJoiningDates(List<Offer__c> newList) {
        Date today = Date.today();
        for (Offer__c o : newList) {
            if (o.Offer_Date__c != null && o.Joining_Date__c != null) {
                if (o.Offer_Date__c > o.Joining_Date__c) {
                    o.addError('Offer Date must be before or on Joining Date.');
                }
            }
            if (o.Joining_Date__c != null && o.Joining_Date__c < today) {
                o.addError('Joining Date must be in the future when creating/updating.');
            }
        }
    }

    private static void updateApplicationStatusToHired(List<Offer__c> newList) {
        Set<Id> interviewIds = new Set<Id>();
        for (Offer__c o : newList) {
            if (o.Interview__c != null) interviewIds.add(o.Interview__c);
        }
        if (interviewIds.isEmpty()) return;

        List<Application__c> appsToUpdate = [
            SELECT Id, Status__c FROM Application__c
            WHERE Id IN (SELECT Application__c FROM Interview__c WHERE Id IN :interviewIds)
            AND Status__c != 'Hired'
        ];
        for (Application__c app : appsToUpdate) {
            app.Status__c = 'Hired';
        }
        if (!appsToUpdate.isEmpty()) {
            update appsToUpdate;
        }
    }

    private static void cascadeOfferStatusToApplication(List<Offer__c> newList, Map<Id, Offer__c> oldMap) {
        Set<Id> interviewIdsForRejected = new Set<Id>();
        Set<Id> interviewIdsForHired = new Set<Id>();

        for (Offer__c o : newList) {
            Offer__c oldOffer = oldMap.get(o.Id);
            if (oldOffer == null || oldOffer.Offer_Status__c == o.Offer_Status__c) continue;
            if (o.Interview__c == null) continue;

            if (o.Offer_Status__c == 'Accepted') {
                interviewIdsForHired.add(o.Interview__c);
            } else if (o.Offer_Status__c == 'Rejected') {
                interviewIdsForRejected.add(o.Interview__c);
            }
        }

        List<Application__c> toUpdate = new List<Application__c>();
        if (!interviewIdsForRejected.isEmpty()) {
            for (Application__c app : [
                SELECT Id, Status__c FROM Application__c
                WHERE Id IN (SELECT Application__c FROM Interview__c WHERE Id IN :interviewIdsForRejected)
            ]) {
                app.Status__c = 'Rejected';
                toUpdate.add(app);
            }
        }
        if (!interviewIdsForHired.isEmpty()) {
            for (Application__c app : [
                SELECT Id, Status__c FROM Application__c
                WHERE Id IN (SELECT Application__c FROM Interview__c WHERE Id IN :interviewIdsForHired)
            ]) {
                app.Status__c = 'Hired';
                toUpdate.add(app);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private static void preventDeletionIfOfferAccepted(List<Offer__c> oldList) {
        for (Offer__c o : oldList) {
            if (o.Offer_Status__c == 'Accepted') {
                o.addError('Cannot delete Offer: Offer has been Accepted.');
            }
        }
    }
}
