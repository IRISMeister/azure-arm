Include %occInclude
Class Silent.Installer
{
XData setup [ XMLNamespace = INSTALLER ]
{
<Manifest>
  <Var Name="Namespace" Value="myapp"/>
  <Var Name="DBDIR" Value="/iris/db"/>
  <Var Name="Import" Value="0"/>

<If Condition='(##class(Config.Namespaces).Exists("${Namespace}")=0)'>
  <Log Text="Creating namespace ${Namespace}" Level="0"/>
  <Namespace Name="${Namespace}" Create="yes" Code="${Namespace}" Ensemble="0" Data="${Namespace}">
    <Configuration>
      <Database Name="${Namespace}"
        Dir="${DBDIR}${Namespace}"
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

ClassMethod EnableShardService() As %Status
{
  set sc = $SYSTEM.Cluster.Initialize()
  quit sc
}

ClassMethod InitializeCluster() As %Status
{
  set sc = $SYSTEM.Cluster.Initialize()
  quit sc
}

ClassMethod JoinCluster(PrimaryNodeIP As %String) As %Status
{
  set sc = $SYSTEM.Cluster.AttachAsDataNode("IRIS://"_PrimaryNodeIP_":1972")
  quit sc  
}

}