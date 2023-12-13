def run(plan, args):

    plan.upload_files(
        src=args["contract_path"],
        name="contracts"
    )

    service_details = plan.add_service(
        name = "foundry",
        config = ServiceConfig(
            image = "ghcr.io/foundry-rs/foundry:latest", 
            files = {
                "/temp/contracts" : "contracts"
            }, 
            entrypoint = ["/bin/sh"]
        ),
    )

    plan.exec(
        service_name = "foundry",
        recipe = ExecRecipe(
            command=["/bin/sh","-c","mkdir foundry-project"]
        ),
    )

    plan.exec(
        service_name = "foundry",
        recipe = ExecRecipe(
            command=["/bin/sh","-c","cd foundry-project && forge init --no-git"]
        ),
    )

    # This recipe will remove contracts and test contracts from initialised foundry-project
    plan.exec(
        service_name = "foundry",
        recipe = ExecRecipe(
            command=["/bin/sh","-c","rm -r /foundry-project/src/* && rm -r /foundry-project/test/*"]
        ),
    )

    # This recipe will copy the user contracts into the foundry-project
    plan.exec(
        service_name = "foundry",
        recipe = ExecRecipe(
            command=["/bin/sh","-c","cp -R ./temp/contracts/* /foundry-project/src/"]
        ),
    )

    # This recipe will build the contract
    plan.exec(
        service_name = "foundry",
        recipe = ExecRecipe(
            command=["/bin/sh","-c","cd foundry-project && forge build"]
        ),
    )

    plan.store_service_files(service_name="foundry", src = "/foundry-project/out", name="contract_artifacts")

    return service_details