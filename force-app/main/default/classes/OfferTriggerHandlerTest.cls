@IsTest
private class OfferTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        Job__c job = new Job__c(Name = 'Open Job', Status__c = 'Open', Last_Date_to_Apply__c = Date.today().addDays(5));
        insert job;
        
        Applicant_Name__c app1 = new Applicant_Name__c(Name = 'Test Applicant');
        insert app1;
        
        Application__c applicationHired = new Application__c(Applicant__c = app1.Id, Job__c = job.Id, Status__c = 'Hired');
        Application__c applicationShortlisted = new Application__c(Applicant__c = app1.Id, Job__c = job.Id, Status__c = 'Shortlisted');
        insert applicationHired;
        insert applicationShortlisted;
        
        Interview__c interviewHired = new Interview__c(Application__c = applicationHired.Id, Scheduled_Date__c = Datetime.now().addDays(2), Status_of_Interview__c = 'Selected');
        Interview__c interviewShortlisted = new Interview__c(Application__c = applicationShortlisted.Id, Scheduled_Date__c = Datetime.now().addDays(2), Status_of_Interview__c = 'Scheduled');
        
        // Bypassing triggers manually for specific statuses is tough, we'll insert then update to bypass Interview creating an offer naturally
        insert interviewShortlisted;
        
        // Wait, inserting an interview with 'Selected' creates an Offer in the InterviewHandler! 
        // Let's insert it as Scheduled, then update to Selected. It WILL create an Offer!
        insert interviewHired;
        interviewHired.Status_of_Interview__c = 'Selected';
        update interviewHired;
        
        // The update above automatically inserts an Offer__c via InterviewTriggerHandler!
        // We can just use that existing offer for some tests.
    }

    @IsTest
    static void testValidateApplicationStatusHired() {
        Interview__c intShortlisted = [SELECT Id FROM Interview__c WHERE Status_of_Interview__c = 'Scheduled' LIMIT 1];
        
        Offer__c invalidOffer = new Offer__c(
            Interview__c = intShortlisted.Id,
            Offer_Status__c = 'Pending',
            Offer_Date__c = Date.today(),
            Joining_Date__c = Date.today().addDays(10)
        );
        
        Test.startTest();
        try {
            insert invalidOffer;
            System.assert(false, 'Expected validation error creating Offer for non-Hired Application.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Application Status is Hired'), 'Expected Application Status Hired error message.');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateOfferAndJoiningDates() {
        Interview__c intHired = [SELECT Id FROM Interview__c WHERE Status_of_Interview__c = 'Selected' LIMIT 1];
        
        Offer__c invalidDateOffer = new Offer__c(
            Interview__c = intHired.Id,
            Offer_Status__c = 'Pending',
            Offer_Date__c = Date.today().addDays(5),
            Joining_Date__c = Date.today().addDays(2) // Joining before Offer Date
        );
        
        Test.startTest();
        try {
            insert invalidDateOffer;
            System.assert(false, 'Expected validation error creating Offer with Joining Date before Offer Date.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Joining Date') || e.getMessage().contains('Offer Date'), 'Expected Date validation error message.');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testCascadeOfferStatusToApplication() {
        Offer__c generatedOffer = [SELECT Id, Offer_Status__c, Interview__r.Application__c FROM Offer__c LIMIT 1];
        Id appId = generatedOffer.Interview__r.Application__c;
        
        // Rejecting the offer should cascade to reject the application
        Test.startTest();
        generatedOffer.Offer_Status__c = 'Rejected';
        update generatedOffer;
        Test.stopTest();
        
        Application__c updatedApp = [SELECT Id, Status__c FROM Application__c WHERE Id = :appId];
        System.assertEquals('Rejected', updatedApp.Status__c, 'Application should be updated to Rejected when Offer is Rejected.');
    }
    
    @IsTest
    static void testPreventDeletionIfOfferAccepted() {
        Offer__c generatedOffer = [SELECT Id, Offer_Status__c FROM Offer__c LIMIT 1];
        
        generatedOffer.Offer_Status__c = 'Accepted';
        update generatedOffer;
        
        Test.startTest();
        try {
            delete generatedOffer;
            System.assert(false, 'Expected validation error deleting an Accepted Offer.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('has been Accepted'), 'Expected Accepted delete error message.');
        }
        Test.stopTest();
    }
}
