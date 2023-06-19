contract_deployment_service = import_module("github.com/hugobyte/chain-package/services/jvm/icon/src/node-setup/contract_deploy.star")
node_service = import_module("github.com/hugobyte/chain-package/services/jvm/icon/src/node-setup/setup_icon_node.star")

def deploy_bmc(plan,args):
    plan.print("Deploying BMC Contract")

    icon_config = args["chains"]["icon"]


    init_message = '{"_net":"%s"}' % icon_config["network"]

    tx_hash = contract_deployment_service.deploy_contract(plan,"bmc",init_message,icon_config)

    service_name = icon_config["service_name"]
    

    score_address = contract_deployment_service.get_score_address(plan,service_name,tx_hash)

    return score_address


def deploy_xcall(plan,bmc_address,args):

    plan.print("Deploying xCall Contract")

    icon_config = args["chains"]["icon"]

    init_message = '{"_bmc":"%s"}' % bmc_address

    tx_hash = contract_deployment_service.deploy_contract(plan,"xcall",init_message,icon_config)
    service_name = icon_config["service_name"]

    score_address = contract_deployment_service.get_score_address(plan,service_name,tx_hash)

    add_service(plan,bmc_address,score_address,args)

    return score_address   


def add_service(plan,bmc_address,xcall_address,args):

    plan.print("Adding xcall  to Bmc %s " % bmc_address)

    icon_config = args["chains"]["icon"]
    service_name = icon_config["service_name"]
    uri = icon_config["endpoint"]
    keystorepath = icon_config["keystore_path"]
    keypassword = icon_config["keypassword"]
    nid = icon_config["nid"]

    method = "addService"
    params = '{"_svc":"xcall","_addr":"%s"}' % xcall_address

    exec_command = ["./bin/goloop","rpc","sendtx","call","--to",bmc_address,"--method",method,"--params",params,"--uri",uri,"--key_store",keystorepath,"--key_password",keypassword,"--step_limit","50000000000","--nid",nid]

    plan.print(exec_command)
    result = plan.exec(service_name=service_name,recipe=ExecRecipe(command=exec_command))

    tx_hash = result["output"].replace('"',"")


    tx_result = node_service.get_tx_result(plan,service_name,tx_hash,uri)

    plan.assert(value=tx_result["extract.status"],assertion="==",target_value="0x1")



 
def open_btp_network(plan,service_name,src,dst,bmc_address,uri,keystorepath,keypassword,nid):
    plan.print("Opening BTP Network")

    last_block_height = node_service.get_last_block(plan,service_name)

    network_name = "{0}-{1}".format(dst,last_block_height)

    args = {"name":network_name,"owner":bmc_address}


    result = node_service.open_btp_network(plan,service_name,args,uri,keystorepath,keypassword,nid)

    return result



# def deploy_bmv_btpblock_java(plan,service_name,bmc_address,src_network_id,network_type_id,block_header,args):

#     network_id = args["network_id"]

#     first_block_header = get_first_btpblock_header(plan,service_name,network_id)
#     src_btp_network_info = get_btp_network_info(plan,icon_service_name,icon_nid)

#     src_first_block_header = icon_setup_node.get_btp_header(plan,icon_service_name,icon_nid,src_btp_network_info)
#     init_message = {
#       "bmc": bmc_address,
#       "srcNetworkID": src_network_id,
#       "networkTypeID": network_type_id,
#       "blockHeader": first_block_header,
#       "seqOffset": "0x0"
#     }

#     tx_hash = contract_deployment_service.deploy_contract(plan,service_name,"bmv-btpblock",init_message,args)

#     score_address = contract_deployment_service.get_score_address(plan,service_name,tx_hash)

#     plan.print("BMV-BTPBlock: deployed ")

#     return score_address

def deploy_bmv_bridge_java(plan,service_name,bmc_address,dst_network,offset,args):

    init_message = '{"_bmc": "%s","_net": "%s","_offset": "%s"}' %(bmc_address,dst_network,offset)

    tx_hash = contract_deployment_service.deploy_contract(plan,"bmv-bridge",init_message,args)

    score_address = contract_deployment_service.get_score_address(plan,service_name,tx_hash)

    plan.print("BMV-BTPBlock: deployed ")

    return score_address

def add_verifier(plan,service_name,bmc_address,dst_chain_network,bmv_address,uri,keystorepath,keypassword,nid):

    method = "addVerifier"
    params = '{"_net":"%s","_addr":"%s"}' % (dst_chain_network,bmv_address)

    exec_command = ["./bin/goloop","rpc","sendtx","call","--to",bmc_address,"--method",method,"--params",params,"--uri",uri,"--key_store",keystorepath,"--key_password",keypassword,"--step_limit","50000000000","--nid",nid]

    plan.print(exec_command)
    result = plan.exec(service_name=service_name,recipe=ExecRecipe(command=exec_command))

    tx_hash = result["output"].replace('"',"")


    tx_result = node_service.get_tx_result(plan,service_name,tx_hash,uri)

    plan.assert(value=tx_result["extract.status"],assertion="==",target_value="0x1")

    return tx_result


def add_btp_link(plan,service_name,bmc_address,dst_bmc_address,src_network_id,uri,keystorepath,keypassword,nid):

    method = "addBTPLink"

    params = '{"_link":"%s","_networkId":"%s"}' %(dst_bmc_address,src_network_id)

    exec_command = ["./bin/goloop","rpc","sendtx","call","--to",bmc_address,"--method",method,"--params",params,"--uri",uri,"--key_store",keystorepath,"--key_password",keypassword,"--step_limit","50000000000","--nid",nid]

    plan.print(exec_command)
    result = plan.exec(service_name=service_name,recipe=ExecRecipe(command=exec_command))

    tx_hash = result["output"].replace('"',"")


    tx_result = node_service.get_tx_result(plan,service_name,tx_hash,uri)

    plan.assert(value=tx_result["extract.status"],assertion="==",target_value="0x1")

    return tx_result


def add_relay(plan,service_name,bmc_address,dst_bmc_address,relay_address,uri,keystorepath,keypassword,nid):

    method = "addRelay"
    params = '{"_link":"%s","_addr":"%s"}' % (dst_bmc_address,relay_address)

    exec_command = ["./bin/goloop","rpc","sendtx","call","--to",bmc_address,"--method",method,"--params",params,"--uri",uri,"--key_store",keystorepath,"--key_password",keypassword,"--step_limit","500000000000","--nid",nid]

    result = plan.exec(service_name=service_name,recipe=ExecRecipe(command=exec_command))

    tx_hash = result["output"].replace('"',"")


    tx_result = node_service.get_tx_result(plan,service_name,tx_hash,uri)

    plan.assert(value=tx_result["extract.status"],assertion="==",target_value="0x1")


    return tx_result


def setup_link_icon(plan,service_name,bmc_address,dst_chain_network,dst_chain_bmc_address,src_chain_network_id,bmv_address,relay_address,args):

    dst_bmc_address = get_btp_address(dst_chain_network,dst_chain_bmc_address)

    plan.print(dst_bmc_address)

    icon_config_data = args["chains"]["icon"]

    uri = icon_config_data["endpoint"]
    keystorepath = icon_config_data["keystore_path"]
    keypassword = icon_config_data["keypassword"]
    nid = icon_config_data["nid"]

    response = add_verifier(plan,service_name,bmc_address,dst_chain_network,bmv_address,uri,keystorepath,keypassword,nid)

    plan.print(response)

    response = add_btp_link(plan,service_name,bmc_address,dst_bmc_address,src_chain_network_id,uri,keystorepath,keypassword,nid)

    plan.print(response)


    response =  add_relay(plan,service_name,bmc_address,dst_bmc_address,relay_address,uri,keystorepath,keypassword,nid)

    plan.print(response)


    plan.print("Icon Link Setup Completed")

def get_btp_address(network,dapp):

    return "btp://{0}/{1}".format(network,dapp)


def deploy_dapp(plan,xcall_address,args):

    plan.print("Deploying dapp Contract")

    icon_config = args["chains"]["icon"]

    init_message = '{"_callService":"%s"}' % xcall_address

    tx_hash = contract_deployment_service.deploy_contract(plan,"dapp-sample",init_message,icon_config)
    service_name = icon_config["service_name"]

    score_address = contract_deployment_service.get_score_address(plan,service_name,tx_hash)

    return score_address   

