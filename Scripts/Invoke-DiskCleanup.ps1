<#
.SYNOPSIS
    Executa uma limpeza profunda de ficheiros temporários e caches em sistemas Windows.

.DESCRIPTION
    Este script foi projetado para libertar espaço em disco de forma segura. Ele para temporariamente
    os serviços do Windows Update e BITS, remove o conteúdo de várias pastas temporárias
    (Temp do Windows, Temp do utilizador), o cache de downloads do Windows Update e os ficheiros
    de Otimização de Entrega. No final, os serviços são reiniciados.
    Requer a execução com privilégios de Administrador.

.EXAMPLE
    .\Invoke-DiskCleanup.ps1 -Verbose
    Executa a limpeza completa e exibe na tela cada etapa que está a ser realizada.

.EXAMPLE
    .\Invoke-DiskCleanup.ps1 -WhatIf
    Simula a execução do script, mostrando quais serviços seriam parados e quais pastas seriam limpas,
    mas não executa nenhuma ação de exclusão ou alteração de serviço. É o modo mais seguro para testes.

.NOTES
    Autor: Gustavo Barbosa
    Data da Versão: 2025-10-20
#>
function Invoke-DiskCleanup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Executar Limpeza Avançada de Disco")) {
            
            Write-Host "--- INICIANDO LIMPEZA AVANÇADA DE DISCO ---" -ForegroundColor Yellow

            # --- Etapa 1: Parando serviços para libertar ficheiros em uso ---
            Write-Verbose "[ETAPA 1/5] Parando serviços do Windows Update e BITS..."
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            Stop-Service -Name BITS -Force -ErrorAction SilentlyContinue

            # --- Etapa 2: Limpeza de pastas de ficheiros temporários ---
            Write-Verbose "[ETAPA 2/5] Limpando pastas de ficheiros temporários..."
            $TempFolders = @(
                "$env:windir\Temp\*",
                "$env:TEMP\*",
                "$env:LOCALAPPDATA\Temp\*"
            )
            foreach ($folder in $TempFolders) {
                if (Test-Path $folder) {
                    try {
                        Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                        Write-Verbose "  - Pasta limpa: $folder"
                    } catch {
                        Write-Warning "  - Não foi possível limpar completamente a pasta: $folder. Alguns ficheiros podem estar em uso."
                    }
                }
            }

            # --- Etapa 3: Limpeza do Cache do Windows Update ---
            Write-Verbose "[ETAPA 3/5] Limpando cache de downloads do Windows Update..."
            $UpdateCache = "$env:windir\SoftwareDistribution\Download"
            if (Test-Path $UpdateCache) {
                try {
                    Remove-Item -Path "$UpdateCache\*" -Recurse -Force -ErrorAction Stop
                    Write-Verbose "  - Cache do Windows Update limpo com sucesso."
                } catch {
                    Write-Warning "  - Não foi possível limpar o cache do Windows Update."
                }
            }

            # --- Etapa 4: Limpando ficheiros de otimização de entrega ---
            Write-Verbose "[ETAPA 4/5] Limpando ficheiros de Otimização de Entrega..."
            $DeliveryOptimization = "$env:windir\SoftwareDistribution\DeliveryOptimization\*"
            if (Test-Path $DeliveryOptimization) {
                try {
                    Remove-Item -Path $DeliveryOptimization -Recurse -Force -ErrorAction Stop
                    Write-Verbose "  - Ficheiros de Otimização de Entrega removidos."
                } catch {
                    # Ignora o erro se a pasta não existir ou não puder ser removida
                }
            }

            # --- Etapa 5: Reiniciando os serviços ---
            Write-Verbose "[ETAPA 5/5] Reiniciando serviços..."
            Start-Service -Name wuauserv
            Start-Service -Name BITS

            Write-Host "--- LIMPEZA CONCLUÍDA ---" -ForegroundColor Yellow
        }
    }
}

# Para executar o script, chame a função.
# Pode adicionar -Verbose ou -WhatIf ao executar.
Invoke-DiskCleanup