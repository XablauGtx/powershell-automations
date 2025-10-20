<#
.SYNOPSIS
    Reinicia uma lista de computadores de forma inteligente, verificando se há utilizadores logados.

.DESCRIPTION
    Este script percorre uma lista de computadores. Para cada um, verifica se há uma sessão de utilizador ativa.
    Se um utilizador estiver logado, o script agenda uma reinicialização para dali a 10 minutos e envia uma mensagem de aviso.
    Se a máquina estiver inativa (sem sessão de utilizador detetada), ela é reiniciada imediatamente.
    Requer privilégios de administrador nos computadores de destino.

.PARAMETER ComputerName
    [Obrigatório] Um ou mais nomes de computador para reiniciar. Pode ser uma string, um array de strings ou pode vir do pipeline.

.PARAMETER DelayMinutes
    [Opcional] O tempo de espera em minutos para a reinicialização agendada, caso um utilizador esteja logado. O padrão é 10 minutos.

.PARAMETER WarningMessage
    [Opcional] A mensagem de aviso que será enviada ao utilizador logado.

.EXAMPLE
    Get-Content C:\Scripts\computadores.txt | .\Invoke-IntelligentRestart.ps1 -Verbose
    Lê uma lista de computadores de um ficheiro de texto e executa o reinício inteligente em cada um,
    exibindo informações detalhadas do processo.

.EXAMPLE
    .\Invoke-IntelligentRestart.ps1 -ComputerName "PC-01", "PC-02" -DelayMinutes 5 -Force
    Executa o reinício inteligente nos dois PCs especificados. Se estiverem em uso, o aviso será de 5 minutos.
    A flag -Force ignora a confirmação "Tem a certeza?".

.EXAMPLE
    .\Invoke-IntelligentRestart.ps1 -ComputerName "PC-INATIVO" -WhatIf
    Simula a execução, mostrando se o PC seria reiniciado imediatamente ou de forma agendada, mas não executa nenhuma ação.

.NOTES
    Autor: Gustavo Barbosa
    Data da Versão: 2025-10-20
#>
function Invoke-IntelligentRestart {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName,

        [int]$DelayMinutes = 10,

        [string]$WarningMessage = "AVISO DE TI: Este computador será reiniciado em $DelayMinutes minutos para manutenção. Por favor, salve o seu trabalho."
    )

    begin {
        Write-Verbose "Iniciando verificação de reinício inteligente."
        $DelaySeconds = $DelayMinutes * 60
    }

    process {
        foreach ($PC in $ComputerName) {
            Write-Host "-------------------------------------------"
            Write-Host "Verificando PC: $PC"

            if (-not (Test-Connection -ComputerName $PC -Count 1 -Quiet)) {
                Write-Warning "  - STATUS: Offline. Impossível conectar."
                continue
            }

            if ($PSCmdlet.ShouldProcess($PC, "Executar Reinício Inteligente")) {
                try {
                    $LoggedOnUser = $null
                    $ExplorerProcess = Get-CimInstance -ClassName Win32_Process -ComputerName $PC -Filter "Name = 'explorer.exe'" -ErrorAction SilentlyContinue

                    if ($ExplorerProcess) {
                        $Owner = Invoke-CimMethod -InputObject $ExplorerProcess[0] -MethodName GetOwner
                        if ($Owner.Domain) {
                            $LoggedOnUser = "$($Owner.Domain)\$($Owner.User)"
                        } else {
                            $LoggedOnUser = $Owner.User
                        }
                    }

                    if (-not [string]::IsNullOrWhiteSpace($LoggedOnUser)) {
                        Write-Host "  - STATUS: Ativo. Utilizador logado: $LoggedOnUser" -ForegroundColor Cyan
                        Write-Verbose "  - AÇÃO: Agendando reinicialização em $DelayMinutes minutos para $PC..."
                        
                        shutdown.exe /r /f /m \\$PC /t $DelaySeconds /c "$WarningMessage"
                        
                        Write-Host "  - SUCESSO: Reinicialização agendada para $PC em $DelayMinutes minutos." -ForegroundColor Green
                    } else {
                        Write-Host "  - STATUS: Inativo. Nenhuma sessão de utilizador encontrada." -ForegroundColor Magenta
                        Write-Verbose "  - AÇÃO: Enviando comando de reinicialização imediata para $PC..."
                        
                        Restart-Computer -ComputerName $PC -Force -Wait -Timeout 120 -ErrorAction Stop
                        
                        Write-Host "  - SUCESSO: O computador $PC foi reiniciado." -ForegroundColor Green
                    }
                } catch {
                    Write-Error "  - ERRO: Falha ao consultar o computador $PC. Verifique as permissões de acesso remoto. Erro: $($_.Exception.Message)"
                }
            }
        }
    }

    end {
        Write-Verbose "Verificação de reinício inteligente concluída."
    }
}

# Para executar o script, você deve chamá-lo a partir do terminal passando os parâmetros.
# Exemplo: Get-Content C:\lista.txt | .\Invoke-IntelligentRestart.ps1
