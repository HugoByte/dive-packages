# Import the required modules
cosmos_node_service = import_module("./cosmos_chains.star")
parser = import_module("../../package_io/input_parser.star")

def start_cosmvm_chains(plan, node_name, chain_id = None, key = None, password = None, public_grpc = None, public_http = None, public_tcp = None, public_rpc = None, chain_config = {}):
    """
    Spin up a single cosmos node and return its configuration.
    
    Args:
        plan (Plan): The Kurtosis plan.
        node_name (str): Cosmos supported Chain Name.
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
    return cosmos_node_service.start_node_service(plan, node_name, chain_id, key, password, public_grpc, public_http, public_tcp, public_rpc, chain_config)

def start_ibc_between_cosmvm_chains(plan, chain_a, chain_b, src_service_config = {}, dst_service_config = {}):
    """
    Start IBC Connection between Chain A and Chain B.

    Args:
        plan (Plan): The Kurtosis plan.
        chain_a (str): The source chain for relaying.
        chain_b (str): The destination chain for relaying.
        src_service_config (dict, optional): The chain config details for source chain.
        dst_service_config (dict, optional): The chain config details for destination chain.

    Returns:
        struct: A dictionary containing the service configuration for the source and destination cosmos nodes.
    """

    if chain_a == "archway" and chain_b == "archway":
        return cosmos_node_service.start_node_services_archway(plan, src_service_config, dst_service_config)

    elif chain_a == "neutron" and chain_b == "neutron":
        return cosmos_node_service.start_node_services_neutron(plan, src_service_config, dst_service_config)

    else:
        chain_a_service = parser.struct_to_dict(cosmos_node_service.start_node_service(plan, chain_a, chain_config = src_service_config))
        chain_b_service = parser.struct_to_dict(cosmos_node_service.start_node_service(plan, chain_b, chain_config = dst_service_config))
        return struct(
            src_config = chain_a_service,
            dst_config = chain_b_service,
        )
