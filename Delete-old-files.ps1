################################################################################################################################################
<# 
.DESCRIPTION
    Ce script a pour but de supprimer les fichiers vieux de X days dans un dossier et ses sous dossiers. 
    A noter qu'il ne supprimera pas les dossiers.
.PARAMETER Folderpath
    Cette argument vous permet de définir le dossier racine à partir duquel ce script commencera à vérifier les fichiers.
.PARAMETER FileAge 
    Cette argument vous permetl'âge en jours à partir duquel vous souhaitez supprimer les fichiers.
.PARAMETER Extension
    Cette argument vous permet de filter les fichiers vérifier par extension.
.PARAMETER Loglocation 
    Cette argument vous permet de spécifier le dossier ou seront gardés les logs.
.EXAMPLE
    delete-old-files -Folderpath C:/users/pboutrois/test -delay 90 -extension .txt -loglocation C:/log
    Cette commande supprime tous les fichiers txt, dont la date de dernière modification supérieure 90 jours stockées ,dans le dossier C:/users/pboutrois/test et stocke les résultats dans le dossier C:/log.
.NOTES
    The log location is by default the directory from where you launch the command. 
#>
################################################################################################################################################

#function delete-old-files {

param(
    [string] $FolderPath,
	[int] $FileAge,
    [string] $Extension,
    [string] $loglocation
    )

#initialisation des variables qui serviront à stocker le nombre de fichiers conservés et supprimés traiter
$nbjeune= 0
$nbvieux= 0

# Vérification des paramètres et message d'erreur si invalide
if ( -not $FolderPath ) {Write-Warning "Veuillez spécifier le chemin d'accès au dossier à vérifier" ; exit }
if (!(test-path $FolderPath)) { Write-Warning " Le dossier spécifier n'existe pas" ;exit } 
if ( -not $FileAge ) { Write-Warning "Veuillez spécifier l'âge en jours à partir duquel les fichiers seront supprimés" ; exit }

# Donne la valeur * à la variable extension si le paramètre n'a pas été spécifier par l'utilisateur.
if (-not $Extension) {$Extension = ".*"}

#Si le dossier ou seront stocké les logs n'est pas renseigné, les stocke automatiquement dans le dossier d'ou est lancé le script.
if (-not $loglocation) 
    {
    write " Par défaut le fichier de log sera crée dans votre répertoire courant, utilisez le paramètre -loglocation si vous désirez changer son emplacement" 
    $loglocation = get-location
    }

#récupère la date d'aujourd'hui formaté pour calculé l'âge des fichiers
$today = get-date 
#récupère la date d'aujourd'hui formaté pour éditer le nom du fichier de log
$today2= get-date -format "dd-MMM-yyy"

# définit l'emplacement du fichier de log et formate son nom pour qu'il indique le dossier sur lequel le script a été modifié. 
$FolderPath2=$FolderPath.Replace('\','-').replace(':','')
$loglocation= -join ("$loglocation",'/log', '_',"$today2","_","$FolderPath2",".csv")

write "Fait le $today sur les fichiers vieux de $FileAge jours. `n" >> $loglocation 

#Calcules la date limite de survie des fichiers
$LastWrite = $today.AddDays(-$FileAge)

#Récupères toute l'arborescence de fichier sous le dossier spécifié et la stocke dans la variables ITEMS.
#Si une extension est spécifié dans la fonction ne cible que les fichiers y correspondant
$Items = Get-ChildItem $FolderPath -Recurse -Force -File | Where {$_.extension -like $Extension}

#Compares la date limite de tout les fichiers stockés dans la variable ITEMS à la date de dernière et les supprime si ils sont trop vieux.
foreach ($item in $items)
    {
    if (($item.LastWriteTime - $LastWrite) -le 0 )
        {
         write $item.Name >> $loglocation
         Remove-Item $item.FullName
         $nbvieux= $nbvieux+1 
    
    }
    else 
    {
        $nbjeune= $nbjeune+1
    }
    }

Write "`n le nombre de fichier supprimé est $nbvieux" >> $loglocation
Write "le nombre de fichier conservé est $nbjeune" >> $loglocation
#}