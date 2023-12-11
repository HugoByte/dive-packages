# Import the required constants
constants = import_module("../../../../../package_io/constants.star")

def start_deploy_service(plan, endpoint):
    """
    Function to start the Ethereum contract deployment service.

    Args:
        plan (Plan): The Kurtosis plan.
        endpoint (str): The service endpoint URL.

    Returns:
        dict: The service response containing configuration data.
    """
    deployer_constants = constants.CONTRACT_DEPLOYMENT_SERVICE_ETHEREUM

    plan.print("Starting Contract Deploy Service")

    plan.upload_files(src = deployer_constants.static_file_path, name = "static-files")

    hardhat_config = read_file(deployer_constants.template_file)
    cfg_template_data = {
        "URL": endpoint
    }
    plan.render_templates(
        config = {
            "hardhat.config.ts": struct(
                template=hardhat_config,
                data=cfg_template_data,
            ),
        },
        name = "config"
    )

    service_config = ServiceConfig(
        image = deployer_constants.node_image,
        files = {
            deployer_constants.static_files_directory_path: "static-files",
            deployer_constants.rendered_file_directory: "config"
        },
        entrypoint = ["/bin/sh", "-c", "mv /static-files/rendered/hardhat.config.ts /static-files/ &&  apk add jq &&  sleep 9999999999"]
    )

    service_response = plan.add_service(name = deployer_constants.service_name, config = service_config)
    plan.exec(service_name = deployer_constants.service_name, recipe = ExecRecipe(command = ["/bin/sh", "-c", "cd static-files && npm install && npm install hardhat && npx hardhat compile"]))

    return service_response

def get_latest_block(plan, current_chain, network_name):
    """
    Function to retrieve the latest block number from the Ethereum network.

    Args:
        plan (Plan): The Kurtosis plan.
        current_chain (str): The current chain.
        network_name (str): The name of the Ethereum network.

    Returns:
        str: The latest block number as a string.
    """
    file_name = "get_block_number.ts"
    params = '{"current_chain":"%s"}' % current_chain

    exec_command = ["/bin/sh", "-c", "cd static-files &&  params='{0}' npx hardhat --network {1} run scripts/{2}".format(params, network_name, file_name)]
    plan.exec(service_name = constants.CONTRACT_DEPLOYMENT_SERVICE_ETHEREUM.service_name, recipe = ExecRecipe(exec_command))

    exec_command = ["/bin/sh", "-c", "cd static-files && cat deployments.json | jq -r .%s.blockNum | tr -d '\n\r'" % current_chain]
    response = plan.exec(service_name = constants.CONTRACT_DEPLOYMENT_SERVICE_ETHEREUM.service_name, recipe = ExecRecipe(exec_command))

    return response["output"]
