# noir-sparse-merkle

A Noir library for verifying Sparse Merkle Tree membership and non-membership proofs. Built for privacy applications like Proof of Innocence systems, where you need to prove an address is NOT on a sanctions list without revealing which address you're checking.

## Why This Exists

Merkle trees are the backbone of every privacy protocol. Noir's stdlib has basic Merkle proof support but no sparse variant and no non-membership proofs. Non-membership proofs are critical for exclusion lists: "prove my UTXO is NOT in the sanctioned set" without revealing which UTXO. This library fills that gap.

## Installation

Requires [nargo](https://noir-lang.org/docs/getting_started/quick_start) (tested with v1.0.0-beta.20).

Add to your `Nargo.toml`:

```toml
[dependencies]
noir_sparse_merkle = { tag = "v0.1.0", git = "https://github.com/ie2173/noir-sparse-merkle" }
```

You also need the Poseidon dependency:

```toml
poseidon = { tag = "v0.3.0", git = "https://github.com/noir-lang/poseidon" }
```

## Quick Start

### Membership Proof

```noir
use noir_sparse_merkle::smt::MerkleProof;
use noir_sparse_merkle::membership::verify_membership;

fn main(
    root: Field,
    leaf: Field,
    siblings: [Field; 3],
    is_left: [bool; 3],
) {
    let proof = MerkleProof {
        root,
        leaf,
        siblings,
        is_left,
    };
    verify_membership(proof);
    // circuit passes if proof is valid, fails otherwise
}
```

### Non-Membership Proof

```noir
use noir_sparse_merkle::smt::{MerkleProof, NonMembershipProof};
use noir_sparse_merkle::non_member::non_membership_proof;

fn main(
    root: Field,
    key: Field,
    left_key: Field,
    right_key: Field,
    left_siblings: [Field; 3],
    left_is_left: [bool; 3],
    right_siblings: [Field; 3],
    right_is_left: [bool; 3],
) {
    let left_proof = MerkleProof {
        root,
        leaf: left_key,
        siblings: left_siblings,
        is_left: left_is_left,
    };
    let right_proof = MerkleProof {
        root,
        leaf: right_key,
        siblings: right_siblings,
        is_left: right_is_left,
    };
    let proof = NonMembershipProof {
        key,
        left_key,
        right_key,
        left_proof,
        right_proof,
    };
    non_membership_proof(proof, root);
    // circuit passes if key is provably absent, fails otherwise
}
```

## API Reference

### Structs

#### `MerkleProof<let N: u32>`

Represents a membership proof for a single leaf in the tree.

| Field | Type | Description |
|-------|------|-------------|
| `root` | `Field` | The Merkle root to verify against |
| `leaf` | `Field` | The leaf value being proven |
| `siblings` | `[Field; N]` | Sibling hashes along the path from leaf to root |
| `is_left` | `[bool; N]` | Path direction at each level (`true` = sibling is on the left) |

#### `NonMembershipProof<let N: u32>`

Represents a proof that a key is absent from a sorted sparse Merkle tree.

| Field | Type | Description |
|-------|------|-------------|
| `key` | `Field` | The key being proven absent |
| `left_key` | `Field` | The largest key in the tree smaller than `key` |
| `right_key` | `Field` | The smallest key in the tree larger than `key` |
| `left_proof` | `MerkleProof<N>` | Membership proof for `left_key` |
| `right_proof` | `MerkleProof<N>` | Membership proof for `right_key` |

### Functions

#### `verify_membership<let N: u32>(proof: MerkleProof<N>)`

Verifies that a leaf is included in a Merkle tree with the given root. Hashes the leaf with each sibling from bottom to top, using `is_left` to determine hash ordering at each level. Asserts the computed root matches `proof.root`. The circuit fails if the proof is invalid.

**Source:** `src/membership.nr`

#### `non_membership_proof<let N: u32>(proof: NonMembershipProof<N>, root: Field)`

Verifies that a key is NOT in a sorted sparse Merkle tree. Checks that:
1. Both `left_key` and `right_key` are valid members of the tree (via `verify_membership`)
2. Both membership proofs verify against the provided `root`
3. Boundary keys are bound to their respective proof leaves
4. `left_key < key < right_key` (the absent key falls between two adjacent leaves)

The circuit fails if any check fails.

**Source:** `src/non_member.nr`

#### `field_less_than<let B: u32>(a: Field, b: Field) -> bool`

Compares two field elements by decomposing them into `B` bits (little-endian via `to_le_bits`) and comparing from the most significant bit downward. Returns `true` if `a < b`.

Common bit widths:
- `field_less_than::<160>(a, b)` for Ethereum addresses (20 bytes)
- `field_less_than::<256>(a, b)` for Solana public keys (32 bytes)
- `field_less_than::<64>(a, b)` for small key spaces

**Source:** `src/non_member.nr`

#### `hash_nodes(left: Field, right: Field) -> Field`

Poseidon BN254 hash of two field elements. Used internally for all Merkle tree hashing. Wraps `poseidon::poseidon::bn254::hash_2`.

**Source:** `src/hash.nr`

## Test Fixture Generator

A Rust script in `scripts/` builds sorted sparse Merkle trees and exports proofs as JSON fixtures for Noir tests.

```bash
cd scripts
cargo run
```

Fixtures are written to `scripts/fixtures/`. The Rust Poseidon implementation (`light-poseidon` with `ark-bn254`) has been cross-validated against Noir's to ensure hash compatibility:

```
Poseidon(1, 2) = 0x115cc0f5e7d690413df64c6b9662e9cf2a3617f2743245519e19607a4417189a
```

Both Rust and Noir produce the same output for the same inputs.

### Generating Custom Fixtures

Edit `scripts/src/main.rs` to define your tree and generate proofs:

```rust
let smt = SortedSMT::new(&[10, 30, 50, 70], 3);  // 4 keys, depth 3
let proof = smt.membership_proof(0);                // proof for leaf at index 0
let nm_proof = smt.non_membership_proof(20);        // proof that 20 is absent
```

## Test Coverage

The library includes comprehensive tests for both membership and non-membership proofs:

**Membership:**
- Leftmost, rightmost, and middle leaf verification
- Depth-4 tree with mixed left/right paths
- Failure cases: wrong root, wrong leaf, wrong sibling
- Single-leaf tree, full tree (all positions occupied)
- All `is_left` path combinations exercised

**Non-Membership:**
- Keys absent between adjacent leaves (10<20<30, 30<40<50, 50<60<70)
- Large keys (Ethereum-sized 160-bit values)
- Failure cases: unbound keys, key smaller/larger than all leaves
- Attempting to prove a present key is absent
- Empty tree and single-leaf tree edge cases

Run all tests:

```bash
nargo test
```

## Limitations

- **Key comparison bit width:** `field_less_than` requires specifying the bit width. Keys must fit within the specified number of bits.
- **Sorted tree assumption:** Non-membership proofs assume the tree was built with leaves sorted by key. The circuit does not enforce global sort order; this is the responsibility of the off-chain tree builder.
- **No boundary sentinels:** Non-membership proofs for keys smaller than all leaves or larger than all leaves are not yet supported. The absent key must fall between two existing leaves.
- **No adjacency enforcement:** The circuit does not verify that the two boundary leaves are actually adjacent in the sorted order. An attacker using non-adjacent bounds (e.g., left=10, right=50 to "prove" 30 is absent) would pass the circuit. Adjacency must be enforced by the tree builder or an additional circuit constraint.
- **BN254 only:** Proofs are generated over the BN254 scalar field. On-chain verification requires BN254 pairing support (Ethereum has native precompiles via EIP-196/197).

## Roadmap

- [ ] Boundary sentinel support for edge-case non-membership proofs
- [ ] Adjacency enforcement in non-membership circuit
- [ ] Full 254-bit field comparison (manual bit decomposition)
- [ ] Noir package registry publishing when available
- [ ] Depth-32 benchmark and optimization pass
- [ ] Domain-separated leaf hashing (second preimage resistance)

## Contributing

PRs welcome. If you find a bug or want to add a feature, open an issue first so we can discuss the approach.

## License

MIT License. Do what you want with it, just keep the attribution.
