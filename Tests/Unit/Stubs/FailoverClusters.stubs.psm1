<#
    .SYNOPSIS
        This is stub cmdlets for the module FailoverClusters which can be used in
        Pester unit tests to be able to test code without having the actual module installed.

    .NOTES
        Generated from module FailoverClusters (version 2.0.0.0), on
        operating system Microsoft Windows Server 2016 Standard 64-bit (10.0.14393)
#>

<#
    Suppressing this rule because these functions are from an external module
    and are only being used as stubs.
#>
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]
param()

function Add-ClusterCheckpoint {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216179')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${ResourceName},        [Parameter(HelpMessage='Name of crypto checkpoint to add.')]        [string]        ${CryptoCheckpointName},        [Parameter(HelpMessage='Type of crypto checkpoint to add.')]        [string]        ${CryptoCheckpointType},        [Parameter(HelpMessage='Key of crypto checkpoint to add.')]        [string]        ${CryptoCheckpointKey},        [Parameter(HelpMessage='Name of registry checkpoint to add.')]        [string]        ${RegistryCheckpoint},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterDisk {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkId=216180')]    param(        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject[]]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterFileServerRole {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216183')]    param(        [Parameter(Mandatory=$true)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Storage},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${StaticAddress},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${IgnoreNetwork},        [Parameter(Position=0)]        [string]        ${Name},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterGenericApplicationRole {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216184')]    param(        [Parameter(Mandatory=$true)]        [ValidateNotNullOrEmpty()]        [string]        ${CommandLine},        [string]        ${Parameters},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${CheckpointKey},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Storage},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${StaticAddress},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${IgnoreNetwork},        [Parameter(Position=0)]        [string]        ${Name},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterGenericScriptRole {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216186')]    param(        [Parameter(Mandatory=$true)]        [ValidateNotNullOrEmpty()]        [string]        ${ScriptFilePath},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Storage},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${StaticAddress},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${IgnoreNetwork},        [Parameter(Position=0)]        [string]        ${Name},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterGenericServiceRole {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216187')]    param(        [Parameter(Mandatory=$true)]        [ValidateNotNullOrEmpty()]        [string]        ${ServiceName},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${CheckpointKey},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Storage},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${StaticAddress},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${IgnoreNetwork},        [Parameter(Position=0)]        [string]        ${Name},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterGroup {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216189')]    param(        [Parameter(Mandatory=$true, Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(Position=1)]        [Object]        ${GroupType},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusteriSCSITargetServerRole {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=229636')]    param(        [Parameter(Mandatory=$true)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Storage},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${StaticAddress},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${IgnoreNetwork},        [Parameter(Position=0)]        [string]        ${Name},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterNode {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216190')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [switch]        ${NoStorage},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterResource {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216192')]    param(        [Parameter(Mandatory=$true, Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [Parameter(Position=1)]        [ValidateNotNullOrEmpty()]        [string]        ${Group},        [Parameter(Mandatory=$true, Position=2)]        [Alias('ResType','Type')]        [ValidateNotNullOrEmpty()]        [string]        ${ResourceType},        [switch]        ${SeparateMonitor},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterResourceDependency {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216193')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Resource},        [Parameter(Position=1)]        [ValidateNotNullOrEmpty()]        [string]        ${Provider},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterResourceType {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216194')]    param(        [Parameter(Mandatory=$true, Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [Parameter(Mandatory=$true, Position=1)]        [ValidateNotNullOrEmpty()]        [string]        ${Dll},        [Parameter(Position=2)]        [ValidateNotNullOrEmpty()]        [string]        ${DisplayName},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterScaleOutFileServerRole {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216200')]    param(        [Parameter(Position=0)]        [string]        ${Name},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterServerRole {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216195')]    param(        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Storage},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${StaticAddress},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${IgnoreNetwork},        [Parameter(Position=0)]        [string]        ${Name},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterSharedVolume {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216196')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterVirtualMachineRole {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkId=216198')]    param(        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)]        [string]        ${VMName},        [Alias('VM')]        [string]        ${VirtualMachine},        [Parameter(ValueFromPipelineByPropertyName=$true)]        [guid]        ${VMId},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Add-ClusterVMMonitoredItem {
    [CmdletBinding(DefaultParameterSetName='VirtualMachine', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216199')]    param(        [System.Collections.Specialized.StringCollection]        ${Service},        [string]        ${EventLog},        [string]        ${EventSource},        [int]        ${EventId},        [switch]        ${OverrideServiceRecoveryActions},        [Parameter(ParameterSetName='VirtualMachine', Position=0)]        [Alias('VM')]        [ValidateNotNullOrEmpty()]        [string]        ${VirtualMachine},        [Parameter(ParameterSetName='VMId', ValueFromPipelineByPropertyName=$true)]        [guid]        ${VMId},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Block-ClusterAccess {
    [CmdletBinding(DefaultParameterSetName='InputObject', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216202')]    param(        [Parameter(Mandatory=$true, Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${User},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Clear-ClusterDiskReservation {
    [CmdletBinding(ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216203')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Node},        [Parameter(Mandatory=$true)]        [uint32[]]        ${Disk},        [switch]        ${Force}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Clear-ClusterNode {
    [CmdletBinding(DefaultParameterSetName='InputObject', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216205')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [switch]        ${Force},        [int]        ${Wait},        [switch]        ${CleanupDisks},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-Cluster {
    [CmdletBinding(DefaultParameterSetName='Name', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216206')]    param(        [Parameter(ParameterSetName='Name', Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [string]        ${Domain}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterAccess {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216207')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${User},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterAvailableDisk {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216208')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Cluster},        [Parameter(ValueFromPipeline=$true)]        [ValidateNotNull()]        [ciminstance]        ${Disk},        [switch]        ${All},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterCheckpoint {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216209')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${ResourceName},        [Parameter(HelpMessage='Searches for checkpoints with a specific name, wildcard expressions are accepted.')]        [string]        ${CheckpointName},        [Parameter(HelpMessage='If specified, command will output registry checkpoints.')]        [switch]        ${RegistryCheckpoint},        [Parameter(HelpMessage='If specified, command will output crypto checkpoints.')]        [switch]        ${CryptoCheckpoint},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterGroup {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216210')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(ValueFromPipelineByPropertyName=$true)]        [guid]        ${VMId},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterLog {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216212')]    param(        [Parameter(Position=0)]        [ValidateNotNull()]        [System.Collections.Specialized.StringCollection]        ${Node},        [ValidateNotNullOrEmpty()]        [string]        ${Destination},        [Alias('Span')]        [uint32]        ${TimeSpan},        [Parameter(HelpMessage='Generate the cluster log using local time instead of GMT.')]        [Alias('lt')]        [switch]        ${UseLocalTime},        [Parameter(HelpMessage='Generate the cluster log without retrieving cluster state information.')]        [Alias('scs')]        [switch]        ${SkipClusterState},        [Parameter(HelpMessage='Generate the cluster health logs.')]        [switch]        ${Health},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterNetwork {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216213')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterNetworkInterface {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216214')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Node},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Network},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterNode {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216215')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterOwnerNode {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216216')]    param(        [Alias('Res')]        [ValidateNotNullOrEmpty()]        [string]        ${Resource},        [ValidateNotNullOrEmpty()]        [string]        ${Group},        [Alias('ResType')]        [ValidateNotNullOrEmpty()]        [string]        ${ResourceType},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterParameter {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkId=216217')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterQuorum {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216218')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Cluster},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterResource {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216219')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(ValueFromPipelineByPropertyName=$true)]        [guid]        ${VMId},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterResourceDependency {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216220')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Resource},        [switch]        ${Guid},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterResourceDependencyReport {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216221')]    param(        [ValidateNotNullOrEmpty()]        [string]        ${Resource},        [ValidateNotNullOrEmpty()]        [string]        ${Group},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterResourceType {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216222')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterSharedVolume {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216223')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterSharedVolumeState {
    [CmdletBinding()]    param(        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Node},        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Get-ClusterVMMonitoredItem {
    [CmdletBinding(DefaultParameterSetName='VirtualMachine', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216224')]    param(        [Parameter(ParameterSetName='VirtualMachine', Position=0)]        [Alias('VM')]        [ValidateNotNullOrEmpty()]        [string]        ${VirtualMachine},        [Parameter(ParameterSetName='VMId', ValueFromPipelineByPropertyName=$true)]        [guid]        ${VMId},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Grant-ClusterAccess {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216225')]    param(        [Parameter(Mandatory=$true, Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${User},        [switch]        ${Full},        [switch]        ${ReadOnly},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Move-ClusterGroup {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216226')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [Parameter(Position=1)]        [ValidateNotNullOrEmpty()]        [string]        ${Node},        [switch]        ${IgnoreLocked},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Move-ClusterResource {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216227')]    param(        [Parameter(Position=0)]        [ValidateNotNull()]        [string]        ${Name},        [Parameter(Position=1)]        [ValidateNotNull()]        [string]        ${Group},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Move-ClusterSharedVolume {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216228')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [Parameter(Position=1)]        [ValidateNotNullOrEmpty()]        [string]        ${Node},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Move-ClusterVirtualMachineRole {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkId=216229')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [Parameter(Position=1)]        [ValidateNotNullOrEmpty()]        [string]        ${Node},        [switch]        ${Cancel},        [Object]        ${MigrationType},        [switch]        ${IgnoreLocked},        [Parameter(ValueFromPipelineByPropertyName=$true)]        [guid]        ${VMId},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function New-Cluster {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkId=216230')]    param(        [Parameter(Mandatory=$true, Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Node},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${StaticAddress},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${IgnoreNetwork},        [switch]        ${NoStorage},        [switch]        ${S2D},        [Alias('aap')]        [Object]        ${AdministrativeAccessPoint},        [switch]        ${Force}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function New-ClusterNameAccount {
    [CmdletBinding(DefaultParameterSetName='InputObject')]    param(        [Parameter(Mandatory=$true)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [Parameter(ParameterSetName='Credentials', Mandatory=$true)]        [Parameter(ParameterSetName='InputObject')]        [pscredential]        ${Credentials},        [Parameter(ParameterSetName='Credentials', Mandatory=$true)]        [Parameter(ParameterSetName='InputObject')]        [string]        ${Domain},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Remove-Cluster {
    [CmdletBinding(DefaultParameterSetName='InputObject', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216231')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Cluster},        [switch]        ${CleanupAD},        [switch]        ${Force},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Remove-ClusterAccess {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216232')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${User},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Remove-ClusterCheckpoint {
    [CmdletBinding(DefaultParameterSetName='InputObject', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216233')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${ResourceName},        [switch]        ${Force},        [Parameter(HelpMessage='Searches for checkpoints with a specific name, regular expressions are accepted.')]        [string]        ${CheckpointName},        [Parameter(HelpMessage='If specified, command will remove registry checkpoints.')]        [switch]        ${RegistryCheckpoint},        [Parameter(HelpMessage='If specified, command will remove crypto checkpoints.')]        [switch]        ${CryptoCheckpoint},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Remove-ClusterGroup {
    [CmdletBinding(DefaultParameterSetName='InputObject', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216234')]    param(        [Parameter(ValueFromPipelineByPropertyName=$true)]        [guid]        ${VMId},        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [switch]        ${Force},        [switch]        ${RemoveResources},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Remove-ClusterNode {
    [CmdletBinding(DefaultParameterSetName='InputObject', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216235')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [switch]        ${Force},        [int]        ${Wait},        [switch]        ${IgnoreStorageConnectivityLoss},        [switch]        ${CleanupDisks},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Remove-ClusterResource {
    [CmdletBinding(DefaultParameterSetName='InputObject', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216236')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [switch]        ${Force},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Remove-ClusterResourceDependency {
    [CmdletBinding(ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216237')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Resource},        [Parameter(Position=1)]        [ValidateNotNullOrEmpty()]        [string]        ${Provider},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Remove-ClusterResourceType {
    [CmdletBinding(DefaultParameterSetName='InputObject', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216238')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Remove-ClusterSharedVolume {
    [CmdletBinding(DefaultParameterSetName='InputObject', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216239')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Remove-ClusterVMMonitoredItem {
    [CmdletBinding(DefaultParameterSetName='VirtualMachine', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216240')]    param(        [Parameter(ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [System.Collections.Specialized.StringCollection]        ${Service},        [string]        ${EventLog},        [string]        ${EventSource},        [int]        ${EventId},        [Parameter(ParameterSetName='VirtualMachine', Position=0)]        [Alias('VM')]        [ValidateNotNullOrEmpty()]        [string]        ${VirtualMachine},        [Parameter(ParameterSetName='VMId', ValueFromPipelineByPropertyName=$true)]        [guid]        ${VMId},        [int]        ${Wait},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Reset-ClusterVMMonitoredState {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216243')]    param(        [int]        ${Wait}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Resume-ClusterNode {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216244')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(Position=1)]        [ValidateNotNullOrEmpty()]        [Object]        ${Failback},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Resume-ClusterResource {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216245')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [string]        ${VolumeName},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Set-ClusterLog {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216246')]    param(        [int]        ${Size},        [int]        ${Level},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Set-ClusterOwnerNode {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkId=216247')]    param(        [ValidateNotNullOrEmpty()]        [string]        ${Resource},        [ValidateNotNullOrEmpty()]        [string]        ${Group},        [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]        [ValidateNotNull()]        [System.Collections.Specialized.StringCollection]        ${Owners},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Set-ClusterParameter {
    [CmdletBinding(DefaultParameterSetName='NoMultiple', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216248')]    param(        [Parameter(ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [Parameter(ParameterSetName='Single Parameter', Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [Parameter(ParameterSetName='Multiple Parameter', Position=0)]        [ValidateNotNull()]        [hashtable]        ${Multiple},        [Parameter(ParameterSetName='Single Parameter', Position=1)]        [psobject]        ${Value},        [switch]        ${Create},        [switch]        ${Delete},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Set-ClusterQuorum {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216249')]    param(        [ValidateNotNullOrEmpty()]        [string]        ${DiskOnly},        [Alias('NodeMajority')]        [switch]        ${NoWitness},        [Alias('NodeAndDiskMajority')]        [ValidateNotNullOrEmpty()]        [string]        ${DiskWitness},        [Alias('NodeAndFileShareMajority')]        [ValidateNotNullOrEmpty()]        [string]        ${FileShareWitness},        [switch]        ${CloudWitness},        [ValidateNotNullOrEmpty()]        [string]        ${AccountName},        [string]        ${Endpoint},        [ValidateNotNullOrEmpty()]        [string]        ${AccessKey},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Set-ClusterResourceDependency {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216250')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Resource},        [Parameter(Position=1)]        [string]        ${Dependency},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Start-Cluster {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkId=216251')]    param(        [Parameter(Position=0)]        [Alias('Cluster')]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [Alias('ips')]        [switch]        ${IgnorePersistentState},        [int]        ${Wait}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Start-ClusterGroup {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216252')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [switch]        ${IgnoreLocked},        [switch]        ${ChooseBestNode},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Start-ClusterNode {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216253')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(HelpMessage='Specifies if the cluster is in a force quorum state.')]        [Alias('fq','FixQuorum')]        [switch]        ${ForceQuorum},        [Parameter(HelpMessage='Specifies whether to clear quarantine state when starting the cluster node')]        [Alias('cq')]        [switch]        ${ClearQuarantine},        [Parameter(HelpMessage='Specifies whether the cluster will bring online groups that were online when the cluster was shut down.')]        [Alias('ips')]        [switch]        ${IgnorePersistentState},        [Alias('pq')]        [switch]        ${PreventQuorum},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Start-ClusterResource {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216254')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [switch]        ${IgnoreLocked},        [switch]        ${ChooseBestNode},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Stop-Cluster {
    [CmdletBinding(DefaultParameterSetName='Cluster name', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216255')]    param(        [Parameter(ParameterSetName='Cluster name', Position=0)]        [Alias('Name')]        [ValidateNotNullOrEmpty()]        [string]        ${Cluster},        [switch]        ${Force},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Stop-ClusterGroup {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216256')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [switch]        ${IgnoreLocked},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Stop-ClusterNode {
    [CmdletBinding(DefaultParameterSetName='InputObject', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216257')]    param(        [Parameter(Position=0)]        [System.Collections.Specialized.StringCollection]        ${Name},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Stop-ClusterResource {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216258')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [switch]        ${IgnoreLocked},        [int]        ${Wait},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Suspend-ClusterNode {
    [CmdletBinding(DefaultParameterSetName='InputObject', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216259')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [switch]        ${Drain},        [switch]        ${ForceDrain},        [switch]        ${Wait},        [Parameter(Position=1)]        [ValidateNotNullOrEmpty()]        [string]        ${TargetNode},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Suspend-ClusterResource {
    [CmdletBinding(ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216260')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [string]        ${VolumeName},        [Alias('FileSystemRedirectedAccess')]        [switch]        ${RedirectedAccess},        [switch]        ${Force},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Test-Cluster {
    [CmdletBinding(DefaultParameterSetName='InputObject', ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216261')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Node},        [ValidateNotNullOrEmpty()]        [System.Object[]]        ${Disk},        [ValidateNotNullOrEmpty()]        [System.Object[]]        ${Pool},        [ValidateNotNullOrEmpty()]        [string]        ${ReportName},        [switch]        ${List},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Include},        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Ignore},        [switch]        ${Force},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Test-ClusterResourceFailure {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216262')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Update-ClusterFunctionalLevel {
    [CmdletBinding(DefaultParameterSetName='InputObject')]    param(        [switch]        ${Force},        [switch]        ${WhatIf},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Update-ClusterIPResource {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkId=216264')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [switch]        ${Renew},        [switch]        ${Release},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Update-ClusterNetworkNameResource {
    [CmdletBinding(DefaultParameterSetName='InputObject', HelpUri='http://go.microsoft.com/fwlink/?LinkId=216265')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [System.Collections.Specialized.StringCollection]        ${Name},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

function Update-ClusterVirtualMachineConfiguration {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkId=216266')]    param(        [Parameter(Position=0)]        [ValidateNotNullOrEmpty()]        [string]        ${Name},        [Parameter(ValueFromPipelineByPropertyName=$true)]        [guid]        ${VMId},        [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]        [ValidateNotNull()]        [psobject]        ${InputObject},        [ValidateNotNullOrEmpty()]        [string]        ${Cluster}
   )

   throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}


