/**
 * Invokes the GrantAccessEndpoint and RevokeAccessEndpoint methods on the nCino nPORTAL PortalAccessController class.
 * @params ContextId - An account, loan or a deposit id, ContactId - the contact id of the user to grant or revoke access to.
 */
public with sharing class PamInvokenPortal {
public static String result;

    public static String grantAccess(id ContextId , id ContactId){
       
        try {

            Map<String, Object> params = New Map<String,Object>();
            params.put('contextObjectId', ContextId );
            params.put('contactId', ContactId);
             //array of string for the result       
            Object obj = nFORCE.RemoteActionController.invoke('nPortal.PortalAccessController.GrantAccessEndpoint', params);
        } catch (Exception e) {
            result = e.getMessage();
        }
        return result;
    }
    
    public static String revokeAccess(id ContextId , id ContactId){
        
        try {

            Map<String, Object> params = New Map<String,Object>();
            params.put('contextObjectId', ContextId);
            params.put('contactId', ContactId);    
            result = (String) nFORCE.RemoteActionController.invoke('nPortal.PortalAccessController.RevokeAccessEndpoint', params);
        }catch (Exception e) {
            result = e.getMessage();
        }
        return result;
    }
}