#[starknet::interface]
pub trait IRewardSystem<TContractState> {
    // Function to add points to a user's balance
    fn add_points(ref self: TContractState, user: felt252, amount: felt252);

    // Function to redeem points from a user's balance
    fn redeem_points(ref self: TContractState, user: felt252, amount: felt252);
}

#[starknet::contract]
mod RewardSystem {
    use starknet::storage::{Map};
    
// // event to signal that a point has been added
#[event]
 #[derive(Drop, starknet::Event)]
 pub struct PointsAdded {
    pub user: felt252,
    pub amount: felt252
 }

// event to signal that a point has been redeemed
#[event]
 #[derive(Drop, starknet::Event)]
pub struct PointsRedeemed {
    pub user: felt252,
    pub amount: felt252
}

// event to signal insufficient amount of points
#[event]
#[derive(Drop, starknet::Event)]
pub struct InsufficientBalance {
    pub user: felt252,
    pub requested_amount: felt252,
    pub available_balance: felt252,
}

 // Define the storage for user balances
    // The key is the user identifier (felt252), and the value is the balance (felt252)
    #[storage]
    pub struct Balances {
        pub balances: Map<felt252, felt252>
    }  

    pub struct Storage {
        pub balances: Balances,
    }

    impl RewardSystem of super::IRewardSystem {
         // Function to add points to a user's balance
    fn add_points(ref self: TContractState, user: felt252, amount: felt252) {
        let current_balance = self.balances.read(user).unwrap_or(0);  // Default to 0 if user doesn't have an entry
        let new_balance = current_balance + amount;

        // Update the user's balance
        self.balances.write(user, new_balance);

        // Emit the PointsAdded event
        PointsAdded { user, amount }.emit();

       }

       // Function to redeem points from a user's balance
    
        fn redeem_points(ref self: TContractState, user: felt252, amount: felt252) {
           let current_balance = self.balances.balances.read(user).unwrap_or(0);
           if current_balance >= amount {
               let new_balance = current_balance - amount;

               self.balances.balances.write(user, new_balance);
               PointsRedeemed { user, amount }.emit();
           } else {
            InsufficientBalance { user, requested_amount: amount, available_balance: current_balance }.emit();

           }
       }



    }

}