/**
 * ExamTriggerHandler - Handles all business logic for Exam__c records
 * Called by ExamTrigger on Before Insert, After Insert, Before Update, After Update, Before Delete
 */
public with sharing class ExamTriggerHandler {

    /**
     * BEFORE INSERT: Validation
     * Runs when: User creates NEW Exam records
     */
    public static void handleBeforeInsert(List<Exam__c> newList) {
        validateApplicationStatusForInsert(newList);
        validateExamDateFuture(newList);
    }

    /**
     * AFTER INSERT: Update Application Status to "Exam"
     * Runs when: Exam records have been successfully inserted
     */
    public static void handleAfterInsert(List<Exam__c> newList) {
        updateApplicationStatusToExam(newList);
    }

    /**
     * BEFORE UPDATE: Validation
     * Runs when: User UPDATES existing Exam records
     */
    public static void handleBeforeUpdate(List<Exam__c> newList, Map<Id, Exam__c> oldMap) {
        // Optional: validate status changes
    }

    /**
     * AFTER UPDATE: Status cascade - Pass -> Application "Exam", Fail -> Application "Rejected"
     * Runs when: Exam records have been successfully updated
     */
    public static void handleAfterUpdate(List<Exam__c> newList, Map<Id, Exam__c> oldMap) {
        cascadeExamStatusToApplication(newList, oldMap);
    }

    /**
     * BEFORE DELETE: Prevent deletion if Application Status = "Hired"
     * Runs when: User attempts to DELETE Exam records
     */
    public static void handleBeforeDelete(List<Exam__c> oldList) {
        preventDeletionIfApplicationHired(oldList);
    }

    private static void validateApplicationStatusForInsert(List<Exam__c> newList) {
        Set<Id> appIds = new Set<Id>();
        for (Exam__c e : newList) {
            if (e.Application__c != null) appIds.add(e.Application__c);
        }
        if (appIds.isEmpty()) return;

        Map<Id, Application__c> appMap = new Map<Id, Application__c>([
            SELECT Id, Status__c FROM Application__c WHERE Id IN :appIds
        ]);

        for (Exam__c e : newList) {
            if (e.Application__c == null) continue;
            Application__c app = appMap.get(e.Application__c);
            if (app != null && app.Status__c != 'Shortlisted' && app.Status__c != 'Exam') {
                e.addError('Exam can only be created if Application Status is Shortlisted or Exam.');
            }
        }
    }

    private static void validateExamDateFuture(List<Exam__c> newList) {
        Datetime now = Datetime.now();
        for (Exam__c e : newList) {
            if (e.Exam_date__c != null && e.Exam_date__c < now) {
                e.addError('Exam Date must be in the future when creating.');
            }
        }
    }

    private static void updateApplicationStatusToExam(List<Exam__c> newList) {
        Set<Id> appIds = new Set<Id>();
        for (Exam__c e : newList) {
            if (e.Application__c != null) appIds.add(e.Application__c);
        }
        if (appIds.isEmpty()) return;

        List<Application__c> appsToUpdate = [
            SELECT Id, Status__c FROM Application__c WHERE Id IN :appIds AND Status__c != 'Exam'
        ];
        for (Application__c app : appsToUpdate) {
            app.Status__c = 'Exam';
        }
        if (!appsToUpdate.isEmpty()) {
            update appsToUpdate;
        }
    }

    private static void cascadeExamStatusToApplication(List<Exam__c> newList, Map<Id, Exam__c> oldMap) {
        List<Id> appIdsForReject = new List<Id>();
        List<Id> appIdsForExam = new List<Id>();
        for (Exam__c e : newList) {
            Exam__c oldExam = oldMap.get(e.Id);
            if (oldExam == null || oldExam.Status__c == e.Status__c) continue;
            if (e.Application__c == null) continue;
            if (e.Status__c == 'Fail') {
                appIdsForReject.add(e.Application__c);
            } else if (e.Status__c == 'Pass') {
                appIdsForExam.add(e.Application__c);
            }
        }

        List<Application__c> toUpdate = new List<Application__c>();
        if (!appIdsForReject.isEmpty()) {
            for (Application__c app : [SELECT Id, Status__c FROM Application__c WHERE Id IN :appIdsForReject]) {
                app.Status__c = 'Rejected';
                toUpdate.add(app);
            }
        }
        if (!appIdsForExam.isEmpty()) {
            for (Application__c app : [SELECT Id, Status__c FROM Application__c WHERE Id IN :appIdsForExam]) {
                app.Status__c = 'Exam'; // Ready for Interview
                toUpdate.add(app);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private static void preventDeletionIfApplicationHired(List<Exam__c> oldList) {
        Set<Id> appIds = new Set<Id>();
        for (Exam__c e : oldList) {
            if (e.Application__c != null) appIds.add(e.Application__c);
        }
        if (appIds.isEmpty()) return;

        Map<Id, Application__c> appMap = new Map<Id, Application__c>([
            SELECT Id, Status__c FROM Application__c WHERE Id IN :appIds AND Status__c = 'Hired'
        ]);

        for (Exam__c e : oldList) {
            if (e.Application__c != null && appMap.containsKey(e.Application__c)) {
                e.addError('Cannot delete Exam: Application status is Hired.');
            }
        }
    }
}
