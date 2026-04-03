import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDashboardData from '@salesforce/apex/RecruiterDashboardController.getDashboardData';
import updateApplicationStatus from '@salesforce/apex/RecruiterDashboardController.updateApplicationStatus';
import postJob from '@salesforce/apex/RecruiterDashboardController.postJob';

const ACTIONS = [
    { label: 'View Profile / Resume', name: 'view_profile' },
    { label: 'Move to Shortlisted', name: 'Shortlisted' },
    { label: 'Move to Interview', name: 'Interview' },
    { label: 'Mark as Hired', name: 'Hired' },
    { label: 'Reject', name: 'Rejected' },
];

const COLUMNS = [
    { label: 'Applicant Name', fieldName: 'applicantName', type: 'text' },
    { label: 'Email', fieldName: 'applicantEmail', type: 'email' },
    { label: 'Status', fieldName: 'status', type: 'text', cellAttributes: { class: { fieldName: 'statusColorClass' } } },
    { label: 'Resume', fieldName: 'resumeLink', type: 'url', typeAttributes: { label: 'View Resume', target: '_blank' } },
    { type: 'action', typeAttributes: { rowActions: ACTIONS } }
];

export default class RecruiterDashboard extends LightningElement {
    @track jobList = [];
    @track searchKey = '';

    @track openJobsCount = 0;
    @track totalApplications = 0;
    @track shortlistedCount = 0;
    @track interviewCount = 0;
    @track hiredCount = 0;

    @track isLoading = true;
    @track error = null;

    // Modals
    @track isPostModalOpen = false;
    @track isDetailModalOpen = false;
    @track selectedApp = null;
    @track isPosting = false;

    // Post Job Forms
    @track newJob = {
        name: '', title: '', location: '', department: 'Computer Science', 
        salary: '', experience: 0, description: '', lastDate: '',
        min10th: '', min12th: '', minCGPA: ''
    };

    departmentOptions = [
        { label: 'AI ML', value: 'AI ML' },
        { label: 'All', value: 'All' },
        { label: 'Automobile', value: 'Automobile' },
        { label: 'Biotech', value: 'Biotech' },
        { label: 'Civil', value: 'Civil' },
        { label: 'Computer Science', value: 'Computer Science' },
        { label: 'Cyber Security', value: 'Cyber Security' },
        { label: 'Data Science', value: 'Data Science' },
        { label: 'Electrical', value: 'Electrical' },
        { label: 'Electronic', value: 'Electronic' },
        { label: 'Iot', value: 'Iot' },
        { label: 'IT', value: 'IT' }
    ];

    columns = COLUMNS;
    activeSections = []; // For the accordion
    _rawJobsData = [];

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        this.isLoading = true;
        this.error = null;
        try {
            const raw = await getDashboardData();
            this.openJobsCount = raw.openJobsCount || 0;
            this.totalApplications = raw.totalApplications || 0;
            this.shortlistedCount = raw.shortlistedCount || 0;
            this.interviewCount = raw.interviewCount || 0;
            this.hiredCount = raw.hiredCount || 0;

            this._rawJobsData = raw.jobs || [];
            if(this._rawJobsData.length > 0) {
                this.activeSections = [this._rawJobsData[0].jobId];
            }
            this.applyFilters();
        } catch (e) {
            this.error = e.body ? e.body.message : e.message;
        } finally {
            this.isLoading = false;
        }
    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase().trim();
        this.applyFilters();
    }

    applyFilters() {
        const searchStr = this.searchKey;
        
        let filtered = this._rawJobsData.map(job => {
            let apps = job.applications || [];
            
            if (searchStr) {
                apps = apps.filter(a => 
                    (a.applicantName && a.applicantName.toLowerCase().includes(searchStr)) ||
                    (a.applicantEmail && a.applicantEmail.toLowerCase().includes(searchStr))
                );
            }

            // Prep applications for Datatable
            let formattedApps = apps.map(app => {
                let colorClass = 'slds-text-color_default';
                if(app.status === 'Hired') colorClass = 'slds-text-color_success';
                else if(app.status === 'Rejected') colorClass = 'slds-text-color_error';
                else if(app.status === 'Shortlisted' || app.status === 'Exam') colorClass = 'slds-text-color_weak';
                else if(app.status === 'Interview') colorClass = 'slds-theme_shade slds-text-color_default';

                return {
                    ...app,
                    statusColorClass: colorClass
                };
            });

            return {
                ...job,
                applications: formattedApps,
                hasApps: formattedApps.length > 0,
                accordionLabel: `${job.jobName} - ${job.jobTitle} (${formattedApps.length} Applicants)`
            };
        });

        // If searching, only show jobs that have matching apps, OR whose title matches
        if (searchStr) {
            filtered = filtered.filter(job => {
                return job.applications.length > 0 || 
                       job.jobName.toLowerCase().includes(searchStr) || 
                       job.jobTitle.toLowerCase().includes(searchStr);
            });
            // Auto expand all when searching
            this.activeSections = filtered.map(j => j.jobId);
        }

        this.jobList = filtered;
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'view_profile') {
            this.selectedApp = row;
            this.isDetailModalOpen = true;
        } else {
            // Status Update Action
            this.isLoading = true;
            try {
                await updateApplicationStatus({ applicationId: row.applicationId, newStatus: actionName });
                this.toast('Success', `${row.applicantName} moved to ${actionName}`, 'success');
                await this.loadData(); // Re-fetch all data to ensure sync
            } catch (e) {
                this.toast('Error', e.body ? e.body.message : e.message, 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }

    closeDetailModal() {
        this.isDetailModalOpen = false;
        this.selectedApp = null;
    }

    // Modal Handling
    openPostModal() { this.isPostModalOpen = true; }
    closePostModal() { 
        this.isPostModalOpen = false; 
        this.newJob = { name: '', title: '', location: '', department: '', salary: '', experience: 0, description: '', lastDate: '', min10th: '', min12th: '', minCGPA: '' };
    }

    handleFieldChange(event) {
        const field = event.target.name;
        this.newJob[field] = event.target.value;
    }

    async submitJob() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (!isInputsCorrect) {
            this.toast('Validation Error', 'Please fill in all required fields with valid values.', 'warning');
            return;
        }
        this.isPosting = true;
        try {
            await postJob({
                jobName:     this.newJob.name,
                jobTitle:    this.newJob.title,
                location:    this.newJob.location,
                department:  this.newJob.department,
                description: this.newJob.description,
                salaryRange: this.newJob.salary,
                experience:  this.newJob.experience ? parseFloat(this.newJob.experience) : 0,
                lastDate:    this.newJob.lastDate || null,
                min10th:     this.newJob.min10th ? parseFloat(this.newJob.min10th) : null,
                min12th:     this.newJob.min12th ? parseFloat(this.newJob.min12th) : null,
                minCGPA:     this.newJob.minCGPA ? parseFloat(this.newJob.minCGPA) : null
            });
            this.toast('Success', `Job ${this.newJob.title} posted successfully!`, 'success');
            this.closePostModal();
            await this.loadData();
        } catch (e) {
            this.toast('Error Posting Job', e.body ? e.body.message : e.message, 'error');
        } finally {
            this.isPosting = false;
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
