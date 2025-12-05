# Azure Landing Zone with 3-Tier Application

This repository contains an Azure Landing Zone implementation with a secure 3-tier web application demonstrating modern cloud architecture patterns and security best practices.

## Architecture Overview

### Landing Zone Components
- **Hub-Spoke Network Topology**: Centralized hub with isolated spoke networks
- **Monitoring & Logging**: Centralized Log Analytics workspace with diagnostic settings
- **Security**: Azure Firewall, Bastion Host, Network Security Groups, and Application Gateway with WAF
- **Identity & Access**: Managed Identities and Azure Key Vault for secrets management

### 3-Tier Application Architecture

#### **Presentation Tier (Web App)**
- **Azure App Service** running .NET 8.0 web application
- **Private endpoint** for secure connectivity
- **VNet integration** for outbound traffic to backend services
- **Managed Identity** for authentication to Azure services

#### **Application Tier (API Layer)**
- **Azure Virtual Machine** running Ubuntu 22.04 LTS with .NET 8.0 API
- **Network Security Groups** with minimal required access
- **Managed Identity** for Azure service authentication
- **Private networking** for secure communication

#### **Data Tier (Database)**
- **Azure SQL Database** with private endpoint
- **Transparent Data Encryption** enabled
- **Advanced Threat Protection** and Vulnerability Assessment
- **Azure AD authentication** with managed identities

## Security Best Practices Implemented

### 🔒 Network Security
- **Private Endpoints**: All PaaS services accessible only through private IPs
- **Network Segmentation**: Dedicated subnets for each tier
- **NSG Rules**: Restrictive firewall rules with minimum required access
- **No Public IP**: Application components have no direct internet access

### 🔐 Identity & Access Management
- **Managed Identities**: No stored credentials or connection strings in code
- **Azure Key Vault**: Centralized secrets management with access policies
- **Least Privilege**: Minimal required permissions for each component

### 🛡️ Data Protection
- **Encryption in Transit**: TLS 1.2+ for all communications
- **Encryption at Rest**: Azure Storage and SQL Database encryption
- **Private DNS Zones**: Custom DNS resolution for private endpoints

### 🔍 Monitoring & Compliance
- **Centralized Logging**: All resources send logs to Log Analytics
- **Security Monitoring**: Advanced Threat Protection enabled
- **Compliance**: Following Azure Security Benchmark guidelines

## Deployment Guide

### Prerequisites
- Azure CLI installed and authenticated
- PowerShell 7+ (for deployment scripts)
- .NET 8.0 SDK (for local development)
- Azure subscription with appropriate permissions

### Step 1: Deploy Infrastructure
```bash
# Clone the repository
git clone <repository-url>
cd azd-landing-zone

# Login to Azure
az login

# Set subscription (replace with your subscription ID)
az account set --subscription "your-subscription-id"

# Deploy the infrastructure
az deployment sub create \
  --location "West Europe" \
  --template-file ./infra/main.bicep \
  --parameters location="West Europe" \
              workload="helloworld" \
              environment="demo" \
              uniquenessSeed="$(az group list --query 'length(@)')"
```

### Step 2: Deploy Applications

#### Deploy Web Application
```powershell
# Navigate to the repository root
cd azd-landing-zone

# Deploy the web application
./scripts/deploy-webapp.ps1 -ResourceGroupName "rg-app-helloworld-demo-weu" -WebAppName "app-helloworld-demo-weu<seed>"
```

#### Deploy API Application
```bash
# This requires access to the VM (through Bastion or VPN)
# Copy the API application files to the VM and run:
chmod +x ./scripts/deploy-api.sh
./scripts/deploy-api.sh "https://kv-helloworld-demo-weu<seed>.vault.azure.net/"
```

## Application Details

### Sample Applications
Both applications demonstrate:
- **Entity Framework Core** with SQL Database connectivity
- **Azure Key Vault integration** for configuration
- **Health check endpoints** for monitoring
- **Swagger/OpenAPI documentation** for APIs
- **Managed Identity authentication** to Azure services

### API Endpoints

#### Web Application
- `GET /` - Main application endpoint with customer count
- `GET /health` - Health check endpoint

#### API Application  
- `GET /api/customers` - List all customers
- `GET /api/customers/{id}` - Get customer by ID
- `POST /api/customers` - Create new customer
- `GET /api/health` - Health check endpoint

## Monitoring and Troubleshooting

### Log Analytics Queries
```kql
// Application logs
AppServiceConsoleLogs
| where TimeGenerated > ago(1h)
| order by TimeGenerated desc

// Security events
SecurityEvent
| where TimeGenerated > ago(1h)
| where EventID in (4625, 4648, 4719, 4720)

// Network traffic
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(1h)
| summarize count() by SrcIP_s, DestIP_s, Action_s
```

### Common Troubleshooting

#### Connection Issues
1. Check NSG rules and ensure required ports are open
2. Verify private endpoint DNS resolution
3. Confirm managed identity permissions in Key Vault

#### Application Errors
1. Check Application Insights for detailed error logs
2. Verify Key Vault access and secret values
3. Test database connectivity from the VM

## Development Workflow

### Local Development
1. **Set up local environment** with .NET 8.0 SDK
2. **Configure local secrets** using `dotnet user-secrets`
3. **Use Azure service principal** for local Azure service access
4. **Test with local SQL Server** or SQL LocalDB

### CI/CD Pipeline
- **Azure DevOps** or **GitHub Actions** for automated deployment
- **Infrastructure as Code** validation with Bicep linter
- **Application security scanning** with OWASP tools
- **Automated testing** with integration tests

## Cost Optimization

### Estimated Monthly Costs (West Europe)
- **App Service Plan (P1v3)**: ~€70
- **Virtual Machine (D2s_v5)**: ~€60  
- **SQL Database (S1)**: ~€15
- **Key Vault**: ~€1
- **Virtual Network & Private Endpoints**: ~€10
- **Log Analytics**: ~€5

**Total**: ~€161/month (varies by usage)

### Optimization Tips
- Use **Azure Reserved Instances** for VMs (up to 72% savings)
- Consider **Azure SQL Elastic Pools** for multiple databases
- Implement **auto-scaling** for App Service Plans
- Use **spot instances** for development environments

## Security Compliance

This solution addresses key security frameworks:
- ✅ **Azure Security Benchmark**
- ✅ **NIST Cybersecurity Framework**
- ✅ **ISO 27001 controls**
- ✅ **GDPR compliance patterns**

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following the established patterns
4. Test infrastructure deployment
5. Submit a pull request

## Support

For issues and questions:
- Create an issue in this repository
- Review the troubleshooting section
- Check Azure documentation for specific services

## License

This project is licensed under the MIT License - see the LICENSE file for details.