<#
.SYNOPSIS
    Desativa e move utilizadores do Active Directory que estão a iniciar um período de férias.

.DESCRIPTION
    Este script foi projetado para ser executado diariamente como uma tarefa agendada. Ele lê um
    ficheiro CSV de entrada que contém os utilizadores que devem iniciar as férias no dia corrente.
    Para cada utilizador correspondente, o script desativa a sua conta no AD, move-o para uma
    Unidade Organizacional (OU) específica para contas em férias e grava um registo com a sua
    OU original para facilitar o processo de retorno.

.PARAMETER InputPath
    [Obrigatório] O caminho para o ficheiro CSV de entrada. Este ficheiro deve conter as
    colunas: SamAccountName, DataInicio, DataFim.

.PARAMETER VacationOU
    [Obrigatório] O Distinguished Name (DN) da Unidade Organizacional para onde os utilizadores
    em férias serão movidos. Ex: "OU=Ferias,DC=dominio,DC=com".

.PARAMETER RegistryPath
    [Obrigatório] O caminho para o ficheiro CSV de registo que será criado ou atualizado.
    Este ficheiro é usado pelo script Restore-ADUserFromVacation.ps1.

.EXAMPLE
    .\Set-ADUserVacation.ps1 -InputPath "C:\RH\ferias.csv" -VacationOU "OU=Ferias,DC=dominio,DC=com" -RegistryPath "C:\Scripts\AD\registo_ferias.csv" -Verbose
    Executa a verificação, processa os utilizadores que entram de férias hoje e exibe um relatório
    detalhado de cada ação na tela.

.EXAMPLE
    .\Set-ADUserVacation.ps1 -InputPath "C:\RH\ferias.csv" -VacationOU "OU=Ferias,DC=dominio,DC=com" -RegistryPath "C:\Scripts\AD\registo_ferias.csv" -WhatIf
    Simula a execução, mostrando quais utilizadores seriam desativados e movidos, e que dados
    seriam gravados no ficheiro de registo, mas sem realizar nenhuma alteração real no AD.

.NOTES
    Autor: Gustavo Barbosa
    Data da Versão: 2025-10-20
#>
function Set-ADUserVacation {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath,

        [Parameter(Mandatory = $true)]
        [string]$VacationOU,

        [Parameter(Mandatory = $true)]
        [string]$RegistryPath
    )

    process {
        if ($PSCmdlet.ShouldProcess("Active Directory e Ficheiros CSV", "Processar início de férias")) {

            # Importa o Módulo do Active Directory
            if (-not (Get-Module -Name ActiveDirectory)) {
                try {
                    Import-Module ActiveDirectory -ErrorAction Stop
                } catch {
                    Write-Error "ERRO CRÍTICO: O módulo do Active Directory não pôde ser importado."
                    return # Usa return para sair da função
                }
            }

            if (-not (Test-Path $InputPath)) {
                Write-Warning "Arquivo de entrada '$InputPath' não encontrado. Nenhum utilizador para processar."
                return
            }

            try {
                $VacationData = Import-Csv -Path $InputPath
            } catch {
                Write-Error "Falha ao ler o arquivo de entrada '$InputPath'. Verifique o formato e as permissões. Erro: $_"
                return
            }

            $Today = (Get-Date).ToString('yyyy-MM-dd')
            Write-Host "--- Iniciando verificação de FÉRIAS (IDA) para $Today ---" -ForegroundColor Yellow

            foreach ($user in $VacationData) {
                if ([string]::IsNullOrWhiteSpace($user.SamAccountName) -or [string]::IsNullOrWhiteSpace($user.DataInicio)) {
                    Write-Warning "AVISO: Linha ignorada por conter campos essenciais (SamAccountName, DataInicio) vazios."
                    continue
                }

                try {
                    $StartDate = (Get-Date $user.DataInicio).ToString('yyyy-MM-dd')
                } catch {
                    Write-Warning "AVISO: Data de início inválida para o utilizador '$($user.SamAccountName)'. Linha ignorada."
                    continue
                }

                if ($StartDate -eq $Today) {
                    Write-Host "DECISÃO: Início de férias hoje! Processando $($user.SamAccountName)..." -ForegroundColor Cyan
                    
                    try {
                        $ADUser = Get-ADUser -Identity $user.SamAccountName -Properties DistinguishedName -ErrorAction Stop
                        
                        # Cria o objeto para o registo
                        $registryObject = [PSCustomObject]@{
                            SamAccountName = $user.SamAccountName
                            DataFim        = (Get-Date $user.DataFim).ToString('yyyy-MM-dd')
                            OUOriginal     = $ADUser.DistinguishedName
                        }

                        # Exporta para o CSV de registo, adicionando ao ficheiro se ele já existir.
                        $registryObject | Export-Csv -Path $RegistryPath -NoTypeInformation -Encoding UTF8 -Append
                        Write-Verbose "[$($user.SamAccountName)] Registro de retorno criado em `"$RegistryPath`"."

                        # AÇÃO 1: Desativa a conta
                        Disable-ADAccount -Identity $ADUser
                        Write-Verbose "[$($user.SamAccountName)] Conta desativada."

                        # AÇÃO 2: Move o utilizador
                        Move-ADObject -Identity $ADUser -TargetPath $VacationOU
                        Write-Host "[$($user.SamAccountName)] Utilizador movido para a OU '$VacationOU'." -ForegroundColor Green

                    } catch {
                        Write-Error "Falha ao processar o início de férias para $($user.SamAccountName). Verifique se o utilizador existe no AD. Erro: $_"
                    }
                }
            }
            Write-Host "--- Verificação de FÉRIAS (IDA) concluída. ---" -ForegroundColor Yellow
        }
    }
}

# Para executar o script, chame a função com os parâmetros necessários.
# Exemplo: Set-ADUserVacation -InputPath "C:\ferias.csv" -VacationOU "OU=Ferias,DC=dominio,DC=com" -RegistryPath "C:\registo.csv"
