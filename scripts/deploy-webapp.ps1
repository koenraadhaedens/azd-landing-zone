# PowerShell script to deploy the Web App to Azure App Service
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$WebAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$SourcePath = ".\src\WebApp"
)

Write-Host "Deploying Web App to Azure App Service..." -ForegroundColor Green

# Build and publish the application
Write-Host "Building application..." -ForegroundColor Yellow
Push-Location $SourcePath
try {
    dotnet restore
    if ($LASTEXITCODE -ne 0) { throw "dotnet restore failed" }
    
    dotnet build --configuration Release
    if ($LASTEXITCODE -ne 0) { throw "dotnet build failed" }
    
    dotnet publish --configuration Release --output "./publish"
    if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed" }
    
    # Create deployment package
    Write-Host "Creating deployment package..." -ForegroundColor Yellow
    Compress-Archive -Path "./publish/*" -DestinationPath "./deploy.zip" -Force
    
    # Deploy to Azure App Service
    Write-Host "Deploying to Azure App Service..." -ForegroundColor Yellow
    az webapp deploy --resource-group $ResourceGroupName --name $WebAppName --src-path "./deploy.zip" --type zip
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deployment successful!" -ForegroundColor Green
        Write-Host "Web App URL: https://$WebAppName.azurewebsites.net" -ForegroundColor Cyan
    } else {
        throw "Deployment failed"
    }
    
} finally {
    Pop-Location
}