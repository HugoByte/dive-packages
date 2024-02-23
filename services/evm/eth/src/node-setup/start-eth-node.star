# Import the required modules and constants
constants = import_module("../../../../../package_io/constants.star")
participant_network = import_module("github.com/kurtosis-tech/ethereum-package/src/participant_network.star")
input_parser = import_module("github.com/kurtosis-tech/ethereum-package/src/package_io/input_parser.star")
network_keys_and_public_address = constants.NETWORK_PORT_KEYS_AND_IP_ADDRESS

def start_eth_node(plan):
    """
    Function to start an Ethereum node.

    Args:
        plan (Plan): The Kurtosis plan.

    Returns:
        dict: A dictionary containing configuration data for the started Ethereum node.
    """
    
    
    jwt_file = upload_jwt(plan)
    eth_constants = constants.ETH_NODE_CLIENT
    args_with_right_defaults = input_parser.input_parser(plan, {})
    num_participants = len(args_with_right_defaults.participants)
    network_params = args_with_right_defaults.network_params
    persistent = args_with_right_defaults.persistent
    xatu_sentry_params = args_with_right_defaults.xatu_sentry_params
    parallel_keystore_generation = args_with_right_defaults.parallel_keystore_generation
    global_tolerations = args_with_right_defaults.global_tolerations
    global_node_selectors = args_with_right_defaults.global_node_selectors

    all_participants, cl_genesis_timestamp, _, _ = participant_network.launch_participant_network(
        plan, 
        args_with_right_defaults.participants,
        network_params, 
        args_with_right_defaults.global_client_log_level,
        jwt_file, 
        persistent, 
        xatu_sentry_params, 
        global_tolerations, 
        global_node_selectors, 
        parallel_keystore_generation
    )

    network_address = get_network_address(all_participants[0].el_client_context.ip_addr, all_participants[0].el_client_context.rpc_port_num)

    return struct(
        service_name = all_participants[0].el_client_context.service_name,
        network_name = eth_constants.network_name,
        network = eth_constants.network,
        nid = eth_constants.nid,
        endpoint = "http://%s" % network_address,
        endpoint_public = "http://",
        keystore_path = eth_constants.keystore_path,
        keypassword = eth_constants.keypassword
    )

def get_network_address(ip_addr, rpc_port):
    """
    Function to return the network address.  

    Args:
        ip_addr (str): The IP address.
        rpc_port (int): The RPC port.

    Returns:
        str: The network address as a string.
    """
    return '{0}:{1}'.format(ip_addr, rpc_port)

def start_node_service(plan, node_type, public_port = None):
    """
    Function to start a node service.

    Args:
        plan (Plan): The Kurtosis plan.
        node_type (str): The type of node to start (e.g., "eth" or "hardhat").
        public_port (int, optional): The public port to start the chain node.

    Returns:
        dict: Configuration data for the started node service as a dictionary.
    """
    if node_type == "eth":
        return start_eth_node(plan)
    else:
        return start_hardhat_node(plan, public_port)

def start_hardhat_node(plan, public_port = None):
    """
    Function to start a Hardhat Ethereum node.

    Args:
        plan (Plan): The Kurtosis plan.
        public_port (int, optional): The public port to start the chain node.

    Returns:
        dict: Configuration data for the started Hardhat node service as a dictionary.
    """
    plan.print("Starting Hardhat Node")

    hardhat_constants = constants.HARDHAT_NODE_CLIENT
    public_port = public_port if public_port != None else hardhat_constants.port

    plan.upload_files(src = hardhat_constants.config_files_path, name = "hardhat-config")

    service_config = ServiceConfig(
        image = hardhat_constants.node_image,
        ports = {
            network_keys_and_public_address.rpc : PortSpec(number = hardhat_constants.port, transport_protocol = network_keys_and_public_address.tcp.upper(), application_protocol = network_keys_and_public_address.http)
        },
        public_ports = {
            network_keys_and_public_address.rpc : PortSpec(number = public_port, transport_protocol = network_keys_and_public_address.tcp.upper(), application_protocol = network_keys_and_public_address.http)
        },
        files = {
            hardhat_constants.config_files_directory : "hardhat-config"
        },
        entrypoint = ["/bin/sh", "-c", "mkdir -p /app && cd app && npm install hardhat && /app/node_modules/.bin/hardhat --config ../config/hardhat.config.js node 2>&1 | tee /app/logs/hardhat.log"]
    )

    response = plan.add_service(name = hardhat_constants.service_name, config = service_config)

    private_url = get_network_address(response.ip_address, hardhat_constants.port)
    public_url = get_network_address(network_keys_and_public_address.public_ip_address, public_port)
    
    return struct(
        service_name = hardhat_constants.service_name,
        network_name = "hardhat",
        network = hardhat_constants.network,
        nid = hardhat_constants.network_id,
        endpoint = "http://%s" % private_url,
        endpoint_public = "http://%s" % public_url,
        keystore_path = hardhat_constants.keystore_path,
        keypassword = hardhat_constants.keypassword
    )

def upload_jwt(plan):
    jwt_file = plan.upload_files(
        src="../../static-files/jwt/jwtsecret",
        name="jwt_file",
    )

    return jwt_file