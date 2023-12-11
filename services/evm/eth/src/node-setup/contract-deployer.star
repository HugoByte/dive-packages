# Import the required constants 
constants = import_module("../../../../../package_io/constants.star")

def deploy_contract(plan, contract_name, params, network_name):
    """
    Deploy Contract to Eth Network

    Args:
        plan (Plan): The Kurtosis plan.
        contract_name (str): The name of the contract to be deployed.
        params (str): The parameters required to deploy the contract.
        network_name (str): The name of the network.
    """
    contract_deployment_file_name = "deploy_{0}.ts".format(contract_name)
    exec_command = ["/bin/sh","-c","cd static-files &&  params='{0}' npx hardhat --network {1} run scripts/{2}".format(params, network_name, contract_deployment_file_name)]
    plan.exec(service_name = constants.CONTRACT_DEPLOYMENT_SERVICE_ETHEREUM.service_name, recipe = ExecRecipe(exec_command))

def get_contract_address(plan, contract_name, chain_type):
    """
    Returns Address of Deployed Contract

    Args:
        plan (Plan): The Kurtosis plan.
        contract_name (str): The name of the contract to be deployed.
        chain_type (str): The name of the chain.

    Returns:
        str: The contract address of the deployed contract.
    """

    exec_command = ["/bin/sh","-c","cd static-files && cat deployments.json | jq -r .%s.contracts.%s | tr -d '\n\r'" % (chain_type, contract_name)]
    response = plan.exec(service_name=constants.CONTRACT_DEPLOYMENT_SERVICE_ETHEREUM.service_name, recipe = ExecRecipe(exec_command))
    return response["output"]



