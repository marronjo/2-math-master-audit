methods {
    function mathMastersTopHalf(uint256) external returns uint256 envfree;
    function solmateTopHalf(uint256) external returns uint256 envfree;
}

rule testTopHalfMathMastersMatchesSolmateTopHalf(uint256 x) {
    assert(mathMastersTopHalf(x) == solmateTopHalf(x));
}