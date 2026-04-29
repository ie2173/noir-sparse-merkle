use crate::hash::hash_nodes;
use crate::membership::verify_membership;
use crate::smt::MerkleProof;
use crate::smt::NonMembershipProof;

pub fn field_less_than<let B: u32>(a: Field, b: Field) -> bool {
    let a_bits: [bool; B] = a.to_le_bits();
    let b_bits: [bool; B] = b.to_le_bits();
    let mut a_less = false;
    let mut decided = false;
    for offset in 0..B {
        let i = B - 1 - offset;
        if !decided {
            if a_bits[i] != b_bits[i] {
                a_less = b_bits[i];
                decided = true;
            }
        }
    }
    a_less
}

pub fn non_membership_proof<let N: u32>(proof: NonMembershipProof<N>, root: Field) {
    // verify both neighbors are actually in the tree
    verify_membership(proof.left_proof);
    verify_membership(proof.right_proof);

    // both proofs must be against the same root
    assert(proof.left_proof.root == root);
    assert(proof.right_proof.root == root);

    // bind boundary keys to the exact leaves that were proven
    assert(proof.left_proof.leaf == proof.left_key);
    assert(proof.right_proof.leaf == proof.right_key);

    // target key falls between the two neighbors
    assert(field_less_than::<160>(proof.left_key, proof.key));
    assert(field_less_than::<160>(proof.key, proof.right_key));
}

#[test]
fn test_field_less_than() {
    assert(field_less_than::<160>(5, 10));
    assert(!field_less_than::<160>(10, 5));
    assert(!field_less_than::<160>(7, 7));
}

#[test(should_fail)]
fn test_field_less_than_fail() {
    assert(field_less_than::<160>(10, 5));
    assert(field_less_than::<160>(7, 7));
}

#[test]
fn test_non_membership_proof() {
    let left_leaf = 10;
    let right_leaf = 20;
    let root = hash_nodes(left_leaf, right_leaf);

    let proof = NonMembershipProof {
        key: 15,
        left_key: left_leaf,
        right_key: right_leaf,
        left_proof: MerkleProof { root, leaf: left_leaf, siblings: [right_leaf], is_left: [false] },
        right_proof: MerkleProof { root, leaf: right_leaf, siblings: [left_leaf], is_left: [true] },
    };
    non_membership_proof(proof, root);
}

// test to see if ethereum 160 bit keys are properly handled by the non-membership proof
#[test]
fn test_non_membership_proof_large_keys() {
    let base: Field = 730750818665451459101842416358141509827966271488;
    let left_leaf = base + 1;
    let right_leaf = base + 10;
    let root = hash_nodes(left_leaf, right_leaf);

    let proof = NonMembershipProof {
        key: base + 5,
        left_key: left_leaf,
        right_key: right_leaf,
        left_proof: MerkleProof { root, leaf: left_leaf, siblings: [right_leaf], is_left: [false] },
        right_proof: MerkleProof { root, leaf: right_leaf, siblings: [left_leaf], is_left: [true] },
    };
    non_membership_proof(proof, root);
}

#[test(should_fail)]
fn test_non_membership_proof_unbound_keys_fail() {
    let left_leaf = 10;
    let right_leaf = 20;
    let root = hash_nodes(left_leaf, right_leaf);

    // left_key does not match left_proof.leaf, so this should fail.
    let proof = NonMembershipProof {
        key: 15,
        left_key: 9,
        right_key: right_leaf,
        left_proof: MerkleProof { root, leaf: left_leaf, siblings: [right_leaf], is_left: [false] },
        right_proof: MerkleProof { root, leaf: right_leaf, siblings: [left_leaf], is_left: [true] },
    };

    non_membership_proof(proof, root);
}

#[test(should_fail)]
fn test_non_membership_key_smaller_than_all_leaves_fail() {
    let left_leaf = 10;
    let right_leaf = 20;
    let root = hash_nodes(left_leaf, right_leaf);

    let proof = NonMembershipProof {
        key: 5,
        left_key: left_leaf,
        right_key: right_leaf,
        left_proof: MerkleProof { root, leaf: left_leaf, siblings: [right_leaf], is_left: [false] },
        right_proof: MerkleProof { root, leaf: right_leaf, siblings: [left_leaf], is_left: [true] },
    };

    non_membership_proof(proof, root);
}

#[test(should_fail)]
fn test_non_membership_key_larger_than_all_leaves_fail() {
    let left_leaf = 10;
    let right_leaf = 20;
    let root = hash_nodes(left_leaf, right_leaf);

    let proof = NonMembershipProof {
        key: 25,
        left_key: left_leaf,
        right_key: right_leaf,
        left_proof: MerkleProof { root, leaf: left_leaf, siblings: [right_leaf], is_left: [false] },
        right_proof: MerkleProof { root, leaf: right_leaf, siblings: [left_leaf], is_left: [true] },
    };

    non_membership_proof(proof, root);
}

#[test(should_fail)]
fn test_non_membership_empty_tree_fail() {
    // Current proof model needs two boundary membership proofs and cannot represent an empty tree.
    let root = 0;

    let proof = NonMembershipProof {
        key: 1,
        left_key: 0,
        right_key: 0,
        left_proof: MerkleProof { root, leaf: 0, siblings: [], is_left: [] },
        right_proof: MerkleProof { root, leaf: 0, siblings: [], is_left: [] },
    };

    non_membership_proof(proof, root);
}

#[test(should_fail)]
fn test_non_membership_single_leaf_tree_fail() {
    // Current proof model expects strict left_key < key < right_key and cannot represent a single-leaf tree.
    let leaf = 10;
    let root = leaf;

    let proof = NonMembershipProof {
        key: 15,
        left_key: leaf,
        right_key: leaf,
        left_proof: MerkleProof { root, leaf, siblings: [], is_left: [] },
        right_proof: MerkleProof { root, leaf, siblings: [], is_left: [] },
    };

    non_membership_proof(proof, root);
}

// -- Fixture-based non-membership tests ---------------------------------------
// Tree: sorted leaves [10, 30, 50, 70] padded to 8 slots, depth 3.
// Root: 0x0d73ba3473aaa35248fc2f3c41a84efad9d95c5d61f9aaa4a02b67d08b3ad04c

// Test 8: key 20 absent - bounded by leaf 10 (index 0) and leaf 30 (index 1)
#[test]
fn test_non_membership_t8_key20_between_10_and_30() {
    let h_10_30 = hash_nodes(10, 30);
    let h_50_70 = hash_nodes(50, 70);
    let h_0_0 = hash_nodes(0, 0);
    let h_right_half = hash_nodes(h_0_0, h_0_0);
    let h_left_half = hash_nodes(h_10_30, h_50_70);
    let root = hash_nodes(h_left_half, h_right_half);

    assert(root == 0x0d73ba3473aaa35248fc2f3c41a84efad9d95c5d61f9aaa4a02b67d08b3ad04c);

    let left_proof = MerkleProof {
        root,
        leaf: 10,
        siblings: [30, h_50_70, h_right_half],
        is_left: [false, false, false],
    };
    let right_proof = MerkleProof {
        root,
        leaf: 30,
        siblings: [10, h_50_70, h_right_half],
        is_left: [true, false, false],
    };
    let proof = NonMembershipProof { key: 20, left_key: 10, right_key: 30, left_proof, right_proof };
    non_membership_proof(proof, root);
}

// Test 9: key 40 absent - bounded by leaf 30 (index 1) and leaf 50 (index 2)
#[test]
fn test_non_membership_t9_key40_between_30_and_50() {
    let h_10_30 = hash_nodes(10, 30);
    let h_50_70 = hash_nodes(50, 70);
    let h_0_0 = hash_nodes(0, 0);
    let h_right_half = hash_nodes(h_0_0, h_0_0);
    let h_left_half = hash_nodes(h_10_30, h_50_70);
    let root = hash_nodes(h_left_half, h_right_half);

    assert(root == 0x0d73ba3473aaa35248fc2f3c41a84efad9d95c5d61f9aaa4a02b67d08b3ad04c);

    let left_proof = MerkleProof {
        root,
        leaf: 30,
        siblings: [10, h_50_70, h_right_half],
        is_left: [true, false, false],
    };
    // index 2 (value 50): right child of (50,70) pair, left child of upper node
    let right_proof = MerkleProof {
        root,
        leaf: 50,
        siblings: [70, h_10_30, h_right_half],
        is_left: [false, true, false],
    };
    let proof = NonMembershipProof { key: 40, left_key: 30, right_key: 50, left_proof, right_proof };
    non_membership_proof(proof, root);
}

// Test 10: key 60 absent - bounded by leaf 50 (index 2) and leaf 70 (index 3)
#[test]
fn test_non_membership_t10_key60_between_50_and_70() {
    let h_10_30 = hash_nodes(10, 30);
    let h_50_70 = hash_nodes(50, 70);
    let h_0_0 = hash_nodes(0, 0);
    let h_right_half = hash_nodes(h_0_0, h_0_0);
    let h_left_half = hash_nodes(h_10_30, h_50_70);
    let root = hash_nodes(h_left_half, h_right_half);

    assert(root == 0x0d73ba3473aaa35248fc2f3c41a84efad9d95c5d61f9aaa4a02b67d08b3ad04c);

    let left_proof = MerkleProof {
        root,
        leaf: 50,
        siblings: [70, h_10_30, h_right_half],
        is_left: [false, true, false],
    };
    let right_proof = MerkleProof {
        root,
        leaf: 70,
        siblings: [50, h_10_30, h_right_half],
        is_left: [true, true, false],
    };
    let proof = NonMembershipProof { key: 60, left_key: 50, right_key: 70, left_proof, right_proof };
    non_membership_proof(proof, root);
}

// Test 13: should_fail - attempt to prove key 30 is absent when 30 IS in the tree.
// Using left_key == right_key == 30 so the ordering constraint (30 < 30) fails.
// NOTE: if an attacker instead used non-adjacent bounds like left=10, right=50, the current
// circuit would accept the proof - adjacency is not enforced. This is a known limitation.
#[test(should_fail)]
fn test_non_membership_t13_present_key_fails() {
    let h_10_30 = hash_nodes(10, 30);
    let h_50_70 = hash_nodes(50, 70);
    let h_0_0 = hash_nodes(0, 0);
    let h_right_half = hash_nodes(h_0_0, h_0_0);
    let h_left_half = hash_nodes(h_10_30, h_50_70);
    let root = hash_nodes(h_left_half, h_right_half);

    // Claim 30 is absent with left_key = right_key = 30. field_less_than(30, 30) == false.
    let left_proof = MerkleProof {
        root,
        leaf: 30,
        siblings: [10, h_50_70, h_right_half],
        is_left: [true, false, false],
    };
    let right_proof = MerkleProof {
        root,
        leaf: 30,
        siblings: [10, h_50_70, h_right_half],
        is_left: [true, false, false],
    };
    let proof = NonMembershipProof { key: 30, left_key: 30, right_key: 30, left_proof, right_proof };
    non_membership_proof(proof, root);
}
