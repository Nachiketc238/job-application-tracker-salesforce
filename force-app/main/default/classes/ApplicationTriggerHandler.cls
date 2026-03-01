/**
 * ApplicationTriggerHandler - Handles all business logic for Application__c records
 * Called by ApplicationTrigger on Before Insert, After Insert, Before Update, After Update
 */
public with sharing class ApplicationTriggerHandler {

    /**
     * BEFORE INSERT: Validation + Auto-populate fields
     * Runs when: User creates NEW Application records (single or bulk)
     */
    public static void handleBeforeInsert(List<Application__c> newList) {
        // 1. Prevent duplicate applications (same Applicant + same Job)
        preventDuplicateApplications(newList);

        // 2. Auto-calculate Application_Job_Key__c (Applicant ID + Job ID)
        setApplicationJobKey(newList);

        // 3. Validate application date (can't apply after Last_Date_to_Apply__c)
        validateApplicationDate(newList);

        // 4. Prevent applications to closed jobs (Job Status = "Close")
        preventApplicationToClosedJobs(newList);

        // 5. Set Application_Date__c automatically on creation
        setApplicationDate(newList);
    }

    /**
     * AFTER INSERT: Create related records / post-creation logic
     * Runs when: Application records have been successfully inserted
     */
    public static void handleAfterInsert(List<Application__c> newList) {
        // Placeholder for post-insert logic (e.g., create tasks, send notifications)
    }

    /**
     * BEFORE UPDATE: Validation
     * Runs when: User UPDATES existing Application records
     */
    public static void handleBeforeUpdate(List<Application__c> newList, Map<Id, Application__c> oldMap) {
        // Re-validate on update if Job or Applicant changed
        preventDuplicateApplications(newList);
        preventApplicationToClosedJobs(newList);
    }

    /**
     * AFTER UPDATE: Update related records when status changes
     * Runs when: Application records have been successfully updated
     */
    public static void handleAfterUpdate(List<Application__c> newList, Map<Id, Application__c> oldMap) {
        // Placeholder for status-change logic (e.g., update related Exam/Interview)
    }

    // --- PRIVATE HELPER METHODS ---

    private static void preventDuplicateApplications(List<Application__c> newList) {
        Set<Id> applicantIds = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();
        for (Application__c app : newList) {
            if (app.Applicant__c != null && app.Job__c != null) {
                applicantIds.add(app.Applicant__c);
                jobIds.add(app.Job__c);
            }
        }

        if (applicantIds.isEmpty() || jobIds.isEmpty()) return;

        // Query existing Applications for same Applicant + Job
        Map<String, Application__c> existingKeyMap = new Map<String, Application__c>();
        for (Application__c existing : [
            SELECT Id, Applicant__c, Job__c, Application_Job_Key__c
            FROM Application__c
            WHERE Applicant__c IN :applicantIds AND Job__c IN :jobIds
        ]) {
            existingKeyMap.put(existing.Applicant__c + '_' + existing.Job__c, existing);
        }

        Set<String> keysInThisBatch = new Set<String>();
        for (Application__c app : newList) {
            if (app.Applicant__c != null && app.Job__c != null) {
                String key = app.Applicant__c + '_' + app.Job__c;
                if (existingKeyMap.containsKey(key) || keysInThisBatch.contains(key)) {
                    app.addError('You have already applied for this job. Duplicate applications are not allowed.');
                }
                keysInThisBatch.add(key);
            }
        }
    }

    private static void setApplicationJobKey(List<Application__c> newList) {
        for (Application__c app : newList) {
            if (app.Applicant__c != null && app.Job__c != null) {
                app.Application_Job_Key__c = app.Applicant__c + '_' + app.Job__c;
            }
        }
    }

    private static void validateApplicationDate(List<Application__c> newList) {
        Map<Id, Job__c> jobMap = new Map<Id, Job__c>();
        for (Application__c app : newList) {
            if (app.Job__c != null) jobMap.put(app.Job__c, null);
        }
        if (jobMap.isEmpty()) return;

        for (Job__c j : [SELECT Id, Last_Date_to_Apply__c FROM Job__c WHERE Id IN :jobMap.keySet()]) {
            jobMap.put(j.Id, j);
        }

        Date today = Date.today();
        for (Application__c app : newList) {
            if (app.Job__c == null) continue;
            Job__c job = jobMap.get(app.Job__c);
            if (job != null && job.Last_Date_to_Apply__c != null) {
                Date lastDate = job.Last_Date_to_Apply__c.date();
                if (today > lastDate) {
                    app.addError('Cannot apply: Last date to apply (' + lastDate + ') has passed.');
                }
            }
        }
    }

    private static void preventApplicationToClosedJobs(List<Application__c> newList) {
        Set<Id> jobIds = new Set<Id>();
        for (Application__c app : newList) {
            if (app.Job__c != null) jobIds.add(app.Job__c);
        }
        if (jobIds.isEmpty()) return;

        Map<Id, Job__c> jobMap = new Map<Id, Job__c>([
            SELECT Id, Status__c FROM Job__c WHERE Id IN :jobIds
        ]);

        for (Application__c app : newList) {
            if (app.Job__c != null) {
                Job__c job = jobMap.get(app.Job__c);
                if (job != null && job.Status__c == 'Close') {
                    app.addError('Cannot apply: This job is closed.');
                }
            }
        }
    }

    private static void setApplicationDate(List<Application__c> newList) {
        Date today = Date.today();
        for (Application__c app : newList) {
            if (app.Application_Date__c == null) {
                app.Application_Date__c = today;
            }
        }
    }
}
