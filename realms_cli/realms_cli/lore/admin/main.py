# First, import click dependency
import click

from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.shared import uint
from realms_cli.deployer import logged_deploy


@click.command()
@click.argument("kinds", nargs=-1)
@click.option("--network", default="goerli")
def whitelist_kinds(kinds, network):
    """
    Add a kind/(s) to lore whitelist
    """
    config = Config(nile_network=network)
    n_kinds = len(kinds)

    approved_kinds = []
    for kind in kinds:
        approved_kinds.append(kind)
        approved_kinds.append("1")

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Lore",
        function="whitelist_kinds",
        arguments=[n_kinds, *approved_kinds],
    )

@click.command()
@click.argument("pois", nargs=-1)
@click.option("--network", default="goerli")
def whitelist_pois(pois, network):
    """
    Add a kind/(s) to lore whitelist
    """
    config = Config(nile_network=network)
    n_pois = len(pois)

    approved_pois = []
    for poi in pois:
        approved_pois.append(poi)
        approved_pois.append("1")

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Lore",
        function="whitelist_pois",
        arguments=[n_pois, *approved_pois],
    )

@click.command()
@click.argument("props", nargs=-1)
@click.option("--network", default="goerli")
def whitelist_props(props, network):
    """
    Add a kind/(s) to lore whitelist
    """
    config = Config(nile_network=network)
    n_props = len(props)

    approved_props = []
    for prop in props:
        approved_props.append(prop)
        approved_props.append("1")

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Lore",
        function="whitelist_kinds",
        arguments=[n_props, *approved_props],
    )
