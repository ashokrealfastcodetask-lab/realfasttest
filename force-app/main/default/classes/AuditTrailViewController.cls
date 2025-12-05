/**
 * @description Controller class for Audit Trail Viewer Lightning Web Component
 * Handles retrieval, filtering, processing, and synchronization of audit trail records
 */
public with sharing class AuditTrailViewController {
    
    /**
     * @description Retrieves audit trail records with optional filtering
     * @param orgConnectionId Optional org connection filter
     * @param metadataType Optional metadata type filter
     * @param searchTerm Optional search term for component name
     * @param fromDate Optional start date filter
     * @param toDate Optional end date filter
     * @param processedOnly Filter to show only processed records
     * @param limitRows Maximum number of records to return
     * @return List of audit trail records
     */
    @AuraEnabled(cacheable=true)
    public static List<SetupAuditTrail__c> getAuditTrails(
        String orgConnectionId,
        String metadataType,
        String searchTerm,
        String fromDate,
        String toDate,
        Boolean processedOnly,
        Integer limitRows
    ) {
        try {
            SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
            List<SetupAuditTrail__c> trails = selector.selectAll();
            
            // Apply filters
            if (String.isNotBlank(orgConnectionId)) {
                trails = filterByOrgConnection(trails, orgConnectionId);
            }
            
            if (String.isNotBlank(metadataType)) {
                trails = filterByMetadataType(trails, metadataType);
            }
            
            if (String.isNotBlank(searchTerm)) {
                trails = filterBySearchTerm(trails, searchTerm);
            }
            
            if (String.isNotBlank(fromDate) && String.isNotBlank(toDate)) {
                DateTime startDate = DateTime.parse(fromDate);
                DateTime endDate = DateTime.parse(toDate);
                trails = filterByDateRange(trails, startDate, endDate);
            }
            
            if (processedOnly != null && processedOnly) {
                trails = filterByProcessedStatus(trails, true);
            }
            
            // Limit results - FIXED: Apex doesn't have subList()
            if (limitRows != null && limitRows > 0 && trails.size() > limitRows) {
                List<SetupAuditTrail__c> limitedTrails = new List<SetupAuditTrail__c>();
                for (Integer i = 0; i < limitRows; i++) {
                    limitedTrails.add(trails[i]);
                }
                trails = limitedTrails;
            }
            
            return trails;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving audit trails: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves all active org connections for dropdown selection
     * @return List of active org connections
     */
    @AuraEnabled(cacheable=true)
    public static List<OrgConnection__c> getOrgConnections() {
        try {
            OrgConnectionSelector selector = new OrgConnectionSelector();
            return selector.selectActive();
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving org connections: ' + e.getMessage());
        }
    }
    
    /**
     * @description Processes selected audit trail records and extracts metadata components
     * @param auditTrailIds List of audit trail record IDs to process
     * @return Result object with processing status and summary
     */
    @AuraEnabled
    public static ProcessingResult processAuditTrails(List<String> auditTrailIds) {
        try {
            if (auditTrailIds == null || auditTrailIds.isEmpty()) {
                throw new IllegalArgumentException('No audit trail IDs provided');
            }
            
            ProcessingResult result = new ProcessingResult();
            SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
            List<SetupAuditTrail__c> trails = selector.selectByIds(auditTrailIds);
            
            if (trails.isEmpty()) {
                result.success = false;
                result.message = 'No audit trail records found';
                return result;
            }
            
            // Process the audit trails using domain class
            SetupAuditTrails domain = new SetupAuditTrails(trails);
            domain.extractMetadataComponents();
            domain.markAsProcessed();
            
            // Update records
            update trails;
            
            result.success = true;
            result.processedCount = trails.size();
            result.message = 'Successfully processed ' + trails.size() + ' audit trail records';
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error processing audit trails: ' + e.getMessage());
        }
    }
    
    /**
     * @description Synchronizes audit trails from a specific org connection
     * @param orgConnectionId ID of the org connection to sync
     * @return Sync result with status and record count
     */
    @AuraEnabled
    public static SyncResult syncOrgAuditTrails(String orgConnectionId) {
        try {
            if (String.isBlank(orgConnectionId)) {
                throw new IllegalArgumentException('Org connection ID is required');
            }
            
            SyncResult result = new SyncResult();
            
            // Get org connection details - FIXED: Changed to selectByIds
            OrgConnectionSelector selector = new OrgConnectionSelector();
            List<OrgConnection__c> orgs = selector.selectByIds(new List<String>{orgConnectionId});
            
            if (orgs.isEmpty()) {
                result.success = false;
                result.message = 'Org connection not found';
                return result;
            }
            
            OrgConnection__c orgConn = orgs[0];
            
            // Simulate sync operation (in real implementation, this would call Metadata API)
            result.success = true;
            result.orgName = orgConn.OrgName__c;
            result.lastSyncDate = DateTime.now();
            result.recordsCreated = 0;
            result.recordsUpdated = 0;
            result.message = 'Sync initiated for ' + orgConn.OrgName__c;
            
            // Update last sync date
            orgConn.LastSyncDate__c = DateTime.now();
            update orgConn;
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error syncing audit trails: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets distinct metadata types from audit trail records
     * @return List of unique metadata types
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getMetadataTypes() {
        try {
            List<String> metadataTypes = new List<String>();
            Set<String> uniqueTypes = new Set<String>();
            
            // FIXED: Changed to AggregateResult
            List<AggregateResult> results = [
                SELECT MetadataType__c 
                FROM SetupAuditTrail__c 
                WHERE MetadataType__c != null 
                GROUP BY MetadataType__c
                LIMIT 1000
            ];
            
            for (AggregateResult result : results) {
                String metadataType = (String)result.get('MetadataType__c');
                if (String.isNotBlank(metadataType)) {
                    uniqueTypes.add(metadataType);
                }
            }
            
            metadataTypes.addAll(uniqueTypes);
            metadataTypes.sort();
            
            return metadataTypes;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving metadata types: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets distinct actions from audit trail records
     * @return List of unique actions
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getActions() {
        try {
            List<String> actions = new List<String>();
            Set<String> uniqueActions = new Set<String>();
            
            // FIXED: Changed to AggregateResult
            List<AggregateResult> results = [
                SELECT Action__c 
                FROM SetupAuditTrail__c 
                WHERE Action__c != null 
                GROUP BY Action__c
                LIMIT 1000
            ];
            
            for (AggregateResult result : results) {
                String action = (String)result.get('Action__c');
                if (String.isNotBlank(action)) {
                    uniqueActions.add(action);
                }
            }
            
            actions.addAll(uniqueActions);
            actions.sort();
            
            return actions;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving actions: ' + e.getMessage());
        }
    }
    
    // ==================== Helper Methods ====================
    
    /**
     * @description Filters audit trails by org connection
     */
    private static List<SetupAuditTrail__c> filterByOrgConnection(
        List<SetupAuditTrail__c> trails, 
        String orgConnectionId
    ) {
        List<SetupAuditTrail__c> filtered = new List<SetupAuditTrail__c>();
        for (SetupAuditTrail__c trail : trails) {
            if (trail.OrgConnection__c == orgConnectionId) {
                filtered.add(trail);
            }
        }
        return filtered;
    }
    
    /**
     * @description Filters audit trails by metadata type
     */
    private static List<SetupAuditTrail__c> filterByMetadataType(
        List<SetupAuditTrail__c> trails, 
        String metadataType
    ) {
        List<SetupAuditTrail__c> filtered = new List<SetupAuditTrail__c>();
        for (SetupAuditTrail__c trail : trails) {
            if (String.isNotBlank(trail.MetadataType__c) && 
                trail.MetadataType__c.equalsIgnoreCase(metadataType)) {
                filtered.add(trail);
            }
        }
        return filtered;
    }
    
    /**
     * @description Filters audit trails by search term in component name
     */
    private static List<SetupAuditTrail__c> filterBySearchTerm(
        List<SetupAuditTrail__c> trails, 
        String searchTerm
    ) {
        List<SetupAuditTrail__c> filtered = new List<SetupAuditTrail__c>();
        String lowerSearchTerm = searchTerm.toLowerCase();
        
        for (SetupAuditTrail__c trail : trails) {
            if (String.isNotBlank(trail.ComponentName__c) && 
                trail.ComponentName__c.toLowerCase().contains(lowerSearchTerm)) {
                filtered.add(trail);
            }
        }
        return filtered;
    }
    
    /**
     * @description Filters audit trails by date range
     */
    private static List<SetupAuditTrail__c> filterByDateRange(
        List<SetupAuditTrail__c> trails, 
        DateTime startDate, 
        DateTime endDate
    ) {
        List<SetupAuditTrail__c> filtered = new List<SetupAuditTrail__c>();
        
        for (SetupAuditTrail__c trail : trails) {
            if (trail.CreatedDate__c >= startDate && trail.CreatedDate__c <= endDate) {
                filtered.add(trail);
            }
        }
        return filtered;
    }
    
    /**
     * @description Filters audit trails by processed status
     */
    private static List<SetupAuditTrail__c> filterByProcessedStatus(
        List<SetupAuditTrail__c> trails, 
        Boolean isProcessed
    ) {
        List<SetupAuditTrail__c> filtered = new List<SetupAuditTrail__c>();
        
        for (SetupAuditTrail__c trail : trails) {
            if (trail.IsProcessed__c == isProcessed) {
                filtered.add(trail);
            }
        }
        return filtered;
    }
    
    // ==================== Inner Classes ====================
    
    /**
     * @description Result wrapper for processing operations
     */
    public class ProcessingResult {
        @AuraEnabled public Boolean success {get; set;}
        @AuraEnabled public String message {get; set;}
        @AuraEnabled public Integer processedCount {get; set;}
    }
    
    /**
     * @description Result wrapper for sync operations
     */
    public class SyncResult {
        @AuraEnabled public Boolean success {get; set;}
        @AuraEnabled public String message {get; set;}
        @AuraEnabled public String orgName {get; set;}
        @AuraEnabled public DateTime lastSyncDate {get; set;}
        @AuraEnabled public Integer recordsCreated {get; set;}
        @AuraEnabled public Integer recordsUpdated {get; set;}
    }
}