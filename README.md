# azure-hpcc-multiple-nodes

With is repository, azure-hpcc-multiple-nodes, one can launch an HPCC cluster on azure. Most of the code of this repository is terraform.

The following tells you how to use this repository to launch an HPCC cluster on azure. 

## Use Azure's bash Cloud Shell. 
Why? Because it has tools you need already installed: git, terraform, azure cli, and others. Plus, you don't have to authenticate, since you did so when you logged into azure.

You can access azure's Cloud Shell by logging into azure and clicking on the icon just to the right of the search bar.

If you are new to azure, when you click on the icon, you will be told you need a subscription to use Azure Cloud Shell. And, you are provided a link to create a free one.

If this is the first time you have accessed the Cloud Shell, Azure will tell you that some storage is needed for the cloud shell to persist the account settings and files.

Click Create Storage. After a few seconds, you should be presented with a Linux shell. At this point, the cloud shell will already be logged into to your Azure account. 

## Clone this repository 
Use the following command to clone this repository.

    git clone https://github.com/tlhumphrey2/azure-hpcc-multiple-nodes.git

Then, cd into the directory, azure-hpcc-multiple-nodes, using the command.

    cd azure-hpcc-multiple-nodes

Specify your cluster parameters by changing the file, terraform.tfvars. Its current contents is:

     prefix_cluster_name = "some-cluster-name"
     admin_password      = "pick secure password"
     resource_group_name = "pick resource group that doesn't currently exist"
     thornodes           = "2"
     roxienodes          = "2"
     supportdisksize     = "30"# size of support disk (esp, dali, dafilesrv, landing zone, etc) (in GB)
     thordisksize        = "30"# size of disk on each thor slave (in GB)
     roxiedisksize       = "30"# size of disk on each roxie (in GB)
     platform            = "https://d2wulyp08c6njk.cloudfront.net/releases/CE-Candidate-7.8.46/bin/platform/hpccsystems-platform-community_7.8.46-1.el7.x86_64.rpm"

These parameters must be changed: prefix_cluster_name, admin_password, and resource_group_name. The 1st 2 parameters can have any values, as long as there are no spaces. The last parameter, resource_group_name must be different than any resource group currently in you azure account.

The parameter, admin_password, is used to ssh into any of the cluster servers (VMs).

Use the following 2 commands to launch your hpcc cluster:

    terraform init.
    terraform apply 2>&1|tee apply.log

In the above 'terraform apply' command, you really don't need "| tee apply.log". But, I use it because the cloud shell times out a lot (at least it did for me). So, after it times out, I start another cloud shell session and do the following command to watch the apply.log file as the cluster is launched.

    tail -f apply.log
   
 Once cluster has launched, the final thing you will see is the IP address that you use for ecl-watch. Also, you can get this by doing the following command:

    terraform output

That's about it. But, below are some additional notes of interest.

### note: The cluster may not be fully ready if you go into ecl watch as soon as the IP address is available (i.e. immediately after cluster has finished launching). If you refresh your browser one or two times it should be ready to use.

### note: You can set thornodes and roxienodes to any number from zero up. The only scenario that didn't work for me was setting thornodes=0 and roxienodes to any positive number. All other cases should work.

