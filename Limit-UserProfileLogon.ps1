<#
.SYNOPSIS
    Impede que novos utilizadores façam login numa máquina se o limite de perfis de utilizador for atingido.

.DESCRIPTION
    Este script foi projetado para ser implementado como um Script de Logon via Política de Grupo (GPO).
    A cada tentativa de login, ele verifica o número de perfis de utilizador já existentes na máquina.
    Se um novo utilizador tentar fazer login e o número de perfis existentes já tiver atingido
    o máximo configurado, o script exibe uma mensagem de bloqueio e executa o logoff do utilizador.
    Contas de sistema e de administrador especificadas são protegidas e nunca são contadas no limite.

.PARAMETER MaxProfiles
    [Obrigatório] O número máximo de perfis de utilizador que podem existir na máquina. Quando este limite
    é atingido, novos logins são bloqueados.

.PARAMETER ProtectedProfiles
    [Obrigatório] Uma lista (array de strings) com os nomes de utilizador que nunca devem ser considerados
    na contagem do limite. É crucial incluir contas de sistema e administradores principais.

.PARAMETER LogPath
    [Opcional] O caminho completo para um ficheiro de log. Se especificado, o script registará
    todas as tentativas de login e ações tomadas. Ex: "C:\Logs\LogonScript.log".

.EXAMPLE
    .\Limit-UserProfileLogon.ps1 -MaxProfiles 5 -ProtectedProfiles "Administrator","suporte.ti" -LogPath "C:\Logs\logon.txt" -Verbose
    Executa a verificação com um limite de 5 perfis, protegendo as contas "Administrator" e "suporte.ti",
    e grava os logs no ficheiro especificado, exibindo também o progresso na tela.

.NOTES
    Autor: Gustavo Barbosa
    Data da Versão: 2025-10-20
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [int]$MaxProfiles = 5,

    [Parameter(Mandatory = $true)]
    [string[]]$ProtectedProfiles = @(
        "Administrator",
        "Default",
        "Default User",
        "Public",
        "All Users",
        "suporte.ti"
    ),

    [Parameter(Mandatory = $false)]
    [string]$LogPath
)

# --- Função para registar logs ---
function Write-Log {
    param ([string]$Message)
    if ($LogPath) {
        try {
            if (-not (Test-Path (Split-Path $LogPath -Parent))) {
                New-Item -ItemType Directory -Path (Split-Path $LogPath -Parent) -Force | Out-Null
            }
            "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" | Add-Content -Path $LogPath
        } catch {
            Write-Warning "Não foi possível escrever no ficheiro de log em '$LogPath'."
        }
    }
    Write-Verbose $Message
}

try {
    $CurrentUser = $env:USERNAME
    Write-Log "Tentativa de login pelo utilizador: $CurrentUser"

    # Não executa a lógica para perfis protegidos
    if ($ProtectedProfiles -contains $CurrentUser) {
        Write-Log "O utilizador '$CurrentUser' é um perfil protegido. Login permitido."
        return
    }

    # Encontra o perfil do utilizador atual que o Windows já começou a criar.
    $CurrentUserProfile = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { $_.LocalPath.EndsWith($CurrentUser) }

    if ($CurrentUserProfile) {
        $LastUseTime = $CurrentUserProfile.LastUseTime
        $Now = Get-Date
        $DifferenceMinutes = ($Now - $LastUseTime).TotalMinutes

        # Se o perfil foi "usado" há menos de 2 minutos, consideramos que ele está a ser criado AGORA.
        if ($DifferenceMinutes -lt 2) {
            Write-Log "Novo login detectado para '$CurrentUser' (perfil recém-criado). Verificando o limite."

            # Contagem de perfis já estabelecidos na máquina.
            $EstablishedProfiles = Get-CimInstance -ClassName Win32_UserProfile | Where-Object {
                (-not $_.Special) -and `
                ($_.LocalPath -notlike "C:\Windows\*") -and `
                ($ProtectedProfiles -notcontains $_.LocalPath.Split('\')[-1]) -and `
                ($_.SID -ne $CurrentUserProfile.SID) # Exclui o perfil atual da contagem
            }
            $ExistingCount = $EstablishedProfiles.Count
            Write-Log "Perfis estabelecidos encontrados: $ExistingCount. Limite configurado: $MaxProfiles."

            if ($ExistingCount -ge $MaxProfiles) {
                $message = "Login Bloqueado: O número máximo de perfis de utilizador ($MaxProfiles) neste computador foi atingido. Entre em contato com o suporte de TI."
                Write-Log "ALERTA: Limite de perfis atingido. Bloqueando login para '$CurrentUser'."
                
                if ($PSCmdlet.ShouldProcess($CurrentUser, "Executar Logoff por excesso de perfis")) {
                    try { msg.exe * /TIME:30 "$message" } catch {}
                    logoff
                }
            } else {
                Write-Log "Limite de perfis OK. Permitindo a criação de novo perfil para '$CurrentUser'."
            }
        } else {
            Write-Log "Perfil para '$CurrentUser' já existe e é antigo. Login permitido."
        }
    } else {
        Write-Log "AVISO: Não foi possível encontrar o perfil para o utilizador atual. Permitindo login por segurança."
    }
} catch {
    Write-Log "ERRO CRÍTICO: Falha ao consultar os perfis de utilizador. Permitindo o login por segurança. Erro: $($_.Exception.Message)"
}

