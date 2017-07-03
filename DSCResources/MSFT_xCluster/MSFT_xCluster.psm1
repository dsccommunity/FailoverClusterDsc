#
# xCluster: DSC resource to configure a Windows Cluster. If the cluster does not exist, it will create one in the
# domain and assign the StaticIPAddress to the cluster. Then, it will add current node to the cluster.
#

#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $StaticIPAddress,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $DomainAdministratorCredential
    )

    $computerInformation = Get-WmiObject -Class Win32_ComputerSystem
    if (($null -eq $computerInformation) -or ($null -eq $computerInformation.Domain))
    {
        throw 'Can''t find machine''s domain name'
    }

    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -Credential $DomainAdministratorCredential

        $cluster = Get-Cluster -Name $Name -Domain $computerInformation.Domain
        if ($null -eq $cluster)
        {
            throw "Can't find the cluster $Name"
        }

        $address = Get-ClusterGroup -Cluster $Name -Name 'Cluster IP Address' | Get-ClusterParameter -Name 'Address'
    }
    finally
    {
        if ($context)
        {
            $context.Undo()
            $context.Dispose()
            Close-UserToken -Token $newToken
        }
    }

    @{
        Name                          = $Name
        StaticIPAddress               = $address.Value
        DomainAdministratorCredential = $DomainAdministratorCredential
    }
}

#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $StaticIPAddress,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $DomainAdministratorCredential
    )

    $bCreate = $true

    Write-Verbose -Message "Checking if Cluster $Name is present ..."

    $computerInformation = Get-WmiObject -Class Win32_ComputerSystem
    if (($null -eq $computerInformation) -or ($null -eq $computerInformation.Domain))
    {
        throw 'Can''t find machine''s domain name'
    }

    try
    {
        $cluster = Get-Cluster -Name $Name -Domain $computerInformation.Domain

        if ($cluster)
        {
            $bCreate = $false
        }
    }
    catch
    {
        $bCreate = $true
    }

    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -Credential $DomainAdministratorCredential

        if ($bCreate)
        {
            Write-Verbose -Message "Cluster $Name is NOT present"

            New-Cluster -Name $Name -Node $env:COMPUTERNAME -StaticAddress $StaticIPAddress -NoStorage -Force -ErrorAction Stop

            if ( -not (Get-Cluster))
            {
                throw 'Cluster creation failed. Please verify output of ''Get-Cluster'' command'
            }

            Write-Verbose -Message "Created Cluster $Name"
        }
        else
        {
            Write-Verbose -Message "Add node to Cluster $Name ..."

            Write-Verbose -Message "Add-ClusterNode $env:COMPUTERNAME to cluster $Name"

            $list = Get-ClusterNode -Cluster $Name
            foreach ($node in $list)
            {
                if ($node.Name -eq $env:COMPUTERNAME)
                {
                    if ($node.State -eq 'Down')
                    {
                        Write-Verbose -Message "Node $env:COMPUTERNAME was down, need remove it from the list."

                        Remove-ClusterNode -Name $env:COMPUTERNAME -Cluster $Name -Force
                    }
                }
            }

            Add-ClusterNode -Name $env:COMPUTERNAME -Cluster $Name -NoStorage

            Write-Verbose -Message "Added node to Cluster $Name"
        }
    }
    finally
    {
        if ($context)
        {
            $context.Undo()
            $context.Dispose()
            Close-UserToken -Token $newToken
        }
    }
}

#
# Test-TargetResource
#
# The code will check the following in order:
# 1. Is machine in domain?
# 2. Does the cluster exist in the domain?
# 3. Is the machine is in the cluster's nodelist?
# 4. Does the cluster node is UP?
#
# Function will return FALSE if any above is not true. Which causes cluster to be configured.
#
function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $StaticIPAddress,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $DomainAdministratorCredential
    )

    $returnValue = $false

    Write-Verbose -Message "Checking if Cluster $Name is present ..."

    $ComputerInfo = Get-WmiObject -Class Win32_ComputerSystem
    if (($null -eq $ComputerInfo) -or ($null -eq $ComputerInfo.Domain))
    {
        throw "Can't find machine's domain name"
    }

    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -Credential $DomainAdministratorCredential

        $cluster = Get-Cluster -Name $Name -Domain $ComputerInfo.Domain

        Write-Verbose -Message "Cluster $Name is present"

        if ($cluster)
        {
            Write-Verbose -Message "Checking if the node is in cluster $Name ..."

            $allNodes = Get-ClusterNode -Cluster $Name

            foreach ($node in $allNodes)
            {
                if ($node.Name -eq $env:COMPUTERNAME)
                {
                    if ($node.State -eq 'Up')
                    {
                        $returnValue = $true
                    }
                    else
                    {
                        Write-Verbose -Message "Node is in cluster $Name but is NOT up, treat as NOT in cluster."
                    }

                    break
                }
            }

            if ($returnValue)
            {
                Write-Verbose -Message "Node is in cluster $Name"
            }
            else
            {
                Write-Verbose -Message "Node is NOT in cluster $Name"
            }
        }
    }
    catch
    {
        Write-Verbose -Message "Cluster $Name is NOT present with Error $_.Message"
    }
    finally
    {
        if ($context)
        {
            $context.Undo()
            $context.Dispose()

            Close-UserToken -Token $newToken
        }
    }

    $returnValue
}


function Get-ImpersonateLib
{
    if ($script:ImpersonateLib)
    {
        return $script:ImpersonateLib
    }

    $sig = @'
[DllImport("advapi32.dll", SetLastError = true)]
public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

[DllImport("kernel32.dll")]
public static extern Boolean CloseHandle(IntPtr hObject);
'@
    $script:ImpersonateLib = Add-Type -PassThru -Namespace 'Lib.Impersonation' -Name ImpersonationLib -MemberDefinition $sig

    return $script:ImpersonateLib
}

function ImpersonateAs
{
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    [IntPtr] $userToken = [Security.Principal.WindowsIdentity]::GetCurrent().Token
    $userToken
    $ImpersonateLib = Get-ImpersonateLib

    $bLogin = $ImpersonateLib::LogonUser($Credential.GetNetworkCredential().UserName, $Credential.GetNetworkCredential().Domain, $Credential.GetNetworkCredential().Password,
        9, 0, [ref]$userToken)

    if ($bLogin)
    {
        $Identity = New-Object Security.Principal.WindowsIdentity $userToken
        $context = $Identity.Impersonate()
    }
    else
    {
        throw "Can't Logon as User $($Credential.GetNetworkCredential().UserName)."
    }

    $context, $userToken
}

function Close-UserToken
{
    param
    (
        [Parameter()]
        [System.IntPtr]
        $Token
    )

    $ImpersonateLib = Get-ImpersonateLib

    $bLogin = $ImpersonateLib::CloseHandle($Token)
    if (-not $bLogin)
    {
        throw 'Can''t close token'
    }
}
