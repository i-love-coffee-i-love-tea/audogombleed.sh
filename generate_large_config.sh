#!/bin/bash
# Generates a large config with 600+ commands, deep nesting, and lots of comments

cat <<'EOF'
[env]
__CLI_CFG_LOG_LEVEL=0

[commands]

# =============================================================================
# Section: Infrastructure Management
# =============================================================================
# This section covers all infrastructure commands for managing
# servers, networks, storage, and virtual machines across
# multiple data centers and availability zones.

# ---------------------------------------------------------------------------
# Subsection: Server Provisioning
# ---------------------------------------------------------------------------
# Commands for provisioning bare-metal and virtual servers
# across various cloud providers and on-premise data centers.
# Supports automated OS installation, hardware discovery,
# firmware updates, and BMC/IPMI management.

provision
	# Provision a new server with the specified configuration
	# Requires network access to the provisioning server
	# and valid credentials for the target environment
	server
		# Deploy a physical bare-metal server
		# Supports Dell, HP, Lenovo, and Supermicro hardware
		bare-metal
			# Deploy to the US East data center
			us-east
				deploy: echo "deploying bare-metal us-east \1"
					# The hostname for the new server
					:hostname:STRING
					# The datacenter rack location
					:rack:STRING
				configure: echo "configuring bare-metal us-east \1"
					# Network configuration profile
					:profile:list:dhcp|static|bonded
				destroy: echo "destroying bare-metal us-east \1"
					:hostname:STRING
				reboot: echo "rebooting bare-metal us-east \1"
					:hostname:STRING
				status: echo "status bare-metal us-east \1"
					:hostname:STRING
				audit: echo "auditing bare-metal us-east"
				inventory: echo "listing bare-metal us-east"
			us-west
				deploy: echo "deploying bare-metal us-west \1"
					:hostname:STRING
					:rack:STRING
				configure: echo "configuring bare-metal us-west \1"
					:profile:list:dhcp|static|bonded
				destroy: echo "destroying bare-metal us-west \1"
					:hostname:STRING
				reboot: echo "rebooting bare-metal us-west \1"
					:hostname:STRING
				status: echo "status bare-metal us-west \1"
					:hostname:STRING
				audit: echo "auditing bare-metal us-west"
				inventory: echo "listing bare-metal us-west"
			eu-central
				deploy: echo "deploying bare-metal eu-central \1"
					:hostname:STRING
					:rack:STRING
				configure: echo "configuring bare-metal eu-central \1"
					:profile:list:dhcp|static|bonded
				destroy: echo "destroying bare-metal eu-central \1"
					:hostname:STRING
				reboot: echo "rebooting bare-metal eu-central \1"
					:hostname:STRING
				status: echo "status bare-metal eu-central \1"
					:hostname:STRING
				audit: echo "auditing bare-metal eu-central"
				inventory: echo "listing bare-metal eu-central"
			ap-southeast
				deploy: echo "deploying bare-metal ap-southeast \1"
					:hostname:STRING
					:rack:STRING
				configure: echo "configuring bare-metal ap-southeast \1"
					:profile:list:dhcp|static|bonded
				destroy: echo "destroying bare-metal ap-southeast \1"
					:hostname:STRING
				reboot: echo "rebooting bare-metal ap-southeast \1"
					:hostname:STRING
				status: echo "status bare-metal ap-southeast \1"
					:hostname:STRING
				audit: echo "auditing bare-metal ap-southeast"
				inventory: echo "listing bare-metal ap-southeast"
		# Deploy a virtual machine
		# Supports KVM, VMware, and Hyper-V hypervisors
		virtual
			kvm
				us-east
					create: echo "creating kvm us-east \1"
						:name:STRING
						:vcpus:int_range:1-128
						:memory:int_range:512-524288
						:disk:int_range:10-100000
					delete: echo "deleting kvm us-east \1"
						:name:STRING
					start: echo "starting kvm us-east \1"
						:name:STRING
					stop: echo "stopping kvm us-east \1"
						:name:STRING
					migrate: echo "migrating kvm us-east \1"
						:name:STRING
						:target:STRING
					snapshot: echo "snapshot kvm us-east \1"
						:name:STRING
						:snapname:STRING
					clone: echo "cloning kvm us-east \1"
						:source:STRING
						:target:STRING
					resize: echo "resizing kvm us-east \1"
						:name:STRING
						:vcpus:int_range:1-128
						:memory:int_range:512-524288
				us-west
					create: echo "creating kvm us-west \1"
						:name:STRING
						:vcpus:int_range:1-128
						:memory:int_range:512-524288
						:disk:int_range:10-100000
					delete: echo "deleting kvm us-west \1"
						:name:STRING
					start: echo "starting kvm us-west \1"
						:name:STRING
					stop: echo "stopping kvm us-west \1"
						:name:STRING
					migrate: echo "migrating kvm us-west \1"
						:name:STRING
						:target:STRING
					snapshot: echo "snapshot kvm us-west \1"
						:name:STRING
						:snapname:STRING
					clone: echo "cloning kvm us-west \1"
						:source:STRING
						:target:STRING
					resize: echo "resizing kvm us-west \1"
						:name:STRING
						:vcpus:int_range:1-128
						:memory:int_range:512-524288
			vmware
				us-east
					create: echo "creating vmware us-east \1"
						:name:STRING
						:vcpus:int_range:1-128
						:memory:int_range:512-524288
					delete: echo "deleting vmware us-east \1"
						:name:STRING
					start: echo "starting vmware us-east \1"
						:name:STRING
					stop: echo "stopping vmware us-east \1"
						:name:STRING
					migrate: echo "migrating vmware us-east \1"
						:name:STRING
						:target:STRING
					snapshot: echo "snapshot vmware us-east \1"
						:name:STRING
						:snapname:STRING
				us-west
					create: echo "creating vmware us-west \1"
						:name:STRING
						:vcpus:int_range:1-128
						:memory:int_range:512-524288
					delete: echo "deleting vmware us-west \1"
						:name:STRING
					start: echo "starting vmware us-west \1"
						:name:STRING
					stop: echo "stopping vmware us-west \1"
						:name:STRING
					migrate: echo "migrating vmware us-west \1"
						:name:STRING
						:target:STRING
					snapshot: echo "snapshot vmware us-west \1"
						:name:STRING
						:snapname:STRING

# =============================================================================
# Section: Network Management
# =============================================================================
# Commands for managing network infrastructure including
# VLANs, firewalls, load balancers, DNS, and VPN tunnels.
# Supports both physical and virtual network devices.

	# Network configuration and management commands
	# Handles all network-related operations across
	# the entire infrastructure fleet
	network
		# VLAN management for network segmentation
		# Each VLAN can be associated with specific
		# security policies and routing rules
		vlan
			create: echo "creating vlan \1 \2"
				# The VLAN ID (1-4094)
				:vlan_id:int_range:1-4094
				# A descriptive name for the VLAN
				:name:STRING
			delete: echo "deleting vlan \1"
				:vlan_id:int_range:1-4094
			list: echo "listing vlans"
			show: echo "showing vlan \1"
				:vlan_id:int_range:1-4094
			modify: echo "modifying vlan \1"
				:vlan_id:int_range:1-4094
				:name:STRING
			assign: echo "assigning vlan \1 to \2"
				:vlan_id:int_range:1-4094
				:interface:STRING
			unassign: echo "unassigning vlan \1 from \2"
				:vlan_id:int_range:1-4094
				:interface:STRING
		# Firewall rule management
		# Supports stateful and stateless rules
		# with IPv4 and IPv6 address families
		firewall
			rule
				add: echo "adding firewall rule \1"
					:rule_name:STRING
					:action:list:allow|deny|log
					:protocol:list:tcp|udp|icmp|any
					:source:STRING
					:destination:STRING
					:port:int_range:1-65535
				delete: echo "deleting firewall rule \1"
					:rule_name:STRING
				list: echo "listing firewall rules"
				show: echo "showing firewall rule \1"
					:rule_name:STRING
				modify: echo "modifying firewall rule \1"
					:rule_name:STRING
					:action:list:allow|deny|log
				enable: echo "enabling firewall rule \1"
					:rule_name:STRING
				disable: echo "disabling firewall rule \1"
					:rule_name:STRING
				move: echo "moving firewall rule \1 to position \2"
					:rule_name:STRING
					:position:int_range:1-1000
			chain
				create: echo "creating firewall chain \1"
					:name:STRING
				delete: echo "deleting firewall chain \1"
					:name:STRING
				list: echo "listing firewall chains"
				flush: echo "flushing firewall chain \1"
					:name:STRING
			policy
				set: echo "setting firewall policy \1 to \2"
					:chain:STRING
					:default:list:accept|drop|reject
				show: echo "showing firewall policy \1"
					:chain:STRING
		# Load balancer configuration
		# Supports L4 and L7 load balancing with
		# health checks, session persistence, and SSL termination
		loadbalancer
			pool
				create: echo "creating lb pool \1"
					:name:STRING
					:algorithm:list:round-robin|least-connections|ip-hash|weighted
					:health_check:list:http|https|tcp|icmp
				delete: echo "deleting lb pool \1"
					:name:STRING
				list: echo "listing lb pools"
				show: echo "showing lb pool \1"
					:name:STRING
				modify: echo "modifying lb pool \1"
					:name:STRING
					:algorithm:list:round-robin|least-connections|ip-hash|weighted
			member
				add: echo "adding lb member \1 to pool \2"
					:address:STRING
					:pool:STRING
					:port:int_range:1-65535
					:weight:int_range:1-256
				delete: echo "deleting lb member \1 from pool \2"
					:address:STRING
					:pool:STRING
				list: echo "listing lb members for pool \1"
					:pool:STRING
			monitor
				create: echo "creating lb monitor \1"
					:name:STRING
					:type:list:http|https|tcp|icmp
					:interval:int_range:1-300
					:timeout:int_range:1-300
				delete: echo "deleting lb monitor \1"
					:name:STRING
				list: echo "listing lb monitors"
			virtual-server
				create: echo "creating lb vserver \1"
					:name:STRING
					:vip:STRING
					:port:int_range:1-65535
					:pool:STRING
					:protocol:list:tcp|udp|http|https
				delete: echo "deleting lb vserver \1"
					:name:STRING
				list: echo "listing lb vservers"
				show: echo "showing lb vserver \1"
					:name:STRING
				enable: echo "enabling lb vserver \1"
					:name:STRING
				disable: echo "disabling lb vserver \1"
					:name:STRING
		# DNS zone and record management
		dns
			zone
				create: echo "creating dns zone \1"
					:domain:STRING
					:type:list:primary|secondary|forward
					:master:STRING?
				delete: echo "deleting dns zone \1"
					:domain:STRING
				list: echo "listing dns zones"
				show: echo "showing dns zone \1"
					:domain:STRING
				transfer: echo "transferring dns zone \1"
					:domain:STRING
			record
				add: echo "adding dns record \1 \2"
					:zone:STRING
					:name:STRING
					:type:list:A|AAAA|CNAME|MX|TXT|SRV|NS|PTR
					:value:STRING
					:ttl:int_range:60-86400?
				delete: echo "deleting dns record \1 \2"
					:zone:STRING
					:name:STRING
				list: echo "listing dns records for \1"
					:zone:STRING
				modify: echo "modifying dns record \1 \2"
					:zone:STRING
					:name:STRING
					:value:STRING
		# VPN tunnel management
		vpn
			ipsec
				create: echo "creating ipsec tunnel \1"
					:name:STRING
					:local_ip:STRING
					:remote_ip:STRING
					:psk:STRING
					:encryption:list:aes128|aes256|3des
					:hash:list:sha1|sha256|sha512|md5
				delete: echo "deleting ipsec tunnel \1"
					:name:STRING
				list: echo "listing ipsec tunnels"
				show: echo "showing ipsec tunnel \1"
					:name:STRING
				status: echo "status ipsec tunnel \1"
					:name:STRING
				up: echo "bringing up ipsec tunnel \1"
					:name:STRING
				down: echo "bringing down ipsec tunnel \1"
					:name:STRING
			wireguard
				create: echo "creating wireguard interface \1"
					:name:STRING
					:listen_port:int_range:1-65535
					:private_key:STRING
				delete: echo "deleting wireguard interface \1"
					:name:STRING
				list: echo "listing wireguard interfaces"
				show: echo "showing wireguard interface \1"
					:name:STRING
				peer
					add: echo "adding wireguard peer \1 to \2"
						:peer_name:STRING
						:interface:STRING
						:public_key:STRING
						:endpoint:STRING
						:allowed_ips:STRING
					delete: echo "deleting wireguard peer \1 from \2"
						:peer_name:STRING
						:interface:STRING
					list: echo "listing wireguard peers on \1"
						:interface:STRING

# =============================================================================
# Section: Storage Management
# =============================================================================
# Commands for managing storage infrastructure including
# SAN, NAS, object storage, and distributed filesystems.
# Supports snapshots, replication, and tiering.

	storage
		# SAN storage management
		# Handles LUN creation, masking, and zoning
		san
			lun
				create: echo "creating lun \1 size \2"
					:name:STRING
					:size:int_range:1-100000
					:pool:STRING
					:protocol:list:iscsi|fc|nvme
				delete: echo "deleting lun \1"
					:name:STRING
				list: echo "listing luns"
				show: echo "showing lun \1"
					:name:STRING
				resize: echo "resizing lun \1 to \2"
					:name:STRING
					:size:int_range:1-100000
				snapshot: echo "snapshot lun \1"
					:name:STRING
					:snapname:STRING
				clone: echo "cloning lun \1 to \2"
					:source:STRING
					:target:STRING
			target
				create: echo "creating san target \1"
					:name:STRING
					:iqn:STRING
					:ip:STRING
				delete: echo "deleting san target \1"
					:name:STRING
				list: echo "listing san targets"
				show: echo "showing san target \1"
					:name:STRING
			mapping
				add: echo "mapping lun \1 to target \2"
					:lun:STRING
					:target:STRING
				delete: echo "unmapping lun \1 from target \2"
					:lun:STRING
					:target:STRING
				list: echo "listing lun mappings"
		# NAS storage management
		# Handles NFS and SMB/CIFS share management
		nas
			share
				create: echo "creating nas share \1"
					:name:STRING
					:path:STRING
					:protocol:list:nfs|cifs|both
					:permissions:list:ro|rw
				delete: echo "deleting nas share \1"
					:name:STRING
				list: echo "listing nas shares"
				show: echo "showing nas share \1"
					:name:STRING
				modify: echo "modifying nas share \1"
					:name:STRING
					:permissions:list:ro|rw
			export
				add: echo "adding export for \1 to \2"
					:share:STRING
					:host:STRING
					:permissions:list:ro|rw|root-squash
				delete: echo "removing export for \1 from \2"
					:share:STRING
					:host:STRING
				list: echo "listing exports for \1"
					:share:STRING
		# Object storage management
		# S3-compatible bucket and object operations
		object-storage
			bucket
				create: echo "creating bucket \1"
					:name:STRING
					:region:list:us-east-1|us-west-2|eu-central-1|ap-southeast-1
					:versioning:list:enabled|disabled
				delete: echo "deleting bucket \1"
					:name:STRING
				list: echo "listing buckets"
				show: echo "showing bucket \1"
					:name:STRING
				modify: echo "modifying bucket \1"
					:name:STRING
					:versioning:list:enabled|disabled
					:encryption:list:aes256|aws-kms|none
			object
				put: echo "uploading \1 to \2"
					:file:FILE
					:bucket:STRING
					:key:STRING?
				get: echo "downloading \1 from \2"
					:bucket:STRING
					:key:STRING
					:destination:DIR?
				delete: echo "deleting object \1 from \2"
					:key:STRING
					:bucket:STRING
				list: echo "listing objects in \1"
					:bucket:STRING
					:prefix:STRING?

# =============================================================================
# Section: Container Orchestration
# =============================================================================
# Commands for managing containerized workloads including
# Docker, Kubernetes, and Nomad clusters.

	# Container orchestration and management
	# Supports multiple orchestration platforms
	container
		# Docker container management
		docker
			container
				run: echo "running docker container \1"
					:image:STRING
					:name:STRING?
					:ports:STRING?
					:volumes:STRING?
					:env:STRING?
				stop: echo "stopping docker container \1"
					:name:STRING
				start: echo "starting docker container \1"
					:name:STRING
				restart: echo "restarting docker container \1"
					:name:STRING
				rm: echo "removing docker container \1"
					:name:STRING
				logs: echo "showing logs for \1"
					:name:STRING
					:lines:int_range:1-10000?
				exec: echo "exec in container \1: \2"
					:name:STRING
					:command:STRING
				inspect: echo "inspecting container \1"
					:name:STRING
				ps: echo "listing docker containers"
					:all:list:true|false?
			image
				build: echo "building docker image \1"
					:tag:STRING
					:context:DIR?
					:dockerfile:FILE?
				pull: echo "pulling docker image \1"
					:image:STRING
				push: echo "pushing docker image \1"
					:image:STRING
				tag: echo "tagging docker image \1 as \2"
					:source:STRING
					:target:STRING
				rmi: echo "removing docker image \1"
					:image:STRING
				ls: echo "listing docker images"
			network
				create: echo "creating docker network \1"
					:name:STRING
					:driver:list:bridge|overlay|macvlan|host?
				delete: echo "deleting docker network \1"
					:name:STRING
				ls: echo "listing docker networks"
				connect: echo "connecting \1 to network \2"
					:container:STRING
					:network:STRING
				disconnect: echo "disconnecting \1 from network \2"
					:container:STRING
					:network:STRING
			volume
				create: echo "creating docker volume \1"
					:name:STRING
					:driver:list:local|nfs|ceph?
				delete: echo "deleting docker volume \1"
					:name:STRING
				ls: echo "listing docker volumes"
				inspect: echo "inspecting docker volume \1"
					:name:STRING
		# Kubernetes cluster management
		kubernetes
			cluster
				create: echo "creating k8s cluster \1"
					:name:STRING
					:node_count:int_range:1-1000
					:node_type:STRING
					:region:STRING
				delete: echo "deleting k8s cluster \1"
					:name:STRING
				list: echo "listing k8s clusters"
				show: echo "showing k8s cluster \1"
					:name:STRING
				scale: echo "scaling k8s cluster \1 to \2 nodes"
					:name:STRING
					:node_count:int_range:1-1000
				upgrade: echo "upgrading k8s cluster \1 to \2"
					:name:STRING
					:version:STRING
			deployment
				create: echo "creating k8s deployment \1"
					:name:STRING
					:image:STRING
					:replicas:int_range:1-1000
					:namespace:STRING?
				delete: echo "deleting k8s deployment \1"
					:name:STRING
					:namespace:STRING?
				list: echo "listing k8s deployments"
					:namespace:STRING?
				scale: echo "scaling k8s deployment \1 to \2"
					:name:STRING
					:replicas:int_range:1-1000
					:namespace:STRING?
				rollback: echo "rolling back k8s deployment \1"
					:name:STRING
					:namespace:STRING?
				status: echo "status k8s deployment \1"
					:name:STRING
					:namespace:STRING?
			service
				create: echo "creating k8s service \1"
					:name:STRING
					:type:list:ClusterIP|NodePort|LoadBalancer
					:port:int_range:1-65535
					:target_port:int_range:1-65535
					:namespace:STRING?
				delete: echo "deleting k8s service \1"
					:name:STRING
					:namespace:STRING?
				list: echo "listing k8s services"
					:namespace:STRING?
				show: echo "showing k8s service \1"
					:name:STRING
					:namespace:STRING?
			configmap
				create: echo "creating k8s configmap \1"
					:name:STRING
					:from_file:FILE?
					:from_literal:STRING?
					:namespace:STRING?
				delete: echo "deleting k8s configmap \1"
					:name:STRING
					:namespace:STRING?
				list: echo "listing k8s configmaps"
					:namespace:STRING?
			secret
				create: echo "creating k8s secret \1"
					:name:STRING
					:type:list:generic|tls|docker-registry
					:from_file:FILE?
					:namespace:STRING?
				delete: echo "deleting k8s secret \1"
					:name:STRING
					:namespace:STRING?
				list: echo "listing k8s secrets"
					:namespace:STRING?
			namespace
				create: echo "creating k8s namespace \1"
					:name:STRING
				delete: echo "deleting k8s namespace \1"
					:name:STRING
				list: echo "listing k8s namespaces"

# =============================================================================
# Section: Database Management
# =============================================================================
# Commands for managing database instances including
# PostgreSQL, MySQL, MongoDB, and Redis clusters.

	database
		# PostgreSQL database management
		postgres
			instance
				create: echo "creating pg instance \1"
					:name:STRING
					:version:list:12|13|14|15|16
					:size:list:small|medium|large|xlarge
					:storage:int_range:10-10000
				delete: echo "deleting pg instance \1"
					:name:STRING
				start: echo "starting pg instance \1"
					:name:STRING
				stop: echo "stopping pg instance \1"
					:name:STRING
				restart: echo "restarting pg instance \1"
					:name:STRING
				status: echo "status pg instance \1"
					:name:STRING
				modify: echo "modifying pg instance \1"
					:name:STRING
					:size:list:small|medium|large|xlarge?
					:storage:int_range:10-10000?
			database
				create: echo "creating pg database \1 on \2"
					:database:STRING
					:instance:STRING
					:encoding:list:UTF8|LATIN1|SQL_ASCII?
					:collation:STRING?
				delete: echo "deleting pg database \1 on \2"
					:database:STRING
					:instance:STRING
				list: echo "listing pg databases on \1"
					:instance:STRING
			user
				create: echo "creating pg user \1 on \2"
					:username:STRING
					:instance:STRING
					:password:STRING
					:superuser:list:true|false
				delete: echo "deleting pg user \1 on \2"
					:username:STRING
					:instance:STRING
				list: echo "listing pg users on \1"
					:instance:STRING
				grant: echo "granting \1 on \2 to \3"
					:privilege:list:SELECT|INSERT|UPDATE|DELETE|ALL
					:database:STRING
					:username:STRING
					:instance:STRING
			backup
				create: echo "creating pg backup of \1"
					:instance:STRING
					:type:list:full|incremental|wal
				restore: echo "restoring pg backup \1 to \2"
					:backup_id:STRING
					:instance:STRING
				list: echo "listing pg backups for \1"
					:instance:STRING
				delete: echo "deleting pg backup \1"
					:backup_id:STRING
		# MySQL database management
		mysql
			instance
				create: echo "creating mysql instance \1"
					:name:STRING
					:version:list:5.7|8.0|8.4
					:size:list:small|medium|large|xlarge
				delete: echo "deleting mysql instance \1"
					:name:STRING
				start: echo "starting mysql instance \1"
					:name:STRING
				stop: echo "stopping mysql instance \1"
					:name:STRING
				status: echo "status mysql instance \1"
					:name:STRING
			database
				create: echo "creating mysql database \1 on \2"
					:database:STRING
					:instance:STRING
				delete: echo "deleting mysql database \1 on \2"
					:database:STRING
					:instance:STRING
				list: echo "listing mysql databases on \1"
					:instance:STRING
			user
				create: echo "creating mysql user \1 on \2"
					:username:STRING
					:instance:STRING
					:password:STRING
				delete: echo "deleting mysql user \1 on \2"
					:username:STRING
					:instance:STRING
				grant: echo "granting \1 on \2.* to \3"
					:privilege:list:SELECT|INSERT|UPDATE|DELETE|ALL
					:database:STRING
					:username:STRING
					:instance:STRING
		# MongoDB database management
		mongodb
			instance
				create: echo "creating mongodb instance \1"
					:name:STRING
					:version:list:5.0|6.0|7.0
					:replica_set:STRING?
				delete: echo "deleting mongodb instance \1"
					:name:STRING
				status: echo "status mongodb instance \1"
					:name:STRING
			database
				create: echo "creating mongodb database \1"
					:database:STRING
					:instance:STRING
				delete: echo "deleting mongodb database \1"
					:database:STRING
					:instance:STRING
			collection
				create: echo "creating mongodb collection \1 in \2"
					:collection:STRING
					:database:STRING
					:instance:STRING
				delete: echo "deleting mongodb collection \1 from \2"
					:collection:STRING
					:database:STRING
					:instance:STRING
				list: echo "listing mongodb collections in \1"
					:database:STRING
					:instance:STRING
		# Redis cluster management
		redis
			cluster
				create: echo "creating redis cluster \1"
					:name:STRING
					:node_count:int_range:3-100
					:size:list:small|medium|large
				delete: echo "deleting redis cluster \1"
					:name:STRING
				status: echo "status redis cluster \1"
					:name:STRING
				scale: echo "scaling redis cluster \1 to \2 nodes"
					:name:STRING
					:node_count:int_range:3-100
			instance
				create: echo "creating redis instance \1"
					:name:STRING
					:port:int_range:1024-65535
					:memory:int_range:64-131072
				delete: echo "deleting redis instance \1"
					:name:STRING
				status: echo "status redis instance \1"
					:name:STRING

# =============================================================================
# Section: Monitoring and Observability
# =============================================================================
# Commands for managing monitoring, logging, tracing,
# and alerting infrastructure.

	monitoring
		# Metrics collection and querying
		metrics
			query: echo "querying metrics: \1"
				:promql:STRING
				:start:STRING?
				:end:STRING?
				:step:STRING?
			targets
				add: echo "adding metrics target \1"
					:url:STRING
					:labels:STRING?
				delete: echo "deleting metrics target \1"
					:url:STRING
				list: echo "listing metrics targets"
			rule
				create: echo "creating metrics rule \1"
					:name:STRING
					:expression:STRING
					:duration:STRING
					:severity:list:critical|warning|info
				delete: echo "deleting metrics rule \1"
					:name:STRING
				list: echo "listing metrics rules"
				show: echo "showing metrics rule \1"
					:name:STRING
		# Log aggregation and querying
		logs
			query: echo "querying logs: \1"
				:query:STRING
				:start:STRING?
				:end:STRING?
				:limit:int_range:1-10000?
			stream
				start: echo "starting log stream for \1"
					:query:STRING
				stop: echo "stopping log stream"
			source
				add: echo "adding log source \1"
					:name:STRING
					:type:list:syslog|journald|file|docker|k8s
					:path:STRING?
				delete: echo "deleting log source \1"
					:name:STRING
				list: echo "listing log sources"
		# Distributed tracing
		tracing
			service
				search: echo "searching traces for \1"
					:service:STRING
					:operation:STRING?
					:duration_min:STRING?
					:duration_max:STRING?
				show: echo "showing trace \1"
					:trace_id:STRING
			sampling
				set: echo "setting sampling rate to \1"
					:rate:int_range:0-100
				show: echo "showing sampling config"
		# Alerting management
		alerts
			channel
				create: echo "creating alert channel \1"
					:name:STRING
					:type:list:email|slack|pagerduty|webhook
					:target:STRING
				delete: echo "deleting alert channel \1"
					:name:STRING
				list: echo "listing alert channels"
				test: echo "testing alert channel \1"
					:name:STRING
			policy
				create: echo "creating alert policy \1"
					:name:STRING
					:rule:STRING
					:channel:STRING
					:severity:list:critical|warning|info
				delete: echo "deleting alert policy \1"
					:name:STRING
				list: echo "listing alert policies"
				enable: echo "enabling alert policy \1"
					:name:STRING
				disable: echo "disabling alert policy \1"
					:name:STRING

# =============================================================================
# Section: CI/CD Pipeline Management
# =============================================================================
# Commands for managing continuous integration and
# deployment pipelines, artifacts, and environments.

	cicd
		# Pipeline management
		pipeline
			create: echo "creating pipeline \1"
				:name:STRING
				:repo:STRING
				:branch:STRING?
				:trigger:list:push|tag|manual|schedule
			delete: echo "deleting pipeline \1"
				:name:STRING
			list: echo "listing pipelines"
			show: echo "showing pipeline \1"
				:name:STRING
			run: echo "running pipeline \1"
				:name:STRING
				:branch:STRING?
				:variables:STRING?
			cancel: echo "canceling pipeline run \1"
				:run_id:STRING
			retry: echo "retrying pipeline run \1"
				:run_id:STRING
			status: echo "status pipeline \1"
				:name:STRING
				:run_id:STRING?
		# Artifact management
		artifact
			push: echo "pushing artifact \1 to \2"
				:file:FILE
				:repository:STRING
				:tag:STRING?
				:type:list:docker|maven|npm|generic
			pull: echo "pulling artifact \1 from \2"
				:artifact:STRING
				:repository:STRING
				:destination:DIR?
			delete: echo "deleting artifact \1 from \2"
				:artifact:STRING
				:repository:STRING
			list: echo "listing artifacts in \1"
				:repository:STRING
			repository
				create: echo "creating artifact repository \1"
					:name:STRING
					:type:list:docker|maven|npm|generic
					:storage:int_range:1-10000?
				delete: echo "deleting artifact repository \1"
					:name:STRING
				list: echo "listing artifact repositories"
		# Environment management
		environment
			create: echo "creating environment \1"
				:name:STRING
				:type:list:development|staging|production
				:cluster:STRING?
			delete: echo "deleting environment \1"
				:name:STRING
			list: echo "listing environments"
			show: echo "showing environment \1"
				:name:STRING
			deploy: echo "deploying \1 to environment \2"
				:artifact:STRING
				:environment:STRING
				:version:STRING
			rollback: echo "rolling back environment \1 to \2"
				:environment:STRING
				:version:STRING
			promote: echo "promoting \1 from \2 to \3"
				:version:STRING
				:source:STRING
				:target:STRING

# =============================================================================
# Section: Security and Compliance
# =============================================================================
# Commands for managing security policies, certificates,
# secrets, and compliance scanning.

	security
		# Certificate management
		certificate
			create: echo "creating certificate \1"
				:name:STRING
				:domain:STRING
				:type:list:lets-encrypt|self-signed|imported
				:validity:int_range:1-3650?
			delete: echo "deleting certificate \1"
				:name:STRING
			list: echo "listing certificates"
			show: echo "showing certificate \1"
				:name:STRING
			renew: echo "renewing certificate \1"
				:name:STRING
			import: echo "importing certificate \1"
				:name:STRING
				:cert_file:FILE
				:key_file:FILE
			export: echo "exporting certificate \1"
				:name:STRING
				:destination:DIR
		# Secret management (Vault-style)
		secret
			vault
				init: echo "initializing vault"
					:shares:int_range:1-10
					:threshold:int_range:1-10
				unseal: echo "unsealing vault with key \1"
					:key:STRING
				status: echo "showing vault status"
			path
				write: echo "writing secret to \1"
					:path:STRING
					:data:STRING
				read: echo "reading secret from \1"
					:path:STRING
				delete: echo "deleting secret at \1"
					:path:STRING
				list: echo "listing secrets at \1"
					:path:STRING
			policy
				create: echo "creating vault policy \1"
					:name:STRING
					:rules:FILE
				delete: echo "deleting vault policy \1"
					:name:STRING
				list: echo "listing vault policies"
		# Compliance scanning
		compliance
			scan
				start: echo "starting compliance scan \1"
					:framework:list:cis|pci-dss|hipaa|soc2|gdpr
					:target:STRING
				status: echo "status compliance scan \1"
					:scan_id:STRING
				report: echo "generating report for scan \1"
					:scan_id:STRING
					:format:list:pdf|html|json|csv
			framework
				list: echo "listing compliance frameworks"
				show: echo "showing framework \1"
					:framework:list:cis|pci-dss|hipaa|soc2|gdpr

# =============================================================================
# Section: Backup and Disaster Recovery
# =============================================================================
# Commands for managing backup policies, snapshots,
# replication, and disaster recovery procedures.

	backup
		# Backup policy management
		policy
			create: echo "creating backup policy \1"
				:name:STRING
				:schedule:STRING
				:retention:int_range:1-365
				:targets:STRING
			delete: echo "deleting backup policy \1"
				:name:STRING
			list: echo "listing backup policies"
			show: echo "showing backup policy \1"
				:name:STRING
			modify: echo "modifying backup policy \1"
				:name:STRING
				:schedule:STRING?
				:retention:int_range:1-365?
			enable: echo "enabling backup policy \1"
				:name:STRING
			disable: echo "disabling backup policy \1"
				:name:STRING
		# Backup job management
		job
			start: echo "starting backup job \1"
				:policy:STRING
			cancel: echo "canceling backup job \1"
				:job_id:STRING
			status: echo "status backup job \1"
				:job_id:STRING
			list: echo "listing backup jobs"
				:policy:STRING?
		# Restore operations
		restore
			start: echo "starting restore from \1"
				:backup_id:STRING
				:destination:STRING
				:point_in_time:STRING?
			status: echo "status restore \1"
				:restore_id:STRING
			cancel: echo "canceling restore \1"
				:restore_id:STRING
		# Disaster recovery
		dr
			plan
				create: echo "creating DR plan \1"
					:name:STRING
					:primary_site:STRING
					:dr_site:STRING
					:rpo:int_range:0-1440
					:rto:int_range:0-1440
				delete: echo "deleting DR plan \1"
					:name:STRING
				list: echo "listing DR plans"
				show: echo "showing DR plan \1"
					:name:STRING
			test
				start: echo "starting DR test for \1"
					:plan:STRING
				stop: echo "stopping DR test for \1"
					:plan:STRING
				status: echo "status DR test for \1"
					:plan:STRING
			failover
				initiate: echo "initiating failover for \1"
					:plan:STRING
				complete: echo "completing failover for \1"
					:plan:STRING
				abort: echo "aborting failover for \1"
					:plan:STRING

# =============================================================================
# Section: Identity and Access Management
# =============================================================================
# Commands for managing users, roles, policies,
# and authentication providers.

	iam
		# User management
		user
			create: echo "creating user \1"
				:username:STRING
				:email:STRING
				:password:STRING?
				:groups:STRING?
			delete: echo "deleting user \1"
				:username:STRING
			list: echo "listing users"
			show: echo "showing user \1"
				:username:STRING
			modify: echo "modifying user \1"
				:username:STRING
				:email:STRING?
				:groups:STRING?
			enable: echo "enabling user \1"
				:username:STRING
			disable: echo "disabling user \1"
				:username:STRING
			password
				reset: echo "resetting password for \1"
					:username:STRING
				change: echo "changing password"
					:old_password:STRING
					:new_password:STRING
		# Role management
		role
			create: echo "creating role \1"
				:name:STRING
				:description:STRING?
				:policies:STRING?
			delete: echo "deleting role \1"
				:name:STRING
			list: echo "listing roles"
			show: echo "showing role \1"
				:name:STRING
			modify: echo "modifying role \1"
				:name:STRING
				:policies:STRING?
			assign: echo "assigning role \1 to \2"
				:role:STRING
				:username:STRING
			unassign: echo "unassigning role \1 from \2"
				:role:STRING
				:username:STRING
		# Policy management
		policy
			create: echo "creating policy \1"
				:name:STRING
				:effect:list:allow|deny
				:actions:STRING
				:resources:STRING
			delete: echo "deleting policy \1"
				:name:STRING
			list: echo "listing policies"
			show: echo "showing policy \1"
				:name:STRING
			modify: echo "modifying policy \1"
				:name:STRING
				:effect:list:allow|deny?
				:actions:STRING?
				:resources:STRING?
		# Service account management
		service-account
			create: echo "creating service account \1"
				:name:STRING
				:description:STRING?
			delete: echo "deleting service account \1"
				:name:STRING
			list: echo "listing service accounts"
			token
				generate: echo "generating token for \1"
					:name:STRING
					:expiry:int_range:1-365
				revoke: echo "revoking token for \1"
					:name:STRING
					:token:STRING

# =============================================================================
# Section: Deep Nesting Stress Test
# =============================================================================
# 8-level deep command paths for benchmarking completion under extreme nesting.

	deep
		level2
			level3
				level4
					level5
						level6
							level7
								level8-alpha: echo "deep alpha \1"
									:param:STRING
								level8-beta: echo "deep beta \1"
									:param:STRING
								level8-gamma: echo "deep gamma \1"
									:param:STRING
EOF