<#
.SYNOPSIS
    Desliga remotamente uma lista de computadores a partir de um arquivo de texto.

.DESCRIPTION
    Este script lê uma lista de nomes de computadores de um arquivo de texto especificado,
    verifica se cada máquina está online e, em seguida, envia um comando de desligamento forçado.
    Requer privilégios de administrador nos computadores de destino.

.PARAMETER Path
    [Obrigatório] O caminho completo para o arquivo de texto (.txt) que contém a lista
    de nomes de computadores, um por linha.

.EXAMPLE
    .\Stop-RemotePCFromFile.ps1 -Path "D:\Scripts\MaquinasParaDesligar.txt"
    Lê a lista do arquivo especificado e desliga cada computador. O PowerShell irá pedir
    confirmação para cada máquina antes de agir.

.EXAMPLE
    .\Stop-RemotePCFromFile.ps1 -Path "D:\Scripts\MaquinasParaDesligar.txt" -Force -Verbose
    Lê a lista, força o desligamento de cada máquina sem pedir confirmação e exibe
    informações detalhadas sobre o progresso.

.EXAMPLE
    Get-Content ".\lista.txt" | .\Stop-RemotePCFromFile.ps1 -WhatIf
    Lê a lista a partir de um ficheiro no mesmo diretório, e simula a operação,
    mostrando quais computadores seriam desligados, mas sem executar a ação.

.NOTES
    Autor: Gustavo Barbosa
    Data da Versão: 2025-10-20
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$Path
)

begin {
    Write-Verbose "Iniciando o processo de desligamento remoto em massa."
    
    if (-not (Test-Path $Path)) {
        Write-Error "O arquivo especificado não foi encontrado em '$Path'."
        # Interrompe a execução do script se o arquivo não existir.
        return
    }
    
    $ComputerList = Get-Content -Path $Path
}

process {
    foreach ($PC in $ComputerList) {
        # Ignora linhas em branco no arquivo de texto
        if ([string]::IsNullOrWhiteSpace($PC)) {
            continue
        }

        # Verifica se o computador está online antes de tentar desligá-lo
        if (-not (Test-Connection -ComputerName $PC -Count 1 -Quiet)) {
            Write-Warning "Não foi possível conectar ao computador '$PC'. A máquina pode estar offline. Pulando."
            continue
        }

        # A ação principal: Desligar o computador
        if ($PSCmdlet.ShouldProcess($PC, "Enviar comando de Desligamento")) {
            try {
                Write-Verbose "A tentar desligar o computador: $PC"
                Stop-Computer -ComputerName $PC -Force -ErrorAction Stop
                Write-Host "Comando de desligamento enviado com sucesso para $PC." -ForegroundColor Green
            }
            catch {
                Write-Error "Falha ao enviar o comando de desligamento para '$PC'. Verifique a conectividade e as permissões. Erro: $($_.Exception.Message)"
            }
        }
    }
}

end {
    Write-Verbose "Processo de desligamento remoto concluído."
}