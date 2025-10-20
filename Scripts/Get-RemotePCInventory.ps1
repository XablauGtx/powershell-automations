<#
.SYNOPSIS
    Coleta informações detalhadas de hardware e software de uma lista de computadores na rede.

.DESCRIPTION
    Este script executa um inventário remoto completo em cada computador especificado,
    coletando dados de SO, hardware (CPU, RAM, Disco, Service Tag) e software instalado.
    Um relatório em formato .txt é gerado para cada máquina num diretório de destino.
    Requer privilégios de administrador nas máquinas de destino e acesso de escrita na pasta de relatórios.

.PARAMETER ComputerListPath
    O caminho para um arquivo de texto (.txt) contendo a lista de nomes de computadores, um por linha.

.PARAMETER ReportPath
    O caminho para a pasta (local ou de rede) onde os relatórios de inventário serão salvos.

.EXAMPLE
    .\Get-RemotePCInventory.ps1 -ComputerListPath "C:\Temp\lista_pcs.txt" -ReportPath "\\Servidor\Relatorios\Inventario" -Verbose
    Executa o inventário usando a lista de PCs especificada, salva os relatórios na pasta de rede e exibe o progresso detalhado na tela.

.EXAMPLE
    .\Get-RemotePCInventory.ps1 -ComputerListPath "C:\Temp\lista_pcs.txt" -ReportPath "C:\Inventarios"
    Executa o inventário e salva os relatórios localmente na pasta C:\Inventarios, sem exibir progresso detalhado.
#>
[CmdletBinding()]
param(
    # 1. Arquivo de texto contendo a lista de nomes de computadores, um por linha.
    [Parameter(Mandatory = $true)]
    [string]$ComputerListPath,

    # 2. Caminho da pasta (local ou de rede) onde os relatórios serão salvos.
    [Parameter(Mandatory = $true)]
    [string]$ReportPath
)

# --- Função para Salvar o Relatório em Arquivo ---
function Save-Report {
    param(
        [string]$ReportContent,
        [string]$DestinationPath,
        [string]$ComputerName
    )
    try {
        if (-not (Test-Path -Path $DestinationPath)) {
            Write-Warning "A pasta de destino '$DestinationPath' não foi encontrada. Tentando criar..."
            New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        }

        $FileName = "$($ComputerName)_$(Get-Date -Format 'yyyy-MM-dd').txt"
        $FullPath = Join-Path -Path $DestinationPath -ChildPath $FileName

        Write-Verbose "  - Salvando relatório em: $FullPath"
        $ReportContent | Out-File -FilePath $FullPath -Encoding utf8 -ErrorAction Stop
        Write-Host "  - Relatório para '$ComputerName' salvo com sucesso!" -ForegroundColor Green
    } catch {
        Write-Error "  - Falha ao salvar o arquivo de relatório para '$ComputerName'. Verifique as permissões de escrita na pasta '$DestinationPath'. Erro: $_"
    }
}

# --- Verificação Inicial ---
if (-not (Test-Path $ComputerListPath)) {
    Write-Error "Arquivo de lista de computadores '$ComputerListPath' não encontrado."
    exit
}
$ComputerList = Get-Content -Path $ComputerListPath

# --- Loop Principal ---
Write-Host "--- INICIANDO INVENTÁRIO REMOTO ---" -ForegroundColor Yellow

foreach ($pc in $ComputerList) {
    Write-Host "--------------------------------------------------"
    Write-Host "Processando computador: $pc"

    if (-not (Test-Connection -ComputerName $pc -Count 1 -Quiet)) {
        Write-Warning "  - STATUS: Offline. Impossível conectar. Pulando para o próximo."
        continue
    }

    try {
        Write-Verbose "  - Coletando dados de Hardware e SO..."
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $pc
        $CPU = Get-CimInstance -ClassName Win32_Processor -ComputerName $pc
        $RAM = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $pc
        $BIOS = Get-CimInstance -ClassName Win32_BIOS -ComputerName $pc
        $Disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $pc
        $Adapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled='TRUE'" -ComputerName $pc

        # ... (O restante da lógica de montagem do relatório permanece o mesmo) ...
        $osInfo = @"
Sistema Operacional: $($OS.Caption)
Versão:              $($OS.Version)
Arquitetura:         $($OS.OSArchitecture)
Último Boot:         $($OS.LastBootUpTime)
"@
        $serviceTagInfo = "Service Tag (Serial):  $($BIOS.SerialNumber)"
        $cpuInfo = "Processador:         $($CPU.Name)"
        $memoriaGB = [math]::Round($RAM.TotalPhysicalMemory / 1GB, 2)
        $ramInfo = "Memória RAM Total:   $memoriaGB GB"
        $diskInfo = "Discos:`n"
        foreach ($disk in $Disks) {
            $tamanhoGB = [math]::Round($disk.Size / 1GB, 2)
            $livreGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $diskInfo += "  - $($disk.DeviceID) Tamanho: $tamanhoGB GB, Livre: $livreGB GB`n"
        }
        $networkInfo = "Rede:`n"
        foreach ($adapter in $Adapters) {
            $networkInfo += "  - Descrição: $($adapter.Description)`n"
            $networkInfo += "    MAC:       $($adapter.MACAddress)`n"
            $networkInfo += "    IP:        $($adapter.IPAddress -join ', ')`n"
        }

        Write-Verbose "  - Coletando lista de softwares (pode demorar)..."
        $Software = Invoke-Command -ComputerName $pc -ScriptBlock {
            Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
            Select-Object DisplayName, DisplayVersion |
            Where-Object { $_.DisplayName -ne $null } |
            Sort-Object DisplayName
        }
        $softwareInfo = "Software Instalado:`n"
        foreach ($app in $Software) {
            $softwareInfo += "  - $($app.DisplayName) (Versão: $($app.DisplayVersion))`n"
        }

        $FinalReport = @"
================================================
RELATÓRIO DE INVENTÁRIO PARA: $pc
Data da Coleta: $(Get-Date)
================================================

--- Sistema Operacional ---
$osInfo

--- Hardware ---
$serviceTagInfo
$cpuInfo
$ramInfo
$diskInfo
$networkInfo

--- Software ---
$softwareInfo
"@
        Save-Report -ReportContent $FinalReport -DestinationPath $ReportPath -ComputerName $pc

    } catch {
        Write-Error "  - ERRO GERAL: Falha ao coletar dados do computador '$pc'. Verifique as permissões de acesso remoto (WMI/WinRM). Erro: $($_.Exception.Message)"
    }
}

Write-Host "--------------------------------------------------"
Write-Host "--- INVENTÁRIO CONCLUÍDO ---" -ForegroundColor Yellow