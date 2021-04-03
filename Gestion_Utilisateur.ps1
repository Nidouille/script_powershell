<#

.SYNOPSIS
Script permettant de requêter les objets utilisateurs des Active Directory enfants de GROUP.CORP en fonction d'une OU

.DESCRIPTION
Ce script permet d'extraire la liste des utilisateurs actifs n'ayant pas ouvert de session dans une OU d'un domaine depuis un temps déterminé.
Ce script exclut les samaccountname commencant par "svc-"


Il envoi 1 fichier par mail avec le résultat de la requête.

.NOTES
Créé le		: 16/02/2017
Projet		: ALIAXIS - gestion des comptes utilisateurs
Equipe		: 
Version		: v2.0
Modifications :	
	Auteur  V1.1 : Liste des modifications
    Auteur  V2.0 : Fabrice LUCAS : modification pour gérer les OUs - Exclusion des Samccountname génériques + Export basé sur lastlogontimestamp

Localisation	: c:\temp (par défaut)
Dépendances	:
Execution		: parametres : Oui/Non

.FUNCTIONALITY
 Usage auquel la fonction est destinée. Ce contenu apparaît lorsque la commande Get-Help inclut le paramètre Functionality de Get-Help.

.PARAMETER Example
Controller = Donner le nom d'un controleur de domaine sur lequel executer la requête
Delay = Le nombre de jours  pour lequel il n'y a pas eu d'ouverture de session.
Ou = L'OU de la société où sont les users
Emaillocalcontact = Le contact local de la société
Emaillocalit = Le contact local de l'IT
Emaillocalrh = Le contact local de la RH
 
.EXAMPLE
Gestion_Utilisateur_v4.ps1 -delay 60 -Controller R2FRCHLECDC01.r2.group.corp -OU "ou=users,ou=nicoll-fr,dc=r2,dc=group,dc=corp" -emaillocalcontact gchaillou@aliaxis.com -emaillocalit gchaillou@aliaxis.com -emaillocalrh gchaillou@aliaxis.com
Effectue une recherche des utilisateurs n'ayant pas ouvert de session depuis au moins 60 jours. La recherche s'effectue sur le controleur de domaine R2FRCHLECDC01.r2.group.corp


.LINK
URL vers WIKI ou internet

#>


##########################################
# PARAMETRES DU SCRIPT
##########################################
[CmdletBinding()]
param (
	$Delay='90',
    [Parameter(Mandatory=$True)] [String]$Controller,
    [Parameter(Mandatory=$True)] [String]$OU,
    [string]$emaillocalcontact='gchaillou@aliaxis.com',
    [string]$emaillocalit='gchaillou@aliaxis@aliaxis.com',
    [string]$emaillocalrh='gchaillou@aliaxis.com'
    )

##########################################
# FONCTIONS
##########################################


##########################################
 # VARIABLES
##########################################

$error.clear()
$ScriptVersion='1.0'                 #Version du script
#$FonctionVersionMini=1.7		#Version minimum attendue du fichier de fonctions basiques
$thisScript = Split-Path $myInvocation.MyCommand.Path -Leaf
$scriptRoot = Split-Path(Resolve-Path $myInvocation.MyCommand.Path)
$Log="C:\temp\" + $thisScript+ ".log"
$LogError={if (-not $?) { "Warning : $($error[0].exception.message)"  | out-file $Log -Append -NoClobber ;$Error.Clear() } }

		if(!(Test-Connection $Controller -BufferSize 16 -Count 1 -ea 0)){
			"Serveur injoignable : $Controller" | out-file $Log -Append -NoClobber
		}
$EndDate=(Get-Date)

#Variable d'environnement 
$ConfirmPreference = 'None'                #Supprime la demande de confirmation à chaque commande remove-item, notamment.
$ErrorActionPreference='Continue'

##########################################
# CORPS DU SCRIPT
##########################################

'$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$' | Out-File $Log -Append -NoClobber
(get-date).ToString() | Out-File $Log -Append -NoClobber

# Import Module
Import-Module -Name ActiveDirectory

gci C:\Temp\*.csv |Remove-Item

		$LOG="C:\temp\Users_LastLogon.log_$OU.csv"
		#$ListeUsers=@(Get-ADUser -Filter * -server $Controller -Properties * -SearchBase $OU | where samaccountname -notlike 'svc-*')
        $ListeUsers=@(Get-ADUser -Filter * -server $Controller -Properties * -SearchBase $OU | where samaccountname -notlike 'svc-*' | where name -notlike 'nicoll*' | where samaccountname -notlike 'test*' | where name -notlike 'teamcenter*' | where name -notlike 'symantec*' | where name -notlike '*reunion*' | where name -notlike '*girpi*' )
         

		ForEach ($Users in $ListeUsers){
				
				
				#Liste des utlisateurs n'ayant pas eu d'ouverture de session depuis au moins 30 jours (défini dans variable $Delay)
				$UserProperties=Get-AdUser $Users.SamAccountName -Properties * -server $Controller 
				$StartDate=[DateTime]::FromFileTime($UserProperties.LastLogonTimeStamp)
				$UserDelay=(New-TimeSpan -Start $StartDate -End $EndDate).Days
				if ($UserDelay -ge $Delay) {

                    $UserProperties | select Name,SamAccountName,distinguishedname,physicalDeliveryOfficeName,@{n="lastLogonDate";e={[datetime]::FromFileTime($_.lastLogonTimestamp)}},Enabled,Mail,Homedirectory | Where enabled -eq $True | export-csv $LOG -Encoding UTF8 -NoTypeInformation -Delimiter ';' -Append -Force -NoClobber 
					&$LogError

					#$UserProperties |select Name,SamAccountName,distinguishedname,physicalDeliveryOfficeName,LastLogonDate,Enabled,Mail,Homedirectory | Where enabled -eq $True | export-csv $LOG -Encoding UTF8 -NoTypeInformation -Delimiter ';' -Append -Force -NoClobber 
					#&$LogError
					
                    #"Intervalle de connexion : $UserDelay"
					#"Compte ayant plus de 90 jours de connexion : $UserProperties.SamAccountName"
				}
		}


$Listelog=@(gci C:\temp\*.csv )
if (!$Listelog){
        Send-MailMessage -Body "pas de fichier de log" -From Maintenance@aliaxis.com -SmtpServer mail.r2.group.corp -To "gchaillou@aliaxis.com" -Subject "Pas de fichier de log"
}
Else{
        Send-MailMessage -Attachments $Listelog -Body "Bonjour <br> </br> Dans le cadre de la revue mensuelle des comptes Active Directory (AD), vous trouverez en piece jointe la liste de tous les utilisateurs actifs.  <br> Pouvez-vous la verifier et nous signaler les comptes qui doivent etre desactives ?</br> <br>Merci de votre collaboration  <br> </br>Hello <br> </br> For Monthly Active Directory Report users (AD) , you find in attachment enabled users list <br> Could you check it and tell me users must be disabled ? </br><br> Thanks for your collaboration </br> " -BodyAsHtml -From gchaillou@aliaxis.com -SmtpServer mail.r2.group.corp -To $emaillocalcontact,$emaillocalit,$emaillocalrh -Subject "Revue mensuelle des comptes utilisateurs Active Directory / Monthly Report Active Directory Users"
}