##############################################################################################
### Nome do Script: backup_local.ps1                                                       ###
### Descrição: Script em PowerShell que agendado no windows executa backup de pastas       ###
### especificas e envia e-mail de quando inicia o backup e quando finaliza o backup.       ###
### Autor: Sérgionei Reichardt                                                             ###
### Data de criação: 15/10/2024                                                            ###
### Última modificação: 15/10/2024                                                         ###
### Versão: 1.0                                                                            ###
##############################################################################################

# Após ajustar as configurações desse script conforme sua necessidade, agende uma tarefa no Windows
# Abra o Agendador de tarefas
# Criar uma tarefa básica
# Nome: BACKUP LOCAL
# Descrição: REALIZAÇÃO DE BACKUP PARA UM UNIDADE EXTERNA OU OUTRO SERVIDOR, RECOMENDO TAMBÉM FAZER UMA CÓPIA EM NUVEM
# Quando deseja que a tarefa seja iniciada?: DIARIAMENTE
# Iniciar: 15/10/2024 00:00:00
# Repetir a cada [ 1 ] dia(s)
# Que ação deve ser executada pela tarefa?: INICIAR UM PROGRAMA
# Programa/script: PowerShell.exe
# Adicione argumentos (opcional): -ExecutionPolicy Unrestricted -File UNIDADE-ONDE-ESTA-SCRIPT:\SCRIPT-BACKUP\backup_local.ps1
# Da um ok/aplicar
# Clique com o botão direito na tarefa criada BACKUP LOCAL
# Propriedades
# Marque a opção: EXECUTAR ESTANDO O USUÁRIO CONECTADO OU NÃO
# Marque a opção: EXECUTAR COM PRIVILEGIOS MAIS ALTOS
# Aba Disparadores: Você pode iniciar a tarefa em direfestes horários, exemplo diariamente ou de hora em hora
# Dê um OK, vai pedir a senha do usuário com as permições mais altas da máquina, rede ou domínio.

# Configurações de e-mail
$smtpServer = "smtp.servidor.com.br"
$smtpFrom = "seuemail@servidor.com.br"
$smtpUser = "seuemail@servidor.com.br"
$smtpPassword = "DIGITE-AQUI-A-SENHA-DO-EMAIL-QUE-ENVIA"
$smtpTo = "destinatario1@servidor.com.br, destinatario1@servidor.com.br, destinatario1@servidor.com.br"

# Função para enviar e-mail
function Send-Email {
    param (
        [string]$Subject,
        [string]$Body
    )

    # Criar objeto de e-mail
    $mailMessage = New-Object System.Net.Mail.MailMessage
    $mailMessage.From = $smtpFrom
    $mailMessage.To.Add($smtpTo)
    $mailMessage.Subject = $Subject
    $mailMessage.Body = $Body

    # Configurar cliente SMTP
    $smtpClient = New-Object System.Net.Mail.SmtpClient($smtpServer)
    $smtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $smtpPassword)

    # Enviar e-mail
    try {
        $smtpClient.Send($mailMessage)
        Write-Host "E-mail enviado com sucesso."
    } catch {
        Write-Host "Falha ao enviar e-mail. Detalhes do erro: $_"
    }
}

# Enviar e-mail de início de backup
$backupStartTime = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
$messageSubject = "[BACKUP LOCAL] - Início do Backup"
$messageBody = "Backup iniciado em $backupStartTime`n"

Send-Email -Subject $messageSubject -Body $messageBody

# Configurações do backup
#   @{source="\\IP-SERVIDOR-ORIGEM\\NOME-PASTA-ORIGEM"; destination="LETRA-UNIDADE-DESTINO:\\PASTA-PRINCIPAL-DESTINO\SUBPASTAS-DESTINO"}
# Você pode configurar quantas pastas e servior que quiser para fazer o backup
# Abaixo tem dois exemplos, sempre separando por vírgular e a ultima linha se a virgula.
$foldersToBackup = @(
    @{source="\\192.168.100.100\\PASTA-1"; destination="F:\\BACKUP\NOME-SERVIDOR\PASTA-1"},
    @{source="\\192.168.100.200\\PASTA-X"; destination="F:\\BACKUP\NOME-SERVIROR\PASTA-X"}

)

$logFolder = "F:\\BACKUP\"
$logFileName = "backup_log_" + (Get-Date -Format "ddMMyyyy-HHmm") + ".log"
$logFile = Join-Path -Path $logFolder -ChildPath $logFileName

# Verifica se a pasta de log existe
if (-not (Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory
}

# Variável para armazenar o status detalhado de cada pasta
$folderStatus = "`nPastas que entraram no backup:`n"

# Loop através das pastas para realizar o backup incremental
foreach ($folder in $foldersToBackup) {
    $sourcePath = $folder.source
    $destinationPath = $folder.destination

    # Adiciona a origem de cada pasta ao status
    $folderStatus += "$sourcePath`n"

    # Comando Robocopy
    $robocopyArgs = "/MIR /w:1 /r:1 /log+:$logFile /np /nfl /ndl"
    
    # Executar Robocopy para backup incremental
    Start-Process -FilePath "robocopy" -ArgumentList "$sourcePath $destinationPath $robocopyArgs" -Wait
}

# Enviar e-mail de conclusão do backup com a lista das pastas
$backupEndTime = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
$messageSubject = "[BACKUP LOCAL] - Fim do Backup"
$messageBody = "Backup concluído em $backupEndTime`n" + $folderStatus
Send-Email -Subject $messageSubject -Body $messageBody