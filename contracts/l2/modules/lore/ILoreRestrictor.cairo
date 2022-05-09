# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet

@contract_interface
namespace ILoreRestrictor:
    func approve_creating(account: felt) -> (ok: felt):
    end

    func approve_adding_revision(account: felt) -> (ok: felt):
    end
end
