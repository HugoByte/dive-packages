# Import the required modules 
contract_deployment_service = import_module("../node-setup/contract_deploy.star")
node_service = import_module("../node-setup/setup_icon_node.star")

def deploy_bmc(plan, network, service_name, uri, keystore_path, keystore_password, nid):
    """
    Deploys BMC contract on ICON 

    Args:
        plan (Plan): The Kurtosis plan.
        network (str): The chain's network.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        str: The address of the deployed BMC contract.
    """
    plan.print("Deploying BMC Contract")
    init_message = '{"_net":"%s"}' % network

    tx_hash = contract_deployment_service.deploy_contract(plan, "bmc", init_message, service_name, uri, keystore_path, keystore_password, nid)

    service_name = service_name
    score_address = contract_deployment_service.get_score_address(plan, service_name, tx_hash)
    
    return score_address

def deploy_xcall(plan, bmc_address, service_name, uri, keystore_path, keystore_password, nid):
    """
    Deploys xCall on ICON

    Args:
        plan (Plan): The Kurtosis plan.
        bmc_address (str): The address of the deployed BMC contract.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        str: The address of the deployed XCall contract.
    """
    plan.print("Deploying xCall Contract")
    init_message = '{"_bmc":"%s"}' % bmc_address

    tx_hash = contract_deployment_service.deploy_contract(plan, "xcall", init_message, service_name, uri, keystore_path, keystore_password, nid)

    score_address = contract_deployment_service.get_score_address(plan, service_name, tx_hash)
    add_service(plan, bmc_address, score_address, service_name, uri, keystore_path, keystore_password, nid)
    
    return score_address   

def add_service(plan, bmc_address, xcall_address, service_name, uri, keystore_path, keystore_password, nid):
    """
    Adds services to BMC contract on ICON

    Args:
        plan (Plan): The Kurtosis plan.
        bmc_address (str): The address of the deployed BMC contract.
        xcall_address (str): The address of the deployed XCall contract.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.
    """
    plan.print("Adding xcall  to Bmc %s " % bmc_address)
    method = "addService"
    params = '{"_svc":"xcall","_addr":"%s"}' % xcall_address

    exec_command = ["./bin/goloop", "rpc", "sendtx", "call", "--to", bmc_address, "--method", method, "--params", params, "--uri", uri, "--key_store", keystore_path, "--key_password", keystore_password, "--step_limit", "50000000000", "--nid", nid]
    result = plan.exec(service_name = service_name, recipe = ExecRecipe(command = exec_command))

    tx_hash = result["output"].replace('"',"")
    tx_result = node_service.get_tx_result(plan, service_name, tx_hash, uri)
    plan.verify(value = tx_result["extract.status"], assertion = "==", target_value = "0x1")

def open_btp_network(plan, service_name, src, dst, bmc_address, uri, keystorepath, keypassword, nid):
    """
    Opens BTP Network on ICON

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the chain's service.
        src (str): The name of the source chain.
        dst (str): The name of the destination chain.
        bmc_address (str): The address of the deployed BMC contract.
        uri (str): The URI for the chain.
        keystorepath (str): The path to the keystore file for the chain.
        keypassword (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        dict: The service details of BTP network on ICON.
    """
    plan.print("Opening BTP Network")
    last_block_height = node_service.get_last_block(plan, service_name)
    network_name = "{0}-{1}".format(dst, last_block_height)

    args = {"name":network_name,"owner":bmc_address}
    result = node_service.open_btp_network(plan, service_name, args, uri, keystorepath, keypassword, nid)
    
    return result

def deploy_bmv_btpblock_java(plan, bmc_address, dst_network_id, dst_network_type_id, first_block_header, service_name, uri, keystore_path, keystore_password, nid):
    """
    Deploys BMV BTPBLOCK on ICON

    Args:
        plan (Plan): The Kurtosis plan.
        bmc_address (str): The address of the deployed BMC contract.
        dst_network_id (str): The network ID of destination chain.
        dst_network_type_id (str): The network type ID of destination chain.
        first_block_header (str): The first block header of the chain.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        str: The address of the deployed BMV BTP block on ICON.
    """
    init_message = '{"bmc": "%s","srcNetworkID": "%s","networkTypeID": "%s", "blockHeader": "0x%s","seqOffset": "0x0"}' % (bmc_address, dst_network_id, dst_network_type_id, first_block_header)

    tx_hash = contract_deployment_service.deploy_contract(plan,"bmv-btpblock",init_message, service_name, uri, keystore_path, keystore_password, nid)
    score_address = contract_deployment_service.get_score_address(plan, service_name, tx_hash)
    plan.print("BMV-BTPBlock: deployed")
    
    return score_address

def deploy_bmv_bridge_java(plan, service_name, bmc_address, dst_network, offset, uri, keystore_path, keystore_password, nid):
    """
    Deploys BMV BRIDGE on ICON

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the chain's service.
        bmc_address (str): The address of the deployed BMC contract.
        dst_network (str): The destination chain's network.
        offset (str): The offset for the chain.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        str: The address of the deployed BMV bridge on ICON.
    """
    init_message = '{"_bmc": "%s","_net": "%s","_offset": "%s"}' %(bmc_address, dst_network, offset)
    tx_hash = contract_deployment_service.deploy_contract(plan, "bmv-bridge", init_message, service_name, uri, keystore_path, keystore_password, nid)

    score_address = contract_deployment_service.get_score_address(plan, service_name, tx_hash)
    plan.print("BMV-BTPBlock: deployed ")
    
    return score_address

def add_verifier(plan, service_name, bmc_address, dst_chain_network, bmv_address, uri, keystorepath, keypassword, nid):
    """
    Adds Verifier to BMC contract on ICON

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the chain's service.
        bmc_address (str): The address of the deployed BMC contract.
        dst_chain_network (str): The destination chain's network.
        bmv_address (str): The address of the deployed BMV contract.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        dict: The service details of verifier added to BMC contract on ICON.
    """
    method = "addVerifier"
    params = '{"_net":"%s","_addr":"%s"}' % (dst_chain_network, bmv_address)

    exec_command = ["./bin/goloop", "rpc", "sendtx", "call", "--to", bmc_address, "--method", method, "--params", params, "--uri", uri, "--key_store", keystorepath, "--key_password", keypassword, "--step_limit", "50000000000", "--nid", nid]
    result = plan.exec(service_name = service_name, recipe = ExecRecipe(command = exec_command))

    tx_hash = result["output"].replace('"',"")
    tx_result = node_service.get_tx_result(plan,service_name,tx_hash,uri)
    plan.verify(value = tx_result["extract.status"], assertion = "==", target_value = "0x1")
    
    return tx_result

def add_btp_link(plan, service_name, bmc_address, dst_bmc_address, src_network_id, uri, keystorepath, keypassword, nid):
    """
    Adds BTP Link to BMC contract on ICON
    
    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the chain's service.
        bmc_address (str): The address of the deployed BMC contract.
        dst_bmc_address (str): The BMC address of destination chain.
        src_network_id (str): The source chain's network.
        uri (str): The URI for the chain.
        keystorepath (str): The path to the keystore file for the chain.
        keypassword (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        dict: The service details of BTP link added to BMC contract on ICON.
    """
    method = "addBTPLink"
    params = '{"_link":"%s","_networkId":"%s"}' %(dst_bmc_address, src_network_id)

    exec_command = ["./bin/goloop", "rpc", "sendtx", "call", "--to", bmc_address, "--method", method, "--params", params, "--uri", uri, "--key_store", keystorepath, "--key_password", keypassword, "--step_limit", "50000000000", "--nid", nid]
    result = plan.exec(service_name = service_name, recipe = ExecRecipe(command = exec_command))

    tx_hash = result["output"].replace('"',"")
    tx_result = node_service.get_tx_result(plan, service_name, tx_hash,uri)
    plan.verify(value = tx_result["extract.status"], assertion = "==", target_value = "0x1")

    return tx_result

def add_relay(plan, service_name, bmc_address, dst_bmc_address, relay_address, uri, keystorepath, keypassword, nid):
    """
    Adds Relay Address to BMC contract on ICON

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the chain's service.
        bmc_address (str): The address of the deployed BMC contract.
        dst_bmc_address (str): The BMC address of destination chain.
        relay_address (str): The relay address.
        uri (str): The URI for the chain.
        keystorepath (str): The path to the keystore file for the chain.
        keypassword (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        dict: The service details of Relay Address added to BMC contract on ICON.
    """

    method = "addRelay"
    params = '{"_link":"%s","_addr":"%s"}' % (dst_bmc_address, relay_address)

    exec_command = ["./bin/goloop", "rpc", "sendtx", "call", "--to", bmc_address, "--method", method, "--params", params, "--uri", uri, "--key_store", keystorepath, "--key_password", keypassword, "--step_limit", "500000000000", "--nid", nid]
    result = plan.exec(service_name = service_name, recipe = ExecRecipe(command = exec_command))

    tx_hash = result["output"].replace('"',"")
    tx_result = node_service.get_tx_result(plan, service_name, tx_hash,uri)
    plan.verify(value = tx_result["extract.status"],assertion = "==",target_value = "0x1")
    
    return tx_result

def setup_link_icon(plan, service_name, bmc_address, dst_chain_network, dst_chain_bmc_address, src_chain_network_id, bmv_address, relay_address, uri, keystore_path, keypassword, nid):
    """
    Configures Link in BMC on ICON

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the chain's service.
        bmc_address (str): The address of the deployed BMC contract.
        dst_chain_network (str): The destination chain's network.
        dst_chain_bmc_address (str): The BMC address of destination chain.
        src_chain_network_id (str): The network ID of source chain.
        bmv_address (str): The address of the deployed BMV contract.
        relay_address (str): The relay address.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keypassword (str): The password for the keystore.
        nid (str): The Network ID for the chain.
    """
    dst_bmc_address = get_btp_address(dst_chain_network, dst_chain_bmc_address)
    add_verifier(plan, service_name, bmc_address, dst_chain_network, bmv_address, uri, keystore_path, keypassword, nid)
    add_btp_link(plan, service_name, bmc_address, dst_bmc_address, src_chain_network_id, uri,keystore_path, keypassword, nid)
    add_relay(plan, service_name, bmc_address, dst_bmc_address, relay_address, uri, keystore_path, keypassword, nid)
    plan.print("Icon Link Setup Completed")

def get_btp_address(network, dapp):
    """
    Returns BTP address

    Args:
        network (str): The chain's network.
        dapp (str):  The BMC address of the chain.

    Returns:
        str: The BTP address of the chain.
    """
    return "btp://{0}/{1}".format(network,dapp)

def deploy_dapp(plan, xcall_address, service_name, uri, keystore_path, keystore_password, nid):
    """
    Deploys dAPP on ICON

    Args:
        plan (Plan): The Kurtosis plan.
        xcall_address (str): The address of the deployed XCall contract.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        str: The address of the dapp contract deployed on ICON.
    """
    plan.print("Deploying dapp Contract")
    init_message = '{"_callService":"%s"}' % xcall_address

    tx_hash = contract_deployment_service.deploy_contract(plan, "dapp-sample", init_message, service_name, uri, keystore_path, keystore_password, nid)
    score_address = contract_deployment_service.get_score_address(plan, service_name, tx_hash)
    
    return score_address   

def deploy_ibc_handler(plan, service_name, uri, keystore_path, keystore_password, nid):
    """
    Deploy ibc handler contract on ICON
    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        str: The address of ibc handler contract deployed on ICON.
    """
    plan.print("IBC handler")
    init_message = '{}' 

    tx_hash = contract_deployment_service.deploy_contract(plan, "ibc-0.1.0-optimized", init_message, service_name, uri, keystore_path, keystore_password, nid)
    plan.print(tx_hash)
    
    score_address = contract_deployment_service.get_score_address(plan, service_name, tx_hash)
    plan.print("deployed ibc handler")

    return score_address

def deploy_light_client_for_icon(plan, service_name, uri, keystore_path, keystore_password, nid, ibc_handler_address):
    """
    Deploy light client contract for ICON 

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.
        ibc_handler_address (str): The address of ibc handler contract deployed on ICON.

    Returns:
        str: The address of light client contract deployed on ICON.
    """
    plan.print("deploy tendermint lightclient")
    init_message = '{"ibcHandler":"%s"}' % ibc_handler_address

    tx_hash = contract_deployment_service.deploy_contract(plan, "tendermint-0.1.0-optimized", init_message, service_name, uri, keystore_path, keystore_password, nid)
    score_address = contract_deployment_service.get_score_address(plan, service_name, tx_hash)
    plan.print("deployed light client")

    return score_address

def deploy_xcall_connection(plan, service_name, uri, keystore_path, keystore_password, nid, xcall_address, ibc_address):
    """
    Deploy XCall connection on ICON.

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.
        xcall_address (str): The address of the deployed XCall contract.
        ibc_address (str): The address of ibc handler contract deployed on ICON.

    Returns:
        str: The address of XCall connection deployed on ICON.
    """
    plan.print("deploy xcall connection")
    plan.print(xcall_address)
    
    init_message= '{"_xCall": "%s","_ibc": "%s","_port": "xcall"}' % (xcall_address, ibc_address)

    tx_hash = contract_deployment_service.deploy_contract(plan, "xcall-connection-0.1.0-optimized", init_message, service_name, uri, keystore_path, keystore_password, nid)
    score_address = contract_deployment_service.get_score_address(plan, service_name, tx_hash)
    
    return score_address


def deploy_xcall_for_ibc(plan, network, service_name, uri, keystore_path, keystore_password, nid):
    """
    Deploy Xcall contract for IBC

    Args:
        plan (Plan): The Kurtosis plan.
        network (str): The chain's network.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        str: The address of Xcall contract deployed for IBC
    """
    plan.print("Deploying xCall Contract for IBC")
    init_message = '{"networkId":"%s"}' % network

    tx_hash = contract_deployment_service.deploy_contract(plan, "xcall-0.1.0-optimized", init_message, service_name, uri, keystore_path, keystore_password, nid)
    score_address = contract_deployment_service.get_score_address(plan, service_name, tx_hash)
    
    return score_address  

def deploy_xcall_dapp(plan, src_chain_config, xcall_address):
    """
    Deploy Xcall Dapp contract

    Args:
        plan (Plan): The Kurtosis plan.
        src_chain_config (dict): Source chain configuration, a dictionary containing the following parameters:
            - "service_name": The name of the source chain's service.
            - "network": The source chain's network.
            - "endpoint": The endpoint URL for the source chain.
            - "keystore_path": The path to the keystore file for the source chain.
            - "keypassword": The password for the keystore.
            - "nid": The Network ID for the source chain.
        
        xcall_address (str): The address of the deployed XCall contract.

    Returns:
        str: The address of the deployed XCall Dapp contract.
    """
    
    plan.print("Deploying Xcall Dapp Contract")
    params = '{"_callService":"%s"}' % (xcall_address)

    tx_hash = contract_deployment_service.deploy_contract(plan, "dapp-multi-protocol-0.1.0-optimized", params, src_chain_config["service_name"], src_chain_config["endpoint"], src_chain_config["keystore_path"], src_chain_config["keypassword"], src_chain_config["nid"])
    score_address = contract_deployment_service.get_score_address(plan, src_chain_config["service_name"], tx_hash)
    
    return score_address  

def add_connection_xcall_dapp(plan, xcall_dapp_address, wasm_network_id, java_xcall_connection_address, wasm_xcall_connection_address, src_chain_config):
    """
    Add connection to Xcall Dapp

    Args:
        plan (Plan): The Kurtosis plan.
        xcall_dapp_address (str): The address of the deployed XCall Dapp contract.
        wasm_network_id (str): The wasm network ID.
        java_xcall_connection_address (str): The java Xcall connection address.
        wasm_xcall_connection_address (str): The wasm Xcall connection address.
        src_chain_config (dict): Source chain configuration, a dictionary containing the following parameters:
            - "service_name": The name of the source chain's service.
            - "network": The source chain's network.
            - "endpoint": The endpoint URL for the source chain.
            - "keystore_path": The path to the keystore file for the source chain.
            - "keypassword": The password for the keystore.
            - "nid": The Network ID for the source chain.

    Returns:
        dict: The service details of connection added.
    """
    plan.print("Configure dapp connection")
    method = "addConnection"
    params = '{"nid":"%s","source":"%s","destination":"%s"}' % (wasm_network_id, java_xcall_connection_address, wasm_xcall_connection_address)

    exec_command = ["./bin/goloop", "rpc", "sendtx", "call", "--to", xcall_dapp_address, "--method", method, "--params", params, "--uri", src_chain_config["endpoint"],"--key_store", src_chain_config["keystore_path"], "--key_password", src_chain_config["keypassword"], "--step_limit", "500000000000", "--nid", src_chain_config["nid"]]
    result = plan.exec(service_name = src_chain_config["service_name"], recipe = ExecRecipe(command = exec_command))

    tx_hash = result["output"].replace('"',"")
    tx_result = node_service.get_tx_result(plan, src_chain_config["service_name"], tx_hash, src_chain_config["endpoint"])
    plan.verify(value = tx_result["extract.status"],assertion = "==",target_value = "0x1")
    
    return tx_result

def configure_xcall_connection(plan, xcall_connection_address, connection_id, counterparty_port_id, counterparty_nid, client_id, service_name, uri, keystorepath, keypassword, nid):
    """
    Configure Xcall connection

    Args:
        plan (Plan): The Kurtosis plan.
        xcall_connection_address (str): The Xcall connection address.
        connection_id (str): The connection ID.
        counterparty_port_id (str): The counterparty port ID.
        counterparty_nid (str): The counterparty network ID.
        client_id (str): The client ID.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystorepath (str): The path to the keystore file for the chain.
        keypassword (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        dict: The service details of xcall connection configured.
    """
    plan.print("Configure Xcall Connection")

    method = "configureConnection"
    params = '{"connectionId":"%s", "counterpartyPortId":"%s", "counterpartyNid":"%s", "clientId":"%s", "timeoutHeight":"1000000"}' % (connection_id, counterparty_port_id, counterparty_nid, client_id)
    
    exec_command = ["./bin/goloop", "rpc", "sendtx", "call", "--to", xcall_connection_address, "--method", method, "--params", params, "--uri", uri, "--key_store", keystorepath, "--key_password", keypassword, "--step_limit", "500000000000", "--nid", nid]
    plan.print(params)
    result = plan.exec(service_name = service_name, recipe = ExecRecipe(command = exec_command))

    tx_hash = result["output"].replace('"',"")
    tx_result = node_service.get_tx_result(plan, service_name, tx_hash, uri)
    plan.verify(value = tx_result["extract.status"], assertion = "==", target_value = "0x1")
    
    return tx_result

def set_default_connection_xcall(plan, xcall_address, wasm_network_id, xcall_connection_address, service_name, uri, keystorepath, keypassword, nid):
    """
    Set up Xcall default connection 

    Args:
        plan (Plan): The Kurtosis plan.
        xcall_address (str): The address of the deployed XCall Dapp contract.
        wasm_network_id (str): The wasm network ID.
        xcall_connection_address (str): The Xcall connection address.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystorepath (str): The path to the keystore file for the chain.
        keypassword (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        dict: The service details of xcall default connection.
    """
    plan.print("Setting Up  Xcall Default connection")
    method = "setDefaultConnection"
    params = '{"_nid":"%s","_connection":"%s"}' % (wasm_network_id, xcall_connection_address)

    exec_command = ["./bin/goloop", "rpc", "sendtx", "call", "--to", xcall_address, "--method", method, "--params", params, "--uri", uri, "--key_store", keystorepath, "--key_password", keypassword, "--step_limit", "500000000000", "--nid", nid]
    result = plan.exec(service_name = service_name, recipe = ExecRecipe(command = exec_command))
    plan.print(params)
    tx_hash = result["output"].replace('"',"")
    tx_result = node_service.get_tx_result(plan, service_name, tx_hash, uri)
    plan.verify(value = tx_result["extract.status"], assertion = "==", target_value = "0x1")
    
    return tx_result

def setup_contracts_for_ibc_java(plan, service_name, uri, keystore_path, keystore_password, nid, network):
    """
    Set up contracts for IBC

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystore_path (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.
        network (str): The chain's network.

    Returns:
        dict: The addresses of contracts deployed.
    """
    plan.print("Setting Contracts")

    ibc_core_address = deploy_ibc_handler(plan, service_name, uri, keystore_path, keystore_password, nid)
    xcall_address = deploy_xcall_for_ibc(plan, network, service_name, uri, keystore_path, keystore_password, nid)
    light_client_address = deploy_light_client_for_icon(plan, service_name, uri, keystore_path, keystore_password, nid, ibc_core_address)
    xcall_connection_address = deploy_xcall_connection(plan, service_name, uri, keystore_path, keystore_password, nid, xcall_address, ibc_core_address)

    contracts = {
        "ibc_core": ibc_core_address,
        "xcall" : xcall_address,
        "light_client" : light_client_address,
        "xcall_connection" : xcall_connection_address
    }

    return contracts

def configure_connection_for_java(plan, xcall_address, xcall_connection_address, wasm_network_id, connection_id, counterparty_port_id, counterparty_nid, client_id, service_name, uri, keystorepath, keypassword, nid):
    """
    Configure connection for channel

    Args:
        plan (Plan): The Kurtosis plan.
        xcall_address (str): The address of the deployed XCall Dapp contract.
        xcall_connection_address (str): The Xcall connection address.
        wasm_network_id (str): The wasm network ID.
        connection_id (str): The connection ID.
        counterparty_port_id (str): The counterparty port ID.
        counterparty_nid (str): The counterparty network ID.
        client_id (str): The client ID.
        service_name (str): The name of the chain's service.
        uri (str): The URI for the chain.
        keystorepath (str): The path to the keystore file for the chain.
        keypassword (str): The password for the keystore.
        nid (str): The Network ID for the chain.

    Returns:
        dict : The service details of xcall connection configured.
    """
    plan.print("configure conection for channel")

    configure_xcal_connection_result = configure_xcall_connection(plan, xcall_connection_address, connection_id, counterparty_port_id, counterparty_nid, client_id, service_name, uri, keystorepath, keypassword, nid)
    set_xcall_connection_result = set_default_connection_xcall(plan, xcall_address, wasm_network_id, xcall_connection_address, service_name, uri, keystorepath, keypassword, nid)

    return set_xcall_connection_result

def deploy_and_configure_dapp_java(plan, src_chain_config, xcall_address, wasm_network_id, java_xcall_connection_address, wasm_xcall_connection_address):
    """
    Deploy and configure the Dapp

    Args:
        plan (Plan): The Kurtosis plan.
        src_chain_config (dict): Source chain configuration, a dictionary containing the following parameters:
            - "service_name": The name of the source chain's service.
            - "network": The source chain's network.
            - "endpoint": The endpoint URL for the source chain.
            - "keystore_path": The path to the keystore file for the source chain.
            - "keypassword": The password for the keystore.
            - "nid": The Network ID for the source chain.
        
        xcall_address (str): The address of the deployed XCall Dapp contract.
        wasm_network_id (str): The wasm network ID.
        java_xcall_connection_address (str): The java Xcall connection address.
        wasm_xcall_connection_address (str): The wasm Xcall connection address.

    Returns:
        dict: The xcall dapp address and the add connection result.
    """
    plan.print("Deploy and Configure Dapp")

    xcall_dapp_address = deploy_xcall_dapp(plan, src_chain_config, xcall_address)

    add_connection_result = add_connection_xcall_dapp(plan, xcall_dapp_address, wasm_network_id, java_xcall_connection_address, wasm_xcall_connection_address, src_chain_config)

    result = {
        "xcall_dapp" : xcall_dapp_address,
        "add_connection_result" : add_connection_result
    }

    return result

def registerClient(plan, service_name, light_client_address, keystorepath, keystore_password, nid, uri, ibc_core_address):
    """
    Register the client

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the chain's service.
        light_client_address (str): The address of light client contract deployed on ICON.
        keystorepath (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.
        uri (str): The URI for the chain.
        ibc_core_address (str): The IBC core address.

    Returns:
        str: The register client hash output. 
    """
    plan.print("registering the client")

    method = "registerClient"
    params = '{"clientType":"07-tendermint","client":"%s"}' % (light_client_address)

    exec_command = ["./bin/goloop", "rpc", "sendtx", "call", "--uri", uri, "--nid", nid, "--step_limit", "5000000000", "--to", ibc_core_address, "--method", method, "--params", params, "--key_store", keystorepath, "--key_password", keystore_password]
    plan.print(exec_command)
    result = plan.exec(service_name = service_name, recipe = ExecRecipe(command = exec_command))

    tx_hash = result["output"]
    tx_result = node_service.get_tx_result(plan, service_name, tx_hash, uri)
    plan.verify(value = tx_result["extract.status"], assertion = "==", target_value = "0x1")

    return tx_hash

def bindPort(plan, service_name, xcall_conn_address, keystorepath, keystore_password, nid, uri, ibc_core_address, port_id):
    """
    Bind Port ID

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the chain's service.
        xcall_conn_address (str): The address of XCall connection deployed on ICON.
        keystorepath (str): The path to the keystore file for the chain.
        keystore_password (str): The password for the keystore.
        nid (str): The Network ID for the chain.
        uri (str): The URI for the chain.
        ibc_core_address (str): The IBC core address.
        port_id (str): The port ID to bind.
        
    Returns:
        str: The Bind port hash output.
    """
    plan.print("Bind Port")

    password = "gochain"
    method = "bindPort"
    params = '{"portId":"%s", "moduleAddress":"%s"}' % (port_id, xcall_conn_address)

    exec_command = ["./bin/goloop", "rpc", "sendtx", "call", "--uri", uri, "--nid", nid, "--step_limit", "5000000000", "--to", ibc_core_address, "--method", method, "--params", params, "--key_store", keystorepath, "--key_password", keystore_password]
    
    result = plan.exec(service_name = service_name, recipe = ExecRecipe(command = exec_command))

    tx_hash = result["output"]
    tx_result = node_service.get_tx_result(plan, service_name, tx_hash, uri)
    plan.verify(value = tx_result["extract.status"], assertion = "==", target_value = "0x1")

    return tx_hash