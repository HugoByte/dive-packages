def start_icon_testnet(plan, rpc_port = None):
    if rpc_port == None:
        rpc_port = 9000

    download_required_files_testnet(plan)
    plan.upload_files(src = "./config", name = "config")
    icon_node_service_config = ServiceConfig(
            image = "iconloop/icon2-node",
            files = {
                "/goloop/config": "config",
                "/goloop": "data",
            },
            ports = {
                "rpc": PortSpec(
                    number = 9000, 
                    transport_protocol = "TCP",
                    application_protocol = "http"
                ),
            },
            public_ports = {
                "rpc": PortSpec(
                    number = rpc_port, 
                    transport_protocol = "TCP",
                    application_protocol = "http"
                ),
            },
            env_vars = {
                "SERVICE": "BerlinNet",
                "GOLOOP_LOG_LEVEL": "trace",
                "KEY_STORE_FILENAME": "keystore.json",
                "KEY_PASSWORD": "iconpass",
                "FASTEST_START": "true",
                "ROLE": "0"
            },
            entrypoint = ["/init"],
    ) 
    icon_node_service_response = plan.add_service(name = "icon-node-testnet", config = icon_node_service_config)
    plan.exec(service_name = "icon-node-testnet", recipe = ExecRecipe(command = ["/bin/sh", "-c", "apk add jq"]))    

def download_required_files_testnet(plan):

    result = plan.run_python(
    run = """
import requests
import subprocess

def fetch_network_info():
    url = "https://networkinfo.solidwallet.io/info/BerlinNet.json"
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        index_url = data["index_url"]
        checksum_url = data["checksum_url"]
        subprocess.Popen(["apt-get", "update"]).wait()
        subprocess.Popen(["apt-get", "install", "-y", "aria2"]).wait()
        subprocess.Popen(["aria2c", "-d", "data/restore", "https://www.gutenberg.org/files/1513/1513-0.txt"]).wait()
        subprocess.Popen(["aria2c", "-d", "data/restore", index_url]).wait()
        subprocess.Popen(["aria2c", "-d", "data/restore", checksum_url]).wait()
    
        download_with_aria2c()

    else:
        print("Failed to fetch network info. Status code:", response.status_code)

    
def download_with_aria2c():
    command = [
        "aria2c",
        "-d", "data",
        "-i", "/data/restore/file_list.txt",
        "-V",
        "-j20",
        "-x16",
        "--http-accept-gzip",
        "--disk-cache=64M",
        "--allow-overwrite",
        "--log-level=error",
        "--log", "download_error.log",
        "-c"
    ]

    subprocess.Popen(command)
    
if __name__ == "__main__":
    fetch_network_info()
""",
        packages = [
            "requests",
        ],
    
        image = "python:latest",

        store = [
            StoreSpec(src = "/data", name = "data"),
        ],
        wait=None
    )