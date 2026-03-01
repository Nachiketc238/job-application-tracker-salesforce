/**
 * InterviewTriggerHandler - Handles all business logic for Interview__c records
 * Called by InterviewTrigger on Before Insert, After Insert, Before Update, After Update, Before Delete
 */
public with sharing class InterviewTriggerHandler {

    /**
     * BEFORE INSERT: Validation
     * Runs when: User creates NEW Interview records
     */
    public static void handleBeforeInsert(List<Interview__c> newList) {
        validateApplicationStatusForInsert(newList);
        validateScheduledDateFuture(newList);
        validateExamPassedIfExists(newList);
    }

    /**
     * AFTER INSERT: Update Application Status to "Interview"
     * Runs when: Interview records have been successfully inserted
     */
    public static void handleAfterInsert(List<Interview__c> newList) {
        updateApplicationStatusToInterview(newList);
    }

    /**
     * BEFORE UPDATE: Validation (optional - e.g. if changing scheduled date)
     * Runs when: User UPDATES existing Interview records
     */
    public static void handleBeforeUpdate(List<Interview__c> newList, Map<Id, Interview__c> oldMap) {
        // Placeholder for update validations
    }

    /**
     * AFTER UPDATE: Status cascade - Selected -> Application "Hired" + Create Offer, Rejected -> "Rejected"
     * Runs when: Interview records have been successfully updated
     */
    public static void handleAfterUpdate(List<Interview__c> newList, Map<Id, Interview__c> oldMap) {
        cascadeInterviewStatusToApplication(newList, oldMap);
    }

    /**
     * BEFORE DELETE: Prevent deletion if Application Status = "Hired"
     * Runs when: User attempts to DELETE Interview records
     */
    public static void handleBeforeDelete(List<Interview__c> oldList) {
        preventDeletionIfApplicationHired(oldList);
    }

    private static void validateApplicationStatusForInsert(List<Interview__c> newList) {
        Set<Id> appIds = new Set<Id>();
        for (Interview__c i : newList) {
            if (i.Application__c != null) appIds.add(i.Application__c);
        }
        if (appIds.isEmpty()) return;

        Map<Id, Application__c> appMap = new Map<Id, Application__c>([
            SELECT Id, Status__c FROM Application__c WHERE Id IN :appIds
        ]);

        for (Interview__c i : newList) {
            if (i.Application__c == null) continue;
            Application__c app = appMap.get(i.Application__c);
            if (app != null && app.Status__c != 'Shortlisted' && app.Status__c != 'Interview') {
                i.addError('Interview can only be created if Application Status is Shortlisted or Interview.');
            }
        }
    }

    private static void validateScheduledDateFuture(List<Interview__c> newList) {
        Datetime now = Datetime.now();
        for (Interview__c i : newList) {
            if (i.Scheduled_Date__c != null && i.Scheduled_Date__c < now) {
                i.addError('Scheduled Date must be in the future.');
            }
        }
    }

    private static void validateExamPassedIfExists(List<Interview__c> newList) {
        Set<Id> appIds = new Set<Id>();
        for (Interview__c i : newList) {
            if (i.Application__c != null) appIds.add(i.Application__c);
        }
        if (appIds.isEmpty()) return;

        Map<Id, Exam__c> examMap = new Map<Id, Exam__c>();
        for (Exam__c e : [SELECT Id, Application__c, Status__c FROM Exam__c WHERE Application__c IN :appIds]) {
            examMap.put(e.Application__c, e);
        }

        for (Interview__c i : newList) {
            if (i.Application__c == null) continue;
            Exam__c exam = examMap.get(i.Application__c);
            if (exam != null && exam.Status__c == 'Fail') {
                i.addError('Cannot schedule interview: Applicant has failed the Exam.');
            }
        }
    }

    private static void updateApplicationStatusToInterview(List<Interview__c> newList) {
        Set<Id> appIds = new Set<Id>();
        for (Interview__c i : newList) {
            if (i.Application__c != null) appIds.add(i.Application__c);
        }
        if (appIds.isEmpty()) return;

        List<Application__c> appsToUpdate = [
            SELECT Id, Status__c FROM Application__c WHERE Id IN :appIds AND Status__c != 'Interview'
        ];
        for (Application__c app : appsToUpdate) {
            app.Status__c = 'Interview';
        }
        if (!appsToUpdate.isEmpty()) {
            update appsToUpdate;
        }
    }

    private static void cascadeInterviewStatusToApplication(List<Interview__c> newList, Map<Id, Interview__c> oldMap) {
        Set<Id> appIdsForHired = new Set<Id>();
        Set<Id> appIdsForRejected = new Set<Id>();
        List<Interview__c> interviewsForOffer = new List<Interview__c>();

        for (Interview__c i : newList) {
            Interview__c oldInt = oldMap.get(i.Id);
            if (oldInt == null || oldInt.Status_of_Interview__c == i.Status_of_Interview__c) continue;
            if (i.Application__c == null) continue;

            if (i.Status_of_Interview__c == 'Selected') {
                appIdsForHired.add(i.Application__c);
                interviewsForOffer.add(i);
            } else if (i.Status_of_Interview__c == 'Rejected') {
                appIdsForRejected.add(i.Application__c);
            }
        }

        List<Application__c> toUpdate = new List<Application__c>();
        if (!appIdsForRejected.isEmpty()) {
            for (Application__c app : [SELECT Id, Status__c FROM Application__c WHERE Id IN :appIdsForRejected]) {
                app.Status__c = 'Rejected';
                toUpdate.add(app);
            }
        }
        if (!appIdsForHired.isEmpty()) {
            for (Application__c app : [SELECT Id, Status__c FROM Application__c WHERE Id IN :appIdsForHired]) {
                app.Status__c = 'Hired';
                toUpdate.add(app);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        // Create Offer when Interview Status = Selected
        if (!interviewsForOffer.isEmpty()) {
            createOffersForSelectedInterviews(interviewsForOffer);
        }
    }

    private static void createOffersForSelectedInterviews(List<Interview__c> interviews) {
        Set<Id> appIds = new Set<Id>();
        for (Interview__c i : interviews) {
            appIds.add(i.Application__c);
        }
        Map<Id, Application__c> appMap = new Map<Id, Application__c>([
            SELECT Id, Applicant__c, Job__c FROM Application__c WHERE Id IN :appIds
        ]);

        List<Offer__c> offersToCreate = new List<Offer__c>();
        for (Interview__c i : interviews) {
            Application__c app = appMap.get(i.Application__c);
            if (app == null) continue;
            offersToCreate.add(new Offer__c(
                Applicant__c = app.Applicant__c,
                Interview__c = i.Id,
                Job__c = app.Job__c,
                Offer_Status__c = 'Pending',
                Offer_Date__c = Date.today()
            ));
        }
        if (!offersToCreate.isEmpty()) {
            insert offersToCreate;
        }
    }

    private static void preventDeletionIfApplicationHired(List<Interview__c> oldList) {
        Set<Id> appIds = new Set<Id>();
        for (Interview__c i : oldList) {
            if (i.Application__c != null) appIds.add(i.Application__c);
        }
        if (appIds.isEmpty()) return;

        Map<Id, Application__c> appMap = new Map<Id, Application__c>([
            SELECT Id, Status__c FROM Application__c WHERE Id IN :appIds AND Status__c = 'Hired'
        ]);

        for (Interview__c i : oldList) {
            if (i.Application__c != null && appMap.containsKey(i.Application__c)) {
                i.addError('Cannot delete Interview: Application status is Hired.');
            }
        }
    }
}
