Include %occInclude
Class Silent.Installer
{
XData setup [ XMLNamespace = INSTALLER ]
{
<Manifest>
  <Var Name="Namespace" Value="IRISDM"/>
  <Var Name="Namespace-cluster" Value="IRISCLUSTER"/>
  <Var Name="DBDIR" Value="/iris/db/"/>
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
<If Condition='(##class(Config.Namespaces).Exists("${Namespace-cluster}")=0)'>
  <Namespace Name="${Namespace-cluster}" Create="yes" Code="${Namespace-cluster}" Ensemble="0" Data="${Namespace-cluster}">
    <Configuration>
      <Database Name="${Namespace-cluster}"
        Dir="${DBDIR}${Namespace-cluster}"
        Create="overwrite"
        Resource="%DB_${Namespace-cluster}"
        PublicPermissions="RW"
        MountAtStartup="true"/>
    </Configuration>
  </Namespace>
  <Log Text="End Creating namespace ${Namespace-cluster}" Level="0"/>
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
ClassMethod LoadCSV(table = "NYTaxi.RowRides",file="/var/tmp/data/100K.csv") As %Status
{
  New $NAMESPACE
  Set $NAMESPACE="IRISDM"
  Set opt={"from": {"file": {"columnseparator":",", "header": true,"charset": "UTF-8" }}}.%ToJSON()
	Set sql="LOAD BULK DATA FROM FILE '"_file_"' INTO "_table_" (VendorID,tpep_pickup_datetime,tpep_dropoff_datetime,passenger_count,trip_distance,RatecodeID,store_and_fwd_flag,PULocationID,DOLocationID,payment_type,fare_amount,extra,mta_tax,tip_amount,tolls_amount,improvement_surcharge,total_amount,congestion_surcharge) USING "_opt

  //Doesn't work this way...
  //LOAD BULK DATA FROM FILE '/var/tmp/data/100.org.csv'
  //INTO NYTaxi.RowRides (VendorID,tpep_pickup_datetime)
  //VALUES (VendorID,TO_TIMESTAMP(tpep_pickup_datetime,'MM/DD/YYYY HH:MI:SS AM'))
  Set st=$ZH
  
  Set rs=$SYSTEM.SQL.Execute(sql,1)
  if rs.%SQLCODE > 0 {
    zw rs
    Return '$$$OK
  } else {
    Set count=rs.%ROWCOUNT
    w count_" records Loaded",!
    Set end=$ZH,duration=end-st
    w "Elapsed time "_duration,!
    w count/duration_" records/sec",!
    Return $$$OK
  }
  Return $$$OK
}

}