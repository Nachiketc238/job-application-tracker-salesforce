# Apex Development Guide: Triggers, Batch Classes, and APIs

## 📚 Table of Contents
1. [What Are Triggers?](#what-are-triggers)
2. [Triggers for This Project](#triggers-for-this-project)
3. [What Are Batch Classes?](#what-are-batch-classes)
4. [Batch Classes for This Project](#batch-classes-for-this-project)
5. [What Are APIs?](#what-are-apis)
6. [APIs for This Project](#apis-for-this-project)
7. [How They Improve the Project](#how-they-improve-the-project)

---

## 🔔 What Are Triggers?

### **Definition:**
A **trigger** is Apex code that executes **automatically** when a record is:
- **Created** (INSERT)
- **Updated** (UPDATE)
- **Deleted** (DELETE)
- **Undeleted** (UNDELETE)

### **When to Use Triggers:**
- ✅ Complex business logic that flows can't handle
- ✅ Cross-object updates (update related records)
- ✅ Data validation that requires SOQL queries
- ✅ Automatic field calculations
- ✅ Enforcing business rules
- ✅ Preventing invalid data

### **Trigger Best Practices:**
1. **One trigger per object** (prevents conflicts)
2. **Handler pattern** (put logic in a separate class)
3. **Bulk-safe** (handle 200+ records at once)
4. **Test coverage** (100% coverage required)

---

## 🎯 Triggers for This Project

### **1. ApplicationTrigger** 
**Purpose:** Handle all Application__c record operations

**What it does:**
- ✅ **Prevent duplicate applications** (same Applicant + same Job)
- ✅ **Auto-calculate Application_Job_Key__c** (Applicant ID + Job ID)
- ✅ **Validate application date** (can't apply after Last_Date_to_Apply__c)
- ✅ **Prevent applications to closed jobs** (Job Status = "Close")
- ✅ **Auto-update related records** when Application status changes
- ✅ **Set Application_Date__c** automatically on creation

**When it fires:**
- Before insert (validation)
- After insert (create related records)
- Before update (validation)
- After update (update related records)

**Example Scenario:**
```
Student applies for Job #123
→ Trigger checks: Is Job #123 still "Open"? ✅
→ Trigger checks: Has this student already applied? ❌ (duplicate!)
→ Trigger throws error: "You have already applied for this job"
```

---

### **2. JobTrigger**
**Purpose:** Handle all Job__c record operations

**What it does:**
- ✅ **Auto-close jobs** after Last_Date_to_Apply__c passes
- ✅ **Prevent status change** if applications exist (business rule)
- ✅ **Update all related Applications** when Job status changes to "Close"
- ✅ **Validate Last_Date_to_Apply__c** (must be in future when creating)
- ✅ **Send notifications** to recruiters when job closes

**When it fires:**
- Before insert (validation)
- After insert (create notifications)
- Before update (validation)
- After update (update related records)

**Example Scenario:**
```
Job #123: Last_Date_to_Apply__c = January 15, 2024
Today = January 16, 2024
→ Trigger automatically sets Job Status = "Close"
→ Trigger updates all Applications for this job: Status = "Rejected"
→ Trigger sends email to Recruiter: "Job #123 has been closed"
```

---

### **3. StudentTrigger**
**Purpose:** Handle all Student__c record operations

**What it does:**
- ✅ **Validate unique Student_ID__c** (prevent duplicates)
- ✅ **Validate unique Email__c** (prevent duplicate emails)
- ✅ **Auto-link Student to Applicant** when both exist
- ✅ **Update related Applications** when Student status changes
- ✅ **Prevent deletion** if Student has active Applications

**When it fires:**
- Before insert (validation)
- Before update (validation)
- Before delete (prevent deletion if related records exist)

**Example Scenario:**
```
New Student created with Student_ID = "STU001"
→ Trigger checks: Does STU001 already exist? ❌ (duplicate!)
→ Trigger throws error: "Student ID already exists"
```

---

### **4. ApplicantTrigger**
**Purpose:** Handle all Applicant_Name__c record operations

**What it does:**
- ✅ **Cascade delete** related Applications when Applicant deleted
- ✅ **Auto-link to Student** if Student exists with same email
- ✅ **Update Application status** when Applicant status changes
- ✅ **Validate email format** and uniqueness

**When it fires:**
- Before delete (prevent if active applications exist)
- After delete (cascade delete related records)
- After insert/update (link to Student)

**Example Scenario:**
```
Recruiter deletes Applicant "John Doe"
→ Trigger checks: Does John have Applications? ✅ (3 applications exist)
→ Trigger deletes all 3 Applications automatically
→ Trigger deletes related Interviews and Exams
→ Data integrity maintained ✅
```

---

### **5. ExamTrigger** ⚠️ MISSING - NEEDS TO BE CREATED
**Purpose:** Handle all Exam__c record operations

**What it does:**
- ✅ **Status Cascade**: When Exam Status = "Pass" → Update Application Status = "Exam"
- ✅ **Status Cascade**: When Exam Status = "Fail" → Update Application Status = "Rejected"
- ✅ **Validation**: Exam can only be created if Application Status = "Shortlisted" or "Exam"
- ✅ **Validation**: Exam_Date__c must be in the future when creating
- ✅ **Auto-update**: When Exam created → Update Application Status = "Exam"
- ✅ **Prevent deletion**: Can't delete Exam if Application Status = "Hired"

**When it fires:**
- Before insert (validation)
- After insert (update Application status)
- Before update (validation)
- After update (cascade status updates)
- Before delete (prevent if Application is Hired)

**Example Scenario:**
```
Exam created for Application #456
→ Trigger checks: Is Application Status = "Shortlisted" or "Exam"? ✅
→ Trigger updates Application Status = "Exam"
→ Exam Status later changed to "Pass"
→ Trigger updates Application Status = "Exam" (ready for Interview)
```

---

### **6. InterviewTrigger** ⚠️ MISSING - NEEDS TO BE CREATED
**Purpose:** Handle all Interview__c record operations

**What it does:**
- ✅ **Status Cascade**: When Interview Status = "Selected" → Update Application Status = "Hired" + Create Offer
- ✅ **Status Cascade**: When Interview Status = "Rejected" → Update Application Status = "Rejected"
- ✅ **Validation**: Interview can only be created if Application Status = "Shortlisted" or "Interview"
- ✅ **Validation**: Scheduled_Date__c must be in the future
- ✅ **Validation**: Can't schedule interview if Exam Status = "Fail" (if Exam exists)
- ✅ **Auto-update**: When Interview created → Update Application Status = "Interview"
- ✅ **Prevent deletion**: Can't delete Interview if Application Status = "Hired"

**When it fires:**
- Before insert (validation)
- After insert (update Application status)
- Before update (validation)
- After update (cascade status updates, create Offer)
- Before delete (prevent if Application is Hired)

**Example Scenario:**
```
Interview created for Application #456
→ Trigger checks: Is Application Status = "Shortlisted" or "Interview"? ✅
→ Trigger checks: If Exam exists, is Exam Status = "Pass"? ✅
→ Trigger updates Application Status = "Interview"
→ Interview Status later changed to "Selected"
→ Trigger updates Application Status = "Hired"
→ Trigger auto-creates Offer__c record
```

---

### **7. OfferTrigger** ⚠️ MISSING - NEEDS TO BE CREATED
**Purpose:** Handle all Offer__c record operations

**What it does:**
- ✅ **Status Cascade**: When Offer Status = "Accepted" → Update Application Status = "Hired" (final) + Update Job positions
- ✅ **Status Cascade**: When Offer Status = "Rejected" → Update Application Status = "Rejected"
- ✅ **Validation**: Offer can only be created if Application Status = "Hired"
- ✅ **Validation**: Offer_Date__c must be <= Joining_Date__c
- ✅ **Validation**: Joining_Date__c must be in the future
- ✅ **Auto-update**: When Offer created → Update Application Status = "Hired"
- ✅ **Prevent deletion**: Can't delete Offer if Offer Status = "Accepted"

**When it fires:**
- Before insert (validation)
- After insert (update Application status)
- Before update (validation)
- After update (cascade status updates, update Job)
- Before delete (prevent if Offer is Accepted)

**Example Scenario:**
```
Offer created for Application #456
→ Trigger checks: Is Application Status = "Hired"? ✅
→ Trigger updates Application Status = "Hired"
→ Offer Status later changed to "Accepted"
→ Trigger updates Application Status = "Hired" (final confirmation)
→ Trigger updates Job: Reduces available positions count
→ Trigger sends email to Recruiter: "Offer accepted"
```

---

## ⚠️ **IMPORTANT: Complete Trigger Coverage**

**You need 7 triggers total, not 4!**

| Trigger | Status | Priority |
|---------|--------|----------|
| ApplicationTrigger | ✅ Mentioned | CRITICAL |
| JobTrigger | ✅ Mentioned | CRITICAL |
| StudentTrigger | ✅ Mentioned | HIGH |
| ApplicantTrigger | ✅ Mentioned | HIGH |
| **ExamTrigger** | ❌ **MISSING** | MEDIUM |
| **InterviewTrigger** | ❌ **MISSING** | MEDIUM |
| **OfferTrigger** | ❌ **MISSING** | MEDIUM |

**Without the 3 missing triggers, your platform will have data inconsistency and broken workflows!**

See `TRIGGER_COVERAGE_ANALYSIS.md` for complete details.

---

## ⚙️ What Are Batch Classes?

### **Definition:**
A **batch class** is Apex code that processes **large volumes of data** (thousands of records) in **chunks** (batches of 200 records).

### **When to Use Batch Classes:**
- ✅ Processing **10,000+ records** at once
- ✅ **Scheduled jobs** (run daily/weekly/monthly)
- ✅ **Data cleanup** (archiving old records)
- ✅ **Bulk updates** (updating thousands of records)
- ✅ **Complex calculations** that take time
- ✅ **Integration** with external systems (API calls)

### **How Batch Classes Work:**
```
1. Start() method: Query records to process (up to 50,000)
2. Execute() method: Process records in batches of 200
3. Finish() method: Send notifications, log results
```

### **Limits:**
- ✅ Can process **millions of records**
- ✅ Runs **asynchronously** (doesn't block users)
- ✅ Each batch gets **200 records**
- ✅ Can run for **up to 24 hours**

---

## 🔄 Batch Classes for This Project

### **1. JobAutoCloseBatch**
**Purpose:** Automatically close jobs that have passed their Last_Date_to_Apply__c

**What it does:**
- ✅ Finds all Jobs where:
  - Status = "Open"
  - Last_Date_to_Apply__c < Today
- ✅ Updates Job Status = "Close"
- ✅ Updates all related Applications: Status = "Rejected"
- ✅ Sends email to Recruiters

**When it runs:**
- **Scheduled daily** at 11:00 PM
- Can also run manually

**Example:**
```
Query: SELECT Id, Name, Last_Date_to_Apply__c FROM Job__c 
       WHERE Status__c = 'Open' 
       AND Last_Date_to_Apply__c < TODAY

Found: 50 jobs that expired
→ Batch processes 50 jobs in 1 batch
→ Updates all 50 jobs: Status = "Close"
→ Updates 500 related Applications: Status = "Rejected"
→ Sends 50 emails to Recruiters
```

**Why use Batch instead of Trigger?**
- ✅ Processes **all expired jobs at once** (not just one)
- ✅ Runs **automatically** every day
- ✅ Doesn't slow down users (runs in background)

---

### **2. ApplicationStatusUpdateBatch**
**Purpose:** Bulk update Application statuses based on business rules

**What it does:**
- ✅ Finds Applications stuck in "Applied" status for 30+ days
- ✅ Auto-updates to "Rejected" (no response = rejected)
- ✅ Sends notification emails to Applicants
- ✅ Creates audit log records

**When it runs:**
- **Scheduled weekly** on Sundays
- Can also run manually

**Example:**
```
Query: SELECT Id, Status__c, Application_Date__c FROM Application__c
       WHERE Status__c = 'Applied'
       AND Application_Date__c < 30_DAYS_AGO

Found: 1,200 applications stuck in "Applied"
→ Batch processes in 6 batches (200 each)
→ Updates all 1,200: Status = "Rejected"
→ Sends 1,200 emails to Applicants
→ Creates 1,200 audit log records
```

---

### **3. DailyApplicationReportBatch**
**Purpose:** Generate daily reports for Recruiters

**What it does:**
- ✅ Counts new Applications per Job
- ✅ Counts Applications by Status
- ✅ Calculates average time in each stage
- ✅ Generates CSV report
- ✅ Emails report to all Recruiters

**When it runs:**
- **Scheduled daily** at 8:00 AM
- Sends report before workday starts

**Example:**
```
Report for January 16, 2024:
- New Applications: 45
- Shortlisted: 12
- In Interview: 8
- Hired: 3
- Rejected: 22

→ Generates CSV file
→ Emails to all Recruiters
→ Stores report in Files
```

---

### **4. StudentDataCleanupBatch**
**Purpose:** Archive old Student records (GDPR compliance)

**What it does:**
- ✅ Finds Students with Status = "Graduated" for 2+ years
- ✅ Finds Students with no Applications for 1+ year
- ✅ Archives old records (moves to Archive object)
- ✅ Deletes personal data (GDPR compliance)

**When it runs:**
- **Scheduled monthly** on 1st of month
- Can also run manually

---

## 🌐 What Are APIs?

### **Definition:**
An **API (Application Programming Interface)** allows **external systems** to:
- ✅ **Read data** from Salesforce (GET)
- ✅ **Create records** in Salesforce (POST)
- ✅ **Update records** in Salesforce (PUT/PATCH)
- ✅ **Delete records** from Salesforce (DELETE)

### **Types of APIs in Salesforce:**

#### **1. REST API** (Most Common)
- ✅ Uses **HTTP methods** (GET, POST, PUT, DELETE)
- ✅ Returns **JSON** data
- ✅ Easy to use from **any programming language**
- ✅ Good for **web applications, mobile apps**

#### **2. SOAP API**
- ✅ Uses **XML** format
- ✅ More structured, enterprise-grade
- ✅ Good for **enterprise integrations**

#### **3. Custom REST Endpoints** (Apex REST)
- ✅ You write **Apex classes** that expose REST endpoints
- ✅ Full control over **request/response format**
- ✅ Can add **authentication, validation, business logic**

### **When to Use APIs:**
- ✅ **External website** needs to post jobs to Salesforce
- ✅ **Mobile app** needs to fetch job listings
- ✅ **Third-party system** (HR system) needs to sync data
- ✅ **Integration** with other platforms (LinkedIn, Indeed)

---

## 🔌 APIs for This Project

### **1. JobPostingRESTService**
**Purpose:** Allow external systems to post jobs to Salesforce

**Endpoint:** `POST /services/apexrest/JobPosting/v1/jobs`

**What it does:**
- ✅ Accepts job data from external system (JSON)
- ✅ Validates job data
- ✅ Creates Job__c record
- ✅ Assigns to Recruiter
- ✅ Returns job ID and status

**Example Request:**
```json
POST https://yourinstance.salesforce.com/services/apexrest/JobPosting/v1/jobs
Headers:
  Authorization: Bearer {access_token}
  Content-Type: application/json

Body:
{
  "jobTitle": "Software Engineer",
  "department": "Engineering",
  "location": "Remote",
  "jobDescription": "We are looking for...",
  "salaryRange": "$80,000 - $100,000",
  "lastDateToApply": "2024-02-15",
  "experienceRequired": "3-5 years",
  "recruiterEmail": "recruiter@company.com"
}
```

**Example Response:**
```json
{
  "success": true,
  "jobId": "a0X5g000000ABC123",
  "message": "Job created successfully"
}
```

**Use Case:**
```
Company has a job posting website
→ Website posts new job to Salesforce via REST API
→ Job automatically appears in Salesforce
→ Recruiters can manage it immediately
```

---

### **2. ApplicationStatusRESTService**
**Purpose:** Allow external systems to check application status

**Endpoint:** `GET /services/apexrest/ApplicationStatus/v1/status/{applicationId}`

**What it does:**
- ✅ Returns Application status for given Application ID
- ✅ Returns related Interview and Exam details
- ✅ Returns current stage in hiring process

**Example Request:**
```json
GET https://yourinstance.salesforce.com/services/apexrest/ApplicationStatus/v1/status/a0Y5g000000XYZ789
Headers:
  Authorization: Bearer {access_token}
```

**Example Response:**
```json
{
  "applicationId": "a0Y5g000000XYZ789",
  "status": "Interview",
  "jobTitle": "Software Engineer",
  "applicantName": "John Doe",
  "currentStage": "Technical Interview Scheduled",
  "interviewDate": "2024-01-20T10:00:00Z",
  "nextSteps": "Awaiting interview results"
}
```

**Use Case:**
```
Student portal website
→ Student enters Application ID
→ Website calls REST API to get status
→ Website displays: "Your application is in Interview stage"
```

---

### **3. BulkApplicationRESTService**
**Purpose:** Allow bulk import of Applications from external system

**Endpoint:** `POST /services/apexrest/BulkApplication/v1/applications`

**What it does:**
- ✅ Accepts array of Applications (JSON)
- ✅ Validates all Applications
- ✅ Creates all Applications in bulk
- ✅ Returns success/failure for each

**Example Request:**
```json
POST https://yourinstance.salesforce.com/services/apexrest/BulkApplication/v1/applications
Body:
{
  "applications": [
    {
      "applicantEmail": "student1@university.edu",
      "jobId": "a0X5g000000ABC123",
      "applicationDate": "2024-01-15"
    },
    {
      "applicantEmail": "student2@university.edu",
      "jobId": "a0X5g000000ABC123",
      "applicationDate": "2024-01-15"
    }
  ]
}
```

**Use Case:**
```
University career portal
→ 500 students apply for Job #123
→ Portal sends all 500 applications to Salesforce via REST API
→ All 500 Applications created in Salesforce automatically
```

---

### **4. JobListingRESTService**
**Purpose:** Public API to fetch open job listings (no authentication required)

**Endpoint:** `GET /services/apexrest/JobListing/v1/jobs`

**What it does:**
- ✅ Returns all Jobs with Status = "Open"
- ✅ Filters by Department, Location (optional)
- ✅ Returns job details (title, description, salary)
- ✅ No authentication required (public endpoint)

**Example Request:**
```json
GET https://yourinstance.salesforce.com/services/apexrest/JobListing/v1/jobs?department=Engineering&location=Remote
```

**Example Response:**
```json
{
  "jobs": [
    {
      "jobId": "a0X5g000000ABC123",
      "jobTitle": "Software Engineer",
      "department": "Engineering",
      "location": "Remote",
      "salaryRange": "$80,000 - $100,000",
      "lastDateToApply": "2024-02-15"
    }
  ],
  "totalCount": 1
}
```

**Use Case:**
```
University job board website
→ Website fetches open jobs from Salesforce via REST API
→ Displays jobs on website
→ Students can see all open positions
```

---

## 🚀 How They Improve the Project

### **Triggers Improve:**
1. ✅ **Data Integrity** - Prevents invalid data (duplicates, expired dates)
2. ✅ **Automation** - Auto-calculates fields, updates related records
3. ✅ **Business Rules** - Enforces company policies automatically
4. ✅ **User Experience** - Users don't need to remember rules
5. ✅ **Performance** - Faster than flows for complex logic

### **Batch Classes Improve:**
1. ✅ **Scalability** - Handles thousands of records at once
2. ✅ **Automation** - Runs automatically on schedule
3. ✅ **Performance** - Doesn't slow down users (runs in background)
4. ✅ **Reporting** - Generates reports automatically
5. ✅ **Data Maintenance** - Keeps data clean automatically

### **APIs Improve:**
1. ✅ **Integration** - Connects with external systems
2. ✅ **Automation** - External systems can create/update data automatically
3. ✅ **Public Access** - Job listings can be displayed on websites
4. ✅ **Mobile Apps** - Mobile apps can fetch data from Salesforce
5. ✅ **Real-time Sync** - Data stays in sync across systems

---

## 📊 Comparison: Triggers vs Flows vs Batch vs API

| Feature | Triggers | Flows | Batch Classes | APIs |
|---------|----------|-------|---------------|------|
| **When it runs** | On record save | On record save / User action | Scheduled / Manual | On HTTP request |
| **Records processed** | 200 at a time | 1-200 at a time | 10,000+ at a time | 1-200 at a time |
| **Complexity** | High (code) | Medium (declarative) | High (code) | High (code) |
| **Performance** | Fast | Medium | Slow (background) | Fast |
| **Use case** | Business logic | Simple automation | Bulk processing | External integration |
| **Best for** | Validation, calculations | UI flows, simple rules | Scheduled jobs, reports | Integration, mobile apps |

---

## 🎯 Summary: What to Build First

### **Priority 1: Triggers (Critical) - 7 Total Needed**
1. ✅ **ApplicationTrigger** - Prevent duplicates, validate dates
2. ✅ **JobTrigger** - Auto-close expired jobs
3. ✅ **StudentTrigger** - Unique validation, linking
4. ✅ **ApplicantTrigger** - Cascade deletes, linking
5. ⚠️ **ExamTrigger** - Status cascade, validation (MISSING)
6. ⚠️ **InterviewTrigger** - Status cascade, scheduling validation (MISSING)
7. ⚠️ **OfferTrigger** - Status cascade, acceptance logic (MISSING)
8. ✅ **Test Classes** - 100% coverage required for all triggers

### **Priority 2: Batch Classes (Important)**
1. ✅ **JobAutoCloseBatch** - Daily job closure
2. ✅ **ApplicationStatusUpdateBatch** - Weekly status updates

### **Priority 3: APIs (Nice to Have)**
1. ✅ **JobListingRESTService** - Public job listings
2. ✅ **ApplicationStatusRESTService** - Status checking

---

## 📝 Next Steps

Would you like me to:
1. ✅ Create the **ApplicationTrigger + Handler + Test Class** (complete example)?
2. ✅ Create the **JobAutoCloseBatch** (scheduled job example)?
3. ✅ Create the **JobListingRESTService** (REST API example)?

Let me know which one you'd like to start with!
