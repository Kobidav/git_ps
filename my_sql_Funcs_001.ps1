$ImportVariables_list = (Split-Path -Parent $PSCommandPath) + "\variables_list.ps1"
.$ImportVariables_list


Function Connect-MySQL() { 
  # Load MySQL .NET Connector Objects 
  [void][system.reflection.Assembly]::LoadWithPartialName("MySql.Data") 
 
  # Open Connection 
  $connStr = "server=" + $MySQLHost + ";port=3306;uid=" + $user + ";pwd=" + $pass + ";database="+$database+";Pooling=FALSE" 
  #Write-Host $connStr
  $conn = New-Object MySql.Data.MySqlClient.MySqlConnection($connStr) 
  $conn.Open() 
  return $conn 
} 
Function Disconnect-MySQL($conn) {
  $conn.Close()
}
Function Execute-MySQLNonQuery($conn, [string]$query) { 
  $command = $conn.CreateCommand()                  # Create command object
  $command.CommandText = $query                     # Load query into object
  $RowsInserted = $command.ExecuteNonQuery()        # Execute command
  $command.Dispose()                                # Dispose of command object
  if ($RowsInserted) { 
    return $RowInserted 
  } else { 
    return $false 
  } 
} 
function AddToMySQL(){


# Connect to MySQL Database 
$conn = Connect-MySQL 


$query = "INSERT IGNORE INTO {0} (comp_name, user_name, op_system, model_name, service_tag, processor,memory, date_boot, upd_need, date_upd, eset_nod, pub_date, date_now, comp_name_shot)`
VALUES ('$sql_comp_name', '$sql_user_name', '$sql_op_sys', '$sql_comp_model', '$sql_serv_tag', '$sql_proc_name','$sql_memory', '$sql_dateboot', '$sql_upd_need', '$sql_upd_date', '$sql_eset', '$sql_date', '$sql_date', '$sql_comp_name_shot')" -f "main_compinv" 
#write-host $query
$Rows = Execute-MySQLNonQuery $conn $query 

#Write-Host $Rows " inserted into database" 
}
Function AddTodayToMySQL {
$Prim=$a+"_"+$Now
# Connect to MySQL Database 
$conn = Connect-MySQL $user $pass $MySQLHost $database 
# So, to insert records into a table 
$query = "CREATE TABLE IF NOT EXISTS Today (`
CompName    VARCHAR(100)    DEFAULT '',`
UserName    VARCHAR(100)    DEFAULT '',`
OpSystem    VARCHAR(100)    DEFAULT '',`
CompModel   VARCHAR(100)    DEFAULT '',`
ServiceTag  VARCHAR(100)    DEFAULT '',`
ProcName    VARCHAR(100)    DEFAULT '',`
Bootup      VARCHAR(100)    DEFAULT '',`
Data        VARCHAR(100)    DEFAULT '',`
Prim        VARCHAR(100)    DEFAULT '',`
PRIMARY KEY  (Prim));"
$Rows = Execute-MySQLNonQuery $conn $query 
#Write-Host $Rows " inserted into database Today"
}


