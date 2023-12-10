# Import the required modules and constants
constants = import_module("../../../../package_io/constants.star")
network_port_keys_and_ip = constants.NETWORK_PORT_KEYS_AND_IP_ADDRESS

def start_cosmos_node(plan, chain_name, chain_id, key, password, service_name, private_grpc, private_http, private_tcp, private_rpc, public_grpc, public_http, public_tcp, public_rpc):
    """
    Configure and start a Cosmos node.

    Args:
        plan (Plan): The Kurtosis plan.
        chain_name (str): Cosmos supported Chain Name.
        chain_id (str): Chain Id of the chain to be started.
        key (str): Key used for creating account.
        password (str): Password for Key.
        service_name (str): Name of the service.
        private_grpc (int): Private gRPC port.
        private_http (int): Private HTTP port.
        private_tcp (int): Private TCP port.
        private_rpc (int): Private RPC port.
        public_grpc (int): Public gRPC port.
        public_http (int): Public HTTP port.
        public_tcp (int): Public TCP port.
        public_rpc (int): Public RPC port.

    Returns:
        struct: Configuration information for the service.
    """
     
    plan.print("Launching " + service_name + " deployment service")
    node_config = constants.node_details[chain_name]
    chain_node_constants = node_config["node_constants"]
    command = format_command(chain_name, chain_node_constants.path, node_config["start_node_cmd"], chain_id, key, password)

    plan.upload_files(src = "../../static_files/scripts", name = "script_files_%s" % (service_name))
    plan.upload_files(src = "../../static_files/contracts", name = "contract_files_%s" % (service_name))

    chain_node_config = ServiceConfig(
        image = chain_node_constants.image,
        files = {
            chain_node_constants.contract_path: "contract_files_%s" % (service_name),
            chain_node_constants.path: "script_files_%s" % (service_name),
        },
        ports = {
            network_port_keys_and_ip.grpc: PortSpec(number = private_grpc, transport_protocol = network_port_keys_and_ip.tcp.upper(), application_protocol = network_port_keys_and_ip.http),
            network_port_keys_and_ip.http: PortSpec(number = private_http, transport_protocol = network_port_keys_and_ip.tcp.upper(), application_protocol = network_port_keys_and_ip.http),
            network_port_keys_and_ip.tcp: PortSpec(number = private_tcp, transport_protocol = network_port_keys_and_ip.tcp.upper(), application_protocol = network_port_keys_and_ip.http),
            network_port_keys_and_ip.rpc: PortSpec(number = private_rpc, transport_protocol = network_port_keys_and_ip.tcp.upper(), application_protocol = network_port_keys_and_ip.http),
        },
        public_ports = {
            network_port_keys_and_ip.grpc: PortSpec(number = public_grpc, transport_protocol = network_port_keys_and_ip.tcp.upper(), application_protocol = network_port_keys_and_ip.http),
            network_port_keys_and_ip.http: PortSpec(number = public_http, transport_protocol = network_port_keys_and_ip.tcp.upper(), application_protocol = network_port_keys_and_ip.http),
            network_port_keys_and_ip.tcp: PortSpec(number = public_tcp, transport_protocol = network_port_keys_and_ip.tcp.upper(), application_protocol = network_port_keys_and_ip.http),
            network_port_keys_and_ip.rpc: PortSpec(number = public_rpc, transport_protocol = network_port_keys_and_ip.tcp.upper(), application_protocol = network_port_keys_and_ip.http),
        },
        entrypoint = ["/bin/sh", "-c"], 
        cmd = [command],
        env_vars = {
            "RUN_BACKGROUND": "0",
        },
    )

    # Add the service to the plan
    node_service_response = plan.add_service(name = service_name, config = chain_node_config)
    plan.print(node_service_response)

    # Get public and private url, (private IP returned by kurtosis service)
    public_url = get_service_url(network_port_keys_and_ip.public_ip_address, chain_node_config.public_ports)
    private_url = get_service_url(node_service_response.ip_address, node_service_response.ports)

    #return service name and endpoints
    return struct(
        service_name = service_name,
        endpoint = private_url,
        endpoint_public = public_url,
        chain_id = chain_id,
        chain_key = key,
    )

def get_service_url(ip_address, ports):
    """
    Get the service URL based on IP address and ports.

    Args:
        ip_address (str): IP address of the service.
        ports (dict): Dictionary of service ports.

    Returns:
        str: The constructed service URL.
    """
    port_id = ports[network_port_keys_and_ip.rpc].number
    protocol = ports[network_port_keys_and_ip.rpc].application_protocol
    url = "{0}://{1}:{2}".format(protocol, ip_address, port_id)
    return url

def format_command(chain_name, path, command, chain_id, key, password):
    """
    Format the command to be executed.

    Args:
        chain_name (str): Cosmos supported Chain Name.
        path (str): The file path. 
        command (str): The command to be formatted.
        chain_id (str): Chain Id of the chain to be started.
        key (str): Key used for creating account.
        password (str): Password for Key.

    Returns:
        str: The formatted command ready to be executed.
    """
    if chain_name == "archway":
        new_cmd = command.format(path, chain_id, key, password)
    elif chain_name == "neutron":
        new_cmd = command.format(path, path, path, key, password, chain_id, path, chain_id, path, chain_id, path)

    return new_cmd
