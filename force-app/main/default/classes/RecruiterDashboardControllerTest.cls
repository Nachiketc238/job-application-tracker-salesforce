@isTest
private class RecruiterDashboardControllerTest {
    @testSetup
    static void setupTestData() {
        Recruiter__c rec = new Recruiter__c(
            Name = 'Test Recruiter',
            Email__c = UserInfo.getUserEmail()
        );
        insert rec;

        Job__c j = new Job__c(
            Name = 'Test Job',
            Job_Title__c = 'Test Title',
            Recruiter__c = rec.Id,
            Status__c = 'Open'
        );
        insert j;

        Student__c s = new Student__c(
            Name = 'Test Student',
            Email__c = 'test@example.com'
        );
        insert s;

        Application__c app = new Application__c(
            Job__c = j.Id,
            Applicant__c = s.Id,
            Status__c = 'Applied'
        );
        insert app;
    }

    @isTest
    static void testGetDashboardData() {
        Test.startTest();
        RecruiterDashboardController.DashboardData data = RecruiterDashboardController.getDashboardData();
        Test.stopTest();

        System.assertNotEquals(null, data, 'Data should not be null');
        System.assertEquals(1, data.totalApplications, 'Should have 1 app');
        System.assertEquals(1, data.openJobsCount, 'Should have 1 open job');
        System.assertEquals(1, data.jobs.size(), 'Should have 1 job wrapper');
        System.assertEquals(1, data.jobs[0].applicationCount, 'Job should have 1 app');
    }

    @isTest
    static void testUpdateApplicationStatus() {
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        
        Test.startTest();
        RecruiterDashboardController.updateApplicationStatus(app.Id, 'Interview');
        Test.stopTest();
        
        Application__c updatedApp = [SELECT Status__c FROM Application__c WHERE Id = :app.Id];
        System.assertEquals('Interview', updatedApp.Status__c, 'Status should be updated');
    }

    @isTest
    static void testPostJob() {
        Test.startTest();
        String jobId = RecruiterDashboardController.postJob(
            'New Job', 'Developer', 'Remote', 'IT', 'Desc', '100k', 2, Date.today()
        );
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Job ID should be returned');
        Job__c j = [SELECT Status__c FROM Job__c WHERE Id = :jobId];
        System.assertEquals('Open', j.Status__c, 'New job should be open');
    }
}
