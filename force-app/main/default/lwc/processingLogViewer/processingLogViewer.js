import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProcessingLogs from '@salesforce/apex/ProcessingLogViewController.getProcessingLogs';
import getProcessTypes from '@salesforce/apex/ProcessingLogViewController.getProcessTypes';
import getLogLevels from '@salesforce/apex/ProcessingLogViewController.getLogLevels';
import getStatuses from '@salesforce/apex/ProcessingLogViewController.getStatuses';
import getLogStatistics from '@salesforce/apex/ProcessingLogViewController.getLogStatistics';
import retryProcessingLog from '@salesforce/apex/ProcessingLogViewController.retryProcessingLog';
import exportLogsToCSV from '@salesforce/apex/ProcessingLogViewController.exportLogsToCSV';

export default class ProcessingLogViewer extends LightningElement {
    @track processingLogs = [];
    @track isLoading = false;
    @track error = '';
    @track showFilters = false;
    
    // Filter properties
    @track selectedOrgId = '';
    @track selectedProcessType = '';
    @track selectedLogLevel = '';
    @track selectedStatus = '';
    @track dateFrom = '';
    @track dateTo = '';
    @track pageSize = 50;
    
    // Statistics
    @track statistics = {};
    
    // Lookup options
    @track processTypes = [];
    @track logLevels = [];
    @track statuses = [];
    
    // Selection
    @track selectedRows = [];
    
    wiredLogsResult;
    wiredStatsResult;
    
    // Column definitions
    columns = [
        { 
            label: 'Log ID', 
            fieldName: 'Id', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Name', 
            fieldName: 'Name', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Process Type', 
            fieldName: 'ProcessType__c', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Log Level', 
            fieldName: 'LogLevel__c', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Status', 
            fieldName: 'Status__c', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Message', 
            fieldName: 'Message__c', 
            type: 'text'
        },
        { 
            label: 'Duration (ms)', 
            fieldName: 'DurationMilliseconds__c', 
            type: 'number',
            sortable: true
        },
        { 
            label: 'Success Rate', 
            fieldName: 'SuccessRate__c', 
            type: 'percent',
            sortable: true
        },
        { 
            label: 'Created Date', 
            fieldName: 'CreatedDate', 
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'short',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit'
            },
            sortable: true
        }
    ];
    
    // Get processing logs
    @wire(getProcessingLogs, {
        orgConnectionId: '$selectedOrgId',
        processType: '$selectedProcessType',
        logLevel: '$selectedLogLevel',
        statusFilter: '$selectedStatus',
        fromDate: '$dateFrom',
        toDate: '$dateTo',
        limitRows: '$pageSize'
    })
    wiredLogs(result) {
        this.wiredLogsResult = result;
        if (result.data) {
            this.processingLogs = result.data;
            this.error = '';
        } else if (result.error) {
            this.error = result.error.body.message;
            this.showError('Error', this.error);
        }
    }
    
    // Get statistics
    @wire(getLogStatistics, {
        fromDate: '$dateFrom',
        toDate: '$dateTo'
    })
    wiredStats(result) {
        this.wiredStatsResult = result;
        if (result.data) {
            this.statistics = result.data;
        }
    }
    
    // Get process types
    @wire(getProcessTypes)
    wiredProcessTypes({ error, data }) {
        if (data) {
            this.processTypes = data.map(type => ({
                label: type,
                value: type
            }));
        } else if (error) {
            this.showError('Error', error.body.message);
        }
    }
    
    // Get log levels
    @wire(getLogLevels)
    wiredLogLevels({ error, data }) {
        if (data) {
            this.logLevels = data.map(level => ({
                label: level,
                value: level
            }));
        } else if (error) {
            this.showError('Error', error.body.message);
        }
    }
    
    // Get statuses
    @wire(getStatuses)
    wiredStatuses({ error, data }) {
        if (data) {
            this.statuses = data.map(status => ({
                label: status,
                value: status
            }));
        } else if (error) {
            this.showError('Error', error.body.message);
        }
    }
    
    /**
     * Handles refresh button click
     */
    handleRefresh() {
        return refreshApex(this.wiredLogsResult);
    }
    
    /**
     * Handles toggle filters
     */
    handleToggleFilters() {
        this.showFilters = !this.showFilters;
    }
    
    /**
     * Handles date from change
     */
    handleDateFromChange(event) {
        this.dateFrom = event.target.value;
    }
    
    /**
     * Handles date to change
     */
    handleDateToChange(event) {
        this.dateTo = event.target.value;
    }
    
    /**
     * Handles process type change
     */
    handleProcessTypeChange(event) {
        this.selectedProcessType = event.target.value;
    }
    
    /**
     * Handles log level change
     */
    handleLogLevelChange(event) {
        this.selectedLogLevel = event.target.value;
    }
    
    /**
     * Handles status change
     */
    handleStatusChange(event) {
        this.selectedStatus = event.target.value;
    }
    
    /**
     * Handles apply filters
     */
    handleApplyFilters() {
        // Filters are automatically applied via wire
        this.showFilters = false;
    }
    
    /**
     * Handles clear filters
     */
    handleClearFilters() {
        this.dateFrom = '';
        this.dateTo = '';
        this.selectedProcessType = '';
        this.selectedLogLevel = '';
        this.selectedStatus = '';
        this.selectedRows = [];
    }
    
    /**
     * Handles row selection
     */
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }
    
    /**
     * Handles row action
     */
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'retry') {
            this.handleRetryLog(row.Id);
        } else if (action.name === 'view') {
            this.handleViewLogDetails(row.Id);
        }
    }
    
    /**
     * Handles retry log
     */
    handleRetryLog(logId) {
        this.isLoading = true;
        retryProcessingLog({ logId: logId })
            .then(() => {
                this.showSuccess('Success', 'Log retry scheduled');
                return refreshApex(this.wiredLogsResult);
            })
            .catch(error => {
                this.showError('Error', error.body.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    /**
     * Handles view log details
     */
    handleViewLogDetails(logId) {
        // Navigate to log record detail view
        window.open('/lightning/r/ProcessingLog__c/' + logId + '/view', '_blank');
    }
    
    /**
     * Handles export to CSV
     */
    handleExportToCSV() {
        if (this.selectedRows.length === 0) {
            this.showError('Error', 'Please select at least one log to export');
            return;
        }
        
        this.isLoading = true;
        const logIds = this.selectedRows.map(row => row.Id);
        
        exportLogsToCSV({ logIds: logIds })
            .then(csvContent => {
                // Create blob and download
                const element = document.createElement('a');
                element.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent));
                element.setAttribute('download', 'processing_logs_' + new Date().getTime() + '.csv');
                element.style.display = 'none';
                document.body.appendChild(element);
                element.click();
                document.body.removeChild(element);
                
                this.showSuccess('Success', 'Logs exported to CSV');
            })
            .catch(error => {
                this.showError('Error', error.body.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    /**
     * Shows success toast
     */
    showSuccess(title, message) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success'
        });
        this.dispatchEvent(event);
    }
    
    /**
     * Shows error toast
     */
    showError(title, message) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error'
        });
        this.dispatchEvent(event);
    }
    
    /**
     * Gets record count
     */
    get recordCount() {
        return this.processingLogs.length;
    }
    
    /**
     * Check if no records
     */
    get hasNoRecords() {
        return this.processingLogs.length === 0;
    }
    
    /**
     * Check if records exist
     */
    get hasRecords() {
        return this.processingLogs.length > 0;
    }
}
