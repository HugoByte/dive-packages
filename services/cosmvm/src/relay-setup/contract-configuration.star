# Import the required modules and constants
cosmvm_deploy = import_module("../node-setup/deploy.star")
PASSCODE = "password"
node_constants = import_module("../../../../package_io/constants.star")
node_details = node_constants.node_details

def deploy_core(plan, chain_name, service_name, chain_id, chain_key):
    """
    Deploy the ibc-core contract on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node service.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
    
    Returns:
        str: The contract address of ibc-core.
    """
    plan.print("Deploying ibc-core contract")
    message = '{}'
    contract_addr_ibc_core = cosmvm_deploy.deploy(plan, chain_name, chain_id, chain_key, "cw_ibc_core", message, service_name)
    return contract_addr_ibc_core

def deploy_xcall(plan, chain_name, service_name, chain_id, chain_key, network_id, denom):
    """
    Deploy the xcall contract on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node service.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        network_id (str): The network ID.
        denom (str): The denomination of fees.

    Returns:
        str: The contract address of xcall.
    """
    plan.print("Deploying xcall contract")
    message = '{"network_id":"%s", "denom":"%s"}' % (network_id, denom)
    contract_addr_xcall = cosmvm_deploy.deploy(plan, chain_name, chain_id, chain_key, "cw_xcall", message, service_name)
    return contract_addr_xcall

def deploy_light_client(plan, chain_name, service_name, chain_id, chain_key, ibc_host_address):
    """
    Deploy the light client on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node service.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        ibc_host_address (str): The IBC host address.

    Returns:
        str: The contract address of the light client.
    """
    plan.print("Deploying the light client")
    message = '{"ibc_host":"%s"}' % (ibc_host_address)
    contract_addr_light_client = cosmvm_deploy.deploy(plan, chain_name, chain_id, chain_key, "cw_icon_light_client", message, service_name)
    return contract_addr_light_client

def deploy_xcall_connection(plan, chain_name, service_name, chain_id, chain_key, xcall_address, ibc_host, port_id, denom):
    """
    Deploy the xcall IBC connection contract on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node service.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        xcall_address (str): The xcall contract address.
        ibc_host (str): The IBC host address.
        port_id (str): The port ID.
        denom (str): The denomination of fees.

    Returns:
        str: The contract address of the xcall IBC connection.
    """
    plan.print("Deploying the xcall ibc connection")
    message = '{"ibc_host":"%s","port_id":"%s","xcall_address":"%s", "denom":"%s"}' % (ibc_host, port_id, xcall_address, denom)
    contract_addr_xcall_connection = cosmvm_deploy.deploy(plan, chain_name, chain_id, chain_key, "cw_xcall_ibc_connection", message, service_name)
    return contract_addr_xcall_connection

def bindPort(plan, chain_name, service_name, chain_id, chain_key, ibc_address, conn_address):
    """
    Bind a mock app to a specific port on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node service.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        ibc_address (str): The IBC contract address.
        conn_address (str): The connection address.

    Returns:
        str: The transaction hash of the binding operation.
    """
    plan.print("Binding mock app to the port")
    bindPort_cmd = node_details[chain_name]["bindPort_cmd"]
    exec_cmd = format_command(chain_name, bindPort_cmd, ibc_address, conn_address, chain_key, chain_id)
    exec = ExecRecipe(command = ["/bin/sh", "-c", exec_cmd])
    result = plan.exec(service_name = service_name, recipe = exec)
    tx_hash = result["output"]
    return tx_hash

def registerClient(plan, chain_name, service_name, chain_id, chain_key, ibc_address, client_address):
    """
    Register a client on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        ibc_address (str): The IBC contract address.
        client_address (str): The client address.

    Returns:
        str: The transaction hash of the registration operation.
    """
    plan.print("Registering the client")
    registerClient_cmd = node_details[chain_name]["registerClient_cmd"]
    exec_cmd = format_command(chain_name, registerClient_cmd, ibc_address, client_address, chain_key, chain_id)
    exec = ExecRecipe(command = ["/bin/sh", "-c", exec_cmd])

    result = plan.exec(service_name = service_name, recipe = exec)
    tx_hash = result["output"]
    return tx_hash

def deploy_xcall_dapp(plan, chain_name, service_name, chain_id, chain_key, xcall_address):
    """
    Deploy the xcall dapp on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node service.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        xcall_address (str): The xcall contract address.

    Returns:
        str: The contract address of the xcall dapp.
    """
    plan.print("Deploying the xcall dapp")
    message = '{"address":"%s"}' % (xcall_address)
    xcall_dapp_address = cosmvm_deploy.deploy(plan, chain_name, chain_id, chain_key, "cw_mock_dapp_multi", message, service_name)
    return xcall_dapp_address

def add_connection_xcall_dapp(plan, chain_name, service_name, chain_id, chain_key, xcall_dapp_address, wasm_xcall_connection_address, xcall_connection_address, java_network_id):
    """
    Configure the xcall dapp by adding a connection.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node service.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        xcall_dapp_address (str): The xcall dapp contract address.
        wasm_xcall_connection_address (str): The wasm xcall connection contract address.
        xcall_connection_address (str): The xcall connection contract address.
        java_network_id (str): The Java network ID.

    Returns:
        str: The transaction hash of the configuration operation.
    """
    plan.print("Configuring xcall dapp")
    params = '{"add_connection":{"src_endpoint":"%s","dest_endpoint":"%s","network_id":"%s"}}' % (wasm_xcall_connection_address, xcall_connection_address, java_network_id)
    
    add_connection_xcall_dapp_cmd = node_details[chain_name]["add_connection_xcall_dapp_cmd"]
    exec_cmd = format_command(chain_name, add_connection_xcall_dapp_cmd, xcall_dapp_address, params, chain_key, chain_id)
    exec = ExecRecipe(command = ["/bin/sh", "-c", exec_cmd])
    
    result = plan.exec(service_name = service_name, recipe = exec)
    tx_hash = result["output"]
    return tx_hash


def configure_xcall_connection(plan, chain_name, service_name, chain_id, chain_key, xcall_connection_address, connection_id, counterparty_port_id, counterparty_nid, client_id):
    """
    Configure an Xcall connection on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node service.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        xcall_connection_address (str): The Xcall connection contract address.
        connection_id (str): The connection ID.
        counterparty_port_id (str): The counterparty port ID.
        counterparty_nid (str): The counterparty NID.
        client_id (str): The client ID.
    """
    plan.print("Configuring Xcall Connections Connection")
    params = '{"configure_connection":{"connection_id":"%s","counterparty_port_id":"%s","counterparty_nid":"%s","client_id":"%s","timeout_height":30000}}' % (connection_id, counterparty_port_id, counterparty_nid, client_id)

    configure_xcall_connection_cmd = node_details[chain_name]["configure_xcall_connection_cmd"]
    exec_cmd = format_command(chain_name, configure_xcall_connection_cmd, xcall_connection_address, params, chain_key, chain_id)
    result = plan.exec(service_name = service_name, recipe = ExecRecipe(command = ["/bin/sh", "-c", exec_cmd]))


def set_default_connection_xcall(plan, chain_name, service_name, chain_id, chain_key, network_id, xcall_connection_address, xcall_address):
    """
    Set the default Xcall connection on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node service.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        network_id (str): The network ID.
        xcall_connection_address (str): The Xcall connection contract address.
        xcall_address (str): The Xcall contract address.
    """
    plan.print("Setting Xcall default connection")
    params = '{"set_default_connection":{"nid":"%s","address":"%s"}}' % (network_id, xcall_connection_address)
    set_default_connection_xcall_cmd = node_details[chain_name]["set_default_connection_xcall_cmd"]
    exec_cmd = format_command(chain_name, set_default_connection_xcall_cmd, xcall_address, params, chain_key, chain_id)
    result = plan.exec(service_name = service_name, recipe = ExecRecipe(command = ["/bin/sh", "-c", exec_cmd]))

def check_tx_result(plan, tx_hash, service_name):
    """
    Check the result of a transaction on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        tx_hash (str): The transaction hash to check.
        service_name (str): The name of the cosmos node service.

    Returns:
        int: The result status code of the transaction.
    """
    plan.print("Checking Tx Result")
    post_request = PostHttpRequestRecipe(
        port_id = "rpc",
        endpoint = "",
        content_type = "application/json",
        body = '{ "jsonrpc": "2.0", "method": "tx", "id": 1, "params": { "hash": %s } }' % tx_hash,
        extract = {
            "status": ".result.code",
        },
    )
    result = plan.wait(service_name = service_name, recipe = post_request, field = "extract.status", assertion = "==", target_value = 0)
    return result

def setup_contracts_for_ibc_wasm(plan, chain_name, service_name, chain_id, chain_key, network_id, denom, port_id):
    """
    Deploy contracts for IBC setup on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node service.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        network_id (str): The network ID.
        denom (str): The denomination of fees.
        port_id (str): The port ID.

    Returns:
        dict: A dictionary containing contract addresses.
    """
    plan.print("Deploying Contracts for IBC Setup")
    ibc_core_address = deploy_core(plan, chain_name, service_name, chain_id, chain_key)
    light_client_address = deploy_light_client(plan, chain_name, service_name, chain_id, chain_key, ibc_core_address)
    xcall_address = deploy_xcall(plan, chain_name, service_name, chain_id, chain_key, network_id, denom)
    xcall_connection_address = deploy_xcall_connection(plan, chain_name, service_name, chain_id, chain_key, xcall_address, ibc_core_address, port_id, denom)
    contracts = {
        "ibc_core": ibc_core_address,
        "xcall": xcall_address,
        "light_client": light_client_address,
        "xcall_connection": xcall_connection_address,
    }
    plan.print("Printing contract addresses")
    plan.print(contracts)
    return contracts

def configure_connection_for_wasm(plan, chain_name, service_name, chain_id, chain_key, xcall_connection_address, connection_id, counterparty_port_id, counterparty_nid, client_id, xcall_address):
    """
    Configure a connection for channel setup IBC on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node service.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        xcall_connection_address (str): The Xcall connection contract address.
        connection_id (str): The connection ID.
        counterparty_port_id (str): The counterparty port ID.
        counterparty_nid (str): The counterparty NID.
        client_id (str): The client ID.
        xcall_address (str): The Xcall contract address.
    """
    plan.print("Configure Connection for Channel Setup IBC")
    plan.wait(service_name, recipe = ExecRecipe(command = ["/bin/sh", "-c", "sleep 40s && echo 'success'"]), field = "code", assertion = "==", target_value = 0, timeout = "200s")
    configure_xcall_connection_result = configure_xcall_connection(plan, chain_name, service_name, chain_id, chain_key, xcall_connection_address, connection_id, counterparty_port_id, counterparty_nid, client_id)
    plan.print(configure_xcall_connection_result)
    plan.wait(service_name, recipe = ExecRecipe(command = ["/bin/sh", "-c", "sleep 40s && echo 'success'"]), field = "code", assertion = "==", target_value = 0, timeout = "200s")
    configure_xcall_result = set_default_connection_xcall(plan, chain_name, service_name, chain_id, chain_key, counterparty_nid, xcall_connection_address, xcall_address)
    plan.print(configure_xcall_result)

def deploy_and_configure_xcall_dapp(plan, chain_name, service_name, chain_id, chain_key, xcall_address, wasm_xcall_connection_address, xcall_connection_address, network_id):
    """
    Deploy and configure the Xcall dapp on a cosmos node.

    Args:
        plan (plan): The Kurtosis plan.
        chain_name (str): The name of the blockchain network.
        service_name (str): The name of the cosmos node service.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        xcall_address (str): The Xcall contract address.
        wasm_xcall_connection_address (str): The wasm Xcall connection contract address.
        xcall_connection_address (str): The Xcall connection contract address.
        network_id (str): The network ID.

    Returns:
        dict: A dictionary containing the Xcall dapp address and the result of adding a connection.
    """
    plan.print("Configure Xcall Dapp")
    xcall_dapp_address = deploy_xcall_dapp(plan, chain_name, service_name, chain_id, chain_key, xcall_address)
    add_connection_result = add_connection_xcall_dapp(plan, chain_name, service_name, chain_id, chain_key, xcall_dapp_address, wasm_xcall_connection_address, xcall_connection_address, network_id)
    result = {
        "xcall_dapp": xcall_dapp_address,
        "add_connection_result": add_connection_result,
    }
    return result

def format_command(chain_name, command, param1, param2, chain_key, chain_id):
    """
    Format the command to be executed.

    Args:
        chain_name (str): The name of the blockchain network.
        command (str): The command to be formatted.
        param1 (str): The first parameter.
        param2 (str): The second parameter.
        chain_key (str): The chain key.
        chain_id (str): The chain ID.

    Returns:
        str: The formatted command ready to be executed.
    """
    if chain_name == "archway":
        exec_cmd = command.format(PASSCODE, param1, param2, chain_key, chain_id)
    elif chain_name == "neutron":
        exec_cmd = command.format(PASSCODE, param1, param2, chain_key, chain_id, chain_id)
    
    return exec_cmd