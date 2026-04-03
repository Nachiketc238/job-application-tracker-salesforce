public with sharing class RecruiterDashboardController {

    public class DashboardData {
        @AuraEnabled public List<JobWrapper> jobs;
        @AuraEnabled public Integer totalApplications;
        @AuraEnabled public Integer shortlistedCount;
        @AuraEnabled public Integer interviewCount;
        @AuraEnabled public Integer hiredCount;
        @AuraEnabled public Integer openJobsCount;
    }

    public class JobWrapper {
        @AuraEnabled public String jobId;
        @AuraEnabled public String jobName;
        @AuraEnabled public String jobTitle;
        @AuraEnabled public String location;
        @AuraEnabled public String status;
        @AuraEnabled public String lastDate;
        @AuraEnabled public String salaryRange;
        @AuraEnabled public Integer applicationCount;
        @AuraEnabled public List<ApplicationData> applications;
    }

    public class ApplicationData {
        @AuraEnabled public String applicationId;
        @AuraEnabled public String status;
        @AuraEnabled public String applicantName;
        @AuraEnabled public String applicantEmail;
        @AuraEnabled public String applicantPhone;
        @AuraEnabled public String applicantSkills;
        @AuraEnabled public String resumeLink;
        @AuraEnabled public String tenthPercent;
        @AuraEnabled public String twelfthPercent;
        @AuraEnabled public String cgpa;
    }

    @AuraEnabled(cacheable=false)
    public static DashboardData getDashboardData() {
        String loggedInEmail = UserInfo.getUserEmail();

        List<Recruiter__c> recruiters = [
            SELECT Id, Name FROM Recruiter__c WHERE Email__c = :loggedInEmail LIMIT 1
        ];
        if (recruiters.isEmpty()) {
            throw new AuraHandledException('No Recruiter record linked to your User email: ' + loggedInEmail);
        }

        Id recruiterId = recruiters[0].Id;

        List<Job__c> jobs = [
            SELECT Id, Name, Job_Title__c, Location__c, Status__c, Last_Date_to_Apply__c,
                   Salary_Range__c, Experience_Required__c
            FROM Job__c
            WHERE Recruiter__c = :recruiterId
            ORDER BY CreatedDate DESC
        ];

        // --- Auto-Close Expired Jobs ---
        List<Job__c> jobsToUpdate = new List<Job__c>();
        for (Job__c j : jobs) {
            if (j.Status__c == 'Open' && j.Last_Date_to_Apply__c != null && j.Last_Date_to_Apply__c < Date.today()) {
                j.Status__c = 'Close';
                jobsToUpdate.add(j);
            }
        }
        if (!jobsToUpdate.isEmpty()) {
            update jobsToUpdate;
        }
        // -------------------------------

        Set<Id> jobIds = new Map<Id, Job__c>(jobs).keySet();

        List<Application__c> allApps = [
            SELECT Id, Status__c, Job__c,
                   Applicant__r.Name, Applicant__r.Personal_Email__c,
                   Applicant__r.Phone_Number__c, Applicant__r.Skills__c,
                   Applicant__r.X10th_Percentage__c, Applicant__r.X12th_Percentage__c, Applicant__r.CGPA__c,
                   Upload_Resume_Link__c
            FROM Application__c
            WHERE Job__c IN :jobIds
            ORDER BY CreatedDate DESC
        ];

        Map<Id, List<ApplicationData>> appsByJob = new Map<Id, List<ApplicationData>>();
        Integer totalApps = 0, shortlisted = 0, interviewing = 0, hired = 0;

        for (Application__c app : allApps) {
            totalApps++;
            if (app.Status__c == 'Shortlisted' || app.Status__c == 'Exam') shortlisted++;
            if (app.Status__c == 'Interview') interviewing++;
            if (app.Status__c == 'Hired') hired++;

            ApplicationData d = new ApplicationData();
            d.applicationId = app.Id;
            d.status = app.Status__c;
            d.applicantName = app.Applicant__r.Name;
            d.applicantEmail = app.Applicant__r.Personal_Email__c;
            d.applicantPhone = app.Applicant__r.Phone_Number__c;
            d.applicantSkills = app.Applicant__r.Skills__c;
            d.resumeLink = app.Upload_Resume_Link__c;
            d.tenthPercent = app.Applicant__r.X10th_Percentage__c != null ? String.valueOf(app.Applicant__r.X10th_Percentage__c) : 'N/A';
            d.twelfthPercent = app.Applicant__r.X12th_Percentage__c != null ? String.valueOf(app.Applicant__r.X12th_Percentage__c) : 'N/A';
            d.cgpa = app.Applicant__r.CGPA__c != null ? String.valueOf(app.Applicant__r.CGPA__c) : 'N/A';

            if (!appsByJob.containsKey(app.Job__c)) {
                appsByJob.put(app.Job__c, new List<ApplicationData>());
            }
            appsByJob.get(app.Job__c).add(d);
        }

        Integer openJobs = 0;
        List<JobWrapper> jobWrappers = new List<JobWrapper>();
        for (Job__c j : jobs) {
            JobWrapper w = new JobWrapper();
            w.jobId = j.Id;
            w.jobName = j.Name;
            w.jobTitle = j.Job_Title__c;
            w.location = j.Location__c;
            w.status = j.Status__c;
            w.salaryRange = j.Salary_Range__c;
            w.lastDate = j.Last_Date_to_Apply__c != null ? j.Last_Date_to_Apply__c.format() : null;
            w.applications = appsByJob.containsKey(j.Id) ? appsByJob.get(j.Id) : new List<ApplicationData>();
            w.applicationCount = w.applications.size();
            if (j.Status__c == 'Open') openJobs++;
            jobWrappers.add(w);
        }

        DashboardData dd = new DashboardData();
        dd.jobs = jobWrappers;
        dd.totalApplications = totalApps;
        dd.shortlistedCount = shortlisted;
        dd.interviewCount = interviewing;
        dd.hiredCount = hired;
        dd.openJobsCount = openJobs;
        return dd;
    }

    @AuraEnabled
    public static void updateApplicationStatus(String applicationId, String newStatus) {
        try {
            update new Application__c(Id = applicationId, Status__c = newStatus);
        } catch (Exception e) {
            throw new AuraHandledException('Update failed: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String postJob(String jobName, String jobTitle, String location, String department,
                                  String description, String salaryRange, Decimal experience, Date lastDate,
                                  Decimal min10th, Decimal min12th, Decimal minCGPA) {
        try {
            String loggedInEmail = UserInfo.getUserEmail();
            List<Recruiter__c> recruiters = [SELECT Id FROM Recruiter__c WHERE Email__c = :loggedInEmail LIMIT 1];
            if (recruiters.isEmpty()) throw new AuraHandledException('Recruiter record not found.');

            Job__c j = new Job__c(
                Name = jobName,
                Job_Title__c = jobTitle,
                Location__c = location,
                Department__c = department,
                Job_Description__c = description,
                Salary_Range__c = salaryRange,
                Experience_Required__c = experience,
                Last_Date_to_Apply__c = lastDate,
                Min_10th_Percentage__c = min10th,
                Min_12th_Percentage__c = min12th,
                Min_CGPA__c = minCGPA,
                Status__c = 'Open',
                Recruiter__c = recruiters[0].Id
            );
            insert j;
            return j.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
