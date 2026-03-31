@IsTest
private class ApplicantTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        // Create matching Student for auto-link test
        Student__c testStudent = new Student__c(
            Name = 'Test Student',
            Email__c = 'teststudent@example.com'
        );
        insert testStudent;
        
        // Setup data for cascade delete test
        Applicant_Name__c app = new Applicant_Name__c(
            Name = 'Test Applicant',
            Personal_Email__c = 'cascade@example.com'
        );
        insert app;
        
        Job__c job = new Job__c(
            Name = 'Test Job',
            Status__c = 'Open',
            Last_Date_to_Apply__c = Date.today().addDays(10)
        );
        insert job;
        
        Application__c application = new Application__c(
            Applicant__c = app.Id,
            Job__c = job.Id,
            Status__c = 'Applied'
        );
        insert application;
        
        Exam__c exam = new Exam__c(
            Application__c = application.Id,
            Exam_Date__c = Date.today().addDays(1),
            Status__c = 'Pass'
        );
        insert exam;
        
        // Transition application to Shortlisted then to Interview to create Interview
        application.Status__c = 'Shortlisted';
        update application;
        
        Interview__c interview = new Interview__c(
            Application__c = application.Id,
            Scheduled_Date__c = Datetime.now().addDays(2),
            Status_of_Interview__c = 'Scheduled'
        );
        insert interview;
        
        // Transition interview to selected to auto-create Offer
        interview.Status_of_Interview__c = 'Selected';
        update interview;
    }

    @IsTest
    static void testAutoLinkToStudentInsert() {
        Test.startTest();
        Applicant_Name__c newApp = new Applicant_Name__c(
            Name = 'New App',
            Personal_Email__c = 'TestStudent@example.com' // Case insensitive test
        );
        insert newApp;
        Test.stopTest();
        
        Applicant_Name__c queriedApp = [SELECT Id, Student__c FROM Applicant_Name__c WHERE Id = :newApp.Id];
        Student__c student = [SELECT Id FROM Student__c LIMIT 1];
        
        System.assertEquals(student.Id, queriedApp.Student__c, 'Applicant should be auto-linked to Student based on email on insert.');
    }
    
    @IsTest
    static void testAutoLinkToStudentUpdate() {
        Applicant_Name__c noEmailApp = new Applicant_Name__c(
            Name = 'NoEmail App'
        );
        insert noEmailApp;
        
        Test.startTest();
        noEmailApp.Personal_Email__c = 'teststudent@example.com';
        update noEmailApp;
        Test.stopTest();
        
        Applicant_Name__c queriedApp = [SELECT Id, Student__c FROM Applicant_Name__c WHERE Id = :noEmailApp.Id];
        Student__c student = [SELECT Id FROM Student__c LIMIT 1];
        
        System.assertEquals(student.Id, queriedApp.Student__c, 'Applicant should be auto-linked to Student based on email on update.');
    }

    @IsTest
    static void testCascadeDeleteRelatedRecords() {
        Applicant_Name__c app = [SELECT Id FROM Applicant_Name__c WHERE Personal_Email__c = 'cascade@example.com' LIMIT 1];
        
        // Verify related records exist
        System.assertEquals(1, [SELECT COUNT() FROM Application__c WHERE Applicant__c = :app.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM Exam__c]);
        System.assertEquals(1, [SELECT COUNT() FROM Interview__c]);
        System.assertEquals(1, [SELECT COUNT() FROM Offer__c]);
        
        Test.startTest();
        delete app;
        Test.stopTest();
        
        // Verify cascade delete
        System.assertEquals(0, [SELECT COUNT() FROM Application__c WHERE Applicant__c = :app.Id], 'Applications should be deleted.');
        System.assertEquals(0, [SELECT COUNT() FROM Exam__c], 'Exams should be deleted.');
        System.assertEquals(0, [SELECT COUNT() FROM Interview__c], 'Interviews should be deleted.');
        System.assertEquals(0, [SELECT COUNT() FROM Offer__c], 'Offers should be deleted.');
    }
}
