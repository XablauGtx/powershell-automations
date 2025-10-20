Scripts de Automação com PowerShell para Ambientes Windows

Este repositório contém uma coleção de scripts PowerShell desenvolvidos para automatizar tarefas comuns de administração de sistemas, segurança e manutenção em ambientes Windows. Cada script foi projetado para resolver um problema específico do dia a dia de uma equipa de TI.

Scripts Disponíveis

1. Gestão de Férias no Active Directory

IniciarFerias.ps1: Automatiza o processo de "iniciar férias" de um utilizador. O script lê um ficheiro CSV, desativa a conta do utilizador no AD, move-o para uma OU específica de "Férias" e regista a sua OU original para o retorno.

FinalizarFerias.ps1: Automatiza o processo de "retorno de férias". O script verifica um ficheiro de registo e, na data correta, reativa a conta do utilizador e move-o de volta para a sua Unidade Organizacional de origem.

2. Manutenção e Inventário de Estações de Trabalho

Inventario.ps1: Executa um inventário remoto completo de hardware e software numa lista de computadores da rede. Gera um relatório detalhado em .txt para cada máquina, centralizando as informações num compartilhamento de rede.

Limpeza de Disco.ps1: Realiza uma limpeza profunda em discos de sistemas Windows, removendo ficheiros temporários, caches do Windows Update e ficheiros de otimização de entrega para libertar espaço.

Otimizar.ps1: Aplica um conjunto de otimizações de performance em máquinas Windows, desativando serviços de telemetria, indexação de pesquisa e outras funcionalidades que consomem recursos desnecessariamente.

Reinicar Correto.ps1: Reinicia remotamente uma lista de computadores de forma inteligente. Se um utilizador estiver logado, o script envia uma mensagem de aviso e agenda a reinicialização. Caso contrário, reinicia a máquina imediatamente.

3. Segurança de Endpoints

BloquearLogin.ps1: Um script de segurança para ser implementado via GPO como script de logon. Ele impede que novos utilizadores façam login numa máquina se o número de perfis de utilizador já existentes exceder um limite pré-definido, evitando a sobrecarga de perfis em máquinas partilhadas.

Como Usar

Cada script contém uma secção de "Configuração" no topo, onde as variáveis (como caminhos de ficheiros e nomes de OUs) podem ser facilmente ajustadas para se adequarem a diferentes ambientes.
