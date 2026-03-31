@RestResource(urlMapping='/StudentPortal/*')
global without sharing class JobPortalAPI {
    
    /**
     * @description Fetches all available jobs to display on the Student Portal.
     * @return List of Job__c records.
     */
    @HttpGet
    global static List<Job__c> getOpenJobs() {
        return [SELECT Id, Name, Job_Title__c, Department__c, Location__c, Experience_Required__c, Salary_Range__c, Job_Description__c, Last_Date_to_Apply__c, Status__c 
                FROM Job__c 
                ORDER BY CreatedDate DESC
                LIMIT 500];
    }
    
    /**
     * @description Handles Login and Registration from the external Student Portal.
     * @return JSON response detailing success or failure.
     */
    @HttpPost
    global static String handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            String action = (String) params.get('action'); // "login", "register", or "apply"
            String email = (String) params.get('email');
            
            if (action == 'login') {
                List<Applicant_Name__c> existingApplicants = [SELECT Id, Name, Resume_Link__c FROM Applicant_Name__c WHERE Personal_Email__c = :email LIMIT 1];
                if (!existingApplicants.isEmpty()) {
                    Applicant_Name__c existingUser = existingApplicants[0];
                    if (res != null) { res.statusCode = 200; }
                    return JSON.serialize(new Map<String, Object>{
                        'status' => 'success',
                        'studentId' => existingUser.Id,
                        'studentName' => existingUser.Name,
                        'hasResume' => String.isNotBlank(existingUser.Resume_Link__c),
                        'message' => 'Login successful! Welcome back, ' + existingUser.Name
                    });
                } else {
                    if (res != null) { res.statusCode = 404; }
                    return JSON.serialize(new Map<String, Object>{
                        'status' => 'error',
                        'message' => 'Email not found. Please register first.'
                    });
                }
            } else if (action == 'register') {
                String name = (String) params.get('name');
                String phone = (String) params.get('phone');
                String skills = (String) params.get('skills');
                String linkedin = (String) params.get('linkedin');
                String location = (String) params.get('location');
                String portfolio = (String) params.get('portfolio');
                Decimal experience = null;
                if (params.get('experience') != null && String.isNotBlank(String.valueOf(params.get('experience')))) {
                    try { experience = Decimal.valueOf(String.valueOf(params.get('experience'))); } catch(Exception e) {}
                }
                
                // check if email already exists
                List<Applicant_Name__c> existingApplicants = [SELECT Id, Name FROM Applicant_Name__c WHERE Personal_Email__c = :email LIMIT 1];
                if (!existingApplicants.isEmpty()) {
                    if (res != null) { res.statusCode = 400; }
                    return JSON.serialize(new Map<String, Object>{
                        'status' => 'error',
                        'message' => 'Email already registered. Please login.'
                    });
                }
                
                Applicant_Name__c newApplicant = new Applicant_Name__c(
                    Name = name,
                    Personal_Email__c = email,
                    Phone_Number__c = phone,
                    Skills__c = skills,
                    LinkedIn_Link__c = linkedin,
                    Current_Location__c = location,
                    Portfolio_GitHub__c = portfolio,
                    Experience_Years__c = experience
                );
                insert newApplicant;
                
                if (res != null) { res.statusCode = 200; }
                
                return JSON.serialize(new Map<String, Object>{
                    'status' => 'success',
                    'studentId' => newApplicant.Id,
                    'studentName' => newApplicant.Name,
                    'message' => 'Applicant profile created successfully!'
                });

            } else if (action == 'apply') {
                String applicantId = (String) params.get('applicantId');
                String jobId = (String) params.get('jobId');
                String resumeLink = (String) params.get('resumeLink');

                Job__c jobRecord = [SELECT Status__c, Last_Date_to_Apply__c FROM Job__c WHERE Id = :jobId LIMIT 1];
                if (jobRecord.Status__c == 'Close' || jobRecord.Status__c == 'Closed' || (jobRecord.Last_Date_to_Apply__c != null && jobRecord.Last_Date_to_Apply__c < Date.today())) {
                    if (res != null) { res.statusCode = 400; }
                    return JSON.serialize(new Map<String, Object>{ 'status' => 'error', 'message' => 'This job is no longer accepting applications due to passed deadline.' });
                }

                Applicant_Name__c applicant = [SELECT Id, Resume_Link__c FROM Applicant_Name__c WHERE Id = :applicantId LIMIT 1];
                
                if (String.isBlank(resumeLink)) {
                    // Blank means the frontend bypassed the modal. Use the saved link!
                    resumeLink = applicant.Resume_Link__c;
                } else {
                    // Save the newly provided resume link to the Applicant profile forever
                    applicant.Resume_Link__c = resumeLink;
                    update applicant;
                }

                // Check if already applied
                List<Application__c> existingApps = [SELECT Id FROM Application__c WHERE Applicant__c = :applicantId AND Job__c = :jobId LIMIT 1];
                if (!existingApps.isEmpty()) {
                    if (res != null) { res.statusCode = 400; }
                    return JSON.serialize(new Map<String, Object>{
                        'status' => 'error',
                        'message' => 'You have already applied for this job.'
                    });
                }

                Application__c newApplication = new Application__c(
                    Applicant__c = applicantId,
                    Job__c = jobId,
                    Status__c = 'Applied',
                    Upload_Resume_Link__c = resumeLink,
                    Application_Date__c = Date.today()
                );
                insert newApplication;

                if (res != null) { res.statusCode = 200; }
                return JSON.serialize(new Map<String, Object>{
                    'status' => 'success',
                    'message' => 'Applied successfully'
                });

            } else if (action == 'getApplications') {
                String applicantId = (String) params.get('applicantId');
                if (String.isBlank(applicantId)) {
                    if (res != null) { res.statusCode = 400; }
                    return JSON.serialize(new Map<String, Object>{ 'status' => 'error', 'message' => 'Applicant ID is required.' });
                }
                
                List<Application__c> apps = [SELECT Job__c FROM Application__c WHERE Applicant__c = :applicantId];
                List<String> jobIds = new List<String>();
                for(Application__c app : apps) {
                    jobIds.add(app.Job__c);
                }
                
                Applicant_Name__c applicant = [SELECT Resume_Link__c FROM Applicant_Name__c WHERE Id = :applicantId LIMIT 1];
                
                if (res != null) { res.statusCode = 200; }
                return JSON.serialize(new Map<String, Object>{
                    'status' => 'success',
                    'appliedJobIds' => jobIds,
                    'hasResume' => String.isNotBlank(applicant.Resume_Link__c)
                });
            } else {
                if (res != null) { res.statusCode = 400; }
                return JSON.serialize(new Map<String, Object>{
                    'status' => 'error',
                    'message' => 'Invalid action.'
                });
            }
        } catch (Exception e) {
            if (res != null) { res.statusCode = 500; }
            return JSON.serialize(new Map<String, Object>{
                'status' => 'error',
                'message' => e.getMessage()
            });
        }
    }
}
