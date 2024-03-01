

param storageAccountName string
param logAnalyticsWorkspaceName string

param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageAccountName 
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties:{
    sku: {
      name: 'PerNode'
    }
    retentionInDays: int(60)
    workspaceCapping: {
      dailyQuotaGb: int(1)
  }
}
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource diagnosticsBlob 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: blobService
  name: 'diagnostics02'
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        categoryGroup:'allLogs'
        enabled: true
      }
    ]
  }
}

resource fileDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: fileService
  name: 'diagnostics00'
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        categoryGroup:'allLogs'
        enabled: true
      }
    ]
  }
}

