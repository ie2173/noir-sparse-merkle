# Poseidon Hash Compatibility Verification

This document guides you through verifying that Noir's Poseidon implementation matches the Rust implementation.

## Background

- **Noir**: Uses `poseidon::poseidon::bn254::hash_2([1, 2])` from the poseidon library
- **Rust**: Uses `light-poseidon` crate (or other Poseidon implementations)

Both should produce the same hash for the same inputs if implementations are compatible.

## Test Inputs

We test with the simple inputs: `hash(1, 2)`

This tests basic Poseidon functionality without complex witness data.

## How to Verify Compatibility

### Step 1: Get the Noir Hash

Run the Noir test that prints the hash:

```bash
cd /Users/ianelliott/Documents/cr0wWeb3/zkProject/sparseMerkle
nargo test test_get_known_hash
```

Look for the `println(result)` output showing the hash value.

**Note:** Currently `nargo test` doesn't display println output in test results. As a workaround:

1. Create a circuit that returns the hash as a return value
2. Or manually compute the value by running the hash in a non-test context

### Step 2: Get the Rust Comparison

Run the Rust compatibility test:

```bash
cd scripts
cargo test test_noir_poseidon_compat -- --nocapture
```

This test documents the process for computing the Rust hash using `light-poseidon`.

### Step 3: Compare

Both implementations should produce identical values for `hash_nodes(1, 2)`.

## Manual Comparison Method

If the above doesn't directly show output values, use this method:

1. **Noir side**: Modify [src/hash.nr](src/hash.nr) temporarily to store the hash in a struct field:

```noir
#[test]
fn test_get_known_hash_debug() {
    let result = hash_nodes(1, 2);
    // The result is computed; you can capture it via constraint values
}
```

2. **Rust side**: Use Python + ark-bn254 or a web tool to compute:

```python
# Using poseidon from nomadic-labs or similar
# This is pseudocode - adapt to your chosen library
poseidon_hash = poseidon([1, 2])
print(f"0x{poseidon_hash:064x}")
```

## Expected Outcome

If both hashes match:

- ✅ Implementations are compatible
- ✅ You can trust Noir's Poseidon for your circuit

If they don't match:

- ❌ Check Poseidon parameter differences (field, round constants, etc.)
- ❌ Verify both are using BN254 curve field
- ❌ Check if endianness differs between implementations

## References

- Noir Poseidon Docs: https://noir-lang.org/docs/noir/stdlib/cryptographic_primitives/poseidon
- light-poseidon Crate: https://github.com/privacy-scaling-explorations/light-poseidon
- Poseidon Paper: https://eprint.iacr.org/2019/458.pdf
