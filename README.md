# Sparse Merkle Tree Circuit Verification

## Abstract

This repo offers a toolkit for verifying inclusion in a merkleTree as well as prove exclusion from the tree as well. This repo was created to offer tooling for creating proof of innocence systems where given an address and a list of banned addresses in merkle tree form.

## Installation

Ensure that you have nargo. To install nargo please click this [link](https://noir-lang.org/docs/getting_started/quick_start)

```bash
    Stuffy stuff Goes Here to ensure that ppl can install it. It'll probably be a command like nargo install

```

## Quick Start

To get up and running please use this guide to get it set up.

```rust
    crab code goes here.
```

## API Reference

#### Structs:

- MerkleProof:

  ```rust
  Generic: u32,
  Root: Field,
  Leaf: Field,
  Siblings: [Field;N],
  Is_Left: [Bool; N],

  ```

- Non-Membership Proof:

  ```rust
  Generic: u32,
  Key:Field,
  Left_Key:Field,
  Right_Key:Field,
  Left_Proof:MerkleProof,
  Right_Proof:MerkleProof,

  ```

#### Functions

- verify_membership:

  ```rust

  ```

- verify_non_member:

  ```rust

  ```

- Field_less_than:

  ```rust

  ```

- hash_nodes:

  ```rust

  ```

## Limitations

## Contributions

## License

I dunno, I guess we can do MIT, you can do shit to it, but just make sure its known I did something to this code.
