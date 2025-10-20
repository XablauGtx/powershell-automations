Scripts de Automação com PowerShell para Ambientes Windows

Este repositório contém uma coleção de scripts PowerShell desenvolvidos para automatizar tarefas comuns de administração de sistemas, segurança e manutenção em ambientes Windows. Cada script foi projetado para resolver um problema específico do dia a dia de uma equipa de TI e refatorado para seguir as melhores práticas, como o uso de funções avançadas, parâmetros e ajuda integrada.

Scripts Disponíveis

1. Gestão de Utilizadores (Active Directory)

Set-ADUserVacation.ps1: Automatiza o processo de "iniciar férias" de um utilizador. O script lê um ficheiro CSV, desativa a conta do utilizador no AD, move-o para uma OU específica de "Férias" e regista a sua OU original para o retorno.

Restore-ADUserFromVacation.ps1: Automatiza o processo de "retorno de férias". O script verifica um ficheiro de registo e, na data correta, reativa a conta do utilizador e move-o de volta para a sua Unidade Organizacional de origem.

2. Manutenção e Inventário Remoto

Get-RemotePCInventory.ps1: Executa um inventário remoto completo de hardware e software numa lista de computadores da rede. Gera um relatório detalhado em .txt para cada máquina, centralizando as informações num compartilhamento de rede.

Invoke-RemotePCRestart.ps1: Um utilitário interativo que solicita o nome de uma máquina e envia um comando de reinicialização remota.

Invoke-IntelligentRestart.ps1: Reinicia remotamente uma lista de computadores de forma inteligente. Se um utilizador estiver logado, o script envia uma mensagem de aviso e agenda a reinicialização. Caso contrário, reinicia a máquina imediatamente.

Stop-RemotePCFromFile.ps1: Desliga remotamente uma lista de computadores especificada num ficheiro de texto.

3. Manutenção e Segurança de Endpoints (GPO / Local)

Invoke-DiskCleanup.ps1: Realiza uma limpeza profunda em discos de sistemas Windows, removendo ficheiros temporários, caches do Windows Update e outros ficheiros desnecessários para libertar espaço.

Invoke-WindowsOptimization.ps1: Aplica um conjunto de otimizações de performance em máquinas Windows, desativando serviços de telemetria, indexação de pesquisa e outras funcionalidades que consomem recursos.

Invoke-ScheduledRestart.ps1: Envia uma notificação visual para o utilizador logado e força uma reinicialização após um tempo pré-determinado. Ideal para ser implementado como uma tarefa agendada.

Limit-UserProfileLogon.ps1: Um script de segurança para ser implementado via GPO como script de logon. Ele impede que novos utilizadores façam login numa máquina se o número de perfis de utilizador já existentes exceder um limite pré-definido.

Como Usar

Cada script foi transformado numa função avançada e inclui um bloco de ajuda detalhado. Para entender como usar qualquer um dos scripts, execute o seguinte comando no PowerShell:

Get-Help .\NomeDoScript.ps1 -Full


Isto irá exibir a sinopse, descrição completa e exemplos práticos de uso para cada ferramenta.
