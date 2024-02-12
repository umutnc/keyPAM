public with sharing class PamUserUtilQueueable implements Queueable{
    private String userId;
    public PamUserUtilQueueable(String userId) {
        this.userId = userId;
    }
    
    public void execute(QueueableContext context) {
    
    User userToUpdate = [SELECT Id, IsActive FROM User WHERE Id = :userId LIMIT 1];
            
        if (userToUpdate != null) {
            userToUpdate.IsActive = false;
            update userToUpdate;
        }

    List<PermissionSetAssignment> permissionSetAssignments = [SELECT Id, PermissionSetId, PermissionSet.Label, AssigneeId  
                                                                FROM PermissionSetAssignment WHERE AssigneeId = :userId 
                                                                AND PermissionSet.Label =:'Customer User Permissions' Limit 1];
    
        if (permissionSetAssignments!= null) {
            delete permissionSetAssignments;
        }
    }
}




   

    