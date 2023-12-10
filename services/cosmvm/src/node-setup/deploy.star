# Import the required modules and constants
constants = import_module("../../../../package_io/constants.star")
node_details = constants.node_details

def deploy(plan, chain_name, chain_id, chain_key, contract_name, message, service_name):
    """
    Deploy a contract on a cosmos supported node.

    Args:
        plan (Plan): The Kurtosis plan.
        chain_id (str): The chain ID.
        chain_key (str): The chain key.
        contract_name (str): The name of the contract to deploy.
        message (str): The message to pass during contract deployment.
        service_name (str): The name of the Neutron node service.
        chain_name (str): The name of the blockchain network.

    Returns:
        str: The contract address.
    """

    # Define the contract file path
    contract = node_details[chain_name]["contract_path"].format(contract_name)
    path = node_details[chain_name]["path"].format(chain_id)

    # Execute a command to store the contract on the chain and retrieve the code ID
    retrieveID_cmd =  "{0} tx wasm store  {1} --from  {2} {3} --keyring-backend test --chain-id {4} --gas auto --gas-adjustment 1.3 -y --output json -b block | jq -r '.logs[0].events[-1].attributes[1].value' > code_id.json "
    plan.exec(
        service_name = service_name, 
        recipe = ExecRecipe(
            command = ["/bin/sh", "-c", retrieveID_cmd.format(node_details[chain_name]["cmd_keyword"], contract, chain_key, path, chain_id)]
        )
    )
    code_id = plan.exec(service_name = service_name, recipe = ExecRecipe(command = ["/bin/sh", "-c", "cat code_id.json | tr -d '\n\r' "]))

    # Instantiate the contract
    instantiate_cmd = "{0} tx wasm instantiate {1} '{2}' --from {3} {4} --keyring-backend test --label {5} --chain-id {6} --no-admin --gas auto --gas-adjustment 1.3 -y -b block | tr -d '\n\r' "
    plan.print("Instantiating the contract")
    exec = ExecRecipe(
        command = ["/bin/sh", "-c", instantiate_cmd.format(node_details[chain_name]["cmd_keyword"], code_id["output"], message, chain_key, path, contract_name, chain_id)]
    )
    plan.exec(service_name = service_name, recipe = exec)

    # Getting the contract address
    contract = plan.exec(service_name = service_name, recipe = ExecRecipe(command = ["/bin/sh", "-c", "%s query wasm list-contract-by-code %s --output json | jq -r '.contracts[-1]' | tr -d '\n\r' " % (node_details[chain_name]["cmd_keyword"], code_id["output"])]))

    return contract["output"]