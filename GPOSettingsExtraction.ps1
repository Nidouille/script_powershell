<#
.SYNOPSIS
   GPOSettingsExtraction.ps1 V1.1 : performs GPO Settings Extraction

   Usage: .\GPOSettingsExtraction.ps1 -backuppath <path> 

.PARAMETER action
    -backuppath : Enter the GPO Backup path

.EXAMPLE 
How to use GPOSettingsExtraction.ps1 :
    .\GPOSettingsExtraction.ps1 -backuppath c:\BackupGPO

.OUTPUTS
Creates the following files in the current directory:
    - GPOSettings-U.csv:  Contains the GPO User Settings
    - GPOSettings-C.csv:  Contains the GPO Computer Settings 

Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance of 
the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
damages whatsoever (including, without limitation, damages for loss of business profits, business 
interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages

#>

#param (
#        [string]$gponame="",
#        [parameter(Mandatory=$true)][string]$backuppath=""
#        )

param (
        [string]$gponame="",
        [string]$backuppath=""
        )

function ParseXml
{
    param ($file,$strgplink,$type,$ExtensionDataType,$STRGPOEnable,$STRGPONoOverride,$GPOdomain)
        $gponame=$file.gpo.Name
        Write-Host $gponame -ForegroundColor Yellow
        #Write-Host $type -ForegroundColor Yellow
        foreach ($Niv1ExtensionType in $ExtensionDataType)
        {
                $GPOCategory=$Niv1ExtensionType.type.split(":")
                write-host $GPOCategory[1] -ForegroundColor Green
                foreach ($Niv2Settings in $Niv1ExtensionType.childnodes)
                {
                    #write-host $Niv2Settings.LocalName -ForegroundColor Cyan
                    $ChildNodes = $Niv2Settings.ChildNodes
                    $count = 0
                    do
                    {
                        $text=""
                        foreach ($Niv3Value in $ChildNodes)
                        {
                            if(!$Niv3Value.clsid)
                            {                             
                                if ($count -eq 0)
                                {
                                    $SettingsName=$Niv3Value.localname + " (" + $Niv3Value.'#text'+ ")"
                                    #write-host $SettingsName -ForegroundColor Gray        
                                    $count = 1
                                }
                                else
                                {
                                    #$text = $text + ";" + $Niv3Value.sid.'#text' + " (" + $Niv3Value.name.'#text' + ")"
                                    #$text1= out-string -InputObject $Niv3Value.innertext -Stream
                                    #$text=$text1.replace("`n"," ")
                                    #Write-Host $text -ForegroundColor Red
                                    $textb = "N/A"
                                    foreach ($Niv4Value in $Niv3Value.childnodes)
                                    {
                                        if ($textb -eq "N/A")
                                        {
                                            $textb = $Niv4Value.innertext
                                        }
                                        else
                                        {
                                            $textb = $textb + " (" + $Niv4Value.innertext + ")"    
                                        }
                                    }
                                    if (($Niv3Value.localname -ne "Explain") -and ($Niv3Value.localname -ne "Supported"))
                                    {
                                        if ($Niv3Value.localname -eq "Category")
                                        {
                                            $Category=$textb
                                         }
                                         else
                                         {
                                            $textb = $Niv3Value.localname +" (" + $textb +")"
                                            if (!$text)
                                            {
                                                $text = $textb.replace("`n"," ")
                                            }
                                            else
                                            {
                                                $text = $text + ";" + $textb.replace("`n"," ")
                                            }
                                        }
                                    }
                                    
                                    #Write-Host $text -ForegroundColor Red
                                }
                                #$ExportFilename = "$pwd\duplicatesettings-"+$type+"-CG.csv"
                                #$gponame+"#" + $type +"#"+$GPOCategory[1]+"#"+$Niv2Settings.LocalName+"#"+$SettingsName+"#"+$text+"#"+$strgplink+"#"+$STRGPOEnable+"#"+$STRGPONoOverride | Out-File -FilePath $ExportFilename  -Append
                                
                             }
                             else
                             {
                                $SettingsName=$Niv3Value.localname + " (" + $Niv3Value.'#text'+ ")"
                                $name=$Niv3Value.localname
                                $prop=$Niv3Value.Properties.OuterXml
                                if ($prop)
                                {
                                    if ($prop.contains("xmlns"))
                                    {
                                        $u=$prop.IndexOf(" xmlns")-4
                                        $prop=$prop.Substring(4,$u)
                                    }
                                }
                                foreach ($strfilter in $Niv3Value.filters.ChildNodes)
                                {
                                    if ($strfilter.ChildNodes.Count -eq 0)
                                    {
                                        $textb=$strfilter.OuterXml
                                        $u=$textb.IndexOf(" xmlns")-4
                                        $textb=$textb.Substring(4,$u)
                                        if (!$textFilter)
                                        {
                                            $textfilter = $textb.replace("`n"," ")
                                        
                                        }
                                        else
                                        {
                                            $textfilter = $textfilter + ";" + $textb.replace("`n"," ")
                                        }
                                    }
                                    else
                                    {
                                        foreach ($subfilter in $strfilter)
                                        {
                                            $textb=$subfilter.OuterXml
                                            $tabsubfilter=$textb.split(">")
                                            $i=0
                                            $u=$tabsubfilter[$i].IndexOf(" xmlns")-4
                                            $textb=$tabsubfilter[$i].Substring(4,$u)+"["
                                            $i=1
                                            do
                                            {
                                                $textb=$textb+$tabsubfilter[$i].Substring(4)
                                                $i=$i+1
                                            }while (($tabsubfilter.count-2) -gt $i)
                                            
                                            $textb=$textb+"]"
                                            if (!$textFilter)
                                            {
                                                $textfilter = $textb.replace("`n"," ")
                                            }
                                            else
                                            {
                                                $textfilter = $textb + ";" + $textb.replace("`n"," ")
                                            } 
                                        }

                                    }
                                    
                                }
                                #write-host "Clsid:$($Niv3Value.clsid)" -BackgroundColor DarkRed
                                #write-host "Filters:$textFilter" -BackgroundColor DarkRed
                                #Write-Host "Order:$($Niv3Value.gposettingOrder)" -BackgroundColor DarkRed
                                #write-host "Name:$($Niv3Value.name)" -BackgroundColor DarkRed
                                #Write-Host "Properties:$prop" -BackgroundColor DarkRed
                                #Write-Host "UID:$($Niv3Value.uid)" -BackgroundColor DarkRed
                                #Write-Host "UserContext:$($Niv3Value.usercontext)" -BackgroundColor DarkRed

                                $text="[Order:$($Niv3Value.gposettingOrder),$prop,$textFilter]"+"@"+$text
                                $textfilter=""
                             }



                            if($Niv3Value.childnodes)
                            {
                                $childnodes=$Niv3Value.childnodes
                            }
                        }
                        $text=$text.Replace("#","_")
                        $SettingsName=$SettingsName.replace("#","_")
                        $ExportFilename = "$pwd\$gpodomain" + "_" + $type + "-duplicatesettings.csv"
                        $gponame+"#" + $type +"#"+$GPOCategory[1]+"#"+$Niv2Settings.LocalName+"#"+$Category+"#"+$SettingsName+"#"+$text+"#"+$strgplink+"#"+$STRGPOEnable+"#"+$STRGPONoOverride | Out-File -FilePath $ExportFilename  -Append
                        #Write-Host $gponame
                        #Write-Host $type
                        #Write-Host $GPOCategory[1]
                        #Write-Host $Niv2Settings.LocalName
                        #Write-Host $SettingsName
                        #write-host $text
                        #Write-Host $strgplink
                        #Write-Host $STRGPONoOverride
                        $count = 0
                    }while ($childnodes -eq $true )
                }
        }
}
                    
function FindGPLink                
{
    param ($file)

        #[xml]$xml=Get-Content -Path $file
        $Niv0GPLink=$file.gpo
        $gponame=$file.gpo.Name
        $gpodomain=$file.gpo.identifier.domain.'#text'
        $i=0
        foreach ($LinkTo in $Niv0GPLink)
        {
            $gplink=$linkto.LinksTo.sompath
            $GPOEnable=$linkto.LinksTo.enabled
            $GPONoOverride=$linkto.LinksTo.nooverride

            if ($gplink.count -gt 1)
            {
                do
                {
                    $Niv0cextData=$file.gpo.computer.ExtensionData.extension
                    ParseXml -file $file -strgplink $gplink[$i] -type "C" -ExtensionDataType $Niv0cextData -STRGPOEnable $GPOEnable[$i] -STRGPONoOverride $GPONoOverride[$i] -GPOdomain $gpodomain
                    $Niv0uextData=$file.gpo.User.ExtensionData.extension
                    ParseXml -file $file -strgplink $gplink[$i] -type "U" -ExtensionDataType $Niv0uextData -STRGPOEnable $GPOEnable[$i] -STRGPONoOverride $GPONoOverride[$i] -GPOdomain $gpodomain
                    $i=$i+1 
                }while($gplink.count -gt $i)
            }
            else
            {
                $Niv0cextData=$file.gpo.computer.ExtensionData.extension
                ParseXml -file $file -strgplink $gplink -type "C" -ExtensionDataType $Niv0cextData -STRGPOEnable $GPOEnable -STRGPONoOverride $GPONoOverride -GPOdomain $gpodomain
                $Niv0uextData=$file.gpo.User.ExtensionData.extension
                ParseXml -file $file -strgplink $gplink -type "U" -ExtensionDataType $Niv0uextData -STRGPOEnable $GPOEnable -STRGPONoOverride $GPONoOverride -GPOdomain $gpodomain
            }
        }
}

#$backuppath=""

if(($backuppath -ne "") -and ($gponame -eq ""))
    {
        "Folder Analyzing"

        Write-Host "Traitement de la GPO : " -ForegroundColor DarkGreen
        $reports=Get-ChildItem -Path $backuppath -Recurse -Include gpreport.xml

        [xml]$repxml=Get-Content -Path $reports[0]
        $gpodomain=$repxml.gpo.identifier.domain.'#text'
        $ExportFilename = "$pwd\$gpodomain" + "_U-duplicatesettings.csv"
        "GPO Name#UorC#Type#Category#Setting#State#Value#GPlink#Enable#NoOverride"| Out-File -FilePath $ExportFilename
        $ExportFilename = "$pwd\$gpodomain" + "_C-duplicatesettings.csv"
        "GPO Name#UorC#Type#Category#Setting#State#Value#GPlink#Enable#NoOverride"| Out-File -FilePath $ExportFilename

        foreach ($rep in $reports)
        {
            [xml]$repxml=Get-Content -Path $rep 
            #ParseXml -file $repxml
            FindGPLink -file $repxml
        }
    }
if(($backuppath -eq "") -and ($gponame -ne ""))
    {
        "File Analyzing"

        Write-Host "Traitement de la GPO : " -ForegroundColor DarkGreen
        
        [xml]$report=Get-GPOReport -Name $gponame -ReportType xml
        $gpodomain=$report.gpo.identifier.domain.'#text'
        "GPO Name#UorC#Type#Category#Setting#State#Value#GPlink#Enable#NoOverride"| Out-File -FilePath "$pwd\$gpodomain_U-duplicatesettings.csv"
        "GPO Name#UorC#Type#Category#Setting#State#Value#GPlink#Enable#NoOverride"| Out-File -FilePath "$pwd\$gpodomain_C-duplicatesettings.csv"
        FindGPLink -file $report
    }
if(($backuppath -ne "") -and ($gponame -ne ""))
    {
        Write-Host "You can only enter one switch" -ForegroundColor Red -BackgroundColor Black
    }