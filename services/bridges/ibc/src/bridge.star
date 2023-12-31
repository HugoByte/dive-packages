# Import the required modules and constants
constants = import_module("../../../../package_io/constants.star")
ibc_relay_config = constants.IBC_RELAYER_SERVICE
icon_setup_node = import_module("../../../jvm/icon/src/node-setup/setup_icon_node.star")
icon_relay_setup = import_module("../../../jvm/icon/src/relay-setup/contract_configuration.star")
icon_service = import_module("../../../jvm/icon/icon.star")
input_parser = import_module("../../../../package_io/input_parser.star")
cosmvm_node = import_module("../../../cosmvm/cosmvm.star")
cosmos_relay_setup = import_module("../../../cosmvm/src/relay-setup/contract-configuration.star")

def run_cosmos_ibc_setup(plan, src_chain, dst_chain, src_service_config = {}, dst_service_config = {}):
    """
    Start IBC bridge between two chains.

    Args:
        plan (Plan): The Kurtosis plan.
        src_chain (str): The name of the source chain.
        dst_chain (str): The name of the destination chain.
        src_service_config (dict, optional): The chain config details for source chain.
        dst_service_config (dict, optional): The chain config details for destination chain.
    
    Returns:
        dict: The configuration data for the IBC bridge.
    """
    # Check if source and destination chains are both CosmVM-based chains (archway or neutron)
    if (src_chain in ["archway", "neutron"]) and (dst_chain in ["archway", "neutron"]):
        # Start IBC between two CosmVM chains
        data = cosmvm_node.start_ibc_between_cosmvm_chains(plan, src_chain, dst_chain, src_service_config, dst_service_config)
        config_data = run_cosmos_ibc_relay_for_already_running_chains(plan, src_chain, dst_chain, data.src_config, data.dst_config)
        return config_data

    if dst_chain in ["archway", "neutron"] and src_chain == "icon":
        # Start ICON node service
        src_chain_config = icon_service.start_node_service(plan, chain_config = src_service_config)
        # Start CosmVM node service
        dst_chain_config = cosmvm_node.start_cosmvm_chains(plan, dst_chain, chain_config = dst_service_config)
        dst_chain_config = input_parser.struct_to_dict(dst_chain_config)
        # Get service names and new generate configuration data
        config_data = run_cosmos_ibc_relay_for_already_running_chains(plan, src_chain, dst_chain, src_chain_config, dst_chain_config)
        return config_data

def run_cosmos_ibc_relay_for_already_running_chains(plan, src_chain, dst_chain, src_chain_config, dst_chain_config):
    """
    Start IBC bridge between two already running chains.

    Args:
        plan (Plan): The Kurtosis plan.
        src_chain (str): The name of the source chain.
        dst_chain (str): The name of the destination chain.
        src_chain_config (dict): The configuration data for the source chain.
        dst_chain_config (dict): The configuration data for the destination chain.

    Returns:
        dict: The configuration data for the IBC bridge.
    """
    config_data = generate_ibc_config(src_chain, dst_chain, src_chain_config, dst_chain_config)
    if src_chain in ["archway", "neutron"] and dst_chain in ["archway", "neutron"]:
        start_cosmos_relay(plan, src_chain, dst_chain, src_chain_config, dst_chain_config)

    elif src_chain == "icon" and dst_chain in ["archway", "neutron"]:
        deploy_icon_contracts, src_chain_data = setup_icon_chain(plan, src_chain_config)
        deploy_cosmos_contracts, dst_chain_data = setup_cosmos_chain(plan, dst_chain, dst_chain_config)
        
        relay_service_response = start_cosmos_relay_for_icon_to_cosmos(plan, src_chain, dst_chain ,src_chain_data, dst_chain_data)
        
        path_name = setup_relay(plan, src_chain_data, dst_chain_data)
        relay_data = get_relay_path_data(plan, relay_service_response.service_name, path_name)
        
        dapp_result_java = icon_relay_setup.deploy_and_configure_dapp_java(plan, src_chain_config, deploy_icon_contracts["xcall"], dst_chain_config["chain_id"], deploy_icon_contracts["xcall_connection"], deploy_cosmos_contracts["xcall_connection"])
        dapp_result_wasm = cosmos_relay_setup.deploy_and_configure_xcall_dapp(plan, dst_chain, dst_chain_config["service_name"], dst_chain_config["chain_id"], dst_chain_config["chain_key"], deploy_cosmos_contracts["xcall"], deploy_cosmos_contracts["xcall_connection"], deploy_icon_contracts["xcall_connection"], src_chain_config["network"])
        
        cosmos_relay_setup.configure_connection_for_wasm(plan, dst_chain, dst_chain_config["service_name"], dst_chain_config["chain_id"], dst_chain_config["chain_key"], deploy_cosmos_contracts["xcall_connection"], relay_data.dst_connection_id, "xcall", src_chain_config["network"], relay_data.dst_client_id, deploy_cosmos_contracts["xcall"])
        icon_relay_setup.configure_connection_for_java(plan, deploy_icon_contracts["xcall"], deploy_icon_contracts["xcall_connection"], dst_chain_config["chain_id"], relay_data.src_connection_id, "xcall", dst_chain_config["chain_id"], relay_data.src_client_id, src_chain_config["service_name"], src_chain_config["endpoint"], src_chain_config["keystore_path"], src_chain_config["keypassword"], src_chain_config["nid"])

        config_data["contracts"][src_chain_config["service_name"]] = deploy_icon_contracts
        config_data["contracts"][dst_chain_config["service_name"]] = deploy_cosmos_contracts    
        config_data["contracts"][src_chain_config["service_name"]]["dapp"] = dapp_result_java["xcall_dapp"]
        config_data["contracts"][dst_chain_config["service_name"]]["dapp"] = dapp_result_wasm["xcall_dapp"]

        # Start relay channel
        start_channel(plan, relay_service_response.service_name, path_name, "xcall", "xcall")

    return config_data

def setup_icon_chain(plan, chain_config):
    """
    Set up icon chain.

    Args:
        plan (Plan): The Kurtosis plan.
        chain_config (dict): The configuration data for the ICON chain.

    Returns:
        dict: The deployed icon contract details and the source chain data.
    """
    deploy_icon_contracts = icon_relay_setup.setup_contracts_for_ibc_java(plan, chain_config["service_name"], chain_config["endpoint"], chain_config["keystore_path"], chain_config["keypassword"], chain_config["nid"], chain_config["network"])
    icon_relay_setup.registerClient(plan, chain_config["service_name"], deploy_icon_contracts["light_client"], chain_config["keystore_path"], chain_config["keypassword"], chain_config["nid"], chain_config["endpoint"], deploy_icon_contracts["ibc_core"])

    # Configure ICON node
    icon_setup_node.configure_node(plan, chain_config["service_name"], chain_config["endpoint"], chain_config["keystore_path"], chain_config["keypassword"], chain_config["nid"])
    src_chain_last_block_height = icon_setup_node.get_last_block(plan, chain_config["service_name"])

    plan.print("source block height %s" % src_chain_last_block_height)

    network_name = "{0}-{1}".format("dst_chain_network_name", src_chain_last_block_height)

    src_data = {
        "name": network_name,
        "owner": deploy_icon_contracts["ibc_core"],
    }

    # Open BTP network on ICON chain
    tx_result_open_btp_network = icon_setup_node.open_btp_network(plan, chain_config["service_name"], src_data, chain_config["endpoint"], chain_config["keystore_path"], chain_config["keypassword"], chain_config["nid"])

    icon_relay_setup.bindPort(plan, chain_config["service_name"], deploy_icon_contracts["xcall_connection"], chain_config["keystore_path"], chain_config["keypassword"], chain_config["nid"], chain_config["endpoint"], deploy_icon_contracts["ibc_core"], "xcall")

    src_chain_id = chain_config["network_name"].split('-', 1)[1]
    network_id = icon_setup_node.hex_to_int(plan, chain_config["service_name"], chain_config["nid"])
    btp_network_id = icon_setup_node.hex_to_int(plan, chain_config["service_name"], tx_result_open_btp_network["extract.network_id"])
    btp_network_type_id = icon_setup_node.hex_to_int(plan, chain_config["service_name"], tx_result_open_btp_network["extract.network_type_id"])

    src_chain_data = {
        "chain_id": src_chain_id,
        "rpc_address": chain_config["endpoint"],
        "ibc_address": deploy_icon_contracts["ibc_core"],
        "password": chain_config["keypassword"],
        "network_id": network_id,
        "btp_network_id": btp_network_id,
        "btp_network_type_id": btp_network_type_id
    }

    return deploy_icon_contracts, src_chain_data

def setup_cosmos_chain(plan, chain_name, chain_config):
    """
    Set up cosmos chains.

    Args:
        plan (Plan): The Kurtosis plan.
        chain_name (str): The name of the cosmos supported chain.
        chain_config (dict): The configuration data for the cosmos supported chain.

    Returns:
        dict: The deployed cosmos contract details and the destination chain data.
    """
    deploy_cosmos_contracts = cosmos_relay_setup.setup_contracts_for_ibc_wasm(plan, chain_name, chain_config["service_name"], chain_config["chain_id"], chain_config["chain_key"], chain_config["chain_id"], "stake", "xcall")
    cosmos_relay_setup.registerClient(plan, chain_name, chain_config["service_name"], chain_config["chain_id"], chain_config["chain_key"], deploy_cosmos_contracts["ibc_core"], deploy_cosmos_contracts["light_client"])
    plan.wait(service_name = chain_config["service_name"], recipe = ExecRecipe(command = ["/bin/sh", "-c", "sleep 10s && echo 'success'"]), field = "code", assertion = "==", target_value = 0, timeout = "200s")
    cosmos_relay_setup.bindPort(plan, chain_name, chain_config["service_name"], chain_config["chain_id"], chain_config["chain_key"], deploy_cosmos_contracts["ibc_core"], deploy_cosmos_contracts["xcall_connection"])

    dst_chain_data = {
        "chain_id": chain_config["chain_id"],
        "key": chain_config["chain_key"],
        "rpc_address": chain_config["endpoint"],
        "ibc_address": deploy_cosmos_contracts["ibc_core"],
        "service_name": chain_config["service_name"],
    }

    return deploy_cosmos_contracts, dst_chain_data

def generate_ibc_config(src_chain, dst_chain, src_chain_config, dst_chain_config):
    """
    Generate IBC configuration details.

    Args:
        src_chain (str): The name of the source chain.
        dst_chain (str): The name of the destination chain.
        src_chain_config (dict): The configuration data for the source chain.
        dst_chain_config (dict): The configuration data for the destination chain.

    Returns:
        dict: The configuration data for the source and destination chains.
    """
    config_data = input_parser.generate_new_config_data_for_ibc(src_chain, dst_chain, src_chain_config["service_name"], dst_chain_config["service_name"])
    config_data["chains"][src_chain_config["service_name"]] = src_chain_config
    config_data["chains"][dst_chain_config["service_name"]] = dst_chain_config
    return config_data

def start_cosmos_relay(plan, src_chain, dst_chain, src_config, dst_config):
    """
    Start a cosmos relay.

    Args:
        plan (Plan): The Kurtosis plan.
        src_chain (str): The name of the source chain.
        dst_chain (str): The name of the destination chain.
        src_config (dict): The configuration data for the source chain.
        dst_config (dict): The configuration data for the destination chain.

    Returns:
        struct: The relay service name.
    """
    plan.print("Starting Cosmos relay")

    plan.upload_files(src = ibc_relay_config.run_file_path, name = "run")

    cosmos_config = read_file(ibc_relay_config.ibc_relay_config_file_template)

    cfg_template_data = {
        "KEY": src_config["chain_key"],
        "CHAINID": src_config["chain_id"],
        "CHAIN": src_chain,
    }
    plan.render_templates(
        config = {
            "cosmos-%s.json" % src_config["chain_id"]: struct(
                template = cosmos_config,
                data = cfg_template_data,
            ),
        },
        name = "config-%s" % src_config["chain_id"],
    )

    cfg_template_data = {
        "KEY": dst_config["chain_key"],
        "CHAINID": dst_config["chain_id"],
        "CHAIN": dst_chain,
    }
    plan.render_templates(
        config = {
            "cosmos-%s.json" % dst_config["chain_id"]: struct(
                template = cosmos_config,
                data = cfg_template_data,
            ),
        },
        name = "config-%s" % dst_config["chain_id"],
    )

    src_chain_seed = plan.exec(service_name = src_config["service_name"], recipe = ExecRecipe(command = ["/bin/sh", "-c", "jq -r '.mnemonic' ../../start-scripts/key_seed.json | tr -d '\n\r'"]))
    dst_chain_seed = plan.exec(service_name = dst_config["service_name"], recipe = ExecRecipe(command = ["/bin/sh", "-c", "jq -r '.mnemonic' ../../start-scripts/key_seed.json | tr -d '\n\r'"]))
    
    # Configure the Cosmos relay service
    relay_service = ServiceConfig(
        image = ibc_relay_config.relay_service_image,
        files = {
            ibc_relay_config.relay_config_files_path + src_config["chain_id"]: "config-%s" % src_config["chain_id"],
            ibc_relay_config.relay_config_files_path + dst_config["chain_id"]: "config-%s" % dst_config["chain_id"],
            ibc_relay_config.relay_config_files_path: "run",
        },
        entrypoint = ["/bin/sh", "-c", "chmod +x ../script/run.sh && sh ../script/run.sh '%s' '%s' '%s' '%s' '%s' '%s' '%s' '%s'" % (src_config["chain_id"], dst_config["chain_id"], src_config["chain_key"], dst_config["chain_key"], src_config["endpoint"], dst_config["endpoint"], src_chain_seed["output"], dst_chain_seed["output"])],
    )

    plan.print(relay_service)
    plan.add_service(name = ibc_relay_config.relay_service_name, config = relay_service)

    return struct(
        service_name = ibc_relay_config.relay_service_name,
    )

def start_cosmos_relay_for_icon_to_cosmos(plan, src_chain, dst_chain, src_chain_config, dst_chain_config):
    """
    Start IBC relay for ICON to cosmos.

    Args:
        plan (Plan): The Kurtosis plan.
        src_chain (str): The name of the source chain.
        dst_chain (str): The name of the destination chain.
        src_chain_config (dict): The configuration data for the source chain.
        dst_chain_config (dict): The configuration data for the destination chain.

    Returns:
        struct: The relay service name.
    """
    plan.print("starting the cosmos relay for icon to cosmos")

    file_name = "%s_config" % dst_chain
    plan.upload_files(src = ibc_relay_config.config_file_path, name = file_name)
    plan.upload_files(src = ibc_relay_config.icon_keystore_file, name = "icon-keystore")

    if dst_chain == "archway":
        wasm_config = read_file(ibc_relay_config.ibc_relay_wasm_file_template)
    elif dst_chain == "neutron":
        wasm_config = read_file(ibc_relay_config.ibc_relay_neutron_wasm_file_template)
    java_config = read_file(ibc_relay_config.ibc_relay_java_file_template)

    cfg_template_data_wasm = {
        "KEY": dst_chain_config["key"],
        "CHAINID": dst_chain_config["chain_id"],
        "RPCADDRESS": dst_chain_config["rpc_address"],
        "IBCADDRESS": dst_chain_config["ibc_address"],
    }

    cfg_template_data_java = {
        "CHAINID": src_chain_config["chain_id"],
        "RPCADDRESS": src_chain_config["rpc_address"],
        "IBCADDRESS": src_chain_config["ibc_address"],
        "ICONNETWORKNID": src_chain_config["network_id"],
        "BTPNETWORKID": src_chain_config["btp_network_id"],
        "BTPNETWORKTYPEID": src_chain_config["btp_network_type_id"]
    }

    plan.render_templates(
        config = {
            "%s.json" % src_chain_config["chain_id"]: struct(
                template = java_config,
                data = cfg_template_data_java,
            ),
        },
        name = "config-%s" % src_chain_config["chain_id"],
    )

    plan.render_templates(
        config = {
            "%s.json" % dst_chain_config["chain_id"]: struct(
                template = wasm_config,
                data = cfg_template_data_wasm,
            ),
        },
        name = "config-%s" % dst_chain_config["chain_id"],
    )

    relay_service = ServiceConfig(
        image = ibc_relay_config.relay_service_image_icon_to_cosmos,
        files = {
            ibc_relay_config.relay_config_files_path + "java": "config-%s" % src_chain_config["chain_id"],
            ibc_relay_config.relay_config_files_path + "wasm": "config-%s" % dst_chain_config["chain_id"],
            ibc_relay_config.relay_keystore_path + src_chain_config["chain_id"]: "icon-keystore",
        },
        entrypoint = ["/bin/sh"],
    )

    plan.add_service(name = ibc_relay_config.relay_service_name_icon_to_cosmos, config = relay_service)

    return struct(
        service_name = ibc_relay_config.relay_service_name_icon_to_cosmos,
    )


def setup_relay_exec(plan, cmd):
    """
    Execute services for setup relay.

    Args:
        plan (Plan): The Kurtosis plan.
        cmd (str): The command to be executed.
    """
    plan.exec(
        service_name = ibc_relay_config.relay_service_name_icon_to_cosmos, 
        recipe = ExecRecipe(
            command = ["/bin/sh", "-c","{}".format(cmd)]
        )
    )

def setup_relay(plan, src_chain_config, dst_chain_config):
    """
    Set up relay between two chains.

    Args:
        plan (Plan): The Kurtosis plan.
        src_chain_config (dict): The configuration data for the source chain.
        dst_chain_config (dict): The configuration data for the destination chain.

    Returns:
        str: The path name.
    """
    src_chain_id = src_chain_config["chain_id"]
    src_password = src_chain_config["password"]

    dst_chain_id = dst_chain_config["chain_id"]
    dst_chain_key = dst_chain_config["key"]
    dst_chain_service_name = dst_chain_config["service_name"]

    setup_relay_exec(plan,"apk add yq")
    seed = plan.exec(service_name = dst_chain_service_name, recipe = ExecRecipe(command = ["/bin/sh", "-c", "jq -r '.mnemonic' ../../start-scripts/key_seed.json | tr -d '\n\r'"]))
    
    plan.print("starting the relay")
    setup_relay_exec(plan,"rly config init")

    plan.print("Adding the chain1")
    setup_relay_exec(plan,"rly chains add --file ../script/wasm/%s.json %s" % (dst_chain_id, dst_chain_id))

    plan.print("Adding the chain2")
    setup_relay_exec(plan,"rly chains add --file ../script/java/%s.json %s" % (src_chain_id, src_chain_id))

    plan.print("Adding the keys")
    setup_relay_exec(plan,"rly keys restore %s %s '%s' " % (dst_chain_id, dst_chain_key, seed["output"]))

    plan.print("Adding the paths")
    path_name = "{0}-{1}".format(src_chain_id, dst_chain_id)
    setup_relay_exec(plan,"rly paths new %s %s %s" % (src_chain_id, dst_chain_id, path_name))
    setup_relay_exec(plan,"rly tx clients %s --client-tp 2000000m -d" % path_name)
    setup_relay_exec(plan,"rly tx connection %s" % path_name)

    return path_name

def get_path_data(plan, service_name, path_name, key):
    """
    Get the path data for the service.

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the service.
        path_name (str): The path name of the service.
        key (str): The chain Key.

    Returns:
        str: The path data.
    """
    response = plan.exec(service_name = service_name, recipe = ExecRecipe(command = [
        "/bin/sh", "-c", "cat /root/.relayer/config/config.yaml | yq '.paths.{0}.{1}'".format(path_name, key)
    ]))
    execute_cmd = ExecRecipe(command = [
        "/bin/sh", "-c", "echo \"{0}\" | tr -d '\n\r'".format(response["output"])
    ])
    result = plan.exec(service_name = service_name, recipe = execute_cmd)
    return result["output"]

def get_relay_path_data(plan, service_name, path_name):
    """
    Get relay path data

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the service.
        path_name (str): The path name of the service.

    Returns:
        struct: A dictionary of configuration details.
    """
    src_chain_id = get_path_data(plan, service_name, path_name, "src.chain-id")
    src_client_id = get_path_data(plan, service_name, path_name, "src.client-id")
    src_connection_id = get_path_data(plan, service_name, path_name, "src.connection-id")
    dst_chain_id = get_path_data(plan, service_name, path_name, "dst.chain-id")
    dst_client_id = get_path_data(plan, service_name, path_name, "dst.client-id")
    dst_connection_id = get_path_data(plan, service_name, path_name, "dst.connection-id")

    config = struct(
        src_chain_id = src_chain_id,
        src_client_id = src_client_id,
        src_connection_id = src_connection_id,
        dst_chain_id = dst_chain_id,
        dst_client_id = dst_client_id,
        dst_connection_id = dst_connection_id,
    )

    return config

def start_channel(plan, service_name, path_name, src_port, dst_port):
    """
    Start a channel

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the service.
        path_name (str): The path name of the service.
        src_port (int): The source chain port.
        dst_port (int): The destination chain port.
    """
    plan.print("Starting Channel")
    exec_cmd = ["/bin/sh", "-c", "rly tx chan %s --src-port=%s --dst-port=%s" % (path_name, src_port, dst_port)]
    plan.exec(service_name = service_name, recipe = ExecRecipe(command = exec_cmd))

def start_relay(plan, service_name):
    """
    Start a relay.

    Args:
        plan (Plan): The Kurtosis plan.
        service_name (str): The name of the service.
    """
    plan.print("Starting Relay")
    plan.exec(service_name = service_name, recipe = ExecRecipe(command = ["/bin/sh", "-c", "ln -sf /proc/1/fd/1 /root/.relayer/relay.log && rly start 1>&2 &"]))
