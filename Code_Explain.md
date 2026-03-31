# Salesforce Backend Code Explanation - Job Application Tracker

This document provides a comprehensive overview of the backend Apex code in our Job Application Tracker org. It breaks down the exact business rules implemented in the Triggers/Handlers, how our Test Classes verify that logic, and provides an overview of Batch Classes.

---

## 1. Trigger Handlers (Business Logic)

Triggers run immediately when a record is created, updated, or deleted. We split out the actual logic into "Trigger Handler" classes. Here is the exact logic running behind the scenes for each custom object:

### `ApplicantTriggerHandler.cls`
- **Auto-link to Student (After Insert/Update):** When an Applicant is created or updated with a `Personal_Email__c`, the system automatically searches the `Student__c` object for a matching email. If found, it automatically links the Applicant to the Student record.
- **Cascade Delete (Before Delete):** If an Applicant record is deleted, the system deletes all related records (Applications, Exams, Interviews, Offers) to keep the database clean before the Applicant is permanently removed.

### `ApplicationTriggerHandler.cls`
- **Prevent Duplicates (Before Insert/Update):** The system checks if the Applicant has already applied for the exact same Job. If so, it throws a "Duplicate application" error.
- **Enforce Deadlines (Before Insert):** Checks the `Last_Date_to_Apply__c` on the related Job. If the date has passed, the application is blocked.
- **Closed Jobs (Before Insert/Update):** Prevents applicants from applying to Jobs where the status is "Close".
- **Auto Defaults (Before Insert):** Automatically populates `Application_Date__c` with today's date if left blank, and generates a unique `Application_Job_Key__c` to enforce duplicate rules.

### `JobTriggerHandler.cls`
- **Future Date Validation (Before Insert/Update):** Ensures that the `Last_Date_to_Apply__c` must be a date in the *future* when creating a Job or keeping it "Open".
- **Auto-Close Expired Jobs (Before Update):** If an Open Job is updated, and its deadline has passed, the system automatically changes its status to "Close".
- **Auto-Reject Applications (After Update):** When a Job's status is changed to "Close", the system finds all pending Applications for that Job and automatically changes their status to "Rejected".

### `InterviewTriggerHandler.cls`
- **Prerequisite Validation (Before Insert):** An interview can only be scheduled if the Application status is "Shortlisted" or "Interview". It also ensures the `Scheduled_Date__c` is in the future.
- **Exam Fallback (Before Insert):** If the applicant failed their Exam (`Status = Fail`), scheduling an interview is blocked entirely.
- **Application Status Cascade (After Insert/Update):** 
  - When an interview is simply *scheduled*, the Application status changes to "Interview".
  - If the interview is marked as "Selected", the Application status changes to "Hired".
  - If the interview is marked as "Rejected", the Application status changes to "Rejected".
- **Auto-Create Offer (After Update):** The moment an interview status changes to "Selected", the system automatically generates a new `Offer__c` record with the status "Pending".
- **Prevent Deletion (Before Delete):** Prevents deleting an Interview if the related Application is already "Hired".

### `OfferTriggerHandler.cls`
- **Prerequisite Validation (Before Insert):** Ensures you can only create an Offer if the Application status is already "Hired".
- **Date Validations (Before Insert/Update):** Ensures the `Offer_Date__c` is on or before the `Joining_Date__c`, and that the `Joining_Date__c` is in the future.
- **Application Status Cascade (After Update):** When an Offer is marked "Rejected" or "Accepted", the main Application matches that status.
- **Prevent Deletion (Before Delete):** Locks the record; if the offer has been "Accepted", it cannot be deleted.

---

## 2. Apex Test Classes

Salesforce requires that at least 75% of your custom Apex code is covered by unit tests before deploying to a production environment. 

### How Do They Work?
1. **Isolated Database:** Test classes do not have access to real data in your org. They use a special `@TestSetup` method to create fake "dummy data" explicitly for the test.
2. **Execution & Simulation:** The test methods (`@IsTest`) simulate actions such as changing a Job's status to Closed or manually bypassing the rules by trying to apply to a closed Job.
3. **Assertions:** We use functions like `System.assertEquals()` to verify that the simulated action produced the exact outcome programmed in our Triggers. 
   - *Example:* The `JobTriggerHandlerTest` attempts to create a Job with a Last Date in the past and *asserts* that Salesforce successfully threw the error message.
4. **Coverage Calculation:** As the test simulator runs, Salesforce tracks which lines of our `TriggerHandler` code were executed to calculate the "Code Coverage" percentage.

### When Do They Work (Execute)?
- **During Deployment:** Every time you try to deploy code to Production, Salesforce automatically runs all local tests to ensure the new code doesn't break existing functionality.
- **Manual Execution:** A developer/admin can manually run tests from the Developer Console or Setup UI.

---

## 3. Apex Batch Classes (Batchable Apex)

*(Note: Currently, we primarily use standard Triggers and standard Salesforce features for our automation, but Batch Apex is available for massive jobs).*

While Triggers handle real-time, single-record operations, Batch Classes handle massive data operations.

### What Are They?
Batch Apex is used when you need to process thousands or millions of records (up to 50 million) without exceeding Salesforce's limits (like the maximum number of SOQL queries permitted).

### How Do They Work?
Batch classes implement the `Database.Batchable` interface and break the massive job down into three steps:
1. **Start:** Collects the massive list of records to be processed (usually via a query).
2. **Execute:** Breaks the massive list into smaller "chunks" (default is 200 records per batch). It runs logic on each chunk independently. 
3. **Finish:** Runs once after all batches are complete, often used to send a confirmation email.

### When Do They Work (Execute)?
Batch classes run asynchronously in the background. They do not hold up the user interface.
- **Scheduled:** They are commonly scheduled to run automatically at a specific time using the `Schedulable` interface.
  - *Example use case:* A nightly batch that scans *all* Open Jobs and auto-closes them if their deadline has passed.
- **Manually Invoked:** Triggered via developer commands dynamically.
