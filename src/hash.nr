use poseidon::poseidon::bn254::hash_2;

pub fn hash_nodes(left: Field, right: Field) -> Field {
    hash_2([left, right])
}

#[test]
fn test_hash_not_zero() {
    let result = hash_nodes(1, 2);
    assert(result != 0);
}

#[test(should_fail)]
fn test_should_not_be_zero() {
    let result = hash_nodes(1, 1);
    assert(result == 0);
}

#[test]
fn test_get_known_hash() {
    let result = hash_nodes(1, 2);
    println(result);
}
