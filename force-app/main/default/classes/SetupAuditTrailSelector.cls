/**
 * @description Selector for SetupAuditTrail__c object
 * Handles all SOQL queries for audit trail records
 */
public class SetupAuditTrailSelector extends ApplicationSelector {
    
    public override Schema.SObjectType getSObjectType() {
        return SetupAuditTrail__c.SObjectType;
    }
    
    public override List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            SetupAuditTrail__c.Id,
            SetupAuditTrail__c.Name,
            SetupAuditTrail__c.Action__c,
            SetupAuditTrail__c.Section__c,
            SetupAuditTrail__c.CreatedById__c,
            SetupAuditTrail__c.CreatedByName__c,
            SetupAuditTrail__c.CreatedDate__c,
            SetupAuditTrail__c.Display__c,
            SetupAuditTrail__c.OrgConnection__c,
            SetupAuditTrail__c.MetadataType__c,
            SetupAuditTrail__c.ComponentName__c,
            SetupAuditTrail__c.IsProcessed__c
        };
    }
    
    /**
     * @description Select audit trails by date range
     */
    public List<SetupAuditTrail__c> selectByDateRange(DateTime startDate, DateTime endDate, Id orgConnectionId) {
        String whereClause = 'CreatedDate__c >= :startDate AND CreatedDate__c <= :endDate';
        
        if (orgConnectionId != null) {
            whereClause += ' AND OrgConnection__c = :orgConnectionId';
        }
        
        String query = buildQueryString(null, whereClause);
        return Database.query(query);
    }
    
    /**
     * @description Select unprocessed audit trails for component analysis
     */
    public List<SetupAuditTrail__c> selectUnprocessed(Integer limitRows) {
        String whereClause = 'IsProcessed__c = false';
        String query = buildQueryString(null, whereClause);
        
        if (limitRows != null && limitRows > 0) {
            query += ' LIMIT ' + limitRows;
        }
        
        return Database.query(query);
    }
    
    /**
     * @description Select audit trails by metadata type for analysis
     */
    public List<SetupAuditTrail__c> selectByMetadataType(String metadataType, Id orgConnectionId) {
        String whereClause = 'MetadataType__c = :metadataType';
        
        if (orgConnectionId != null) {
            whereClause += ' AND OrgConnection__c = :orgConnectionId';
        }
        
        String query = buildQueryString(null, whereClause);
        return Database.query(query);
    }
    
    /**
     * @description Get audit trail counts by org for dashboard
     */
    public Map<Id, Integer> getCountByOrg() {
        Map<Id, Integer> countMap = new Map<Id, Integer>();
        
        for (AggregateResult ar : [
            SELECT OrgConnection__c orgId, COUNT(Id) cnt
            FROM SetupAuditTrail__c
            GROUP BY OrgConnection__c
        ]) {
            countMap.put((Id)ar.get('orgId'), (Integer)ar.get('cnt'));
        }
        
        return countMap;
    }
}