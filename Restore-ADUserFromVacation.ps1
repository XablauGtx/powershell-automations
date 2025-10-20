<#
.SYNOPSIS
    Reativa e move utilizadores do Active Directory que estão a retornar de férias.

.DESCRIPTION
    Este script foi projetado para ser executado diariamente como uma tarefa agendada. Ele lê um
    ficheiro de registo CSV que contém os utilizadores atualmente em férias. Para cada utilizador,
    o script verifica se a data de retorno (data final das férias + 1 dia) é hoje. Se for,
    ele reativa a conta do utilizador no AD, move-o de volta para a sua Unidade Organizacional (OU)
    original e remove-o do ficheiro de registo. Requer o módulo ActiveDirectory.

.PARAMETER RegistryPath
    [Obrigatório] O caminho completo para o ficheiro CSV de registo (Ex: "C:\Scripts\UsuariosEmFerias.csv").
    Este ficheiro deve conter as colunas: SamAccountName, DataFim, OUOriginal.

.EXAMPLE
    .\Restore-ADUserFromVacation.ps1 -RegistryPath "C:\Scripts\UsuariosEmFerias.csv" -Verbose
    Executa a verificação, processa os utilizadores que retornam hoje e exibe um relatório detalhado
    de cada ação na tela.

.EXAMPLE
    .\Restore-ADUserFromVacation.ps1 -RegistryPath "C:\AD\Ferias.csv" -WhatIf
    Simula a execução, mostrando quais utilizadores seriam reativados e movidos, e como o ficheiro
    de registo seria atualizado, mas sem realizar nenhuma alteração real no AD ou no ficheiro.

.NOTES
    Autor: Gustavo Barbosa
    Data da Versão: 2025-10-20
#>
function Restore-ADUserFromVacation {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RegistryPath
    )

    process {
        if ($PSCmdlet.ShouldProcess("Active Directory e Ficheiro de Registo '$RegistryPath'", "Verificar e processar retorno de férias")) {
            
            # Importa o Módulo do Active Directory
            if (-not (Get-Module -Name ActiveDirectory)) {
                try {
                    Import-Module ActiveDirectory -ErrorAction Stop
                } catch {
                    Write-Error "ERRO CRÍTICO: O módulo do Active Directory não pôde ser importado."
                    return
                }
            }

            if (-not (Test-Path $RegistryPath)) {
                Write-Warning "Arquivo de registro '$RegistryPath' não encontrado. Nenhum utilizador para processar."
                return
            }

            try {
                # Usa o cmdlet nativo para mais robustez na leitura do CSV
                $VacationingUsers = Import-Csv -Path $RegistryPath
            } catch {
                Write-Error "Falha crítica ao ler ou processar o arquivo CSV. Verifique se não está aberto noutro programa. Erro: $_"
                return
            }
            
            $Today = (Get-Date).ToString('yyyy-MM-dd')
            Write-Host "--- Iniciando verificação de FÉRIAS (VOLTA) para $Today ---" -ForegroundColor Yellow

            if ($VacationingUsers.Count -eq 0) {
                Write-Host "Nenhum utilizador encontrado no arquivo de registro para processar."
                return
            }

            $UsersToKeepInRegistry = @()

            foreach ($user in $VacationingUsers) {
                Write-Verbose "--------------------------------------------------"
                Write-Verbose "Analisando utilizador: $($user.SamAccountName)"

                if ([string]::IsNullOrWhiteSpace($user.SamAccountName) -or [string]::IsNullOrWhiteSpace($user.DataFim)) {
                    Write-Warning "AVISO: Linha para '$($user.SamAccountName)' ignorada por conter campos essenciais vazios."
                    $UsersToKeepInRegistry += $user
                    continue
                }

                try {
                    $EndDate = [datetime]::ParseExact($user.DataFim.Trim(), 'yyyy-MM-dd', $null)
                    $ReturnDate = $EndDate.AddDays(1).ToString('yyyy-MM-dd')
                    Write-Verbose "Data Fim lida: $($user.DataFim) | Data de Retorno calculada: $ReturnDate"

                    if ($ReturnDate -eq $Today) {
                        Write-Host "DECISÃO: A data de retorno é hoje! Processando $($user.SamAccountName)..." -ForegroundColor Cyan
                        
                        try {
                            $ADUser = Get-ADUser -Identity $user.SamAccountName -ErrorAction Stop
                            
                            # Ação 1: Reativar a conta
                            Enable-ADAccount -Identity $ADUser
                            Write-Verbose "[$($user.SamAccountName)] Conta reativada com sucesso."

                            # Ação 2: Mover o objeto de volta para a OU original
                            Move-ADObject -Identity $ADUser -TargetPath $user.OUOriginal
                            Write-Host "[$($user.SamAccountName)] Utilizador movido de volta para '$($user.OUOriginal)'." -ForegroundColor Green
                        } catch {
                             Write-Error "Falha ao processar o utilizador do AD '$($user.SamAccountName)'. Ele será mantido no registo para verificação manual. Erro: $_"
                             $UsersToKeepInRegistry += $user
                        }
                    } else {
                        Write-Verbose "DECISÃO: Ainda não é o dia do retorno. Mantendo utilizador no registro."
                        $UsersToKeepInRegistry += $user
                    }
                } catch {
                    Write-Error "Falha ao processar a data para o utilizador '$($user.SamAccountName)'. Data lida: '$($user.DataFim)'. Ele será mantido no registo. Erro: $_"
                    $UsersToKeepInRegistry += $user
                }
            }

            # Atualiza o ficheiro de registo, mantendo apenas os utilizadores que ainda não retornaram.
            $UsersToKeepInRegistry | Export-Csv -Path $RegistryPath -NoTypeInformation -Encoding UTF8
            
            Write-Host "--------------------------------------------------"
            Write-Host "--- Verificação de FÉRIAS (VOLTA) concluída. Arquivo de registro atualizado. ---" -ForegroundColor Yellow
        }
    }
}

# Para executar o script, chame a função com os parâmetros necessários.
# Exemplo: Restore-ADUserFromVacation -RegistryPath "C:\Scripts\UsuariosEmFerias.csv"