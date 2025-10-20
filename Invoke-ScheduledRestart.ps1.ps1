<#
.SYNOPSIS
    Agenda uma reinicialização forçada do computador local após um período de tempo, exibindo uma notificação visual para o utilizador.

.DESCRIPTION
    Este script foi projetado para ser executado localmente numa estação de trabalho, idealmente através de
    uma Tarefa Agendada ou de um sistema de gestão remota. Ele exibe uma notificação "Toast" do Windows 10/11
    com um título e uma mensagem personalizáveis, aguarda um tempo definido e, em seguida, executa
    uma reinicialização forçada do computador. Requer privilégios de Administrador para reiniciar a máquina.

.PARAMETER DelayInSeconds
    O tempo de espera em segundos antes que o computador seja reiniciado. O valor padrão é 600 (10 minutos).

.PARAMETER Title
    O título da notificação que será exibida para o utilizador.

.PARAMETER Message
    A mensagem principal da notificação, explicando o motivo da reinicialização.

.EXAMPLE
    .\Invoke-ScheduledRestart.ps1 -DelayInSeconds 300 -Title "Atualização Crítica" -Message "O sistema será reiniciado em 5 minutos para aplicar atualizações de segurança."
    Agenda uma reinicialização para dali a 5 minutos com um título e mensagem personalizados.

.EXAMPLE
    .\Invoke-ScheduledRestart.ps1 -WhatIf
    Mostra que o computador seria reiniciado, mas não executa a notificação nem a reinicialização. Útil para validar a lógica do script.

.NOTES
    Autor: Gustavo Barbosa
    Data da Versão: 2025-10-20
#>
function Invoke-ScheduledRestart {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [int]$DelayInSeconds = 600,
        [string]$Title = "Aviso de Reinicialização",
        [string]$Message = "Este computador será reiniciado automaticamente em $($DelayInSeconds / 60) minutos para manutenção programada. Salve os seus trabalhos."
    )

    process {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Agendar Reinicialização com Notificação")) {
            
            Write-Verbose "A exibir notificação 'Toast' para o utilizador."

            # Tenta carregar os tipos necessários do Windows Runtime.
            try {
                [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
                $template = @"
<toast duration='long'>
    <visual>
        <binding template='ToastGeneric'>
            <text>$Title</text>
            <text>$Message</text>
        </binding>
    </visual>
</toast>
"@
                $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
                $xml.LoadXml($template)
                $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
                # O AppId pode ser qualquer string, mas ajuda a identificar a origem da notificação.
                $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("ManutencaoDoSistema")
                $notifier.Show($toast)
                Write-Verbose "Notificação enviada com sucesso."
            } catch {
                Write-Warning "Não foi possível exibir a notificação 'Toast'. O ambiente pode não suportar esta funcionalidade (ex: Windows Server Core). A reinicialização continuará."
                # Como alternativa, pode usar msg.exe se a notificação falhar
                # try { msg.exe * /TIME:30 "$Message" } catch {}
            }

            Write-Host "A aguardar $DelayInSeconds segundos antes de reiniciar..." -ForegroundColor Yellow
            Start-Sleep -Seconds $DelayInSeconds

            Write-Host "A iniciar a reinicialização forçada agora." -ForegroundColor Red
            Restart-Computer -Force
        }
    }
}

# Para executar o script, chame a função.
# Pode passar parâmetros para personalizar a execução.
Invoke-ScheduledRestart
