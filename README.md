# RealFast: Salesforce Metadata Deployment & Audit Management System

A comprehensive Salesforce DX solution for metadata deployment, package management, and audit trail tracking with modern Lightning Web Components and Apex controllers.

## 🎯 Project Overview

RealFast is an enterprise-grade metadata deployment system designed to streamline Salesforce metadata migrations, deployments, and audit trail management. It provides a complete suite of tools for managing org connections, creating deployment packages, monitoring deployments in real-time, and tracking audit trails across Salesforce environments.

### Key Features

- **Multi-Step Deployment Wizard**: Guided process for creating deployment packages with metadata type selection and validation
- **Real-Time Deployment Monitor**: Track deployment progress with live status updates and detailed metrics
- **Audit Trail Viewer**: Comprehensive audit trail filtering, viewing, and analytics
- **Processing Log Dashboard**: Monitor processing activities, export logs, and retry failed operations
- **Metadata Type Configuration**: Centralized management of supported metadata types and configurations
- **Org Connection Management**: Securely manage connections to multiple Salesforce organizations
- **CSV Export Functionality**: Export audit trails and logs for external analysis

## 📊 Architecture

### Custom Objects

| Object | Purpose | Key Fields |
|--------|---------|-----------|
| **OrgConnection__c** | Manage Salesforce org connections | Org Name, Connection Type, API Version, Base URL, Auth Token |
| **SetupAuditTrail__c** | Master record for audit trails | Organization ID, Instance URL, Status |
| **DeploymentPackage__c** | Define deployment packages | Package Name, Metadata Types, Status, Package XML |
| **PackageComponent__c** | Components within packages (child) | API Name, Metadata Type, Status |
| **DeploymentHistory__c** | Track all deployments | Deployment ID, Status, Components, Metrics |
| **ProcessingLog__c** | Activity logging | Log Type, Status, Message, Stacktrace |
| **MetadataTypeConfig__mdt** | Configuration metadata | Metadata Type Name, Is Supported, Requires Test Run, etc. |

### Apex Controllers (1,479 lines total)

| Controller | Purpose | Key Methods |
|-----------|---------|------------|
| **AuditTrailViewController** | Audit trail operations | getAuditTrails, processAuditTrails, syncOrgAuditTrails, getMetadataTypes |
| **DeploymentWizardController** | Multi-step package creation | createDeploymentPackage, generatePackageXml, validatePackage, initiateDeployment |
| **ProcessingLogViewController** | Log monitoring and analytics | getProcessingLogs, getLogStatistics, retryProcessingLog, exportLogsToCSV |
| **DeploymentMonitorController** | Real-time deployment tracking | getDeploymentHistory, pollDeploymentStatus, cancelDeployment, retryDeployment |

### Lightning Web Components (4 components)

| Component | Purpose | Features |
|-----------|---------|----------|
| **deploymentWizard** | 4-step package creation wizard | Progress bar, metadata selection, validation, XML preview |
| **processingLogViewer** | Activity monitoring dashboard | Statistics, filtering, pagination, CSV export |
| **deploymentMonitor** | Real-time deployment tracker | Auto-polling (10s), metrics, modal details, status colors |
| **auditTrailViewer** | Audit trail management | 9-column datatable, advanced filtering, date/org/type filters |

## 🚀 Getting Started

### Prerequisites

- Salesforce CLI (sf) v2.0+
- Node.js 18.0+
- Git 2.30+
- A Salesforce org with DX enabled

### Installation

1. **Clone the repository**
   ```powershell
   git clone https://github.com/realfast/realfasttest.git
   cd realfasttest
   ```

2. **Install dependencies**
   ```powershell
   npm install
   ```

3. **Authenticate with Salesforce**
   ```powershell
   sf org login web --alias dev-hub
   ```

4. **Create a scratch org**
   ```powershell
   sf org create scratch --definition-file config/project-scratch-def.json --alias realfast-dev
   ```

5. **Deploy the project**
   ```powershell
   sf project deploy start --source-dir force-app --wait 30
   ```

## 📝 Project Structure

```
force-app/
├── main/default/
│   ├── classes/          # Apex controllers and services
│   ├── lwc/              # Lightning Web Components
│   ├── objects/          # Custom object definitions
│   ├── permissionsets/   # Permission set configurations
│   └── staticresources/  # Static files and resources
config/
├── project-scratch-def.json  # Scratch org configuration
scripts/
├── apex/                 # Apex scripts
└── soql/                 # SOQL queries
.github/
└── workflows/           # CI/CD automation
```

## 🔧 Development Workflow

### Working with Features

1. **Create a feature branch**
   ```powershell
   git checkout -b feature/your-feature-name
   ```

2. **Make changes and validate locally**
   ```powershell
   sf project deploy start --source-dir force-app --wait 30
   ```

3. **Run tests** (when test classes are added)
   ```powershell
   sf apex run test --test-level RunLocalTests --wait 10
   ```

4. **Commit and push**
   ```powershell
   git add .
   git commit -m "feat: describe your feature"
   git push origin feature/your-feature-name
   ```

5. **Create a Pull Request**

### Deployment

#### Development Environment
```powershell
sf project deploy start --source-dir force-app --target-org dev --wait 30
```

#### Production Environment
```powershell
sf project deploy start --source-dir force-app --target-org prod --wait 60 --test-level RunLocalTests
```

#### With Test Execution
```powershell
sf project deploy start --source-dir force-app --wait 30 --test-level RunLocalTests
```

## 📚 Documentation

- **[LWC & Controller Summary](./LWC_AND_CONTROLLER_SUMMARY.md)** - Detailed component and controller documentation
- **[Deployment Summary](./DEPLOYMENT_SUMMARY.md)** - Deployment procedures and validation steps
- **[Deployment Verification](./DEPLOYMENT_VERIFICATION.md)** - Verification checklist and troubleshooting

## 🔐 Security & Best Practices

### Code Quality

- **ESLint Configuration**: Enforced coding standards (`eslint.config.js`)
- **Jest Tests**: Unit testing framework configured (`jest.config.js`)
- **Apex Pattern**: Service, Selector, and Domain patterns implemented
- **Error Handling**: Comprehensive AuraHandledException handling in all controllers

### Configuration Management

- **YAML-based Config**: Environment-specific settings in `deployment-config.yml`
- **Project Configuration**: Metadata API version tracking in `project-config.yml`
- **Sensitive Data**: Use Salesforce Named Credentials for API tokens

### Performance Optimization

- **Polling Strategy**: 10-second interval for deployment monitoring
- **Pagination**: 100 records per page in all data tables
- **Caching**: Leverage @wire adapters for efficient data fetching
- **Batch Processing**: Support for bulk operations in controllers

## 🧪 Testing

### Test Coverage

Unit tests should achieve minimum 75% code coverage:

```powershell
sf apex run test --test-level RunLocalTests --result-format human
```

### Manual Testing

1. **Deployment Wizard**: Create and validate a test package
2. **Deployment Monitor**: Monitor a deployment in real-time
3. **Audit Trail Viewer**: Filter and view audit trail records
4. **Processing Logs**: Check logs and retry operations

## 🔄 CI/CD Pipeline

The project includes GitHub Actions workflow for automated testing and deployment:

- **Validate**: Metadata syntax validation on PR
- **Deploy Dev**: Deploy to development org on PR merge
- **Deploy Prod**: Deploy to production org on release (manual trigger)

See `.github/workflows/deploy.yml` for configuration details.

## 📋 Supported Metadata Types

The system supports the following Salesforce metadata types (configurable via MetadataTypeConfig__mdt):

- ApexClass
- ApexTrigger
- ApexPage
- ApexComponent
- LightningWebComponent
- CustomObject
- CustomField
- CustomMetadata
- Layout
- RecordType
- ValidationRule
- Workflow
- ProcessBuilder
- Flow

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

- Follow Apex naming conventions
- Use meaningful variable names
- Document complex logic with comments
- Ensure 75%+ test coverage

## 📦 Dependencies

### Salesforce

- Salesforce Metadata API v64.0
- Salesforce CLI v2.0+

### Node.js

- eslint ^9.0.0
- jest ^29.0.0

## 🐛 Troubleshooting

### Deployment Failures

1. **Check org limits**: `sf org list`
2. **Validate metadata**: `sf project validate --source-dir force-app`
3. **Review error details**: Check the deployment report

### LWC Component Issues

1. **Clear browser cache**: Hard refresh (Ctrl+Shift+Delete)
2. **Check console errors**: Open browser DevTools
3. **Verify permissions**: Check user permission sets

### Connection Issues

1. **Re-authenticate**: `sf org login web --alias dev-hub`
2. **Check API version**: Ensure compatibility with org version
3. **Review firewall rules**: Ensure API traffic is allowed

## 📞 Support

For issues or questions:
- Open an issue on GitHub
- Check existing documentation
- Contact the development team

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Authors

- **Ashok Chandra** - Initial implementation

## 🙏 Acknowledgments

- Salesforce DX Documentation
- Lightning Web Components Best Practices
- Apex Design Patterns
