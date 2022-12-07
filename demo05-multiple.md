
Example of combined control in EAST. 

✅ AAD AD Roles assigned
✅ AAD 'AppRoleAssignments' via Graph, such as
✅ Azure RBAC Role assignments
✅ Events linked to managed identity in Azure Activity logs
✅ Permissions assigned in Azure Key Vault
    - Events linked to managed identity in the Key Vault log

  

  node ./plugins/main.js --batch=10 --nativescope=true --roleAssignments --checkAad --subInclude=3539c2a2-cd25-48c6-b295-14e59334ef1c --namespace=RG-FN-22114 --nx --scanAuditLogs=20 --composites --clearTokens --SkipStorageThrottling