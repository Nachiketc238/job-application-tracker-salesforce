List<String> fields = new List<String>{ 
    'Job__c.Status__c', 
    'Job__c.Last_Date_to_Apply__c', 
    'Applicant_Name__c.Resume_Link__c', 
    'Applicant_Name__c.Skills__c', 
    'Applicant_Name__c.Experience_Years__c', 
    'Applicant_Name__c.LinkedIn_Link__c', 
    'Applicant_Name__c.Portfolio_GitHub__c', 
    'Applicant_Name__c.Current_Location__c', 
    'Application__c.Upload_Resume_Link__c' 
}; 
List<FieldPermissions> newPerms = new List<FieldPermissions>(); 
for(PermissionSet ps : [SELECT Id FROM PermissionSet WHERE IsOwnedByProfile = true]) { 
    for(String f : fields) { 
        newPerms.add(new FieldPermissions(
            ParentId = ps.Id, 
            SobjectType = f.split('\\.')[0], 
            Field = f, 
            PermissionsEdit = true, 
            PermissionsRead = true
        )); 
    } 
} 
Database.insert(newPerms, false);
