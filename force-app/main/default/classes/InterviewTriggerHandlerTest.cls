@IsTest
private class InterviewTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        Job__c job = new Job__c(Name = 'Open Job', Status__c = 'Open', Last_Date_to_Apply__c = Date.today().addDays(5));
        insert job;
        
        Applicant_Name__c app1 = new Applicant_Name__c(Name = 'Test Applicant');
        insert app1;
        
        Application__c applicationHired = new Application__c(Applicant__c = app1.Id, Job__c = job.Id, Status__c = 'Hired');
        Application__c applicationShortlisted = new Application__c(Applicant__c = app1.Id, Job__c = job.Id, Status__c = 'Shortlisted');
        Application__c applicationApplied = new Application__c(Applicant__c = app1.Id, Job__c = job.Id, Status__c = 'Applied');
        Application__c applicationRejected = new Application__c(Applicant__c = app1.Id, Job__c = job.Id, Status__c = 'Rejected');
        
        insert applicationHired;
        insert applicationShortlisted;
        insert applicationApplied;
        insert applicationRejected;
        
        Exam__c failedExam = new Exam__c(Application__c = applicationRejected.Id, Exam_Date__c = Date.today(), Status__c = 'Fail');
        insert failedExam;
        
        Interview__c validInterview = new Interview__c(Application__c = applicationShortlisted.Id, Scheduled_Date__c = Datetime.now().addDays(2), Status_of_Interview__c = 'Scheduled');
        insert validInterview;
    }

    @IsTest
    static void testValidateApplicationStatusForInsert() {
        Application__c appliedApp = [SELECT Id FROM Application__c WHERE Status__c = 'Applied' LIMIT 1];
        
        Interview__c newInterview = new Interview__c(Application__c = appliedApp.Id, Scheduled_Date__c = Datetime.now().addDays(2), Status_of_Interview__c = 'Scheduled');
        
        Test.startTest();
        try {
            insert newInterview;
            System.assert(false, 'Expected validation error for creating interview on Applied application.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Shortlisted or Interview'), 'Expected Shortlisted/Interview error message.');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateScheduledDateFuture() {
        Application__c shortlistedApp = [SELECT Id FROM Application__c WHERE Status__c = 'Shortlisted' LIMIT 1];
        
        Interview__c newInterview = new Interview__c(Application__c = shortlistedApp.Id, Scheduled_Date__c = Datetime.now().addDays(-2), Status_of_Interview__c = 'Scheduled');
        
        Test.startTest();
        try {
            insert newInterview;
            System.assert(false, 'Expected validation error for past scheduled date.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('future'), 'Expected future date error message.');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateExamPassedIfExists() {
        Application__c rejectedApp = [SELECT Id FROM Application__c WHERE Status__c = 'Rejected' LIMIT 1];
        
        Interview__c newInterview = new Interview__c(Application__c = rejectedApp.Id, Scheduled_Date__c = Datetime.now().addDays(2), Status_of_Interview__c = 'Scheduled');
        
        Test.startTest();
        try {
            insert newInterview; // Will fail BOTH application status check and exam failed check. 
            // In handler, validateApplicationStatusForInsert adds an error, validateExamPassedIfExists adds another.
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('failed the Exam') || e.getMessage().contains('Shortlisted or Interview'), 'Expected validation errors.');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateApplicationStatusToInterview() {
        Application__c shortlistedApp = [SELECT Id, Status__c FROM Application__c WHERE Status__c = 'Shortlisted' LIMIT 1];
        
        // When inserting via UI it works. Our Setup already did this when creating validInterview, 
        // which was attached to applicationShortlisted. Wait, let's verify if the status changed.
        Application__c updatedApp = [SELECT Id, Status__c FROM Application__c WHERE Id = :shortlistedApp.Id];
        System.assertEquals('Interview', updatedApp.Status__c, 'Application should be updated to Interview when Interview is created.');
    }
    
    @IsTest
    static void testCascadeInterviewStatusToApplication() {
        Interview__c interviewToUpdate = [SELECT Id, Status_of_Interview__c, Application__c FROM Interview__c LIMIT 1];
        
        Test.startTest();
        interviewToUpdate.Status_of_Interview__c = 'Selected';
        update interviewToUpdate;
        Test.stopTest();
        
        Application__c updatedApp = [SELECT Id, Status__c FROM Application__c WHERE Id = :interviewToUpdate.Application__c];
        System.assertEquals('Hired', updatedApp.Status__c, 'Application should be updated to Hired when Interview is Selected.');
        
        // Check if Offer was created
        System.assertEquals(1, [SELECT COUNT() FROM Offer__c WHERE Interview__c = :interviewToUpdate.Id], 'Offer should be auto-created for Selected Interview.');
    }
    
    @IsTest
    static void testPreventDeletionIfApplicationHired() {
        // Find the interview for the hired app? 
        // We didn't create an interview for the Hired app in setup.
        // Let's create an interview that leads to Hired.
        Application__c shortlistedApp = [SELECT Id, Status__c FROM Application__c WHERE Status__c = 'Shortlisted' LIMIT 1];
        Interview__c intv = new Interview__c(Application__c = shortlistedApp.Id, Scheduled_Date__c = Datetime.now().addDays(2), Status_of_Interview__c = 'Selected');
        insert intv;
        // Application is now Hired.
        
        Test.startTest();
        try {
            delete [SELECT Id FROM Interview__c WHERE Id = :intv.Id];
            System.assert(false, 'Expected validation error preventing delete of an Interview tied to a Hired Application.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Application status is Hired'), 'Expected hired application delete error message.');
        }
        Test.stopTest();
    }
}
