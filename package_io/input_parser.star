def generate_new_config_data(links, srcchain_service_name, dst_chain_service_name, bridge):
    config_data = "" 
    if bridge == "":
        config_data = {
        "links": links,
        "chains": {
            "%s" % srcchain_service_name: {},
            "%s" % dst_chain_service_name: {},
        },
        "contracts": {
            "%s" % srcchain_service_name: {},
            "%s" % dst_chain_service_name: {},
        },
        }
    else:

        config_data = {
        "links": links,
        "chains": {
            "%s" % srcchain_service_name: {},
            "%s" % dst_chain_service_name: {},
        },
        "contracts": {
            "%s" % srcchain_service_name: {},
            "%s" % dst_chain_service_name: {},
        },
        "bridge": bridge,
        }

    return config_data



def generate_new_config_data_for_ibc(src_chain, dst_chain, srcchain_service_name, dst_chain_service_name):
    """
    Generate new config data for IBC

    Args:
        src_chain (str): The source chain name.
        dst_chain (str): The destination chain name.
        srcchain_service_name (str): The source chain service name.
        dst_chain_service_name (str): The destination chain service name.

    Returns:
        dict: Configuration data for IBC.
    """
    config_data = {
    "links": {
        "src": "%s" % src_chain,
        "dst": "%s" % dst_chain
    },
    "chains": {
        "%s" % srcchain_service_name: {},
        "%s" % dst_chain_service_name: {},
    },
    "contracts": {
        "%s" % srcchain_service_name: {},
        "%s" % dst_chain_service_name: {},
    },
    }
    
    return config_data


def generate_new_config_data_for_btp(src_chain, dst_chain, srcchain_service_name, dst_chain_service_name, bridge):
    """
    Generate new config data for BTP

    Args:
        src_chain (str): The source chain name.
        dst_chain (str): The destination chain name.
        srcchain_service_name (str): The source chain service name.
        dst_chain_service_name (str): The destination chain service name.
        bridge (str): The type of BTP bridge.

    Returns:
        dict: Configuration data for BTP.
    """
    config_data = "" 
    if bridge == "":
        config_data = {
        "links": {
            "src": "%s" % src_chain,
            "dst": "%s" % dst_chain
        },
        "chains": {
            "%s" % srcchain_service_name: {},
            "%s" % dst_chain_service_name: {},
        },
        "contracts": {
            "%s" % srcchain_service_name: {},
            "%s" % dst_chain_service_name: {},
        },
        }
    else:

        config_data = {
        "links": {
            "src": "%s" % src_chain,
            "dst": "%s" % dst_chain
        },
        "chains": {
            "%s" % srcchain_service_name: {},
            "%s" % dst_chain_service_name: {},
        },
        "contracts": {
            "%s" % srcchain_service_name: {},
            "%s" % dst_chain_service_name: {},
        },
        "bridge": "%s" % bridge
        }

    return config_data



def generate_new_config_data_cosmvm_cosmvm(links, srcchain_service_name, dst_chain_service_name):
    config_data = {
        "links": links,
        "chains": {
            "%s" % srcchain_service_name: {},
            "%s" % dst_chain_service_name: {},
        },
    }

    return config_data


def struct_to_dict(s):
    """
    Convert struct to dict

    Args:
        s (struct): Struct to be converted.

    Returns:
        dict: Struct converted to dict.
    """
    fields = dir(s)
    return {field: getattr(s, field) for field in fields if not field.startswith("_")}