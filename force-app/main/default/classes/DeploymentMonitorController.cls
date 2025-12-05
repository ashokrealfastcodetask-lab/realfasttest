/**
 * @description Controller class for Deployment Monitor Lightning Web Component
 * Handles real-time monitoring of deployment status, progress tracking, and deployment history
 */
public with sharing class DeploymentMonitorController {
    
    /**
     * @description Retrieves deployment history records with filtering
     * @param statusFilter Filter by deployment status
     * @param orgConnectionId Optional org connection filter
     * @param fromDate Optional start date filter
     * @param toDate Optional end date filter
     * @param limitRows Maximum number of records to return
     * @return List of deployment history records
     */
    @AuraEnabled(cacheable=true)
    public static List<DeploymentHistory__c> getDeploymentHistory(
        String statusFilter,
        String orgConnectionId,
        String fromDate,
        String toDate,
        Integer limitRows
    ) {
        try {
            String whereClause = 'WHERE 1=1';
            
            if (String.isNotBlank(statusFilter)) {
                whereClause += ' AND DeploymentStatus__c = \'' + String.escapeSingleQuotes(statusFilter) + '\'';
            }
            
            if (String.isNotBlank(orgConnectionId)) {
                whereClause += ' AND TargetOrg__c = \'' + String.escapeSingleQuotes(orgConnectionId) + '\'';
            }
            
            if (String.isNotBlank(fromDate) && String.isNotBlank(toDate)) {
                whereClause += ' AND CreatedDate >= ' + fromDate + ' AND CreatedDate <= ' + toDate;
            }
            
            String query = 'SELECT Id, Name, DeploymentPackage__c, SourceOrg__c, TargetOrg__c, ' +
                          'DeploymentStatus__c, ' +
                          'RunTests__c, TestsExecuted__c, TestsPassed__c, TestsFailed__c, ' +
                          'CreatedDate, LastModifiedDate ' +
                          'FROM DeploymentHistory__c ' + whereClause + 
                          ' ORDER BY CreatedDate DESC';
            
            if (limitRows != null && limitRows > 0) {
                query += ' LIMIT ' + limitRows;
            }
            
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving deployment history: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets detailed information about a specific deployment
     * @param deploymentId ID of the deployment history record
     * @return Detailed deployment information
     */
    @AuraEnabled(cacheable=true)
    public static DeploymentDetail getDeploymentDetail(String deploymentId) {
        try {
            DeploymentHistory__c history = [
                SELECT Id, Name, DeploymentPackage__c, DeploymentPackage__r.Name,
                       SourceOrg__c, SourceOrg__r.OrgName__c, TargetOrg__c, TargetOrg__r.OrgName__c,
                       DeploymentStatus__c, CreatedDate, CreatedBy.Name,
                       RunTests__c, TestsExecuted__c, TestsPassed__c,
                       TestsFailed__c
                FROM DeploymentHistory__c
                WHERE Id = :deploymentId
                LIMIT 1
            ];
            
            DeploymentDetail detail = new DeploymentDetail();
            detail.deploymentId = history.Id;
            detail.name = history.Name;
            detail.packageName = history.DeploymentPackage__r.Name;
            detail.sourceOrgName = history.SourceOrg__r?.OrgName__c;
            detail.targetOrgName = history.TargetOrg__r.OrgName__c;
            detail.status = history.DeploymentStatus__c;
            detail.requestedBy = history.CreatedBy.Name;
            detail.createdDate = history.CreatedDate;
            detail.runTests = history.RunTests__c;
            detail.testsExecuted = (Integer)history.TestsExecuted__c;
            detail.testsPassed = (Integer)history.TestsPassed__c;
            detail.testsFailed = (Integer)history.TestsFailed__c;
            
            return detail;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving deployment detail: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets components associated with a deployment
     * @param deploymentId ID of the deployment history record
     * @return List of deployment components
     */
    @AuraEnabled(cacheable=true)
    public static List<ComponentStatus> getDeploymentComponents(String deploymentId) {
        try {
            List<ComponentStatus> components = new List<ComponentStatus>();
            
            // Get the deployment package ID from history
            DeploymentHistory__c history = [
                SELECT DeploymentPackage__c
                FROM DeploymentHistory__c
                WHERE Id = :deploymentId
                LIMIT 1
            ];
            
            List<PackageComponent__c> pkgComponents = [
                SELECT Id, ComponentName__c, MetadataType__c, DeploymentStatus__c
                FROM PackageComponent__c
                WHERE DeploymentPackage__c = :history.DeploymentPackage__c
                ORDER BY ComponentName__c
            ];
            
            Integer sequence = 1;
            for (PackageComponent__c comp : pkgComponents) {
                ComponentStatus compStatus = new ComponentStatus();
                compStatus.componentId = comp.Id;
                compStatus.name = comp.ComponentName__c;
                compStatus.type = comp.MetadataType__c;
                compStatus.displayName = comp.ComponentName__c; // Using ComponentName as display name
                compStatus.status = comp.DeploymentStatus__c;
                compStatus.sequence = sequence++;
                
                components.add(compStatus);
            }
            
            return components;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving deployment components: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets deployment status options for filtering
     * @return List of available deployment statuses
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getDeploymentStatuses() {
        return new List<String>{
            'Queued',
            'In Progress',
            'Succeeded',
            'Failed',
            'Canceled'
        };
    }
    
    /**
     * @description Cancels an in-progress deployment
     * @param deploymentId ID of the deployment to cancel
     * @return Result of cancellation
     */
    @AuraEnabled
    public static CancelResult cancelDeployment(String deploymentId) {
        try {
            CancelResult result = new CancelResult();
            
            DeploymentHistory__c history = [
                SELECT Id, DeploymentStatus__c
                FROM DeploymentHistory__c
                WHERE Id = :deploymentId
                LIMIT 1
            ];
            
            if (history.DeploymentStatus__c != 'In Progress') {
                result.success = false;
                result.message = 'Only in-progress deployments can be cancelled';
                return result;
            }
            
            history.DeploymentStatus__c = 'Canceled';
            
            update history;
            
            result.success = true;
            result.message = 'Deployment cancelled successfully';
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error cancelling deployment: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retries a failed deployment
     * @param deploymentId ID of the deployment to retry
     * @return Result of retry initiation
     */
    @AuraEnabled
    public static RetryDeploymentResult retryDeployment(String deploymentId) {
        try {
            RetryDeploymentResult result = new RetryDeploymentResult();
            
            DeploymentHistory__c history = [
                SELECT Id, DeploymentStatus__c, DeploymentPackage__c
                FROM DeploymentHistory__c
                WHERE Id = :deploymentId
                LIMIT 1
            ];
            
            if (history.DeploymentStatus__c != 'Failed') {
                result.success = false;
                result.message = 'Only failed deployments can be retried';
                return result;
            }
            
            // Create new deployment history record for retry
            DeploymentHistory__c newHistory = new DeploymentHistory__c();
            newHistory.DeploymentPackage__c = history.DeploymentPackage__c;
            newHistory.DeploymentStatus__c = 'Queued';
            
            insert newHistory;
            
            result.success = true;
            result.message = 'Deployment retry initiated';
            result.newDeploymentId = newHistory.Id;
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrying deployment: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets deployment metrics and summary statistics
     * @param fromDate Optional start date filter
     * @param toDate Optional end date filter
     * @return Deployment metrics wrapper
     */
    @AuraEnabled(cacheable=true)
    public static DeploymentMetrics getDeploymentMetrics(String fromDate, String toDate) {
        try {
            DeploymentMetrics metrics = new DeploymentMetrics();
            
            String whereClause = '';
            if (String.isNotBlank(fromDate) && String.isNotBlank(toDate)) {
                whereClause = ' WHERE CreatedDate >= ' + fromDate + ' AND CreatedDate <= ' + toDate;
            }
            
            // Get total deployments
            AggregateResult totalResult = Database.query(
                'SELECT COUNT() cnt FROM DeploymentHistory__c' + whereClause
            );
            metrics.totalDeployments = (Integer)totalResult.get('cnt');
            
            // Get deployment status breakdown
            List<AggregateResult> statusResults = Database.query(
                'SELECT DeploymentStatus__c, COUNT() cnt FROM DeploymentHistory__c' + whereClause +
                ' GROUP BY DeploymentStatus__c'
            );
            
            for (AggregateResult result : statusResults) {
                String status = (String)result.get('DeploymentStatus__c');
                Integer count = (Integer)result.get('cnt');
                
                if (status == 'Succeeded') {
                    metrics.successfulDeployments = count;
                } else if (status == 'Failed') {
                    metrics.failedDeployments = count;
                } else if (status == 'In Progress') {
                    metrics.inProgressDeployments = count;
                }
            }
            
            // Calculate success rate
            if (metrics.totalDeployments > 0) {
                metrics.successRate = (Decimal)metrics.successfulDeployments / metrics.totalDeployments * 100;
            }
            
            return metrics;
        } catch (Exception e) {
            throw new AuraHandledException('Error calculating deployment metrics: ' + e.getMessage());
        }
    }
    
    /**
     * @description Polls for deployment status updates
     * @param deploymentId ID of the deployment to poll
     * @return Updated deployment information
     */
    @AuraEnabled(cacheable=false)
    public static DeploymentStatusUpdate pollDeploymentStatus(String deploymentId) {
        try {
            DeploymentHistory__c history = [
                SELECT Id, DeploymentStatus__c, TestsExecuted__c, TestsPassed__c, TestsFailed__c
                FROM DeploymentHistory__c
                WHERE Id = :deploymentId
                LIMIT 1
            ];
            
            DeploymentStatusUpdate statusUpdate = new DeploymentStatusUpdate();
            statusUpdate.deploymentId = history.Id;
            statusUpdate.status = history.DeploymentStatus__c;
            statusUpdate.testsExecuted = (Integer)history.TestsExecuted__c;
            statusUpdate.testsPassed = (Integer)history.TestsPassed__c;
            statusUpdate.testsFailed = (Integer)history.TestsFailed__c;
            statusUpdate.timestamp = DateTime.now();
            
            return statusUpdate;
        } catch (Exception e) {
            throw new AuraHandledException('Error polling deployment status: ' + e.getMessage());
        }
    }
    
    // ==================== Inner Classes ====================
    
    /**
     * @description Wrapper for detailed deployment information
     */
    public class DeploymentDetail {
        @AuraEnabled public String deploymentId {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String packageName {get; set;}
        @AuraEnabled public String sourceOrgName {get; set;}
        @AuraEnabled public String targetOrgName {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public String requestedBy {get; set;}
        @AuraEnabled public DateTime createdDate {get; set;}
        @AuraEnabled public Boolean runTests {get; set;}
        @AuraEnabled public Integer testsExecuted {get; set;}
        @AuraEnabled public Integer testsPassed {get; set;}
        @AuraEnabled public Integer testsFailed {get; set;}
    }
    
    /**
     * @description Wrapper for component deployment status
     */
    public class ComponentStatus {
        @AuraEnabled public String componentId {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String type {get; set;}
        @AuraEnabled public String displayName {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public Integer sequence {get; set;}
    }
    
    /**
     * @description Wrapper for deployment cancellation result
     */
    public class CancelResult {
        @AuraEnabled public Boolean success {get; set;}
        @AuraEnabled public String message {get; set;}
    }
    
    /**
     * @description Wrapper for deployment retry result
     */
    public class RetryDeploymentResult {
        @AuraEnabled public Boolean success {get; set;}
        @AuraEnabled public String message {get; set;}
        @AuraEnabled public String newDeploymentId {get; set;}
    }
    
    /**
     * @description Wrapper for deployment metrics
     */
    public class DeploymentMetrics {
        @AuraEnabled public Integer totalDeployments {get; set;}
        @AuraEnabled public Integer successfulDeployments {get; set;}
        @AuraEnabled public Integer failedDeployments {get; set;}
        @AuraEnabled public Integer inProgressDeployments {get; set;}
        @AuraEnabled public Decimal successRate {get; set;}
        @AuraEnabled public Integer avgComponentsDeployed {get; set;}
    }
    
    /**
     * @description Wrapper for deployment status poll results
     */
    public class DeploymentStatusUpdate {
        @AuraEnabled public String deploymentId {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public Integer testsExecuted {get; set;}
        @AuraEnabled public Integer testsPassed {get; set;}
        @AuraEnabled public Integer testsFailed {get; set;}
        @AuraEnabled public DateTime timestamp {get; set;}
    }
}