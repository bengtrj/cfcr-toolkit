#### Deploy bosh script
1. Figure out gcp/bosh requirements to CFCR
    PER BOSH DIRECTOR
    1. dns
        google_dns_managed_zone - MAYBE ONE FOR ALL CLUSTERS?
            name        "${var.env_id}-cfcr-zone"
            dns_name    "${kubernetes_master_host}"
            description "DNS zone for the ${var.env_id} cfcr environment"
        google_dns_record_set          
            name "${kubernetes_master_host}"
            type "A"
            ttl  "300"
    PER CLUSTER
    1. Service account for master and worker with:
        
1. review bosh deployment and run successfully
1. Change script to include this steps

#### Deploy CFCR script



#### Teardown script
1. bbl down
1. delete script created resources (networks etc) 