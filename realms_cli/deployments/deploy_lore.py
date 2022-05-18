from realms_cli.caller_invoker import wrapped_send
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
import time

def run(nre):

    config = Config(nre.network)

    # logged_deploy(
    #     nre,
    #     "Lore",
    #     alias="Lore",
    #     arguments=[],
    # )

    # module, _ = safe_load_deployment("Lore", "goerli")

    # logged_deploy(
    #     nre,
    #     "PROXY_Logic",
    #     alias="proxy_Lore",
    #     arguments=[strhex_as_strfelt(module)],
    # )

    # print('🕒 Waiting for deploy before invoking')
    # time.sleep(180) 

    # set module access within realms access
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Lore",
        function="initializer",
        arguments=[strhex_as_strfelt(config.ADMIN_ADDRESS)]
    )