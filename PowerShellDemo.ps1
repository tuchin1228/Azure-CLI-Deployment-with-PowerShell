
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


