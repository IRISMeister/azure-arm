Include %occInclude
Class Silent.Installer
{
XData setup [ XMLNamespace = INSTALLER ]
{
<Manifest>
  <Var Name="Namespace" Value="myapp"/>
  <Var Name="Import" Value="0"/>

<If Condition='(##class(Config.Namespaces).Exists("${Namespace}")=0)'>
  <Log Text="Creating namespace ${Namespace}" Level="0"/>
  <Namespace Name="${Namespace}" Create="yes" Code="${Namespace}" Ensemble="0" Data="${Namespace}">
    <Configuration>
      <Database Name="${Namespace}"
        Dir="${MGRDIR}${Namespace}"
        Create="overwrite"
        Resource="%DB_${Namespace}"
        PublicPermissions="RW"
        MountAtStartup="true"/>
    </Configuration>
  </Namespace>
  <Log Text="End Creating namespace ${Namespace}" Level="0"/>
</If>

<Namespace Name="${Namespace}" Create="no">
  <CSPApplication Url="/csp/${Namespace}" Directory="${CSPDIR}${Namespace}" Resource=""/>
</Namespace>
<Namespace Name="${Namespace}" Create="no">
  <CSPApplication Url="/csp/${Namespace}" Directory="${CSPDIR}${Namespace}" Resource=""/>
</Namespace>
<Namespace Name="%SYS" Create="no">
  <Invoke Class="Silent.Installer" Method="setupExt" CheckStatus="1"/>
</Namespace>
</Manifest>
}

ClassMethod setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
  Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "setup")
}

ClassMethod setupExt() As %Status
{
  Set tSC='$$$OK
  Try {
    Set tSC=##class(Security.System).Get(,.params)
    $$$ThrowOnError(tSC)
    Set params("AutheEnabled")=$ZHEX("7FF") ; Ebable O/S auth
    Set tSC=##class(Security.System).Modify(,.params)
    $$$ThrowOnError(tSC)

    #; need "root" user to perform app consistent backup via pre/post script.
    #; somehow sudo -u irisowner dosen't work with this.
    #; https://docs.microsoft.com/ja-jp/azure/backup/backup-azure-linux-app-consistent
    Set tSC=##class(Security.Users).Copy("SuperUser","root",,,,"sys")
    $$$ThrowOnError(tSC)
  } Catch(e) {
	  Set tSC=e.AsStatus()
  }
  Return tSC
}

ClassMethod EnableMirroringService() As %Status
{
  do ##class(Security.Services).Get("%Service_Mirror", .p)
  set p("Enabled") = 1
  set sc=##class(Security.Services).Modify("%Service_Mirror", .p)
  quit sc
}

ClassMethod CreateMirrorSet(ArbiterIP As %String) As %Status
{
  set mirrorName="MIRRORSET"
  set hostName=$system.INetInfo.HostNameToAddr($system.INetInfo.LocalHostName())
  set systemName="MIRRORNODE01"
  // Create mirror:
  set mirror("UseSSL") = 0
  if (ArbiterIP'="none") {
    set mirror("ArbiterNode") = ArbiterIP_"|2188"
    set mirror("ECPAddress") = hostName  // Windows on AWS need this
  }
  set sc = ##class(SYS.Mirror).CreateNewMirrorSet(mirrorName, systemName, .mirror)
  write !,"Creating mirror "_mirrorName_"..."
  if 'sc do $system.OBJ.DisplayError(sc)  
  quit sc
}

ClassMethod JoinAsFailover(PrimaryNodeIP As %String) As %Status
{
  set mirrorName="MIRRORSET"
  set hostName=$system.INetInfo.HostNameToAddr($system.INetInfo.LocalHostName())
  set systemName="MIRRORNODE02"
  // Join as failover:
  set mirror("ECPAddress") = hostName  // Windows on AWS need this
  set sc=##class(SYS.Mirror).JoinMirrorAsFailoverMember(mirrorName,systemName,"IRIS",PrimaryNodeIP,,.mirror)
  write !,"Jonining mirror "_mirrorName_"...",!
  if 'sc do $system.OBJ.DisplayError(sc)
  quit sc
}

ClassMethod CreateMirroredDB(dbName As %String, dir As %String = "") As %Status
{
  if (dir="") { set dir="/datadisks/disk1/iris/db/" }
  set mirrorName="MIRRORSET"
  
  write !, "Creating databases and NS ",dbName,"...",!
  
  // Create the directory
  do ##class(%Library.File).CreateDirectoryChain(dir)
  do ##class(%Library.File).CreateNewDir(dir,dbName)
  // Add DB to config
  set Properties("Directory")=dir_dbName
  do ##class(Config.Databases).Create(dbName,.Properties)
  // Set the DB properties
  set Properties("Directory")=dir_dbName
  // wait until mirror is ready on this node
  For i=1:1:10 {
    h 1
    Set mirrorStatus=$LIST($SYSTEM.Mirror.GetMemberStatus(mirrorName))
    if mirrorStatus="Backup" Quit
    if mirrorStatus="Primary" Quit
  }
  if ((mirrorStatus'="Primary")&(mirrorStatus'="Backup")) { 
    write "Mirror failed to be ready: Mirror Status:"_mirrorStatus,!
    quit '$$$OK
  }

  set rc = ##class(SYS.Database).CreateDatabase(dir_dbName,,,,,,dbName,mirrorName)
  if 'rc { 
    write !,"Database creation failed!"
    do $system.OBJ.DisplayError(rc)
    quit rc
  }
  
  // Create namespace for mirrored database
  set ns("Globals")=dbName
  set ns("Routines")=dbName
  do ##class(Config.Namespaces).Create(dbName,.ns)
  set rc = ##class(Config.Namespaces).Exists(dbName,.obj,.status)
  if 'rc {
    write !, "NS creation failed."
    do $system.OBJ.DisplayError(rc)
    quit rc
  }
    
  quit $$$OK
}
}