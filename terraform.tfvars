admin_password      = "Th0r3N0de"
resource_group_name = "benchmark_tests6"
vm_size             = "Standard_D13"# The size of all cluster VMs
#vm_size             = "Standard_DS2_v2"# The size of all cluster VMs
thornodes           = "3"
roxienodes          = "0"
slavesPerNode       = "16" # number of slaves on each vm or instance
supportdisksize     = "600"# size of support disk (esp, dali, dafilesrv, landing zone, etc) (in GB)
thordisksize        = "600"# size of disk on each thor slave (in GB)
roxiedisksize       = "5"# size of disk on each roxie (in GB)
prefix_cluster_name = "benchmark-tests6"
platform            = "https://d2wulyp08c6njk.cloudfront.net/releases/CE-Candidate-8.0.4/bin/platform/hpccsystems-platform-community_8.0.4-1.el7.x86_64.rpm"
