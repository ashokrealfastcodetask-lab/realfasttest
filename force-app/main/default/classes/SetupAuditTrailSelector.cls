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
     * @description Select all audit trail records (with default limit for safety)
     * @return List of all SetupAuditTrail__c records
     */
    public List<SetupAuditTrail__c> selectAll() {
        return selectAll(10000); // Default limit to prevent governor issues
    }
    
    /**
     * @description Select all audit trail records with custom limit
     * @param limitRows Maximum number of records to return
     * @return List of SetupAuditTrail__c records
     */
    public List<SetupAuditTrail__c> selectAll(Integer limitRows) {
        String query = buildQueryString(null, null);
        
        if (limitRows != null && limitRows > 0) {
            query += ' LIMIT ' + limitRows;
        }
        
        return Database.query(query);
    }
    
    /**
     * @description Select all audit trail records ordered by created date
     * @param limitRows Maximum number of records to return
     * @return List of SetupAuditTrail__c records ordered by CreatedDate__c DESC
     */
    public List<SetupAuditTrail__c> selectAllOrderByDate(Integer limitRows) {
        String query = buildQueryString(null, null) + ' ORDER BY CreatedDate__c DESC';
        
        if (limitRows != null && limitRows > 0) {
            query += ' LIMIT ' + limitRows;
        }
        
        return Database.query(query);
    }
    
    /**
     * @description Select audit trails by list of IDs
     * @param auditTrailIds List of audit trail IDs
     * @return List of SetupAuditTrail__c records
     */
    public List<SetupAuditTrail__c> selectByIds(List<String> auditTrailIds) {
        if (auditTrailIds == null || auditTrailIds.isEmpty()) {
            return new List<SetupAuditTrail__c>();
        }
        
        Set<Id> idSet = new Set<Id>();
        for (String idStr : auditTrailIds) {
            if (String.isNotBlank(idStr)) {
                idSet.add((Id)idStr);
            }
        }
        
        String whereClause = 'Id IN :idSet';
        String query = buildQueryString(null, whereClause);
        return Database.query(query);
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