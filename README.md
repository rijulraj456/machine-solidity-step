> :warning: The Cartesi team keeps working internally on the next version of this repository, following its regular development roadmap. Whenever there's a new version ready or important fix, these are published to the public source tree as new releases.

# Cartesi RISC-V Solidity Emulator

The Cartesi RISC-V Solidity Emulator is the on-chain host implementation of the Cartesi Machine Specification. The libraries and contracts are written in Solidity, the migration script is written in Javascript (with the help of [Truffle](https://github.com/trufflesuite/truffle)), and the testing scripts are written in Python.

For Cartesi's design to work, this implementation must have the exact transition function as the off-chain [Cartesi RISC-V Emulator](https://github.com/cartesi/machine-emulator), meaning that if given the same initial state (s[i]) both implementation's step functions should reach a bit by bit consistent state s[i + 1].

Since the cost of storing a full Cartesi Machine state within the blockchain is prohibitive, all machine states are represented in the blockchain as cryptographic hashes. The contents of those states and memory represented by those hashes are only known off-chain.

Cartesi uses Merkle tree operations and properties to ensure that the blockchain has the ability to correctly verify a state transition without having full state-access. However, the RISC-V Solidity emulator abstracts these operations away and acts as if it knows the full contents of a machine state - it uses the Memory Manager interface to fetch or write any necessary words to memory.

## Memory Manager

The memory manager contract is consumed by the RISC-V Solidity emulator as if the entire state content was available - since the off and on-chain emulators match down to the order in which accesses are logged. When a dispute arises, Alice sends her off-chain state access log referent to the disagreement step to the MemoryManager contract, which will guide the execution of a Step (i.e state transition function).

The MemoryManager contract offers the RISC-V Solidity emulator a very simple interface that consists of:

* read - reads a word in a specific address.
* write - writes a word in a specific address.
* finishReplayPhase - signals that the Step has completed.

It also makes sure that all accesses performed by the Step function match the ones provided by Alice and are consistent with the Merkle proofs provided by her. If that is not the case, Alice loses the dispute.

The real Memory Manager contract can be found at [Arbitration DLib](https://github.com/cartesi/arbitration-dlib). In the present repo we have a MockMemoryManager, that still offers the same interface and makes sure all the proofs are consistent - but it doesn't comply with the Verification Game requirements. It should not be used in production, it doesn't include security measures, it doesn't provide access control and so on. The MockMemoryManager is meant to be used for testing purposes, so that the state transition function can be tested without the need to play a full mock verification game.

## Step function

Step is the previously mentioned state transition function, it is meant to take the machine from state s[i] to state[i + 1], using the memory manager as an assistant. The step function receives a MemoryManager index - which should have been populated with the access log generated by the emulator off-chain and returns an Exit code signaling the result of its execution.

The Step execution usually consists of the following steps:
- Check if machine is halted.
- If not, raise the highest priority interrupt (if there is any to be raised).
- Fetch instruction.
- If Fetch was successful, tries to execute that instruction.
- If Execute was successful updates the number of retired instructions.
- Updated the mcycle.
- End Step.

During a Step execution, every necessary read or write (be it to memory, registers etc) is processed and verified by the MemoryManager at the index provided in the function call.

## Memory Interactor

The Memory Interactor contract is the middleman between the Step and the Memory Manager contracts. It's constructor must receive Memory Manager's address in order to operate on the correct deployed version. The Memory Interactor is responible for correcting the endianess of the information available in Memory Manager. The endianess swap is necessary because  RiscV treats its memory as little-endian while EVM uses big-endian order. The contract is also used to help step take care of partial reads and writes to memory, since Memory Manager only knows how to deal with entire words(64 bits).


## Getting Started

### Install

Install dependencies

    npm install

Compile contracts with

    ./node_modules/.bin/truffle compile

Having a node listening to 8545, you can deploy using

    ./node_modules/.bin/truffle deploy


### Run tests

Run step tests with docker

    docker build . -t cartesi/step-test -f Dockerfile.step
    
    docker run cartesi/step-test

Run ram tests with docker

    docker build . -t cartesi/ram-test -f Dockerfile.ram
    
    docker run cartesi/ram-test


Build main test docker image with aleth

    docker build . -t cartesi/tests

Run step test with docker + aleth

    docker run cartesi/tests

Run sequence test with all files

    docker run -v <hostpath>:/usr/src/app/proofs/ --entrypoint ./machine-test cartesi/test sequence --network Istanbul --contracts-config sequence_contracts.json

Run sequence test with standar input

    cat <jsonfile> | docker run -i --entrypoint ./machine-test cartesi/test sequence --network Istanbul --contracts-config sequence_contracts.json --cin

## Contributing

Thank you for your interest in Cartesi! Head over to our [Contributing Guidelines](CONTRIBUTING.md) for instructions on how to sign our Contributors Agreement and get started with Cartesi!

Please note we have a [Code of Conduct](CODE_OF_CONDUCT.md), please follow it in all your interactions with the project.

## Authors

* *Felipe Argento*

## License
The machine-solidity-step repository and all contributions are licensed under
[APACHE 2.0](https://www.apache.org/licenses/LICENSE-2.0). Please review our [LICENSE](LICENSE) file.


