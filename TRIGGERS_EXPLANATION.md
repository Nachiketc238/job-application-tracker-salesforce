# Job Application Tracker – Triggers Explanation

This document explains each trigger, when it runs, and how the code works.

---

## Overview: What is a Trigger?

A **trigger** is Apex code that runs **automatically** when records are inserted, updated, or deleted. It is event-driven: you don’t call it manually; Salesforce invokes it based on DML operations.

**When it runs:**

| Trigger context | When it fires |
|-----------------|---------------|
| `before insert` | Right before new records are saved to the database |
| `after insert` | Right after new records are saved |
| `before update` | Right before existing records are updated |
| `after update` | Right after existing records are updated |
| `before delete` | Right before records are deleted |
| `after delete` | Right after records are deleted |

---

## 1. ApplicationTrigger

**File:** `ApplicationTrigger.trigger`  
**Handler:** `ApplicationTriggerHandler.cls`  
**Object:** `Application__c`

### When it runs

| Event | When |
|-------|------|
| Before insert | User creates a new Application (or bulk insert) |
| After insert | Application record is saved |
| Before update | User edits an Application |
| After update | Application changes are saved |

### What the code does

1. **preventDuplicateApplications**  
   - Ensures the same Applicant cannot apply twice for the same Job.  
   - Builds a key `ApplicantId_JobId` and checks it against existing records and records in the same batch.  
   - If duplicate: `addError()` stops the save and shows an error.

2. **setApplicationJobKey**  
   - Sets `Application_Job_Key__c` = `ApplicantId_JobId` for uniqueness.

3. **validateApplicationDate**  
   - Checks that `Last_Date_to_Apply__c` on the Job has not passed.  
   - If it has: blocks creation and shows an error.

4. **preventApplicationToClosedJobs**  
   - Checks that the Job’s `Status__c` is not `"Close"`.  
   - If closed: blocks creation.

5. **setApplicationDate**  
   - Sets `Application_Date__c` to today when it is blank.

---

## 2. JobTrigger

**File:** `JobTrigger.trigger`  
**Handler:** `JobTriggerHandler.cls`  
**Object:** `Job__c`

### When it runs

| Event | When |
|-------|------|
| Before insert | User creates a new Job |
| After insert | Job is saved (placeholder for notifications) |
| Before update | User edits a Job |
| After update | Job changes are saved |

### What the code does

1. **validateLastDateToApply**  
   - Ensures `Last_Date_to_Apply__c` is in the future when the Job is Open.  
   - Blocks saving if the date is in the past.

2. **autoCloseExpiredJobs**  
   - If `Last_Date_to_Apply__c` is in the past and status is `"Open"`, sets status to `"Close"`.

3. **updateApplicationsWhenJobCloses** (after update)  
   - When a Job’s status changes from non-Close to `"Close"`, finds related Applications and sets their status to `"Rejected"`.

---

## 3. StudentTrigger

**File:** `StudentTrigger.trigger`  
**Handler:** `StudentTriggerHandler.cls`  
**Object:** `Student__c`

### When it runs

| Event | When |
|-------|------|
| Before insert | User creates a new Student |
| Before update | User edits a Student |
| Before delete | User tries to delete a Student |

### What the code does

1. **validateUniqueStudentId**  
   - Checks that `Student_ID__c` is not already used by another Student (ignores the current record on update).  
   - Also checks within the same batch for duplicates.

2. **validateUniqueEmail**  
   - Same logic for `Email__c`: unique across Students and within the batch.

3. **preventDeletionWithActiveApplications**  
   - Counts Applications where `Applicant__r.Student__c` = Student Id.  
   - If any exist: blocks deletion with `addError()`.

---

## 4. ApplicantTrigger

**File:** `ApplicantTrigger.trigger`  
**Handler:** `ApplicantTriggerHandler.cls`  
**Object:** `Applicant_Name__c`

### When it runs

| Event | When |
|-------|------|
| Before delete | User tries to delete an Applicant |
| After insert | Applicant is saved |
| After update | Applicant changes are saved |

### What the code does

1. **cascadeDeleteRelatedRecords** (before delete)  
   - Finds Applications for the Applicant.  
   - Deletes Offers → Exams → Applications (Interviews are removed when Applications are deleted because of Master-Detail).  
   - Keeps referential integrity and avoids orphan records.

2. **linkApplicantToStudent** (after insert/update)  
   - If `Personal_Email__c` matches a Student’s `Email__c`, sets `Student__c` on the Applicant.  
   - Uses a static flag to avoid recursion when updating Applicants.

---

## 5. ExamTrigger

**File:** `ExamTrigger.trigger`  
**Handler:** `ExamTriggerHandler.cls`  
**Object:** `Exam__c`

### When it runs

| Event | When |
|-------|------|
| Before insert | User creates a new Exam |
| After insert | Exam is saved |
| Before update | User edits an Exam |
| After update | Exam changes are saved |
| Before delete | User tries to delete an Exam |

### What the code does

1. **validateApplicationStatusForInsert**  
   - Allows Exam creation only if Application status is `"Shortlisted"` or `"Exam"`.

2. **validateExamDateFuture**  
   - Ensures `Exam_date__c` is in the future.

3. **updateApplicationStatusToExam** (after insert)  
   - When an Exam is created, updates the related Application status to `"Exam"`.

4. **cascadeExamStatusToApplication** (after update)  
   - `Exam.Status__c = "Fail"` → Application `"Rejected"`.  
   - `Exam.Status__c = "Pass"` → Application `"Exam"` (ready for Interview).

5. **preventDeletionIfApplicationHired**  
   - If Application status is `"Hired"`, prevents Exam deletion.

---

## 6. InterviewTrigger

**File:** `InterviewTrigger.trigger`  
**Handler:** `InterviewTriggerHandler.cls`  
**Object:** `Interview__c`

### When it runs

| Event | When |
|-------|------|
| Before insert | User creates a new Interview |
| After insert | Interview is saved |
| Before update | User edits an Interview |
| After update | Interview changes are saved |
| Before delete | User tries to delete an Interview |

### What the code does

1. **validateApplicationStatusForInsert**  
   - Allows Interview creation only if Application status is `"Shortlisted"` or `"Interview"`.

2. **validateScheduledDateFuture**  
   - Ensures `Scheduled_Date__c` is in the future.

3. **validateExamPassedIfExists**  
   - If an Exam exists for the Application and its status is `"Fail"`, blocks Interview creation.

4. **updateApplicationStatusToInterview** (after insert)  
   - Sets related Application status to `"Interview"`.

5. **cascadeInterviewStatusToApplication** (after update)  
   - `Status_of_Interview__c = "Selected"` → Application `"Hired"` and creates an Offer.  
   - `Status_of_Interview__c = "Rejected"` → Application `"Rejected"`.

6. **preventDeletionIfApplicationHired**  
   - If Application status is `"Hired"`, prevents Interview deletion.

---

## 7. OfferTrigger

**File:** `OfferTrigger.trigger`  
**Handler:** `OfferTriggerHandler.cls`  
**Object:** `Offer__c`

### When it runs

| Event | When |
|-------|------|
| Before insert | User creates a new Offer |
| After insert | Offer is saved |
| Before update | User edits an Offer |
| After update | Offer changes are saved |
| Before delete | User tries to delete an Offer |

### What the code does

1. **validateApplicationStatusHired**  
   - Allows Offer creation only if Application status is `"Hired"` (typically after Interview is Selected).

2. **validateOfferAndJoiningDates**  
   - `Offer_Date__c` must be before or on `Joining_Date__c`.  
   - `Joining_Date__c` must be in the future.

3. **updateApplicationStatusToHired** (after insert)  
   - Sets related Application status to `"Hired"`.

4. **cascadeOfferStatusToApplication** (after update)  
   - `Offer_Status__c = "Accepted"` → Application `"Hired"`.  
   - `Offer_Status__c = "Rejected"` → Application `"Rejected"`.

5. **preventDeletionIfOfferAccepted**  
   - If `Offer_Status__c = "Accepted"`, prevents Offer deletion.

---

## Trigger Flow Summary

```
Application created → ApplicationTrigger (validation, key, date)
                     → JobTrigger (auto-close, reject apps when job closes)

Student created     → StudentTrigger (unique ID, unique email)
Student deleted     → StudentTrigger (block if has applications)

Applicant deleted   → ApplicantTrigger (cascade delete Applications, Exams, Offers)
Applicant created/updated → ApplicantTrigger (link to Student by email)

Exam created        → ExamTrigger (set Application = Exam)
Exam updated        → ExamTrigger (Pass → Exam, Fail → Rejected)
Exam deleted        → ExamTrigger (block if Application Hired)

Interview created   → InterviewTrigger (set Application = Interview)
Interview updated   → InterviewTrigger (Selected → Hired + create Offer, Rejected → Rejected)
Interview deleted   → InterviewTrigger (block if Application Hired)

Offer created       → OfferTrigger (set Application = Hired)
Offer updated       → OfferTrigger (Accepted → Hired, Rejected → Rejected)
Offer deleted       → OfferTrigger (block if Accepted)
```

---

## Handler Pattern

Each trigger uses a **handler class** for the business logic:

1. **Triggers** only detect the event (insert/update/delete) and call the correct handler method.
2. **Handlers** contain all validation and logic.
3. This keeps triggers short, logic testable, and code maintainable.

Example:

```apex
trigger ApplicationTrigger on Application__c (before insert, after insert, ...) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ApplicationTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    // ...
}
```

`Trigger.new` holds the records being inserted/updated. `Trigger.oldMap` holds the previous values on update. The handler receives these and runs the appropriate logic.
