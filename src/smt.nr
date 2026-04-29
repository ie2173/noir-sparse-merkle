pub struct MerkleProof<let N: u32> {
    pub root: Field,
    pub leaf: Field,
    pub siblings: [Field; N],
    pub is_left: [bool; N],
}

pub struct NonMembershipProof<let N: u32> {
    pub key: Field,
    pub left_key: Field,
    pub right_key: Field,
    pub left_proof: MerkleProof<N>,
    pub right_proof: MerkleProof<N>,
}
