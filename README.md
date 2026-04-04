# 🚀 Job Application Tracker - Enterprise Recruitment Management

[![API Version](https://img.shields.io/badge/Salesforce-v65.0-blue.svg)](https://developer.salesforce.com/)
[![Development Model](https://img.shields.io/badge/Model-Salesforce%20DX-green.svg)](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models)
[![Status](https://img.shields.io/badge/Status-Complete-brightgreen.svg)](https://github.com/)

**Job Application Tracker** is a sophisticated, enterprise-grade recruitment management system built on the Salesforce Cloud Platform using modern Salesforce DX development practices. It provides a complete end-to-end solution for managing complex, multi-stage hiring processes, from initial registration to job offer.

---

## 📋 Executive Summary

The platform is designed to serve educational institutions and organizations managing bulk hiring. It automates **12+ critical recruitment workflows**, manages **9 interrelated custom objects**, and provides responsive user interfaces through **9+ configurable page layouts**.

### 🌟 Key Differentiators:
- **Zero-Duplicate Architecture**: Intelligent decision logic prevents redundant applications.
- **Referential Integrity**: Cascade delete handlers ensure a clean and consistent database.
- **Real-Time Notifications**: Automated updates for applicants and recruiters at every stage.
- **Mobile-Responsive UI**: Optimized layouts for field recruiters and on-the-go access.
- **Enterprise-Grade Audit**: Comprehensive tracking for compliance and transparency.

---

## 🏗️ Technical Architecture

### **Core Technology Stack**
- **Platform**: Salesforce (API v65.0)
- **Frontend**: Lightning Web Components (LWC), Aura Components
- **Backend**: Apex Classes, Salesforce Flows
- **Development**: Salesforce DX (SFDX), Salesforce CLI
- **Quality Assurance**: Jest (Unit Testing), ESLint, Prettier, Husky

### **Data Model (Object Relationships)**
The system manages 9 custom objects with the following core relationships:

| Object | Purpose |
|--------|---------|
| **Student__c** | Student profiles and academic records. |
| **Applicant_Name__c** | Candidate details, resumes, and qualifications. |
| **Job__c** | Open positions with requirements and descriptions. |
| **Application__c** | Individual job application tracking. |
| **Interview__c** | Scheduling and feedback management. |
| **Exam__c** | Technical assessment tracking and results. |
| **Offer__c** | Salary offers and acceptance tracking. |
| **Recruiter__c** | Recruiter management and assignments. |

---

## 🔄 Automated Workflows (12+ Flows)

Our recruitment pipeline is fully orchestrated using advanced Salesforce Flows:

1.  **Student Registration**: Automated onboarding with duplicate prevention.
2.  **Application Creation**: Intelligent validation and linking.
3.  **Resume Upload**: Secure document storage and searchable content assets.
4.  **Shortlisting**: Automatic status updates and applicant notifications.
5.  **Evaluation Pipeline**: Seamless transitions from Exam → Technical Evaluation → Interview Scheduled.
6.  **Hiring & Offers**: Automated offer generation and onboarding triggers.
7.  **Data Cleanup**: Cascade delete handling to maintain referential integrity.

---

## 🛠️ Development Setup

### **Prerequisites**
- Salesforce CLI
- Visual Studio Code with Salesforce Extension Pack
- Node.js (for Jest and Linting)

### **Installation**
1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/your-repo/job-application-tracker.git
    cd job-application-tracker
    ```
2.  **Authorize Your Org**:
    ```bash
    sf org login web -d -a my-org
    ```
3.  **Deploy Source**:
    ```bash
    sf project deploy start
    ```
4.  **Assign Permission Sets**:
    ```bash
    sf org assign permset -n Your_Permset_Name
    ```

---

## 🧪 Quality Assurance & Testing

We maintain high code standards through:
- **Jest**: Unit testing for Lightning Web Components.
- **ESLint**: Static code analysis for JavaScript/Apex.
- **Prettier**: Consistent code formatting across the project.
- **Husky**: Pre-commit hooks to ensure quality standards are met before pushing.

To run tests:
```bash
npm run test:unit
```

To run linting:
```bash
npm run lint
```

---

## 🎓 Skills Demonstrated
- **Salesforce Platform**: Object Design, Flow Automation, Apex, LWC.
- **Engineering Practices**: Version Control (Git), CI/CD concepts, Automated Testing.
- **Business Process**: Workflow Orchestration, Data Governance, UX Optimization.

---

> [!NOTE]  
> This project was developed as a capstone for PBL Semester 5, demonstrating production-ready Salesforce development and enterprise architecture.

**Last Updated**: January 2026
