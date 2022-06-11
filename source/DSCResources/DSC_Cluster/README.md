# Description

Used to configure a failover cluster. Ensures that a group of machines form a
cluster. If the cluster does not exist, it will be created in the domain and
the static IP address will be assigned to the cluster. When the cluster exist
(either it was created or already existed), it will add the target node
(`$env:COMPUTERNAME`) to the cluster.

## Requirements

* Target machine must be running Windows Server 2008 R2 or later.
