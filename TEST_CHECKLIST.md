# Sparse Merkle Tree Circuit Test Checklist

Purpose: ensure the ZK circuit correctly proves membership/non-membership for a banned-address tree and fails safely on invalid witnesses.

## 1) Hash Primitive (`hash_nodes`) Tests

- [ ] Determinism: same `(left, right)` always gives the same output.
- [ ] Order sensitivity: verify `hash_nodes(a, b) != hash_nodes(b, a)` (if your design is ordered).
- [ ] Distinct inputs: several different input pairs produce different outputs.
- [ ] Non-triviality: known simple inputs do not always map to `0`.
- [ ] Regression vectors: pin at least 3-5 fixed input/output vectors to catch accidental changes.

## 2) Leaf Encoding Tests

- [ ] Canonical leaf encoding for addresses is defined and tested.
- [ ] Same address encoded twice yields identical leaf hash.
- [ ] Different addresses produce different leaf hashes.
- [ ] Boundary addresses tested (e.g., `0x00..00`, `0xFF..FF`, and one random real-looking address).
- [ ] If domain separators are used (recommended), test they are applied correctly.

## 3) Membership Proof Tests (`membership.nr`)

- [ ] Valid membership proof succeeds for a known banned address.
- [ ] Wrong root causes proof verification to fail.
- [ ] Wrong sibling at one level causes failure.
- [ ] Wrong path index/bit at one level causes failure.
- [ ] Wrong leaf value (different address) causes failure.
- [ ] Test at minimum depth and a deeper realistic depth.

## 4) Non-Membership Proof Tests (`non_member.nr`)

- [ ] Valid non-membership proof succeeds for a known non-banned address.
- [ ] Attempting non-membership for an actually banned address fails.
- [ ] Wrong empty-branch/default hash witness fails.
- [ ] Wrong path index/bit causes failure.
- [ ] Wrong root causes failure.
- [ ] Non-membership edge case near occupied neighbor key is covered.

## 5) Sparse Merkle Tree Transition/Consistency Tests (`smt.nr`)

- [ ] Inserting one address updates root to expected value.
- [ ] Inserting same address again is idempotent (or behaves as specified).
- [ ] Inserting two different addresses yields same root regardless of insertion order (if your tree-building semantics require this).
- [ ] Deleting/removing (if supported) restores expected root.
- [ ] Default-empty tree root matches a pinned constant.

## 6) Negative Security Tests (Should Fail)

- [ ] Proof with mismatched public inputs fails.
- [ ] Proof where any witness element is modified by `+1` fails.
- [ ] Proof where path length/depth is inconsistent fails.
- [ ] Proof for one address cannot be replayed for another address.
- [ ] Membership witness cannot be reused as non-membership witness.

## 7) Constraint/Interface Tests (`lib.nr` / entry circuit)

- [ ] Public/private input wiring is correct and tested.
- [ ] Root is public if verifiers must check it externally.
- [ ] Address privacy expectation is tested (private if intended).
- [ ] Circuit rejects malformed input format/size assumptions.

## 8) Integration Tests (End-to-End)

- [ ] Build a small banned set off-circuit, generate witness, verify proof in-circuit.
- [ ] Compare circuit-computed root with off-circuit implementation for same dataset.
- [ ] Test with multiple randomized datasets (property-style smoke tests).
- [ ] Ensure proving/verifying still works at realistic tree depth and witness size.

## 9) Performance/Practicality Checks

- [ ] Prover time measured at target depth.
- [ ] Constraint count tracked and monitored for regressions.
- [ ] Witness generation time tracked.
- [ ] CI test subset runs quickly; full suite runs on schedule/nightly.

## Suggested Priority Order

1. Hash determinism + order tests
2. One valid membership and one valid non-membership test
3. Core failure tests (wrong root, wrong sibling, wrong path bit)
4. Pinned vector tests + edge cases
5. End-to-end and performance checks

## Minimal "Done" Definition

- [ ] At least 1 passing and 3 failing tests for membership.
- [ ] At least 1 passing and 3 failing tests for non-membership.
- [ ] Pinned vectors for hash and empty-tree root.
- [ ] End-to-end test against an independent off-circuit implementation.
