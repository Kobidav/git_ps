#Remote Functions
#######################################
$ImportMySQLFunctions = (Split-Path -Parent $PSCommandPath) + "\my_sql_Funcs_001.ps1"
.$ImportMySQLFunctions

#Local Functions
################################
Function Get_boot_time($ComputerName){
$opt = New-CimSessionOption -Protocol Dcom
$cs = New-CimSession -ComputerName $ComputerName -SessionOption $opt
$boottime = (([datetime](($cs | get-ciminstance win32_operatingsystem).LastBootUpTime)))
return (get-date $boottime -Format "yyyy-MM-dd hh:mm:ss")
}     #Getting time of last computer`s boot
Function Get_Proc_Name($ComputerName){
$proc_Name = (Get-WmiObject -computername $ComputerName Win32_Processor).name
$proc_Name = $proc_Name -replace "CPU" -replace "@" -replace "  ", " "
 while ($proc_Name.contains("  "))
{ $proc_Name = $proc_Name -replace "  ", " "
 }

return $proc_Name
}     #Getting and correct processor name
Function Read_Upd_Log($ComputerName){
$Log_File_Path="\\" + $ComputerName + "\c$\Windows\SoftwareDistribution\ReportingEvents.log"
$Log_array=(Get-Content $Log_File_Path)[-1..-100]
 foreach ($unit in $Log_array)  {
    $Update_result =(-2), ("0000-00-00 00:00:00") 
    $unit_array =$unit.split("`t")
    $date_time = ($unit_array[1]).substring(0,19)
    if ($unit_array[3] -eq 147){
        $Update_result =($unit_array[11]).substring(44,2), $date_time 
        break
       }
    if ($unit_array[3] -eq 148){
        $Update_result =(-1), $date_time 
        break
       }
    }
return $Update_result  
}      #Getting result and time of last computer`s update check
Function Get_Eset_upd_ver($ComputerName){
   Try{
   
    Invoke-Command -ComputerName $ComputerName {Start-Service RemoteRegistry}
    $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$ComputerName) 
    $RegSubKey = $Reg.OpenSubKey("SOFTWARE\ESET\ESET Security\CurrentVersion\Info")
    $Values = $RegSubKey.GetValue("ScannerVersion")
    Invoke-Command -ComputerName $ComputerName {Stop-Service RemoteRegistry}
    
    return [int]($Values.substring(0,5))
    }
   Catch{ Write-Host "Error Eset Nod :"  $_  -ForeGroundColor Yellow
   return -1}
}  #Getting Eset Nod Number os signature virus database
Function Get_Memory_s($ComputerName){
$memory_size = (get-wmiobject Win32_ComputerSystem -computer $ComputerName).TotalPhysicalMemory
return ([string]$memory_size).Substring(0,1)+ "." + ([string]$memory_size).Substring(1,1) + "GB"
}      #Getting Memory Size
Function Get_User_Name($ComputerName){
$User_name = ([string]((Get-WmiObject win32_computersystem -comp $ComputerName).Username) -replace $Domain_name -replace "\\")
If ($User_name -eq "") {$User_name = "No_Name"}
return $User_name 
}


cls
import-module ActiveDirectory
$Now = get-date -Format "yyyy-MM-dd hh:mm:ss"
Write-Host "Run computer scaning" -ForeGroundColor Green
$Check_interval = [DateTime]::Today.AddDays(-60);
$ListComputers = Get-ADComputer -Filter '(LastLogonDate -gt $Check_interval) -and ((OperatingSystem -eq "Windows 10 Pro") -or (OperatingSystem -eq "Windows 7 Professional") -or (OperatingSystem -like "*XP*"))'  -Properties OperatingSystem, LastLogonDate | select name, OperatingSystem, LastLogonDate
Write-Host "List of active computers... done" -ForeGroundColor Green 
$numb= 1
$data = @()
$ListComputers | foreach { $ComputerName=$_.name

if ((Test-connection $ComputerName -count 2 -quiet) -eq "True")
{

Write-Host "Computer checking " -ForeGroundColor Green "(" $numb ") " $ComputerName 
$row = New-Object PSObject
$row | Add-Member -MemberType NoteProperty -Name "CompName" -Value $ComputerName
$row | Add-Member -MemberType NoteProperty -Name "UserName" -Value  (Get_User_Name $ComputerName)
$row | Add-Member -MemberType NoteProperty -Name "OpSystem" -Value ([string]((Get-WmiObject -computername $ComputerName Win32_OperatingSystem).caption) -replace "Microsoft" -replace "Professional").TrimStart()
$row | Add-Member -MemberType NoteProperty -Name "CompModel" -Value (([string](Get-WmiObject win32_computersystem -comp $ComputerName).Model)).Trim()
$row | Add-Member -MemberType NoteProperty -Name "ServiceTag" -Value ([string]((Get-WmiObject -computername $ComputerName win32_SystemEnclosure).serialnumber))
$row | Add-Member -MemberType NoteProperty -Name "ProcName" -Value (Get_Proc_Name $ComputerName)
$row | Add-Member -MemberType NoteProperty -Name "Memory" -Value (Get_Memory_s $ComputerName)
$row | Add-Member -MemberType NoteProperty -Name "Bootup" -Value (Get_boot_time $ComputerName)
$row | Add-Member -MemberType NoteProperty -Name "Update_Need" -Value ([int]((Read_Upd_Log $ComputerName)[0]))
$row | Add-Member -MemberType NoteProperty -Name "Update_chk" -Value ((Read_Upd_Log $ComputerName)[1])
$row | Add-Member -MemberType NoteProperty -Name "Eset" -Value (Get_Eset_upd_ver $ComputerName)
#############################
$data += $row
$data
##################**Add_MySQL**###################
#####################ForSQL
$sql_comp_name = $row.CompName
$sql_user_name = $row.UserName
$sql_op_sys = $row.OpSystem
$sql_comp_model = $row.CompModel
$sql_serv_tag = $row.ServiceTag
$sql_proc_name = $row.ProcName
$sql_memory = $row.Memory
$sql_dateboot= $row.Bootup
$sql_upd_need= $row.Update_Need
$sql_upd_date= $row.Update_chk
$sql_eset= $row.Eset
$sql_date = (Get-Date -Format "yyyy-MM-dd hh:mm:ss")
$sql_comp_name_shot = ([string]($row.CompName) -Replace "-" -replace "_")
AddToMySQL
$data.clear()
$numb= $numb + 1
}
}
