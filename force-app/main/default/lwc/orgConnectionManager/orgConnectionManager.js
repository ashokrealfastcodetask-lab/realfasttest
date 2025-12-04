import { LightningElement, wire } from 'lwc';
import getOrgConnections from '@salesforce/apex/OrgConnectionSelector.selectActive';

export default class OrgConnectionManager extends LightningElement {
    orgConnections = [];
    isLoading = false;
    error = null;

    @wire(getOrgConnections)
    wiredOrgConnections({ error, data }) {
        if (data) {
            this.orgConnections = data;
            this.error = null;
        } else if (error) {
            this.error = error;
            this.orgConnections = [];
        }
    }

    get hasConnections() {
        return this.orgConnections && this.orgConnections.length > 0;
    }

    handleRefresh() {
        this.isLoading = true;
        // Refresh logic here
        setTimeout(() => {
            this.isLoading = false;
        }, 1000);
    }
}
