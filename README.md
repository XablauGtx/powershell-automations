<!-- BANNER -->
<p align="center">
  <img src="https://raw.githubusercontent.com/<seu-usuario>/<seu-repo>/main/assets/banner-powershell.png" alt="PowerShell Automation Banner" width="100%">
</p>

<h1 align="center">⚙️ PowerShell Automation Scripts for Windows Environments</h1>

<p align="center">
  <b>Automatize. Padronize. Domine o seu ambiente Windows.</b>
</p>

<p align="center">
  <a href="https://learn.microsoft.com/en-us/powershell/"><img src="https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell&logoColor=white" alt="PowerShell"></a>
  <a href="#"><img src="https://img.shields.io/badge/Windows-10%2F11%20%7C%20Server%202019+-0078D6?logo=windows&logoColor=white" alt="Windows"></a>
  <a href="#"><img src="https://img.shields.io/badge/Status-Ativo-brightgreen?style=flat-square" alt="Status"></a>
  <a href="https://github.com/<seu-usuario>/<seu-repo>/issues"><img src="https://img.shields.io/github/issues/<seu-usuario>/<seu-repo>?color=orange&style=flat-square" alt="Issues"></a>
  <a href="https://github.com/<seu-usuario>/<seu-repo>/commits/main"><img src="https://img.shields.io/github/last-commit/<seu-usuario>/<seu-repo>?color=yellow&style=flat-square" alt="Last Commit"></a>
</p>

---

## 🧭 Visão Geral

Este repositório contém uma coleção de **scripts PowerShell** desenvolvidos para automatizar tarefas comuns de **administração, segurança e manutenção** em **ambientes Windows corporativos**.  

Cada script segue as **melhores práticas**:  
✅ Funções avançadas  
✅ Parâmetros e validações robustas  
✅ Ajuda integrada (`Get-Help`)  
✅ Logging padronizado  
✅ Compatibilidade com PowerShell 5.1+ e 7.x  

---

## 🧑‍💼 Gestão de Utilizadores (Active Directory)

| Script | Função |
|--------|--------|
| 🗂️ **Set-ADUserVacation.ps1** | Desativa contas e move utilizadores para uma OU de “Férias”. Regista a OU original para retorno. |
| 🔄 **Restore-ADUserFromVacation.ps1** | Reativa automaticamente contas no retorno e move-as de volta à OU de origem. |

---

## 🧰 Manutenção e Inventário Remoto

| Script | Função |
|--------|--------|
| 🧾 **Get-RemotePCInventory.ps1** | Gera inventário remoto (hardware + software) e exporta relatórios centralizados. |
| ♻️ **Invoke-RemotePCRestart.ps1** | Reinicialização remota de um único host, com confirmação. |
| ⚡ **Invoke-IntelligentRestart.ps1** | Reinicialização inteligente em massa — detecta sessões logadas e agenda o restart. |
| ⏻ **Stop-RemotePCFromFile.ps1** | Desliga remotamente todas as máquinas listadas num ficheiro .txt. |

---

## 🔒 Manutenção e Segurança de Endpoints (GPO / Local)

| Script | Função |
|--------|--------|
| 🧹 **Invoke-DiskCleanup.ps1** | Limpeza profunda de temporários, cache e Windows Update. |
| 🚀 **Invoke-WindowsOptimization.ps1** | Otimiza o Windows desativando serviços pesados e telemetria. |
| 🔁 **Invoke-ScheduledRestart.ps1** | Exibe notificação e reinicia após tempo definido — ideal para tarefas agendadas. |
| 👥 **Limit-UserProfileLogon.ps1** | Bloqueia logins se o limite de perfis locais for atingido (ideal via GPO). |

---

## ⚙️ Como Usar

Cada script possui **ajuda integrada**. Para exibir detalhes completos, execute:

```powershell
Get-Help .\NomeDoScript.ps1 -Full
```


🔹 Inclui:

Sinopse e parâmetros detalhados

Exemplos reais de uso

Observações de compatibilidade

🧩 Padrões Seguidos

✔️ Convenção de nomes Verb-Noun
✔️ Uso de [CmdletBinding()] e [Parameter()]
✔️ Tratamento de erros com Try/Catch
✔️ Logging centralizado
✔️ Comentários estruturados para gerar documentação automática

💬 Contribuições

Sinta-se à vontade para colaborar!
Abra um Pull Request com novos scripts, correções ou melhorias.

👉 Ver Issues

👨‍💻 Autor

Gustavo Barbosa
💼 Profissional de TI • Automação • Infraestrutura • PowerShell
🌐 Portfólio

💻 GitHub
 | 💬 LinkedIn

<p align="center"> <i>“Automatizar é libertar tempo para o que realmente importa.”</i> <br>— PowerShell Automation Lab </p> ```
