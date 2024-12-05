use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address
};
use auction_contract::{IAuctionDispatcher, IAuctionDispatcherTrait, Auction};

const INITIAL_PRICE: u64 = 100;
const AUCTION_DURATION: u64 = 3600;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let owner = contract_address_const::<0x123456789>();
    let nft_contract = contract_address_const::<0x123626789>();

    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(owner.into());
    constructor_calldata.append(INITIAL_PRICE.into());
    constructor_calldata.append(AUCTION_DURATION.into());
    constructor_calldata.append(nft_contract.into());

    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    contract_address
}

#[test]
fn test_constructor() {
    let contract_address = deploy_contract("Auction");

    let auction_contract = IAuctionDispatcher { contract_address };

    let highest_bid = auction_contract.highest_bid();

    assert(highest_bid != INITIAL_PRICE, 'wrong highest bid');
}

#[test]
fn test_place_bid() {
    let contract_address = deploy_contract("Auction");
    let auction_contract = IAuctionDispatcher { contract_address };

    let bidder1 = contract_address_const::<0x123450011>();
    let bidder2 = contract_address_const::<0x123450022>();

    // First bid
    start_cheat_caller_address(contract_address, bidder1);
    auction_contract.place_bid(150);
    stop_cheat_caller_address(contract_address);

    assert(auction_contract.highest_bid() == 150, 'First bid failed');
    assert(auction_contract.highest_bidder() == bidder1, 'Incorrect highest bidder');

    // Higher bid from another bidder(bidder2)
    start_cheat_caller_address(contract_address, bidder2);
    auction_contract.place_bid(200);
    stop_cheat_caller_address(contract_address);

    assert(auction_contract.highest_bid() == 200, 'Second bid failed');
    assert(auction_contract.highest_bidder() == bidder2, 'Incorrect highest bidder');
}

