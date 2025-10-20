<#
.SYNOPSIS
    Aplica um conjunto de otimizações de performance em sistemas Windows.

.DESCRIPTION
    Este script foi projetado para melhorar a performance de estações de trabalho ao desativar
    serviços e tarefas agendadas que consomem recursos, como telemetria, indexação de pesquisa (Windows Search)
    e SysMain (Superfetch). Ele também realiza uma limpeza básica de ficheiros temporários.
    É crucial executar este script com privilégios de Administrador para que as alterações de serviços
    e tarefas agendadas possam ser aplicadas.

.EXAMPLE
    .\Invoke-WindowsOptimization.ps1 -Verbose
    Executa todas as otimizações e exibe um relatório detalhado de cada ação que está a ser tomada.

.EXAMPLE
    .\Invoke-WindowsOptimization.ps1 -WhatIf
    Simula a execução do script, mostrando todos os serviços que seriam parados/desativados e
    tarefas que seriam desativadas, mas sem realizar nenhuma alteração real no sistema.
    Este é o modo mais seguro para verificar o impacto do script antes de o executar.

.NOTES
    Autor: Gustavo Barbosa
    Data da Versão: 2025-10-20
#>
function Invoke-WindowsOptimization {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Aplicar Otimizações de Performance do Windows")) {
            
            Write-Host "--- INICIANDO OTIMIZAÇÃO DO SISTEMA ---" -ForegroundColor Yellow

            # Array de serviços a serem desativados
            $servicesToDisable = @("WSearch", "SysMain", "DiagTrack", "dmwappushservice")

            foreach ($serviceName in $servicesToDisable) {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    Write-Verbose "Processando serviço: $serviceName"
                    if ($service.Status -ne 'Stopped') {
                        Stop-Service -Name $serviceName -Force
                        Write-Verbose "  - Serviço parado."
                    }
                    if ($service.StartType -ne 'Disabled') {
                        Set-Service -Name $serviceName -StartupType Disabled
                        Write-Verbose "  - Tipo de inicialização definido como 'Disabled'."
                    }
                } else {
                    Write-Warning "Serviço '$serviceName' não encontrado. Pulando."
                }
            }

            # Array de tarefas agendadas a serem desativadas
            Write-Verbose "Desativando tarefas agendadas de telemetria..."
            $scheduledTasks = @(
                "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
                "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
                "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
            )
            foreach ($task in $scheduledTasks) {
                try {
                    schtasks /Change /TN $task /Disable 2>$null
                    Write-Verbose "  - Tarefa desativada: $task"
                } catch {
                    Write-Warning "  - Não foi possível desativar a tarefa '$task'."
                }
            }

            # Desativar sugestões e dicas do Windows via Registro
            Write-Verbose "Desativando sugestões de conteúdo via registo..."
            $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            $registryKeys = @("SubscribedContent-338389Enabled", "SubscribedContent-353698Enabled", "SubscribedContent-310093Enabled")
            
            if (Test-Path $registryPath) {
                foreach ($key in $registryKeys) {
                    try {
                        Set-ItemProperty -Path $registryPath -Name $key -Value 0 -ErrorAction Stop
                        Write-Verbose "  - Chave de registo definida: $key"
                    } catch {
                        # Ignora o erro se a chave não existir
                    }
                }
            }

            # Limpar ficheiros temporários
            Write-Verbose "Limpando ficheiros temporários..."
            $tempPaths = @("$env:temp\*", "C:\Windows\Temp\*")
            foreach ($path in $tempPaths) {
                if (Test-Path $path.TrimEnd('*')) {
                    Remove-Item $path -Force -Recurse -ErrorAction SilentlyContinue
                    Write-Verbose "  - Limpeza executada em: $path"
                }
            }

            Write-Host "--- OTIMIZAÇÃO CONCLUÍDA ---" -ForegroundColor Green
            Write-Host "É recomendado reiniciar o computador para que todas as alterações sejam aplicadas."
        }
    }
}

# Para executar o script, chame a função.
Invoke-WindowsOptimization
