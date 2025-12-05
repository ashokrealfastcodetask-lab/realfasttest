/**
 * @description Controller class for Processing Log Viewer Lightning Web Component
 * Handles retrieval, filtering, and monitoring of processing logs with real-time updates
 */
public with sharing class ProcessingLogViewController {
    
    /**
     * @description Retrieves processing logs with optional filtering
     * @param orgConnectionId Optional org connection filter
     * @param processType Optional process type filter
     * @param logLevel Optional log level filter (DEBUG, INFO, WARN, ERROR, CRITICAL)
     * @param statusFilter Optional status filter (Success, Failed, In Progress)
     * @param fromDate Optional start date filter
     * @param toDate Optional end date filter
     * @param limitRows Maximum number of records to return
     * @return List of processing logs
     */
    @AuraEnabled(cacheable=true)
    public static List<ProcessingLog__c> getProcessingLogs(
        String orgConnectionId,
        String processType,
        String logLevel,
        String statusFilter,
        String fromDate,
        String toDate,
        Integer limitRows
    ) {
        try {
            String whereClause = 'WHERE 1=1';
            
            if (String.isNotBlank(orgConnectionId)) {
                whereClause += ' AND OrgConnection__c = \'' + String.escapeSingleQuotes(orgConnectionId) + '\'';
            }
            
            if (String.isNotBlank(processType)) {
                whereClause += ' AND ProcessType__c = \'' + String.escapeSingleQuotes(processType) + '\'';
            }
            
            if (String.isNotBlank(logLevel)) {
                whereClause += ' AND LogLevel__c = \'' + String.escapeSingleQuotes(logLevel) + '\'';
            }
            
            if (String.isNotBlank(statusFilter)) {
                whereClause += ' AND Status__c = \'' + String.escapeSingleQuotes(statusFilter) + '\'';
            }
            
            if (String.isNotBlank(fromDate) && String.isNotBlank(toDate)) {
                whereClause += ' AND CreatedDate >= ' + fromDate + ' AND CreatedDate <= ' + toDate;
            }
            
            String query = 'SELECT Id, Name, OrgConnection__c, ProcessType__c, LogLevel__c, ' +
                          'Status__c, LogMessage__c, DurationMilliseconds__c, CreatedDate, ' +
                          'SuccessRate__c, RetryCount__c, BatchJobId__c ' +
                          'FROM ProcessingLog__c ' + whereClause + 
                          ' ORDER BY CreatedDate DESC';
            
            if (limitRows != null && limitRows > 0) {
                query += ' LIMIT ' + limitRows;
            }
            
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving processing logs: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves distinct process types for filtering
     * @return List of unique process types
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getProcessTypes() {
        try {
            List<String> processTypes = new List<String>();
            Set<String> uniqueTypes = new Set<String>();
            
            List<ProcessingLog__c> logs = [
                SELECT ProcessType__c 
                FROM ProcessingLog__c 
                WHERE ProcessType__c != null 
                LIMIT 10000
            ];
            
            for (ProcessingLog__c log : logs) {
                uniqueTypes.add(log.ProcessType__c);
            }
            
            processTypes.addAll(uniqueTypes);
            processTypes.sort();
            
            return processTypes;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving process types: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves distinct log levels for filtering
     * @return List of available log levels
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getLogLevels() {
        return new List<String>{
            'DEBUG',
            'INFO',
            'WARN',
            'ERROR',
            'CRITICAL'
        };
    }
    
    /**
     * @description Retrieves distinct statuses for filtering
     * @return List of available statuses
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getStatuses() {
        return new List<String>{
            'Success',
            'Failed',
            'In Progress',
            'Queued',
            'Cancelled'
        };
    }
    
    /**
     * @description Gets processing log details by ID
     * @param logId ID of the processing log
     * @return Detailed processing log record
     */
    @AuraEnabled(cacheable=true)
    public static ProcessingLog__c getLogDetails(String logId) {
        try {
            return [
                SELECT Id, Name, OrgConnection__c, ProcessType__c, LogLevel__c, Status__c,
                       LogMessage__c, DurationMilliseconds__c, SuccessRate__c, RetryCount__c,
                       CreatedDate, LastModifiedDate, BatchJobId__c,
                       StackTrace__c
                FROM ProcessingLog__c
                WHERE Id = :logId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving log details: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets summary statistics for processing logs
     * @param fromDate Optional start date for statistics
     * @param toDate Optional end date for statistics
     * @return Statistics wrapper with counts and metrics
     */
    @AuraEnabled(cacheable=true)
    public static LogStatistics getLogStatistics(String fromDate, String toDate) {
        try {
            LogStatistics stats = new LogStatistics();
            
            String whereClause = '';
            if (String.isNotBlank(fromDate) && String.isNotBlank(toDate)) {
                whereClause = ' WHERE CreatedDate >= ' + fromDate + ' AND CreatedDate <= ' + toDate;
            }
            
            // Get total count
            AggregateResult totalResult = Database.query(
                'SELECT COUNT() cnt FROM ProcessingLog__c' + whereClause
            );
            stats.totalLogs = (Integer)totalResult.get('cnt');
            
            // Get success/failure counts
            List<AggregateResult> statusResults = Database.query(
                'SELECT Status__c, COUNT() cnt FROM ProcessingLog__c' + whereClause + 
                ' GROUP BY Status__c'
            );
            
            for (AggregateResult result : statusResults) {
                String status = (String)result.get('Status__c');
                Integer count = (Integer)result.get('cnt');
                
                if (status == 'Success') {
                    stats.successCount = count;
                } else if (status == 'Failed') {
                    stats.failureCount = count;
                } else if (status == 'In Progress') {
                    stats.inProgressCount = count;
                }
            }
            
            // Get average duration
            List<AggregateResult> durationResults = Database.query(
                'SELECT AVG(DurationMilliseconds__c) avgDuration FROM ProcessingLog__c' + whereClause
            );
            
            if (!durationResults.isEmpty()) {
                stats.averageDuration = (Integer)durationResults[0].get('avgDuration');
            }
            
            // Get average success rate
            List<AggregateResult> successRateResults = Database.query(
                'SELECT AVG(SuccessRate__c) avgRate FROM ProcessingLog__c' + whereClause
            );
            
            if (!successRateResults.isEmpty()) {
                stats.averageSuccessRate = (Decimal)successRateResults[0].get('avgRate');
            }
            
            return stats;
        } catch (Exception e) {
            throw new AuraHandledException('Error calculating statistics: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retries a failed processing log
     * @param logId ID of the log to retry
     * @return Retry result
     */
    @AuraEnabled
    public static RetryResult retryProcessingLog(String logId) {
        try {
            RetryResult result = new RetryResult();
            
            ProcessingLog__c log = [
                SELECT Id, RetryCount__c, Status__c, ProcessType__c
                FROM ProcessingLog__c
                WHERE Id = :logId
                LIMIT 1
            ];
            
            if (log.Status__c != 'Failed') {
                result.success = false;
                result.message = 'Only failed logs can be retried';
                return result;
            }
            
            // Update retry count
            log.RetryCount__c = (log.RetryCount__c != null ? log.RetryCount__c : 0) + 1;
            log.Status__c = 'Queued';
            
            update log;
            
            result.success = true;
            result.message = 'Retry scheduled for log: ' + log.Id;
            result.newRetryCount = (Integer)log.RetryCount__c;
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrying log: ' + e.getMessage());
        }
    }
    
    /**
     * @description Exports processing logs to CSV format
     * @param logIds List of log IDs to export
     * @return CSV content as string
     */
    @AuraEnabled
    public static String exportLogsToCSV(List<String> logIds) {
        try {
            if (logIds == null || logIds.isEmpty()) {
                throw new IllegalArgumentException('No logs selected for export');
            }
            
            List<ProcessingLog__c> logs = [
                SELECT Id, Name, ProcessType__c, LogLevel__c, Status__c, LogMessage__c,
                       DurationMilliseconds__c, CreatedDate, SuccessRate__c, RetryCount__c
                FROM ProcessingLog__c
                WHERE Id IN :logIds
                ORDER BY CreatedDate DESC
            ];
            
            String csvContent = '';
            
            // Add header
            csvContent += 'Log ID,Name,Process Type,Log Level,Status,Message,';
            csvContent += 'Duration (ms),Created Date,Success Rate,Retry Count\n';
            
            // Add data rows
            for (ProcessingLog__c log : logs) {
                csvContent += '"' + log.Id + '",';
                csvContent += '"' + escapeCsvField(log.Name) + '",';
                csvContent += '"' + (log.ProcessType__c != null ? log.ProcessType__c : '') + '",';
                csvContent += '"' + (log.LogLevel__c != null ? log.LogLevel__c : '') + '",';
                csvContent += '"' + (log.Status__c != null ? log.Status__c : '') + '",';
                csvContent += '"' + escapeCsvField(log.LogMessage__c) + '",';
                csvContent += (log.DurationMilliseconds__c != null ? String.valueOf(log.DurationMilliseconds__c) : '0') + ',';
                csvContent += '"' + log.CreatedDate.format() + '",';
                csvContent += (log.SuccessRate__c != null ? String.valueOf(log.SuccessRate__c) : '0') + ',';
                csvContent += (log.RetryCount__c != null ? String.valueOf(log.RetryCount__c) : '0') + '\n';
            }
            
            return csvContent;
        } catch (Exception e) {
            throw new AuraHandledException('Error exporting logs: ' + e.getMessage());
        }
    }
    
    /**
     * @description Helper method to escape CSV field values
     * @param fieldValue The field value to escape
     * @return Escaped field value
     */
    private static String escapeCsvField(String fieldValue) {
        if (fieldValue == null) {
            return '';
        }
        // Replace double quotes with two double quotes for CSV escaping
        return fieldValue.replace('"', '""');
    }
    
    // ==================== Inner Classes ====================
    
    /**
     * @description Wrapper for log statistics
     */
    public class LogStatistics {
        @AuraEnabled public Integer totalLogs {get; set;}
        @AuraEnabled public Integer successCount {get; set;}
        @AuraEnabled public Integer failureCount {get; set;}
        @AuraEnabled public Integer inProgressCount {get; set;}
        @AuraEnabled public Integer averageDuration {get; set;}
        @AuraEnabled public Decimal averageSuccessRate {get; set;}
    }
    
    /**
     * @description Wrapper for retry result
     */
    public class RetryResult {
        @AuraEnabled public Boolean success {get; set;}
        @AuraEnabled public String message {get; set;}
        @AuraEnabled public Integer newRetryCount {get; set;}
    }
}