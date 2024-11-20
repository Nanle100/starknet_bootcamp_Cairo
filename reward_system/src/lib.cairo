use starknet::ContractAddress;
#[starknet::interface]
pub trait IRewardSystem<TContractState> {
    // Function to add points to a user's balance
    fn add_points(ref self: TContractState, user: ContractAddress, amount: u32);

    // Function to redeem points from a user's balance
    fn redeem_points(ref self: TContractState, user: ContractAddress, amount: u32);
}

#[starknet::contract]
mod RewardSystem {
    use starknet::storage::{Map};
    use starknet::ContractAddress;

    // Define the storage for user balances
    // The key is the user identifier (felt252), and the value is the balance (felt252)
    #[storage]
    pub struct Storage {
        pub balances: Map<ContractAddress, u32>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        PointsAdded: PointsAdded,
        PointsRedeemed: PointsRedeemed,
        InsufficientBalance: InsufficientBalance
    }
    
// // event to signal that a point has been added

 #[derive(Drop, starknet::Event)]
 pub struct PointsAdded {
    pub user: ContractAddress,
    pub amount: u32
 }

// event to signal that a point has been redeemed
 #[derive(Drop, starknet::Event)]
pub struct PointsRedeemed {
    pub user: ContractAddress,
    pub amount: u32
}

// event to signal insufficient amount of points
#[derive(Drop, starknet::Event)]
pub struct InsufficientBalance {
    pub user: ContractAddress,
    pub requested_amount: u32,
    pub available_balance: u32,
}

 
#[abi(embed_v0)]
    impl RewardSystem of super::IRewardSystem<ContractState> {
         // Function to add points to a user's balance
    fn add_points(ref self: ContractState, user: ContractAddress, amount: u32) {
        let current_balance = self.balances.read(user);  // Default to 0 if user doesn't have an entry
        let new_balance = current_balance + amount;

        // Update the user's balance
        self.balances.write(user, new_balance);

        // Emit the PointsAdded event
        self.emit(PointsAdded { user, amount});

       }

       // Function to redeem points from a user's balance
    
        fn redeem_points(ref self: ContractState, user: ContractAddress, amount: u32) {
           let current_balance = self.balances.read(user);
           if current_balance >= amount {
               let new_balance = current_balance - amount;

               self.balances.write(user, new_balance);
               self.emit(PointsRedeemed { user, amount});

           } else {
            self.emit(InsufficientBalance { user, requested_amount: amount, available_balance: current_balance });

           }
       }



    }

}