# Import the required modules 
eth_node = import_module("./src/node-setup/start-eth-node.star")
eth_relay_setup = import_module("./src/relay-setup/contract_configuration.star")

def start_eth_node_service(plan, node_type, public_port = None):
    """
    Function to start an Ethereum node service.

    Args:
        plan (Plan): The Kurtosis plan.
        node_type (str): The name of EVM supported chain.
        public_port (int, optional): The public port to start the chain node.

    Returns:
        dict: A dictionary containing configuration data for the started Ethereum node service.
    """
    node_service_data = eth_node.start_node_service(plan, node_type, public_port)

    config_data = {
        "service_name": node_service_data.service_name,
        "nid": node_service_data.nid,
        "network": node_service_data.network,
        "network_name": node_service_data.network_name,
        "endpoint": node_service_data.endpoint,
        "endpoint_public": node_service_data.endpoint_public,
        "keystore_path": node_service_data.keystore_path,
        "keypassword": node_service_data.keypassword
    }

    return config_data

def deploy_bmv_eth(plan, bridge, data, network, network_name, chain_name):
    """
    Function to deploy a BMV Ethereum contract.
    
    Args:
        plan (Plan): The Kurtosis plan.
        bridge (bool): BMV bridge if true or false.
        data (struct): A dictionary containing chain data.
        network (str): The chain network.
        network_name (str): The chain network name.
        chain_name (str): The name of EVM supported chain.

    Returns:
        str: The address of the deployed contract.
    """
    if bridge == "true":
        address = eth_relay_setup.deploy_bmv_bridge(plan, data.block_height, data.bmc, data.network, chain_name, network, network_name)
        return address

    else :
        address = eth_relay_setup.deploy_bmv(plan ,data.block_header, data.bmc, data.network, data.network_type_id, chain_name, network, network_name)
        return address


