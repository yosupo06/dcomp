module dcomp.numeric.convolution;

/// Zeta変換
T[] zeta(T)(T[] v, bool rev) {
    import core.bitop : bsr;
    int n = bsr(v.length);
    assert(1<<n == v.length);
    foreach (fe; 0..n) {
        foreach (i, _; v) {
            if (i & (1<<fe)) continue;
            if (!rev) {
                v[i] += v[i|(1<<fe)];
            } else {
                v[i] -= v[i|(1<<fe)];
            }
        }
    }
    return v;
}

/// hadamard変換
T[] hadamard(T)(T[] v, bool rev) {
    import core.bitop : bsr;
    int n = bsr(v.length);
    assert(1<<n == v.length);
    foreach (fe; 0..n) {
        foreach (i, _; v) {
            if (i & (1<<fe)) continue;
            auto l = v[i], r = v[i|(1<<fe)];
            if (!rev) {
                v[i] = l+r;
                v[i|(1<<fe)] = l-r;
            } else {
                v[i] = (l+r)/2;
                v[i|(1<<fe)] = (l-r)/2;
            }
        }
    }
    return v;
}
