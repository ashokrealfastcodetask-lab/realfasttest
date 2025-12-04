import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDeploymentHistory from '@salesforce/apex/DeploymentMonitorController.getDeploymentHistory';
import getDeploymentStatuses from '@salesforce/apex/DeploymentMonitorController.getDeploymentStatuses';
import getDeploymentMetrics from '@salesforce/apex/DeploymentMonitorController.getDeploymentMetrics';
import pollDeploymentStatus from '@salesforce/apex/DeploymentMonitorController.pollDeploymentStatus';
import cancelDeployment from '@salesforce/apex/DeploymentMonitorController.cancelDeployment';
import retryDeployment from '@salesforce/apex/DeploymentMonitorController.retryDeployment';
import getDeploymentDetail from '@salesforce/apex/DeploymentMonitorController.getDeploymentDetail';

export default class DeploymentMonitor extends LightningElement {
    @track deployments = [];
    @track isLoading = false;
    @track error = '';
    @track showFilters = false;
    @track selectedDetailId = '';
    @track deploymentDetail = null;
    @track deploymentComponents = [];
    
    // Filter properties
    @track selectedStatus = '';
    @track selectedOrgId = '';
    @track dateFrom = '';
    @track dateTo = '';
    @track pageSize = 50;
    
    // Polling
    @track isPolling = false;
    @track pollingInterval;
    
    // Statistics
    @track metrics = {};
    
    // Lookup options
    @track statuses = [];
    
    wiredDeploymentsResult;
    wiredMetricsResult;
    
    // Column definitions
    columns = [
        { 
            label: 'Name', 
            fieldName: 'Name', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Package', 
            fieldName: 'PackageName', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Target Org', 
            fieldName: 'TargetOrgName', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Status', 
            fieldName: 'DeploymentStatus__c', 
            type: 'text',
            sortable: true,
            cellAttributes: { 
                class: { 
                    fieldName: 'statusClass' 
                } 
            }
        },
        { 
            label: 'Requested By', 
            fieldName: 'RequestedByName', 
            type: 'text',
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
        },
        { 
            type: 'action',
            typeAttributes: { 
                rowActions: [{label: 'View', name: 'view'}, {label: 'Cancel', name: 'cancel'}, {label: 'Retry', name: 'retry'}]
            }
        }
    ];
    
    connectedCallback() {
        // Initialize polling
        this.startPolling();
    }
    
    disconnectedCallback() {
        // Clean up polling
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
        }
    }
    
    // Get deployment history
    @wire(getDeploymentHistory, {
        statusFilter: '$selectedStatus',
        orgConnectionId: '$selectedOrgId',
        fromDate: '$dateFrom',
        toDate: '$dateTo',
        limitRows: '$pageSize'
    })
    wiredDeployments(result) {
        this.wiredDeploymentsResult = result;
        if (result.data) {
            this.deployments = result.data.map(dep => ({
                ...dep,
                PackageName: dep.DeploymentPackage__r?.Name || 'N/A',
                TargetOrgName: dep.TargetOrg__r?.OrgName__c || 'N/A',
                RequestedByName: dep.RequestedBy__r?.Name || 'N/A',
                statusClass: this.getStatusClass(dep.DeploymentStatus__c)
            }));
            this.error = '';
        } else if (result.error) {
            this.error = result.error.body.message;
            this.showError('Error', this.error);
        }
    }
    
    // Get deployment metrics
    @wire(getDeploymentMetrics, {
        fromDate: '$dateFrom',
        toDate: '$dateTo'
    })
    wiredMetrics(result) {
        this.wiredMetricsResult = result;
        if (result.data) {
            this.metrics = result.data;
        }
    }
    
    // Get deployment statuses
    @wire(getDeploymentStatuses)
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
     * Starts polling for deployment updates
     */
    startPolling() {
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
        }
        
        // Poll every 10 seconds
        this.pollingInterval = setInterval(() => {
            this.pollDeployments();
        }, 10000);
    }
    
    /**
     * Polls for deployment updates
     */
    pollDeployments() {
        // In progress deployments
        const inProgressDeps = this.deployments.filter(dep => dep.DeploymentStatus__c === 'In Progress');
        
        if (inProgressDeps.length > 0) {
            inProgressDeps.forEach(dep => {
                pollDeploymentStatus({ deploymentId: dep.Id })
                    .then(update => {
                        // Update deployment status
                        const index = this.deployments.findIndex(d => d.Id === update.deploymentId);
                        if (index >= 0) {
                            this.deployments[index].DeploymentStatus__c = update.status;
                            this.deployments[index].statusClass = this.getStatusClass(update.status);
                        }
                    })
                    .catch(error => {
                        console.error('Error polling deployment:', error);
                    });
            });
        }
    }
    
    /**
     * Gets CSS class for status
     */
    getStatusClass(status) {
        switch(status) {
            case 'Succeeded':
                return 'status-success';
            case 'Failed':
                return 'status-failed';
            case 'In Progress':
                return 'status-in-progress';
            case 'Canceled':
                return 'status-canceled';
            default:
                return 'status-queued';
        }
    }
    
    /**
     * Handles refresh button click
     */
    handleRefresh() {
        return refreshApex(this.wiredDeploymentsResult);
    }
    
    /**
     * Handles toggle filters
     */
    handleToggleFilters() {
        this.showFilters = !this.showFilters;
    }
    
    /**
     * Handles status filter change
     */
    handleStatusChange(event) {
        this.selectedStatus = event.target.value;
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
     * Handles apply filters
     */
    handleApplyFilters() {
        this.showFilters = false;
    }
    
    /**
     * Handles clear filters
     */
    handleClearFilters() {
        this.selectedStatus = '';
        this.dateFrom = '';
        this.dateTo = '';
    }
    
    /**
     * Handles row action
     */
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        switch (action.name) {
            case 'view':
                this.handleViewDeployment(row.Id);
                break;
            case 'cancel':
                this.handleCancelDeployment(row.Id);
                break;
            case 'retry':
                this.handleRetryDeployment(row.Id);
                break;
        }
    }
    
    /**
     * Handles view deployment
     */
    handleViewDeployment(deploymentId) {
        this.selectedDetailId = deploymentId;
        this.isLoading = true;
        
        getDeploymentDetail({ deploymentId: deploymentId })
            .then(detail => {
                this.deploymentDetail = detail;
                this.isLoading = false;
            })
            .catch(error => {
                this.showError('Error', error.body.message);
                this.isLoading = false;
            });
    }
    
    /**
     * Handles cancel deployment
     */
    handleCancelDeployment(deploymentId) {
        if (!confirm('Are you sure you want to cancel this deployment?')) {
            return;
        }
        
        this.isLoading = true;
        
        cancelDeployment({ deploymentId: deploymentId })
            .then(result => {
                if (result.success) {
                    this.showSuccess('Success', result.message);
                    return refreshApex(this.wiredDeploymentsResult);
                } else {
                    this.showError('Error', result.message);
                }
            })
            .catch(error => {
                this.showError('Error', error.body.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    /**
     * Handles retry deployment
     */
    handleRetryDeployment(deploymentId) {
        if (!confirm('Are you sure you want to retry this deployment?')) {
            return;
        }
        
        this.isLoading = true;
        
        retryDeployment({ deploymentId: deploymentId })
            .then(result => {
                if (result.success) {
                    this.showSuccess('Success', result.message);
                    return refreshApex(this.wiredDeploymentsResult);
                } else {
                    this.showError('Error', result.message);
                }
            })
            .catch(error => {
                this.showError('Error', error.body.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    /**
     * Closes detail view
     */
    handleCloseDetail() {
        this.selectedDetailId = '';
        this.deploymentDetail = null;
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
        return this.deployments.length;
    }
    
    /**
     * Check if no records
     */
    get hasNoRecords() {
        return this.deployments.length === 0;
    }
    
    /**
     * Check if records exist
     */
    get hasRecords() {
        return this.deployments.length > 0;
    }
    
    /**
     * Check if detail view is open
     */
    get isDetailOpen() {
        return this.selectedDetailId !== '';
    }
}
