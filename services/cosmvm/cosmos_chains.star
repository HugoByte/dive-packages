# Import required modules and constants
cosmos_node_service = import_module("./src/node-setup/start_node.star")
parser = import_module("../../package_io/input_parser.star")
constants = import_module("../../package_io/constants.star")

archway_node0_config = constants.ARCHAY_NODE0_CONFIG
archway_node1_config = constants.ARCHAY_NODE1_CONFIG
archway_service_config = constants.ARCHWAY_SERVICE_CONFIG
archway_private_ports = constants.COMMON_ARCHWAY_PRIVATE_PORTS

neutron_node1_config = constants.NEUTRON_NODE1_CONFIG
neutron_node2_config = constants.NEUTRON_NODE2_CONFIG
neutron_service_config = constants.NEUTRON_SERVICE_CONFIG
neutron_private_ports = constants.NEUTRON_PRIVATE_PORTS

def start_node_service(plan, chain_name, chain_id = None, key = None, password = None, public_grpc = None, public_http = None, public_tcp = None, public_rpc = None):
    
    if chain_name == "archway":
        service_config = archway_node0_config
        cosmos_service_config = archway_service_config
        password = password if password != None else cosmos_service_config.password
        private_ports = archway_private_ports

    else:
        service_config = neutron_node1_config
        cosmos_service_config = neutron_service_config
        password = password if password != None else service_config.password
        private_ports = neutron_private_ports

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

def start_node_services_neutron(plan):
    """
    Configure and start two Neutron node services, serving as the source and destination to establish an IBC relay connection between them.

    Args:
        plan (plan): plan.

    Returns:
        struct: Configuration information for the source and destination services.
    """
    chain_name = "neutron"
    # Start the source and destination Neutron node services
    service_name_src = "{0}-{1}".format(neutron_service_config.service_name, neutron_node1_config.chain_id)
    service_name_dst = "{0}-{1}".format(neutron_service_config.service_name, neutron_node2_config.chain_id)
    src_chain_response = cosmos_node_service.start_cosmos_node(plan, chain_name, neutron_node1_config.chain_id, neutron_node1_config.key, neutron_node1_config.password, service_name_src, neutron_private_ports.http, neutron_private_ports.rpc, neutron_private_ports.tcp, neutron_private_ports.grpc, neutron_node1_config.http, neutron_node1_config.rpc, neutron_node1_config.tcp, neutron_node1_config.grpc)
    dst_chain_response = cosmos_node_service.start_cosmos_node(plan, chain_name, neutron_node2_config.chain_id, neutron_node2_config.key, neutron_node2_config.password, service_name_dst, neutron_private_ports.http, neutron_private_ports.rpc, neutron_private_ports.tcp, neutron_private_ports.grpc, neutron_node2_config.http, neutron_node2_config.rpc, neutron_node2_config.tcp, neutron_node2_config.grpc)

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

def start_node_services_archway(plan):
    """
    Configure and start two Cosmos nodes for Archway.

    Args:
        plan (plan): plan.

    Returns:
        struct: Configuration information for source and destination services.
    """
    chain_name = "archway"
    service_name_src = "{0}-{1}".format(archway_service_config.service_name, archway_node0_config.chain_id)
    service_name_dst = "{0}-{1}".format(archway_service_config.service_name, archway_node1_config.chain_id)

    src_config = parser.struct_to_dict(cosmos_node_service.start_cosmos_node(
        plan,
        chain_name,
        archway_node0_config.chain_id,
        archway_node0_config.key,
        archway_service_config.password,
        service_name_src,
        archway_private_ports.grpc,
        archway_private_ports.http,
        archway_private_ports.tcp,
        archway_private_ports.rpc,
        archway_node0_config.grpc,
        archway_node0_config.http,
        archway_node0_config.tcp,
        archway_node0_config.rpc,
    ))

    dst_config = parser.struct_to_dict(cosmos_node_service.start_cosmos_node(
        plan,
        chain_name,
        archway_node1_config.chain_id,
        archway_node1_config.key,
        archway_service_config.password,
        service_name_dst,
        archway_private_ports.grpc,
        archway_private_ports.http,
        archway_private_ports.tcp,
        archway_private_ports.rpc,
        archway_node1_config.grpc,
        archway_node1_config.http,
        archway_node1_config.tcp,
        archway_node1_config.rpc,
    ))

    return struct(
        src_config = src_config,
        dst_config = dst_config,
    )