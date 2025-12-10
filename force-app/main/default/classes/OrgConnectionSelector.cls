/**
 * @description Selector for OrgConnection__c object
 */
public class OrgConnectionSelector extends ApplicationSelector {
    
    public override Schema.SObjectType getSObjectType() {
        return OrgConnection__c.SObjectType;
    }
    
    public override List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            OrgConnection__c.Id,
            OrgConnection__c.Name,
            OrgConnection__c.OrgName__c,
            OrgConnection__c.OrgType__c,
            OrgConnection__c.InstanceURL__c,
            OrgConnection__c.IsActive__c,
            OrgConnection__c.NamedCredential__c,
            OrgConnection__c.LastSyncDate__c,
            OrgConnection__c.SyncFrequency__c
        };
    }
    
    
    /**
     * @description Select active org connections
     */
    public List<OrgConnection__c> selectActive() {
        String whereClause = 'IsActive__c = true';
        String query = buildQueryString(null, whereClause);
        return Database.query(query);
    }
    
    /**
     * @description Select orgs ready for sync based on frequency
     */
    public List<OrgConnection__c> selectReadyForSync() {
        String whereClause = 'IsActive__c = true AND ' +
                           '(LastSyncDate__c = null OR ' +
                           'LastSyncDate__c < LAST_N_HOURS:1)';
        return Database.query(buildQueryString(null, whereClause));
    }
    
    /**
     * @description Select org connections by list of IDs
     * @param orgConnectionIds List of org connection IDs
     * @return List of OrgConnection__c records
     */
    public List<OrgConnection__c> selectByIds(List<String> orgConnectionIds) {
        if (orgConnectionIds == null || orgConnectionIds.isEmpty()) {
            return new List<OrgConnection__c>();
        }
        
        Set<Id> idSet = new Set<Id>();
        for (String idStr : orgConnectionIds) {
            if (String.isNotBlank(idStr)) {
                idSet.add((Id)idStr);
            }
        }
        
        String whereClause = 'Id IN :idSet';
        String query = buildQueryString(null, whereClause);
        return Database.query(query);
    }
}