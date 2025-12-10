import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAuditTrails from '@salesforce/apex/AuditTrailViewController.getAuditTrails';
import getOrgConnections from '@salesforce/apex/AuditTrailViewController.getOrgConnections';
import processAuditTrails from '@salesforce/apex/AuditTrailViewController.processAuditTrails';
import syncOrgAuditTrails from '@salesforce/apex/AuditTrailViewController.syncOrgAuditTrails';

export default class AuditTrailViewer extends LightningElement {
    @track auditTrails = [];
    @track filteredTrails = [];
    @track orgConnections = [];
    @track isLoading = false;
    @track error;
   
    
    // Filter properties
    @track selectedOrgId = '';
    @track selectedAction = '';
    @track selectedMetadataType = '';
    @track searchTerm = '';
    @track dateFrom = '';
    @track dateTo = '';
    @track showProcessedOnly = false;
    
    // Pagination
    @track pageSize = 50;
    @track currentPage = 1;
    @track totalRecords = 0;
    @track totalPages = 0;
    
    // Selection
    @track selectedRows = [];
    
    wiredAuditTrailsResult;
    
    // Column definitions
    columns = [
        { 
            label: 'Created Date', 
            fieldName: 'CreatedDate__c', 
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
            label: 'Action', 
            fieldName: 'Action__c', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Section', 
            fieldName: 'Section__c', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Component', 
            fieldName: 'ComponentName__c', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Metadata Type', 
            fieldName: 'MetadataType__c', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Display', 
            fieldName: 'Display__c', 
            type: 'text'
        },
        { 
            label: 'User', 
            fieldName: 'CreatedByName__c', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Org', 
            fieldName: 'orgName', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Processed', 
            fieldName: 'IsProcessed__c', 
            type: 'boolean'
        }
    ];
    
    // Action options
    get actionOptions() {
        return [
            { label: 'All Actions', value: '' },
            { label: 'Created', value: 'created' },
            { label: 'Changed', value: 'changed' },
            { label: 'Deleted', value: 'deleted' },
            { label: 'Activated', value: 'activated' },
            { label: 'Deactivated', value: 'deactivated' }
        ];
    }
    
    // Metadata type options
    get metadataTypeOptions() {
        const types = new Set();
        types.add('');
        this.auditTrails.forEach(trail => {
            if (trail.MetadataType__c) {
                types.add(trail.MetadataType__c);
            }
        });
        
        return Array.from(types).sort().map(type => ({
            label: type || 'All Types',
            value: type
        }));
    }
    
    // Page size options
    get pageSizeOptions() {
        return [
            { label: '25', value: 25 },
            { label: '50', value: 50 },
            { label: '100', value: 100 },
            { label: '200', value: 200 }
        ];
    }
    
    // Computed properties
    get hasRecords() {
        return this.filteredTrails && this.filteredTrails.length > 0;
    }
    
    get paginatedRecords() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.filteredTrails.slice(start, end);
    }
    
    get showPagination() {
        return this.totalPages > 1;
    }
    
    get isFirstPage() {
        return this.currentPage === 1;
    }
    
    get isLastPage() {
        return this.currentPage === this.totalPages;
    }
    
    get recordInfo() {
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end = Math.min(this.currentPage * this.pageSize, this.totalRecords);
        return `Showing ${start}-${end} of ${this.totalRecords}`;
    }
    
    get hasSelection() {
        return this.selectedRows.length > 0;
    }
    
    // Wire methods
    @wire(getOrgConnections)
    wiredOrgs({ error, data }) {
        if (data) {
            this.orgConnections = [
                { label: 'All Orgs', value: '' },
                ...data.map(org => ({
                    label: org.OrgName__c,
                    value: org.Id
                }))
            ];
        } else if (error) {
            this.showError('Error loading org connections', error);
        }
    }
    
    connectedCallback() {
        this.loadAuditTrails();
    }
    
    // Load audit trails
    loadAuditTrails() {
        this.isLoading = true;
        this.error = undefined;
        
        console.log('loadAuditTrails called');
        
        const params = {
            orgConnectionId: this.selectedOrgId || null,
            action: this.selectedAction || null,
            metadataType: this.selectedMetadataType || null,
            searchTerm: this.searchTerm || null,
            dateFrom: this.dateFrom || null,
            dateTo: this.dateTo || null,
            processedOnly: this.showProcessedOnly
        };
        
        console.log('Filter params:', params);
        
        getAuditTrails(params)
            .then(result => {
                console.log('Audit trails received:', result);
                if (result && result.length > 0) {
                    this.auditTrails = result.map(trail => ({
                        ...trail,
                        orgName: trail.OrgConnection__r ? trail.OrgConnection__r.OrgName__c : ''
                    }));
                } else {
                    this.auditTrails = [];
                    console.log('No audit trails returned');
                }
                this.applyFilters();
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error loading audit trails:', error);
                this.showError('Error loading audit trails', error);
                this.isLoading = false;
            });
    }
    
    // Filter methods
    applyFilters() {
        let filtered = [...this.auditTrails];
        
        // Apply search filter
        if (this.searchTerm) {
            const searchLower = this.searchTerm.toLowerCase();
            filtered = filtered.filter(trail => 
                (trail.Display__c && trail.Display__c.toLowerCase().includes(searchLower)) ||
                (trail.ComponentName__c && trail.ComponentName__c.toLowerCase().includes(searchLower)) ||
                (trail.Section__c && trail.Section__c.toLowerCase().includes(searchLower))
            );
        }
        
        this.filteredTrails = filtered;
        this.totalRecords = filtered.length;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.currentPage = 1;
    }
    
    // Event handlers
    handleOrgChange(event) {
        this.selectedOrgId = event.detail.value;
        this.loadAuditTrails();
    }
    
    handleActionChange(event) {
        this.selectedAction = event.detail.value;
        this.loadAuditTrails();
    }
    
    handleMetadataTypeChange(event) {
        this.selectedMetadataType = event.detail.value;
        this.loadAuditTrails();
    }
    
    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        // Debounce search
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.applyFilters();
        }, 300);
    }
    
    handleDateFromChange(event) {
        this.dateFrom = event.target.value;
        this.loadAuditTrails();
    }
    
    handleDateToChange(event) {
        this.dateTo = event.target.value;
        this.loadAuditTrails();
    }
    
    handleProcessedToggle(event) {
        this.showProcessedOnly = event.target.checked;
        this.loadAuditTrails();
    }
    
    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value, 10);
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.currentPage = 1;
    }
    
    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }
    
    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }
    
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }
    
    // Action handlers
    handleRefresh() {
        this.loadAuditTrails();
        this.showSuccess('Audit trails refreshed');
    }
    
    handleSyncOrg() {
        if (!this.selectedOrgId) {
            this.showWarning('Please select an org to sync');
            return;
        }
        
        this.isLoading = true;
        
        syncOrgAuditTrails({ orgConnectionId: this.selectedOrgId })
            .then(result => {
                this.showSuccess(`Successfully synced ${result} audit trail records`);
                this.loadAuditTrails();
            })
            .catch(error => {
                this.showError('Error syncing audit trails', error);
                this.isLoading = false;
            });
    }
    
    handleProcessSelected() {
        if (this.selectedRows.length === 0) {
            this.showWarning('Please select audit trails to process');
            return;
        }
        
        this.isLoading = true;
        const trailIds = this.selectedRows.map(row => row.Id);
        
        processAuditTrails({ auditTrailIds: trailIds })
            .then(() => {
                this.showSuccess(`Successfully processed ${trailIds.length} audit trails`);
                this.selectedRows = [];
                this.loadAuditTrails();
            })
            .catch(error => {
                this.showError('Error processing audit trails', error);
                this.isLoading = false;
            });
    }
    
    handleClearFilters() {
        this.selectedOrgId = '';
        this.selectedAction = '';
        this.selectedMetadataType = '';
        this.searchTerm = '';
        this.dateFrom = '';
        this.dateTo = '';
        this.showProcessedOnly = false;
        this.loadAuditTrails();
    }
    
    // Toast notifications
    showSuccess(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: message,
                variant: 'success'
            })
        );
    }
    
    showWarning(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Warning',
                message: message,
                variant: 'warning'
            })
        );
    }
    
    showError(title, error) {
        let message = 'Unknown error';
        if (error) {
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (error.body && error.body.message) {
                message = error.body.message;
            } else if (typeof error.body === 'string') {
                message = error.body;
            } else if (typeof error === 'string') {
                message = error;
            }
        }
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'error',
                mode: 'sticky'
            })
        );
    }
}