# Azure CLI on Powershell

## 安裝 Azure CLI

> 參考文件：https://learn.microsoft.com/zh-tw/cli/azure/install-azure-cli

## 登入 Azure
1. Powershell
2. 登入
   ```powershell
    Connect-AzAccount
   ```
3. 查看可用租用戶
   ```powershell
    Get-AzTenant
   ```
4. 選擇操作租用戶
   ```powershell
    Connect-AzAccount -TenantId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```
5. 驗證當前租用戶
   ```powershell
    Get-AzContext
   ```

## 建立腳本 (以 Azure OpenAI Service 為例)

1. 建立腳本檔案 PowerShellDemo.ps1
2. 貼上以下內容
    ```powershell
    # 建立服務結構，視服務建立流程自行修改
    # groupName：資源群組名稱
    # location：OpenAI 地區
    # modelDeployment：OpenAI 部署名稱
    # modelName：OpenAI 使用的模型名稱
    # modelVersion：OpenAI 使用的模型版本
    # 一個資源群組可能建立多個 OpenAI 服務，因此 source 使用陣列
    # 一個 OpenAI 服務中可能建立多個模型，因此 source 中使用陣列存放欲建立的模型
    $jsonData = @'
    [{
        "groupName": "gpt-S1",
        "source":[
            {
                "sourceName": "gpt-test1",
                "location": "eastus2",
                "modelArray": [{
                    "modelDeployment": "gpt3e1",
                    "modelName": "gpt-35-turbo-16k",
                    "modelVersion": "0613"
                }]
            }
        ]
    },
    {
        "groupName": "gpt-S2",
        "source":[
            {
                "sourceName": "gpt-test2",
                "location": "northcentralus",
                "modelArray": [
                    {
                        "modelDeployment": "gpt3e1",
                        "modelName": "gpt-35-turbo-16k",
                        "modelVersion": "0613"
                    }, {
                        "modelDeployment": "gpt4e1",
                        "modelName": "gpt-4o",
                        "modelVersion": "2024-05-13"
                    }
                ]
            }
        ]
        
    }]
    '@

    # 將 JSON 資料轉換為 PowerShell 物件
    $deployments = $jsonData | ConvertFrom-Json

    foreach ($deployment in $deployments) {
        # 取得資源群組名稱
        $groupName = $deployment.groupName
        
        # 建立資源群組
        New-AzResourceGroup -Name $groupName -Location eastus

        foreach($source in $deployment.source) {

            $sourceName = $source.sourceName
            $location = $source.location
            
            # 建立 OpenAI 服務
            New-AzCognitiveServicesAccount -ResourceGroupName $groupName -Name $sourceName -Type OpenAI -SkuName S0 -Location $location
        

            foreach($model in $source.modelArray) {
                $modelDeployment = $model.modelDeployment
                $modelName = $model.modelName
                $modelVersion = $model.modelVersion

                Write-Output "Processing deployment: $groupName, $sourceName, $modelDeployment, $modelName, $modelVersion, $location"

                $model = New-Object -TypeName 'Microsoft.Azure.Management.CognitiveServices.Models.DeploymentModel' -Property @{
                    Name = $modelName
                    Version = $modelVersion
                    Format = 'OpenAI'
                }

                $properties = New-Object -TypeName 'Microsoft.Azure.Management.CognitiveServices.Models.DeploymentProperties' -Property @{
                    Model = $model
                }

                $sku = New-Object -TypeName "Microsoft.Azure.Management.CognitiveServices.Models.Sku" -Property @{
                    Name = 'Standard'
                    Capacity = '10'
                }

                # 建立 OpenAI 模型部署
                New-AzCognitiveServicesAccountDeployment -ResourceGroupName $groupName -AccountName $sourceName -Name $modelDeployment -Properties $properties -Sku $sku
            }
        }
        
    }

    ```