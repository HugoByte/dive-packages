# Import the required modules and constants
cosmos_node_service = import_module("./src/node-setup/start_node.star")
parser = import_module("../../package_io/input_parser.star")
constants = import_module("../../package_io/constants.star")
node_details = constants.node_details

# Archway node configurations
archway_node0_config = constants.ARCHAY_NODE0_CONFIG
archway_node1_config = constants.ARCHAY_NODE1_CONFIG
archway_service_config = constants.ARCHWAY_SERVICE_CONFIG
archway_private_ports = constants.COMMON_ARCHWAY_PRIVATE_PORTS

# Neutron node configurations
neutron_node1_config = constants.NEUTRON_NODE1_CONFIG
neutron_node2_config = constants.NEUTRON_NODE2_CONFIG
neutron_service_config = constants.NEUTRON_SERVICE_CONFIG
neutron_private_ports = constants.NEUTRON_PRIVATE_PORTS

def start_node_service(plan, chain_name, chain_id = None, key = None, password = None, public_grpc = None, public_http = None, public_tcp = None, public_rpc = None, chain_config = {}):
    """
    Spin up a single cosmos node and return its configuration.

    Args:
        plan (Plan): The Kurtosis plan.
        chain_name (str): Cosmos supported Chain Name.
        chain_id (str, optional): Chain Id of the chain to be started. Defaults to None.
        key (str, optional):  Key used for creating account. Defaults to None.
        password (str, optional): Password for Key. Defaults to None.
        public_grpc (int, optional): GRPC Endpoint for chain to run. Defaults to None.
        public_http (int, optional): HTTP Endpoint for chain to run. Defaults to None.
        public_tcp (int, optional): TCP Endpoint for chain to run. Defaults to None.
        public_rpc (int, optional): RPC Endpoint for chain to run. Defaults to None.
        chain_config (dict, optional): The chain config details for the chain.

    Returns:
        struct: The response from starting the cosmos node service.
    """

    default_service_config = node_details[chain_name]["service_config"]
    service_config = get_service_config(default_service_config, chain_config)
    cosmos_service_config = node_details[chain_name]["cosmos_service_config"]
    password = node_details[chain_name]["password"]
    private_ports = node_details[chain_name]["private_ports"]

    chain_id = chain_id if chain_id != None else service_config.chain_id
    key = key if key != None else service_config.key
    public_http = public_http if public_http != None else service_config.http
    public_rpc = public_rpc if public_rpc != None else service_config.rpc
    public_tcp = public_tcp if public_tcp != None else service_config.tcp
    public_grpc = public_grpc if public_grpc != None else service_config.grpc
    service_name = "{0}-{1}".format(cosmos_service_config.service_name, chain_id)

    return cosmos_node_service.start_cosmos_node(
        plan,
        chain_name,
        chain_id,
        key,
        password,
        service_name,
        private_ports.grpc,
        private_ports.http,
        private_ports.tcp,
        private_ports.rpc,
        public_grpc,
        public_http,
        public_tcp,
        public_rpc,
    )

def start_node_services_neutron(plan, src_service_config = {}, dst_service_config = {}):
    """
    Configure and start two Neutron node services, serving as the source and destination to establish an IBC relay connection between them.

    Args:
        plan (Plan): The Kurtosis plan.
        src_service_config (dict, optional): The chain config details for source chain.
        dst_service_config (dict, optional): The chain config details for destination chain.

    Returns:
        struct: Configuration information for the source and destination services.
    """
    chain_name = "neutron"
    node1_password = neutron_node1_config.password
    node2_password = neutron_node2_config.password
 
    node1_service_config = get_service_config(neutron_node1_config, src_service_config)
    node2_service_config = get_service_config(neutron_node2_config, dst_service_config)

    # Start the source and destination Neutron node services
    service_name_src = "{0}-{1}".format(neutron_service_config.service_name, node1_service_config.chain_id)
    service_name_dst = "{0}-{1}".format(neutron_service_config.service_name, node2_service_config.chain_id)
    src_chain_response = cosmos_node_service.start_cosmos_node(
        plan, 
        chain_name, 
        node1_service_config.chain_id, 
        node1_service_config.key, 
        node1_password, 
        service_name_src, 
        neutron_private_ports.grpc,
        neutron_private_ports.http,
        neutron_private_ports.tcp,
        neutron_private_ports.rpc,
        node1_service_config.grpc, 
        node1_service_config.http,
        node1_service_config.tcp, 
        node1_service_config.rpc
    )
    dst_chain_response = cosmos_node_service.start_cosmos_node(
        plan, 
        chain_name, 
        node2_service_config.chain_id, 
        node2_service_config.key,
        node2_password, 
        service_name_dst, 
        neutron_private_ports.grpc,
        neutron_private_ports.http,
        neutron_private_ports.tcp,
        neutron_private_ports.rpc,
        node2_service_config.grpc, 
        node2_service_config.http, 
        node2_service_config.tcp, 
        node2_service_config.rpc
    )

    # Create configuration dictionaries for both services
    src_service_config = {
        "service_name": src_chain_response.service_name,
        "endpoint": src_chain_response.endpoint,
        "endpoint_public": src_chain_response.endpoint_public,
        "chain_id": src_chain_response.chain_id,
        "chain_key": src_chain_response.chain_key,
    }

    dst_service_config = {
        "service_name": dst_chain_response.service_name,
        "endpoint": dst_chain_response.endpoint,
        "endpoint_public": dst_chain_response.endpoint_public,
        "chain_id": dst_chain_response.chain_id,
        "chain_key": dst_chain_response.chain_key,
    }

    return struct(
        src_config = src_service_config,
        dst_config = dst_service_config,
    )

def start_node_services_archway(plan, src_service_config = {}, dst_service_config = {}):
    """
    Configure and start two Neutron node services, serving as the source and destination to establish an IBC relay connection between them.

    Args:
        plan (Plan): The Kurtosis plan.
        src_service_config (dict, optional): The chain config details for source chain.
        dst_service_config (dict, optional): The chain config details for destination chain.

    Returns:
        struct: Configuration information for the source and destination services.
    """
    chain_name = "archway"
    node1_service_config = get_service_config(archway_node0_config, src_service_config)
    node2_service_config = get_service_config(archway_node1_config, dst_service_config)
 
    service_name_src = "{0}-{1}".format(archway_service_config.service_name, node1_service_config.chain_id)
    service_name_dst = "{0}-{1}".format(archway_service_config.service_name, node2_service_config.chain_id)

    src_config = parser.struct_to_dict(cosmos_node_service.start_cosmos_node(
        plan,
        chain_name,
        node1_service_config.chain_id,
        node1_service_config.key,
        archway_service_config.password,
        service_name_src,
        archway_private_ports.grpc,
        archway_private_ports.http,
        archway_private_ports.tcp,
        archway_private_ports.rpc,
        node1_service_config.grpc, 
        node1_service_config.http,
        node1_service_config.tcp, 
        node1_service_config.rpc
    ))

    dst_config = parser.struct_to_dict(cosmos_node_service.start_cosmos_node(
        plan,
        chain_name,
        node2_service_config.chain_id,
        node2_service_config.key,
        archway_service_config.password,
        service_name_dst,
        archway_private_ports.grpc,
        archway_private_ports.http,
        archway_private_ports.tcp,
        archway_private_ports.rpc,
        node2_service_config.grpc, 
        node2_service_config.http, 
        node2_service_config.tcp, 
        node2_service_config.rpc
    ))

    return struct(
        src_config = src_config,
        dst_config = dst_config,
    )

def get_service_config(default_service_config, chain_config):
    if len(chain_config) != 0:
        service_config = struct(
            chain_id = default_service_config.chain_id,
            grpc = chain_config.get("public_grpc", default_service_config.grpc),
            http = chain_config.get("public_http", default_service_config.http),
            tcp = chain_config.get("public_tcp", default_service_config.tcp),
            rpc = chain_config.get("public_rpc", default_service_config.rpc),
            key = default_service_config.key,
        )
    else:
        service_config = default_service_config

    return service_config
