#[starknet::interface]
trait ICounter<T> {
    fn get_counter(self: @T) -> usize;
    fn increase_counter(ref self: T);
    fn decrease_counter(ref self: T);
    fn reset_counter(ref self: T);
}

#[starknet::contract]
mod Counter {
    use OwnableComponent::InternalTrait;
    use starknet::event::EventEmitter;
    use super::ICounter;
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use openzeppelin_access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        counter: u32,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CounterIncreased: CounterIncreased,
        CounterDecreased: CounterDecreased,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        counter: u32
    }
    
    #[derive(Drop, starknet::Event)]
    struct CounterDecreased {
        counter: u32
    }

    pub mod Errors {
        pub const NEGATIVE_COUNTER: felt252 = 'Counter can\'t be negative';
    }


    #[constructor]
    fn constructor(ref self: ContractState, init_value: u32, owner: ContractAddress) {
        self.counter.write(init_value);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl CounterImpl of ICounter<ContractState>{
        fn get_counter(self: @ContractState) -> u32 {
           self.counter.read()

        }

        fn increase_counter(ref self: ContractState) {
            let old_count = self.counter.read();
            let increase_count = old_count + 1;
            self.counter.write(increase_count);
            self.emit(CounterDecreased {counter: increase_count})
        }

        fn decrease_counter (ref self: ContractState) {
            let old_count = self.counter.read();
            assert(old_count > 0, Errors::NEGATIVE_COUNTER);
            let decrease_count = old_count - 1;
            self.counter.write(decrease_count);
            self.emit(CounterDecreased {counter: decrease_count})
        }

        fn reset_counter(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.counter.write(0)
        }
    }

}
