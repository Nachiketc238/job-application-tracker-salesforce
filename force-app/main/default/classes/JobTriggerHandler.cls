/**
 * JobTriggerHandler - Handles all business logic for Job__c records
 * Called by JobTrigger on Before Insert, After Insert, Before Update, After Update
 */
public with sharing class JobTriggerHandler {

    /**
     * BEFORE INSERT: Validation
     * Runs when: User creates NEW Job records
     */
    public static void handleBeforeInsert(List<Job__c> newList) {
        validateLastDateToApply(newList);
    }

    /**
     * AFTER INSERT: Create notifications (placeholder)
     * Runs when: Job records have been successfully inserted
     */
    public static void handleAfterInsert(List<Job__c> newList) {
        // Placeholder: Send notifications to recruiters
    }

    /**
     * BEFORE UPDATE: Validation + Auto-close expired jobs
     * Runs when: User UPDATES existing Job records
     */
    public static void handleBeforeUpdate(List<Job__c> newList, Map<Id, Job__c> oldMap) {
        validateLastDateToApply(newList);
        autoCloseExpiredJobs(newList, oldMap);
        // Prevent status change if applications exist - optional business rule
    }

    /**
     * AFTER UPDATE: Update related Applications when Job status changes to Close
     * Runs when: Job records have been successfully updated
     */
    public static void handleAfterUpdate(List<Job__c> newList, Map<Id, Job__c> oldMap) {
        updateApplicationsWhenJobCloses(newList, oldMap);
    }

    private static void validateLastDateToApply(List<Job__c> newList) {
        Date today = Date.today();
        for (Job__c job : newList) {
            if (job.Last_Date_to_Apply__c != null) {
                Date lastDate = job.Last_Date_to_Apply__c.date();
                if (lastDate < today && job.Status__c != 'Close') {
                    job.addError('Last Date to Apply must be in the future when creating or keeping job Open.');
                }
            }
        }
    }

    private static void autoCloseExpiredJobs(List<Job__c> newList, Map<Id, Job__c> oldMap) {
        Date today = Date.today();
        for (Job__c job : newList) {
            if (job.Last_Date_to_Apply__c != null && job.Status__c == 'Open') {
                Date lastDate = job.Last_Date_to_Apply__c.date();
                if (lastDate < today) {
                    job.Status__c = 'Close';
                }
            }
        }
    }

    private static void updateApplicationsWhenJobCloses(List<Job__c> newList, Map<Id, Job__c> oldMap) {
        Set<Id> closedJobIds = new Set<Id>();
        for (Job__c job : newList) {
            Job__c oldJob = oldMap.get(job.Id);
            if (oldJob != null && oldJob.Status__c != 'Close' && job.Status__c == 'Close') {
                closedJobIds.add(job.Id);
            }
        }
        if (closedJobIds.isEmpty()) return;

        List<Application__c> appsToUpdate = [
            SELECT Id, Status__c FROM Application__c
            WHERE Job__c IN :closedJobIds AND Status__c != 'Rejected'
        ];
        for (Application__c app : appsToUpdate) {
            app.Status__c = 'Rejected';
        }
        if (!appsToUpdate.isEmpty()) {
            update appsToUpdate;
        }
    }
}
