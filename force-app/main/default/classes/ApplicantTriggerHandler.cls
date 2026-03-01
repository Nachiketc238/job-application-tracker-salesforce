/**
 * ApplicantTriggerHandler - Handles all business logic for Applicant_Name__c records
 * Called by ApplicantTrigger on Before Delete, After Delete, After Insert, After Update
 */
public with sharing class ApplicantTriggerHandler {

    private static Boolean isExecuting = false;

    /**
     * BEFORE DELETE: Cascade delete related records (Applications, Exams, Offers)
     * Runs when: User attempts to DELETE Applicant records
     * We delete related data BEFORE Applicant is deleted to maintain referential integrity
     */
    public static void handleBeforeDelete(List<Applicant_Name__c> oldList) {
        cascadeDeleteRelatedRecords(oldList);
    }

    /**
     * AFTER INSERT: Auto-link to Student if Student exists with same email
     * Runs when: Applicant records have been successfully inserted
     */
    public static void handleAfterInsert(List<Applicant_Name__c> newList) {
        linkApplicantToStudent(newList);
    }

    /**
     * AFTER UPDATE: Auto-link to Student if Student exists with same email
     * Runs when: Applicant records have been successfully updated
     */
    public static void handleAfterUpdate(List<Applicant_Name__c> newList, Map<Id, Applicant_Name__c> oldMap) {
        linkApplicantToStudent(newList);
    }

    /**
     * Cascade delete: Applications -> (Interviews cascade via MasterDetail), Exams, Offers
     */
    private static void cascadeDeleteRelatedRecords(List<Applicant_Name__c> oldList) {
        Set<Id> applicantIds = new Set<Id>();
        for (Applicant_Name__c a : oldList) {
            applicantIds.add(a.Id);
        }

        // Get Application IDs for these Applicants
        List<Application__c> applications = [
            SELECT Id FROM Application__c WHERE Applicant__c IN :applicantIds
        ];
        Set<Id> appIds = new Set<Id>();
        for (Application__c app : applications) {
            appIds.add(app.Id);
        }
        if (appIds.isEmpty()) return;

        // Get Interview IDs (MasterDetail - will auto-delete when Application deleted)
        List<Interview__c> interviews = [
            SELECT Id FROM Interview__c WHERE Application__c IN :appIds
        ];
        Set<Id> interviewIds = new Set<Id>();
        for (Interview__c i : interviews) {
            interviewIds.add(i.Id);
        }

        // Delete Offers linked to these Interviews (orphan them or delete)
        List<Offer__c> offersToDelete = [
            SELECT Id FROM Offer__c WHERE Interview__c IN :interviewIds
        ];
        if (!offersToDelete.isEmpty()) {
            delete offersToDelete;
        }

        // Delete Exams for these Applications
        List<Exam__c> examsToDelete = [
            SELECT Id FROM Exam__c WHERE Application__c IN :appIds
        ];
        if (!examsToDelete.isEmpty()) {
            delete examsToDelete;
        }

        // Delete Applications (this cascades to delete Interviews via MasterDetail)
        delete applications;
    }

    /**
     * Auto-link Applicant to Student if Student exists with matching Personal_Email
     */
    private static void linkApplicantToStudent(List<Applicant_Name__c> newList) {
        if (isExecuting) return;
        try {
            isExecuting = true;
            Set<String> emails = new Set<String>();
            for (Applicant_Name__c a : newList) {
                if (String.isNotBlank(a.Personal_Email__c)) {
                    emails.add(a.Personal_Email__c.toLowerCase());
                }
            }
            if (emails.isEmpty()) return;

            Map<String, Id> emailToStudentId = new Map<String, Id>();
            for (Student__c s : [SELECT Id, Email__c FROM Student__c WHERE Email__c != null]) {
                emailToStudentId.put(s.Email__c.toLowerCase(), s.Id);
            }

            List<Applicant_Name__c> toUpdate = new List<Applicant_Name__c>();
            for (Applicant_Name__c a : newList) {
                if (String.isBlank(a.Personal_Email__c) || a.Student__c != null) continue;
                Id studentId = emailToStudentId.get(a.Personal_Email__c.toLowerCase());
                if (studentId != null) {
                    toUpdate.add(new Applicant_Name__c(Id = a.Id, Student__c = studentId));
                }
            }
            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        } finally {
            isExecuting = false;
        }
    }
}
