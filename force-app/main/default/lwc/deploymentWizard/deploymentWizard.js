import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAvailableMetadataTypes from '@salesforce/apex/DeploymentWizardController.getAvailableMetadataTypes';
import getTargetOrgs from '@salesforce/apex/DeploymentWizardController.getTargetOrgs';
import createDeploymentPackage from '@salesforce/apex/DeploymentWizardController.createDeploymentPackage';
import generatePackageXml from '@salesforce/apex/DeploymentWizardController.generatePackageXml';
import validatePackage from '@salesforce/apex/DeploymentWizardController.validatePackage';
import initiateDeployment from '@salesforce/apex/DeploymentWizardController.initiateDeployment';

export default class DeploymentWizard extends LightningElement {
    @track currentStep = 1;
    @track totalSteps = 4;
    @track packageName = '';
    @track packageDescription = '';
    @track selectedSourceOrg = '';
    @track selectedTargetOrg = '';
    @track selectedMetadataTypes = [];
    @track metadataTypes = [];
    @track targetOrgs = [];
    @track selectedComponents = [];
    @track isLoading = false;
    @track error = '';
    @track packageId = '';
    
    // Deployment options
    @track deploymentOptions = {
        testLevel: 'NoTestRun',
        runTests: false,
        rollbackOnError: true,
        checkOnly: false,
        ignoreWarnings: false
    };
    
    @track packageXml = '';
    @track validationErrors = [];
    @track isValidationPassed = false;
    
    // Column definitions for component selection
    componentColumns = [
        { label: 'Metadata Type', fieldName: 'metadataType', type: 'text', sortable: true },
        { label: 'Component Name', fieldName: 'componentName', type: 'text', sortable: true },
        { label: 'Status', fieldName: 'status', type: 'text' }
    ];
    
    // Get metadata types
    @wire(getAvailableMetadataTypes)
    wiredMetadataTypes({ error, data }) {
        if (data) {
            this.metadataTypes = data.map(mt => ({
                label: mt.MetadataType__c,
                value: mt.MetadataType__c
            }));
        } else if (error) {
            this.showError('Error loading metadata types', error.body.message);
        }
    }
    
    // Get target orgs
    @wire(getTargetOrgs)
    wiredTargetOrgs({ error, data }) {
        if (data) {
            this.targetOrgs = data.map(org => ({
                label: org.OrgName__c,
                value: org.Id
            }));
        } else if (error) {
            this.showError('Error loading target orgs', error.body.message);
        }
    }
    
    /**
     * Handles next step
     */
    handleNextStep() {
        if (this.validateCurrentStep()) {
            this.currentStep++;
        }
    }
    
    /**
     * Handles previous step
     */
    handlePreviousStep() {
        if (this.currentStep > 1) {
            this.currentStep--;
        }
    }
    
    /**
     * Handles package name change
     */
    handlePackageNameChange(event) {
        this.packageName = event.target.value;
    }
    
    /**
     * Handles package description change
     */
    handlePackageDescriptionChange(event) {
        this.packageDescription = event.target.value;
    }
    
    /**
     * Handles source org selection
     */
    handleSourceOrgChange(event) {
        this.selectedSourceOrg = event.target.value;
    }
    
    /**
     * Handles target org selection
     */
    handleTargetOrgChange(event) {
        this.selectedTargetOrg = event.target.value;
    }
    
    /**
     * Handles metadata type selection
     */
    handleMetadataTypeChange(event) {
        this.selectedMetadataTypes = event.target.value;
        
        // Auto-populate selectedComponents with selected metadata types as components
        // In production, this would fetch actual components from the org
        if (this.selectedMetadataTypes && this.selectedMetadataTypes.length > 0) {
            this.selectedComponents = this.selectedMetadataTypes.map((type, index) => ({
                id: type + '_' + (index + 1),
                metadataType: type,
                componentName: type + '_' + (index + 1),
                displayName: type,
                status: 'Selected'
            }));
        } else {
            this.selectedComponents = [];
        }
    }
    
    /**
     * Handles deployment option changes
     */
    handleDeploymentOptionChange(event) {
        const fieldName = event.target.dataset.field;
        if (event.target.type === 'checkbox') {
            this.deploymentOptions[fieldName] = event.target.checked;
        } else {
            this.deploymentOptions[fieldName] = event.target.value;
        }
    }
    
    /**
     * Handles component selection
     */
    handleComponentSelection(event) {
        this.selectedComponents = event.detail.selectedRows;
    }
    
    /**
     * Validates current step
     */
    validateCurrentStep() {
        switch (this.currentStep) {
            case 1:
                if (!this.packageName || !this.selectedTargetOrg) {
                    this.showError('Validation Error', 'Package name and target org are required');
                    return false;
                }
                return true;
            case 2:
                if (this.selectedMetadataTypes.length === 0) {
                    this.showError('Validation Error', 'At least one metadata type must be selected');
                    return false;
                }
                return true;
            case 3:
                return this.validateDeployment();
            default:
                return true;
        }
    }
    
    /**
     * Validates deployment configuration
     */
    validateDeployment() {
        // Validate deployment options
        if (this.deploymentOptions.runTests && this.deploymentOptions.testLevel === 'NoTestRun') {
            this.showError('Validation Error', 'Test level must be specified when running tests');
            return false;
        }
        return true;
    }
    
    /**
     * Handles create and deploy
     */
    handleCreateAndDeploy() {
        this.isLoading = true;
        this.error = '';
        
        // Validate that components are selected
        if (!this.selectedComponents || this.selectedComponents.length === 0) {
            this.isLoading = false;
            this.showError('Validation Error', 'At least one component must be selected. Please go back to Step 2 and select metadata types.');
            return;
        }
        
        // Create package components
        const components = this.selectedComponents.map(comp => ({
            metadataType: comp.metadataType,
            componentName: comp.componentName,
            displayName: comp.displayName
        }));
        
        createDeploymentPackage({
            packageName: this.packageName,
            description: this.packageDescription,
            sourceOrgId: this.selectedSourceOrg,
            targetOrgId: this.selectedTargetOrg,
            selectedComponents: components
        })
        .then(result => {
            this.packageId = result.packageId;
            
            // Generate package XML
            return generatePackageXml({ packageId: this.packageId });
        })
        .then(xml => {
            this.packageXml = xml;
            
            // Validate package
            return validatePackage({ packageId: this.packageId });
        })
        .then(validationResult => {
            if (!validationResult.isValid) {
                this.validationErrors = validationResult.issues;
                this.isValidationPassed = false;
                this.currentStep = 3;
                this.isLoading = false;
                return;
            }
            
            this.isValidationPassed = true;
            
            // Initiate deployment
            return initiateDeployment({ 
                packageId: this.packageId,
                options: this.deploymentOptions
            });
        })
        .then(deploymentResult => {
            this.isLoading = false;
            this.showSuccess('Deployment initiated', 'Deployment ID: ' + deploymentResult.deploymentId);
            this.resetWizard();
        })
        .catch(error => {
            this.isLoading = false;
            this.showError('Error', error.body?.message || 'An error occurred');
        });
    }
    
    /**
     * Resets wizard to initial state
     */
    resetWizard() {
        this.currentStep = 1;
        this.packageName = '';
        this.packageDescription = '';
        this.selectedSourceOrg = '';
        this.selectedTargetOrg = '';
        this.selectedMetadataTypes = [];
        this.selectedComponents = [];
        this.packageId = '';
        this.packageXml = '';
        this.validationErrors = [];
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
     * Check if next button should be disabled
     */
    get isNextDisabled() {
        return this.currentStep === this.totalSteps;
    }
    
    /**
     * Check if previous button should be disabled
     */
    get isPreviousDisabled() {
        return this.currentStep === 1;
    }
    
    /**
     * Get progress percentage
     */
    get progressPercentage() {
        return (this.currentStep / this.totalSteps) * 100;
    }
    
    /**
     * Check if step 1 is active
     */
    get isStep1() {
        return this.currentStep === 1;
    }
    
    /**
     * Check if step 2 is active
     */
    get isStep2() {
        return this.currentStep === 2;
    }
    
    /**
     * Check if step 3 is active
     */
    get isStep3() {
        return this.currentStep === 3;
    }
    
    /**
     * Check if step 4 is active
     */
    get isStep4() {
        return this.currentStep === 4;
    }
    
    /**
     * Check if last step
     */
    get isLastStep() {
        return this.currentStep === this.totalSteps;
    }
    
    /**
     * Get test level options
     */
    get testLevelOptions() {
        return [
            { label: 'No Test Run', value: 'NoTestRun' },
            { label: 'Run Specified Tests', value: 'RunSpecifiedTests' },
            { label: 'Run Local Tests', value: 'RunLocalTests' },
            { label: 'Run All Tests in Org', value: 'RunAllTestsInOrg' }
        ];
    }
}
