/**
 * @description Controller for Audit Trail Viewer LWC component
 * Handles fetching and processing setup audit trails
 */
public with sharing class AuditTrailViewController {
    
    /**
     * @description Get all org connections
     * @return List of OrgConnection__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<OrgConnection__c> getOrgConnections() {
        try {
            return [
                SELECT Id, OrgName__c, OrgType__c, IsActive__c
                FROM OrgConnection__c
                WHERE IsActive__c = true
                ORDER BY OrgName__c
                LIMIT 1000
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching org connections: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get audit trails with optional filtering
     * @param orgConnectionId Filter by org connection
     * @param action Filter by action
     * @param metadataType Filter by metadata type
     * @param searchTerm Search in display field
     * @param dateFrom Filter from date
     * @param dateTo Filter to date
     * @param processedOnly Show only processed records
     * @return List of SetupAuditTrail__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<SetupAuditTrail__c> getAuditTrails(
        String orgConnectionId,
        String action,
        String metadataType,
        String searchTerm,
        String dateFrom,
        String dateTo,
        Boolean processedOnly
    ) {
        try {
            String query = 'SELECT Id, CreatedDate__c, Action__c, Section__c, ComponentName__c, MetadataType__c, Display__c, CreatedByName__c, IsProcessed__c, OrgConnection__c, OrgConnection__r.OrgName__c FROM SetupAuditTrail__c';
            List<String> whereConditions = new List<String>();
            
            if (String.isNotBlank(orgConnectionId)) {
                whereConditions.add('OrgConnection__c = \'' + String.escapeSingleQuotes(orgConnectionId) + '\'');
            }
            
            if (String.isNotBlank(action)) {
                whereConditions.add('Action__c = \'' + String.escapeSingleQuotes(action) + '\'');
            }
            
            if (String.isNotBlank(metadataType)) {
                whereConditions.add('MetadataType__c = \'' + String.escapeSingleQuotes(metadataType) + '\'');
            }
            
            if (String.isNotBlank(searchTerm)) {
                String escapedSearch = '%' + String.escapeSingleQuotes(searchTerm) + '%';
                whereConditions.add('Display__c LIKE \'' + escapedSearch + '\'');
            }
            
            if (processedOnly != null && processedOnly) {
                whereConditions.add('IsProcessed__c = true');
            }
            
            if (whereConditions.size() > 0) {
                query += ' WHERE ' + String.join(whereConditions, ' AND ');
            }
            
            query += ' ORDER BY CreatedDate__c DESC LIMIT 10000';
            System.debug('Query: ' + query);
            List<SetupAuditTrail__c> results = Database.query(query);
            System.debug('Results count: ' + results.size());
            return results;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' StackTrace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error fetching audit trails: ' + e.getMessage());
        }
    }
    
    
    /**
     * @description Process selected audit trails
     * @param auditTrailIds List of audit trail IDs to process
     * @return Number of records processed
     */
    @AuraEnabled
    public static Integer processAuditTrails(List<String> auditTrailIds) {
        try {
            List<SetupAuditTrail__c> trails = [
                SELECT Id, IsProcessed__c, Action__c, Section__c, Display__c
                FROM SetupAuditTrail__c
                WHERE Id IN :auditTrailIds
            ];
            
            SetupAuditTrails auditTrailsDomain = new SetupAuditTrails(trails);
            auditTrailsDomain.markAsProcessed();
            auditTrailsDomain.extractMetadataComponents();
            
            update trails;
            return trails.size();
        } catch (Exception e) {
            throw new AuraHandledException('Error processing audit trails: ' + e.getMessage());
        }
    }
    
    /**
     * @description Sync audit trails from specified org
     * @param orgConnectionId The org connection to sync from
     * @return Number of records synced
     */
    @AuraEnabled
    public static Integer syncOrgAuditTrails(String orgConnectionId) {
        try {
            OrgConnection__c org = [
                SELECT Id, OrgName__c
                FROM OrgConnection__c
                WHERE Id = :orgConnectionId
                LIMIT 1
            ];
            
            List<SetupAuditTrail__c> trails = [
                SELECT Id, Action__c, Section__c, Display__c, CreatedDate__c, CreatedByName__c
                FROM SetupAuditTrail__c
                WHERE OrgConnection__c = :orgConnectionId
                ORDER BY CreatedDate__c DESC
                LIMIT 10000
            ];
            
            SetupAuditTrails auditTrailsDomain = new SetupAuditTrails(trails);
            auditTrailsDomain.extractMetadataComponents();
            
            update trails;
            return trails.size();
        } catch (Exception e) {
            throw new AuraHandledException('Error syncing org audit trails: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get metadata types
     * @return List of metadata types
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getMetadataTypes() {
        try {
            Set<String> types = new Set<String>();
            for (AggregateResult ar : [
                SELECT MetadataType__c FROM SetupAuditTrail__c 
                WHERE MetadataType__c != null 
                GROUP BY MetadataType__c LIMIT 100
            ]) {
                types.add((String) ar.get('MetadataType__c'));
            }
            return new List<String>(types);
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching metadata types: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get actions
     * @return List of actions
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getActions() {
        return new List<String>{'created', 'changed', 'deleted', 'activated', 'deactivated'};
    }
}