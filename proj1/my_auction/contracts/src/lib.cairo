use starknet::{ContractAddress, get_caller_address, get_block_timestamp};

#[starknet::interface]
pub trait IAuction<TContractState> {
    fn place_bid(ref self: TContractState, bid_amount: u64);

    fn end_auction(ref self: TContractState);

    fn highest_bidder(ref self: TContractState) -> ContractAddress;

    fn highest_bid(ref self: TContractState) -> u64;
}

#[starknet::contract]
pub mod Auction {
    use starknet::ContractAddress;
    use super::{get_caller_address, get_block_timestamp};
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        end_time: u64,
        owner: ContractAddress,
        initial_price: u64,
        highest_bidder: ContractAddress,
        highest_bid: u64,
        nft_contract: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        placeBid: placeBid,
        endAuction: endAuction,
    }

    #[derive(Drop, starknet::Event)]
    pub struct placeBid {
        pub bidder: ContractAddress,
        pub amount: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct endAuction {
        pub winner: ContractAddress,
        pub amount: u64,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        initial_price: u64,
        duration: u64,
        nft_contract: ContractAddress
    ) {
        let now = get_block_timestamp();

        self.end_time.write(now + duration);
        self.owner.write(owner);
        self.initial_price.write(initial_price);
        self.nft_contract.write(nft_contract);
    }


    #[abi(embed_v0)]
    impl AuctionImpl of super::IAuction<ContractState> {
        fn place_bid(ref self: ContractState, bid_amount: u64) {
            // auction must be done within the alloted time
            assert(get_block_timestamp() < self.end_time.read(), 'Auction Ended');
            // bidders must place amount higher that the current bidder amount
            assert(bid_amount > self.highest_bid.read(), 'bid_amount < highest');

            // the person calling this function becomes a bidder
            let bidder = get_caller_address();

            self.highest_bidder.write(bidder);
            self.highest_bid.write(bid_amount);

            self.emit(placeBid { bidder, amount: bid_amount });
        }

        fn end_auction(ref self: ContractState) {
            assert(get_caller_address() == self.owner.read(), 'Not authorized');
            assert(get_block_timestamp() >= self.end_time.read(), 'Auction still ongoing');

            let winner = self.highest_bidder.read();
            let amount = self.highest_bid.read();

            self.emit(endAuction { winner, amount });
        }

        fn highest_bidder(ref self: ContractState) -> ContractAddress {
            self.highest_bidder.read()
        }

        fn highest_bid(ref self: ContractState) -> u64 {
            self.highest_bid.read()
        }
    }
}
