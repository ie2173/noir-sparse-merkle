use crate::hash::hash_nodes;
use crate::smt::MerkleProof;

pub fn verify_membership<let N: u32>(proof: MerkleProof<N>) {
    let mut current_hash = proof.leaf;

    for i in 0..N {
        let sibling = proof.siblings[i];
        if proof.is_left[i] {
            current_hash = hash_nodes(sibling, current_hash);
        } else {
            current_hash = hash_nodes(current_hash, sibling);
        }
    }

    assert(current_hash == proof.root);
}

#[test]
fn test_verify_membership() {
    let leaf = 42;
    let sibling1 = 100;
    let sibling2 = 200;

    let hash1 = hash_nodes(leaf, sibling1);
    let root = hash_nodes(hash1, sibling2);

    let proof = MerkleProof { root, leaf, siblings: [sibling1, sibling2], is_left: [false, false] };

    verify_membership(proof);
}

#[test]
fn test_verify_membership_level_2() {
    let leaf = 42;
    let sibling1 = 100;
    let sibling2 = 200;
    let sibling3 = 300;

    let hash1 = hash_nodes(leaf, sibling1);
    let hash2 = hash_nodes(hash1, sibling2);
    let root = hash_nodes(hash2, sibling3);

    let proof = MerkleProof {
        root,
        leaf,
        siblings: [sibling1, sibling2, sibling3],
        is_left: [false, false, false],
    };

    verify_membership(proof);
}

#[test(should_fail)]
fn test_verify_membership_wrong_level() {
    // if we set n to an incorrect level the verification should fail
    let leaf = 42;
    let sibling1 = 100;
    let sibling2 = 200;

    let hash1 = hash_nodes(leaf, sibling1);
    let root = hash_nodes(hash1, sibling2);

    // This should fail because we are only providing one sibling instead of two
    let proof = MerkleProof { root, leaf, siblings: [sibling1], is_left: [false] };
    verify_membership(proof);
}

#[test(should_fail)]
fn test_verify_membership_wrong() {
    let leaf = 42;
    let sibling1 = 100;
    let sibling2 = 200;

    let hash1 = hash_nodes(leaf, sibling1);
    let root = hash_nodes(hash1, sibling2);

    // This should fail because the leaf is incorrect
    let proof =
        MerkleProof { root, leaf: 43, siblings: [sibling1, sibling2], is_left: [false, false] };
    verify_membership(proof);
}

// -- Fixture-based tests -------------------------------------------------------
// Tree: sorted leaves [10, 30, 50, 70] padded to 8 slots, depth 3.
// Root verified against Rust-generated value:
//   0x0d73ba3473aaa35248fc2f3c41a84efad9d95c5d61f9aaa4a02b67d08b3ad04c

// Test 1: leftmost occupied leaf (index 0, value 10) - all right siblings, path all false
#[test]
fn test_membership_t1_index0_leaf10() {
    let h_10_30 = hash_nodes(10, 30);
    let h_50_70 = hash_nodes(50, 70);
    let h_0_0 = hash_nodes(0, 0);
    let h_right_half = hash_nodes(h_0_0, h_0_0);
    let h_left_half = hash_nodes(h_10_30, h_50_70);
    let root = hash_nodes(h_left_half, h_right_half);

    assert(root == 0x0d73ba3473aaa35248fc2f3c41a84efad9d95c5d61f9aaa4a02b67d08b3ad04c);

    let proof = MerkleProof {
        root,
        leaf: 10,
        siblings: [30, h_50_70, h_right_half],
        is_left: [false, false, false],
    };
    verify_membership(proof);
}

// Test 2: rightmost occupied leaf (index 3, value 70) - path [true, true, false]
#[test]
fn test_membership_t2_index3_leaf70() {
    let h_10_30 = hash_nodes(10, 30);
    let h_50_70 = hash_nodes(50, 70);
    let h_0_0 = hash_nodes(0, 0);
    let h_right_half = hash_nodes(h_0_0, h_0_0);
    let h_left_half = hash_nodes(h_10_30, h_50_70);
    let root = hash_nodes(h_left_half, h_right_half);

    assert(root == 0x0d73ba3473aaa35248fc2f3c41a84efad9d95c5d61f9aaa4a02b67d08b3ad04c);

    let proof = MerkleProof {
        root,
        leaf: 70,
        siblings: [50, h_10_30, h_right_half],
        is_left: [true, true, false],
    };
    verify_membership(proof);
}

// Test 3: middle leaf (index 1, value 30) - mixed path [true, false, false]
#[test]
fn test_membership_t3_index1_leaf30() {
    let h_10_30 = hash_nodes(10, 30);
    let h_50_70 = hash_nodes(50, 70);
    let h_0_0 = hash_nodes(0, 0);
    let h_right_half = hash_nodes(h_0_0, h_0_0);
    let h_left_half = hash_nodes(h_10_30, h_50_70);
    let root = hash_nodes(h_left_half, h_right_half);

    assert(root == 0x0d73ba3473aaa35248fc2f3c41a84efad9d95c5d61f9aaa4a02b67d08b3ad04c);

    let proof = MerkleProof {
        root,
        leaf: 30,
        siblings: [10, h_50_70, h_right_half],
        is_left: [true, false, false],
    };
    verify_membership(proof);
}

// Test 4: depth-4 tree with 8 real leaves [5,15,25,35,45,55,65,75] at index 4 (value 45).
// Path [false, false, true, false] - exercises a true mid-path right-child step.
#[test]
fn test_membership_t4_depth4_index4_leaf45() {
    let h_5_15 = hash_nodes(5, 15);
    let h_25_35 = hash_nodes(25, 35);
    let h_45_55 = hash_nodes(45, 55);
    let h_65_75 = hash_nodes(65, 75);
    let h_0_0 = hash_nodes(0, 0);
    let h_00_00 = hash_nodes(h_0_0, h_0_0); // layer-2 empty quad

    let l2_left = hash_nodes(h_5_15, h_25_35); // layer 2, index 0
    let l2_mid = hash_nodes(h_45_55, h_65_75); // layer 2, index 1
    let l3_left = hash_nodes(l2_left, l2_mid);
    let l3_right = hash_nodes(h_00_00, h_00_00);
    let root = hash_nodes(l3_left, l3_right);

    assert(root == 0x11bf6ae60261f0f6bde6cba7a86a5baa94c5b99c2022daf30a9514d01f6ee832);

    let proof = MerkleProof {
        root,
        leaf: 45,
        siblings: [55, h_65_75, l2_left, l3_right],
        is_left: [false, false, true, false],
    };
    verify_membership(proof);
}

// Test 5: should_fail - valid siblings and leaf but tampered root
#[test(should_fail)]
fn test_membership_t5_wrong_root() {
    let h_10_30 = hash_nodes(10, 30);
    let h_50_70 = hash_nodes(50, 70);
    let h_0_0 = hash_nodes(0, 0);
    let h_right_half = hash_nodes(h_0_0, h_0_0);
    let h_left_half = hash_nodes(h_10_30, h_50_70);
    let real_root = hash_nodes(h_left_half, h_right_half);

    let proof = MerkleProof {
        root: real_root + 1, // corrupted root
        leaf: 10,
        siblings: [30, h_50_70, h_right_half],
        is_left: [false, false, false],
    };
    verify_membership(proof);
}

// Test 6: should_fail - valid proof structure but wrong leaf value
#[test(should_fail)]
fn test_membership_t6_wrong_leaf() {
    let h_10_30 = hash_nodes(10, 30);
    let h_50_70 = hash_nodes(50, 70);
    let h_0_0 = hash_nodes(0, 0);
    let h_right_half = hash_nodes(h_0_0, h_0_0);
    let h_left_half = hash_nodes(h_10_30, h_50_70);
    let root = hash_nodes(h_left_half, h_right_half);

    let proof = MerkleProof {
        root,
        leaf: 11, // real leaf is 10
        siblings: [30, h_50_70, h_right_half],
        is_left: [false, false, false],
    };
    verify_membership(proof);
}

// Test 7: should_fail - valid proof structure but one sibling is wrong
#[test(should_fail)]
fn test_membership_t7_wrong_sibling() {
    let h_10_30 = hash_nodes(10, 30);
    let h_50_70 = hash_nodes(50, 70);
    let h_0_0 = hash_nodes(0, 0);
    let h_right_half = hash_nodes(h_0_0, h_0_0);
    let h_left_half = hash_nodes(h_10_30, h_50_70);
    let root = hash_nodes(h_left_half, h_right_half);

    let proof = MerkleProof {
        root,
        leaf: 10,
        siblings: [31, h_50_70, h_right_half], // siblings[0] should be 30
        is_left: [false, false, false],
    };
    verify_membership(proof);
}

// -- Edge case tests -----------------------------------------------------------

// Test 14: single-leaf tree (depth 1, two slots: [leaf, 0])
#[test]
fn test_membership_t14_single_leaf_tree() {
    let root = hash_nodes(42, 0);

    let proof = MerkleProof { root, leaf: 42, siblings: [0], is_left: [false] };
    verify_membership(proof);
}

// Test 15: full tree - depth 2, all 4 positions occupied with [10, 20, 30, 40].
// Verifies every leaf and exercises all four is_left path combinations:
//   index 0: [false, false]   index 1: [true,  false]
//   index 2: [false, true ]   index 3: [true,  true ]
#[test]
fn test_membership_t15_full_tree_all_leaves() {
    let h_10_20 = hash_nodes(10, 20);
    let h_30_40 = hash_nodes(30, 40);
    let root = hash_nodes(h_10_20, h_30_40);

    let proof_10 = MerkleProof { root, leaf: 10, siblings: [20, h_30_40], is_left: [false, false] };
    let proof_20 = MerkleProof { root, leaf: 20, siblings: [10, h_30_40], is_left: [true, false] };
    let proof_30 = MerkleProof { root, leaf: 30, siblings: [40, h_10_20], is_left: [false, true] };
    let proof_40 = MerkleProof { root, leaf: 40, siblings: [30, h_10_20], is_left: [true, true] };

    verify_membership(proof_10);
    verify_membership(proof_20);
    verify_membership(proof_30);
    verify_membership(proof_40);
}

// Test 16: mixed is_left paths - confirmed by tests 1-4 covering:
//   t1: [false,false,false]  t2: [true,true,false]  t3: [true,false,false]
//   t4: [false,false,true,false]  t15: all four depth-2 combos
// This test adds a path with true at every level to complete coverage.
#[test]
fn test_membership_t16_all_right_children() {
    // Leaf at index 3 of [A, B, C, D] - path [true, true]
    let a: Field = 1;
    let b: Field = 2;
    let c: Field = 3;
    let d: Field = 4;
    let h_ab = hash_nodes(a, b);
    let h_cd = hash_nodes(c, d);
    let root = hash_nodes(h_ab, h_cd);

    // index 3 (value d=4): right child of (c,d), whole (c,d) subtree is right child of root
    let proof = MerkleProof { root, leaf: 4, siblings: [3, h_ab], is_left: [true, true] };
    verify_membership(proof);
}
