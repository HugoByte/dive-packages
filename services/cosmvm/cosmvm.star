# Import the required modules
cosmos_node_service = import_module("./cosmos_chains.star")
parser = import_module("../../package_io/input_parser.star")

def start_cosmvm_chains(plan, node_name, chain_id = None, key = None, password = None, public_grpc = None, public_http = None, public_tcp = None, public_rpc = None):
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

    Returns:
       struct: The response from starting the cosmos node service.
    """
    return cosmos_node_service.start_node_service(plan, node_name, chain_id, key, password, public_grpc, public_http, public_tcp, public_rpc)

def start_ibc_between_cosmvm_chains(plan, chain_a, chain_b):
    """
    Start IBC Connection between Chain A and Chain B.

    Args:
        plan (Plan): The Kurtosis plan.
        chain_a (str): The source chain for relaying.
        chain_b (str): The destination chain for relaying.

    Returns:
        struct: A dictionary containing the service configuration for the source and destination cosmos nodes.
    """

    if chain_a == "archway" and chain_b == "archway":
        return cosmos_node_service.start_node_services_archway(plan)

    elif chain_a == "neutron" and chain_b == "neutron":
        return cosmos_node_service.start_node_services_neutron(plan)

    else:
        chain_a_service = parser.struct_to_dict(cosmos_node_service.start_node_service(plan, chain_a))
        chain_b_service = parser.struct_to_dict(cosmos_node_service.start_node_service(plan, chain_b))
        return struct(
            src_config = chain_a_service,
            dst_config = chain_b_service,
        )
