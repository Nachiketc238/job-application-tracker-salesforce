/**
 * StudentTriggerHandler - Handles all business logic for Student__c records
 * Called by StudentTrigger on Before Insert, Before Update, Before Delete
 */
public with sharing class StudentTriggerHandler {

    /**
     * BEFORE INSERT: Validation (unique Student_ID__c, unique Email__c)
     * Runs when: User creates NEW Student records
     */
    public static void handleBeforeInsert(List<Student__c> newList) {
        validateUniqueStudentId(newList, null);
        validateUniqueEmail(newList, null);
    }

    /**
     * BEFORE UPDATE: Validation
     * Runs when: User UPDATES existing Student records
     */
    public static void handleBeforeUpdate(List<Student__c> newList, Map<Id, Student__c> oldMap) {
        validateUniqueStudentId(newList, oldMap);
        validateUniqueEmail(newList, oldMap);
    }

    /**
     * BEFORE DELETE: Prevent deletion if Student has active Applications
     * Runs when: User attempts to DELETE Student records
     */
    public static void handleBeforeDelete(List<Student__c> oldList) {
        preventDeletionWithActiveApplications(oldList);
    }

    private static void validateUniqueStudentId(List<Student__c> newList, Map<Id, Student__c> oldMap) {
        Set<String> studentIds = new Set<String>();
        Set<String> idsInBatch = new Set<String>();
        for (Student__c s : newList) {
            if (String.isNotBlank(s.Student_ID__c)) {
                studentIds.add(s.Student_ID__c);
                idsInBatch.add(s.Student_ID__c);
            }
        }
        if (studentIds.isEmpty()) return;

        List<Student__c> existing = [
            SELECT Id, Student_ID__c FROM Student__c
            WHERE Student_ID__c IN :studentIds
        ];
        Map<String, Id> existingMap = new Map<String, Id>();
        for (Student__c s : existing) {
            existingMap.put(s.Student_ID__c, s.Id);
        }

        for (Student__c s : newList) {
            if (String.isBlank(s.Student_ID__c)) continue;
            Id existingId = existingMap.get(s.Student_ID__c);
            if (existingId != null && existingId != s.Id) {
                s.addError('Student ID already exists. Please use a unique Student ID.');
            }
        }
    }

    private static void validateUniqueEmail(List<Student__c> newList, Map<Id, Student__c> oldMap) {
        Set<String> emails = new Set<String>();
        for (Student__c s : newList) {
            if (String.isNotBlank(s.Email__c)) {
                emails.add(s.Email__c);
            }
        }
        if (emails.isEmpty()) return;

        Map<String, Id> existingMap = new Map<String, Id>();
        for (Student__c s : [SELECT Id, Email__c FROM Student__c WHERE Email__c IN :emails]) {
            existingMap.put(s.Email__c.toLowerCase(), s.Id);
        }

        Set<String> seenInBatch = new Set<String>();
        for (Student__c s : newList) {
            if (String.isBlank(s.Email__c)) continue;
            String key = s.Email__c.toLowerCase();
            Id existingId = existingMap.get(key);
            if ((existingId != null && existingId != s.Id) || seenInBatch.contains(key)) {
                s.addError('Email already exists. Please use a unique email address.');
            }
            seenInBatch.add(key);
        }
    }

    private static void preventDeletionWithActiveApplications(List<Student__c> oldList) {
        Set<Id> studentIds = new Set<Id>();
        for (Student__c s : oldList) {
            studentIds.add(s.Id);
        }

        Set<Id> studentsWithApps = new Set<Id>();
        for (AggregateResult ar : [
            SELECT Applicant__r.Student__c studentId FROM Application__c
            WHERE Applicant__r.Student__c IN :studentIds
            GROUP BY Applicant__r.Student__c
        ]) {
            studentsWithApps.add((Id) ar.get('studentId'));
        }
        for (Student__c s : oldList) {
            if (studentsWithApps.contains(s.Id)) {
                s.addError('Cannot delete Student: Active applications exist. Please remove or resolve applications first.');
            }
        }
    }
}
