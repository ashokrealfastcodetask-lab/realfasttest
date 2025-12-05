import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getDeploymentPackages from '@salesforce/apex/DeploymentPackageSelector.getselectActive';

export default class DeploymentPackageViewer extends LightningElement {
    deploymentPackages = [];
    isLoading = false;
    error = null;
    wiredPackagesResult;

    columns = [
        { label: 'Package Name', fieldName: 'PackageName__c' },
        { label: 'Version', fieldName: 'Version__c' },
        { label: 'Status', fieldName: 'Status__c' },
        { label: 'Component Count', fieldName: 'ComponentCount__c', type: 'number' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
    ];

    @wire(getDeploymentPackages)
    wiredDeploymentPackages(result) {
        this.wiredPackagesResult = result;
        const { error, data } = result;
        if (data) {
            this.deploymentPackages = data;
            this.error = null;
        } else if (error) {
            this.error = error;
            this.deploymentPackages = [];
        }
    }

    get hasPackages() {
        return this.deploymentPackages && this.deploymentPackages.length > 0;
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredPackagesResult).then(() => {
            this.isLoading = false;
        });
    }

    handleRowAction(event) {
        const row = event.detail.row;
        // Handle row action - e.g., view details, edit, delete
        console.log('Row action:', row);
    }
}
