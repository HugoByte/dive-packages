ICON_NODE_CLIENT = struct(
    node_image = "iconloop/goloop-icon:v1.3.9",
    config_files_directory = "/goloop/config/",
    contracts_directory = "/goloop/contracts/",
    keystore_directory = "/goloop/keystores/",
    config_files_path = "../../static-files/config/",
    contract_files_path = "../../static-files/contracts/",
    keystore_files_path = "../../../../bridges/btp/static-files/keystores/keystore.json",
    rpc_endpoint_path = "api/v3/icon_dex",
    service_name = "icon-node-",
    genesis_file_path = "/goloop/genesis/",
)

HARDHAT_NODE_CLIENT = struct(
    node_image = "node:lts-alpine",
    port = 8545,
    config_files_path = "../../static-files/hardhat.config.js",
    config_files_directory = "/config/",
    service_name = "hardhat-node",
    network = "0x539.hardhat",
    network_id = "0x539",
    keystore_path = "keystores/hardhat_keystore.json",
    keypassword = "hardhat",
)

CONTRACT_DEPLOYMENT_SERVICE_ETHEREUM = struct(
    node_image = "node:lts-alpine",
    static_file_path = "../../static-files/",
    static_files_directory_path = "/static-files/",
    service_name = "eth-contract-deployer",
    template_file = "../../static-files/hardhat.config.ts.tmpl",
    rendered_file_directory = "/static-files/rendered/",
)

ETH_NODE_CLIENT = struct(
    service_name = "el-1-geth-lighthouse",
    network_name = "eth",
    network = "0x301824.eth",
    nid = "0x301824",
    keystore_path = "keystores/eth_keystore.json",
    keypassword = "password",
)
ARCHWAY_SERVICE_CONFIG = struct(
    start_script = "../../static_files/start.sh",
    default_contract_path = "../../static_files/contracts",
    service_name = "node-service",
    image = "archwaynetwork/archwayd:v2.0.0",
    path = "/start-scripts/",
    contract_path = "/root/contracts/",
    config_files = "../../static_files/config/",
    password = "password",
)

NEUTRON_SERVICE_CONFIG = struct(
    service_name = "neutron-node",
    image = "hugobyte/neutron-node:v0.2",
    init_script = "../../static_files/init.sh",
    start_script = "../../static_files/start.sh",
    init_nutrond_script = "../../static_files/init-neutrond.sh",
    path = "/start-scripts/",
    default_contract_path = "../../../archway/static_files/contracts",
    contract_path = "/root/contracts/",
)

IBC_RELAYER_SERVICE = struct(
    ibc_relay_config_file_template = "../static-files/config/cosmosjson.tpl",
    relay_service_name = "cosmos-ibc-relay",
    # updated the ibc relay image
    relay_service_image = "hugobyte/ibc-relay:v0.1",
    relay_config_files_path = "/script/",
    run_file_path = "../static-files/run.sh",
    relay_service_image_icon_to_cosmos = "hugobyte/icon-ibc-relay:v0.1",
    relay_service_name_icon_to_cosmos = "ibc-relayer",
    config_file_path = "../static-files/config",
    ibc_relay_wasm_file_template = "../static-files/config/archwayibc.json.tpl",
    ibc_relay_neutron_wasm_file_template = "../static-files/config/neutronibc.json.tpl",
    ibc_relay_java_file_template = "../static-files/config/icon.json.tpl",
    icon_keystore_file = "../../btp/static-files/keystores/keystore.json",
    relay_keystore_path = "/root/.relayer/keys/"
)

NETWORK_PORT_KEYS_AND_IP_ADDRESS = struct(
    grpc = "grpc",
    rpc = "rpc",
    http = "http",
    tcp = "tcp",
    public_ip_address = "127.0.0.1",
)

ARCHAY_NODE0_CONFIG = struct(
    chain_id = "constantine-3",
    grpc = 9090,
    http = 9091,
    tcp = 26658,
    rpc = 4564,
    key = "constantine-3-key",
    
)

ARCHAY_NODE1_CONFIG = struct(
    chain_id = "archway-node-1",
    grpc = 9080,
    http = 9092,
    tcp = 26659,
    rpc = 4566,
    key = "archway-node-1-key",
)

COMMON_ARCHWAY_PRIVATE_PORTS = struct(
    grpc = 9090,
    http = 9091,
    tcp = 26656,
    rpc = 26657,
)

NEUTRON_PRIVATE_PORTS = struct(
    http = 1317,
    rpc = 26657,
    tcp = 26656,
    grpc = 9090,
)

NEUTRON_NODE1_CONFIG = struct(
    http = 1317,
    rpc = 26669,
    tcp = 26656,
    grpc = 8032,
    chain_id = "test-chain1",
    key = "test-key",
    password = "clock post desk civil pottery foster expand merit dash seminar song memory figure uniform spice circle try happy obvious trash crime hybrid hood cushion",
)

NEUTRON_NODE2_CONFIG = struct(
    http = 1311,
    rpc = 26653,
    tcp = 26652,
    grpc = 8091,
    chain_id = "test-chain2",
    key = "test-key",
    password = "clock post desk civil pottery foster expand merit dash seminar song memory figure uniform spice circle try happy obvious trash crime hybrid hood cushion",
)

ICON_NODE0_CONFIG = struct(
    private_port = 9080,
    public_port = 8090,
    p2p_listen_address = 7080,
    p2p_address = 8080,
    cid = "0xacbc4e",
    uploaded_genesis = {},
    genesis_file_path = "../../static-files/config/genesis-icon-0.zip",
    genesis_file_name = "genesis-icon-0.zip"
)


ICON_NODE1_CONFIG = struct(
    private_port = 9081,
    public_port = 8091,
    p2p_listen_address = 7081,
    p2p_address = 8081,
    cid = "0x42f1f3",
    uploaded_genesis = {},
    genesis_file_path = "../../static-files/config/genesis-icon-1.zip",
    genesis_file_name = "genesis-icon-1.zip"
)

ARCHWAY_COMMANDS = struct(
    start_node_cmd = "cd ../..{0} && chmod +x start_archway.sh && ./start_archway.sh {1} {2} {3}",
    bindPort_cmd = '''echo '{0}' | archwayd tx wasm execute "{1}" '{{"bind_port":{{"address":"{2}", "port_id":"xcall"}}}}' --from {3} --keyring-backend test --chain-id {4} --output json -y''',
    registerClient_cmd = '''echo '{0}' | archwayd tx wasm execute "{1}" '{{"register_client":{{"client_type":"iconclient","client_address":"{2}"}}}}' --from {3} --keyring-backend test --chain-id {4} --output json -y''',
    add_connection_xcall_dapp_cmd = "echo '{0}' | archwayd tx wasm execute {1} '{2}' --from {3} --keyring-backend test --chain-id {4} --output json -y",
    configure_xcall_connection_cmd = "echo '{0}'| archwayd tx wasm execute {1} '{2}' --from {3} --keyring-backend test --chain-id {4} --output json -y",
    set_default_connection_xcall_cmd = "echo '{0}'| archwayd tx wasm execute {1} '{2}' --from {3} --keyring-backend test --chain-id {4} --output json -y"
)

NEUTRON_COMMANDS = struct(
    start_node_cmd = "chmod +x ../..{0}init.sh && chmod +x ../..{1}start_neutron.sh && chmod +x ../..{2}init-neutrond.sh && key={3} password=\"{4}\" CHAINID={5} ../..{6}init.sh && CHAINID={7} ../..{8}init-neutrond.sh && CHAINID={9} ../..{10}start_neutron.sh",
    bindPort_cmd = '''echo '{0}' | neutrond tx wasm execute "{1}" '{{"bind_port":{{"address":"{2}", "port_id":"xcall"}}}}' --from {3} --home ./data/{4} --keyring-backend test --chain-id {5} --output json -y''',
    registerClient_cmd = '''echo '{0}' | neutrond tx wasm execute "{1}" '{{"register_client":{{"client_type":"iconclient","client_address":"{2}"}}}}' --from {3} --home ./data/{4} --keyring-backend test --chain-id {5} --output json -y''',
    add_connection_xcall_dapp_cmd = "echo '{0}' | neutrond tx wasm execute {1} '{2}' --from {3} --home ./data/{4} --keyring-backend test --chain-id {5} --output json -y",
    configure_xcall_connection_cmd = "echo '{0}'| neutrond tx wasm execute {1} '{2}' --from {3} --home ./data/{4} --keyring-backend test --chain-id {5} --output json -y",
    set_default_connection_xcall_cmd = "echo '{0}'| neutrond tx wasm execute {1} '{2}' --from {3} --home ./data/{4} --keyring-backend test --chain-id {5} --output json -y"
)

node_details = {
    "archway" : {
        "node_constants" : ARCHWAY_SERVICE_CONFIG,
        "cmd_keyword" : "archwayd",
        "contract_path" : "../contracts/{0}.wasm",
        "path" : "",
        "service_config" : ARCHAY_NODE0_CONFIG,
        "cosmos_service_config" : ARCHWAY_SERVICE_CONFIG,
        "private_ports" : COMMON_ARCHWAY_PRIVATE_PORTS,
        "password" : ARCHWAY_SERVICE_CONFIG.password,
        "start_node_cmd" : ARCHWAY_COMMANDS.start_node_cmd,
        "bindPort_cmd" : ARCHWAY_COMMANDS.bindPort_cmd,
        "registerClient_cmd" : ARCHWAY_COMMANDS.registerClient_cmd,
        "add_connection_xcall_dapp_cmd": ARCHWAY_COMMANDS.add_connection_xcall_dapp_cmd,    
        "configure_xcall_connection_cmd": ARCHWAY_COMMANDS.configure_xcall_connection_cmd,            
        "set_default_connection_xcall_cmd": ARCHWAY_COMMANDS.set_default_connection_xcall_cmd      
    },

    "neutron" : {
        "node_constants" : NEUTRON_SERVICE_CONFIG,
        "cmd_keyword" : "neutrond",
        "contract_path" : "../../root/contracts/{0}.wasm",
        "path":"--home ./data/{0}",
        "service_config" : NEUTRON_NODE1_CONFIG,
        "cosmos_service_config" : NEUTRON_SERVICE_CONFIG,
        "password" : NEUTRON_NODE1_CONFIG.password,
        "private_ports" : NEUTRON_PRIVATE_PORTS,
        "start_node_cmd": NEUTRON_COMMANDS.start_node_cmd,
        "bindPort_cmd": NEUTRON_COMMANDS.bindPort_cmd,
        "registerClient_cmd": NEUTRON_COMMANDS.registerClient_cmd,
        "add_connection_xcall_dapp_cmd": NEUTRON_COMMANDS.add_connection_xcall_dapp_cmd,
        "configure_xcall_connection_cmd": NEUTRON_COMMANDS.configure_xcall_connection_cmd,
        "set_default_connection_xcall_cmd": NEUTRON_COMMANDS.set_default_connection_xcall_cmd
    }
}