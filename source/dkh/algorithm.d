module dkh.algorithm;

import std.traits : isFloatingPoint, isIntegral;

/**
Do binary search, pred(l) must be false, pred(r) must be true, and pred must have monotonic

$(D [pred(l) = false, false, ..., false, true, true, ..., pred(r) = true])
    
Returns:
    minimum x, s.t. $(D pred(x) = true)
 */
T binSearch(alias pred, T)(T l, T r) if (isIntegral!T) {
    while (r-l > 1) {
        T md = l + (r-l) / 2;
        if (!pred(md)) l = md;
        else r = md;
    }
    return r;
}

/// ditto
T binSearch(alias pred, T)(T l, T r, int cnt = 60) if (isFloatingPoint!T) {
    foreach (i; 0..cnt) {
        T md = (l+r)/2;
        if (!pred(md)) l = md;
        else r = md;
    }
    return r;
}

///
unittest {
    assert(binSearch!(x => x*x >= 100)(0, 20) == 10);
    assert(binSearch!(x => x*x >= 101)(0, 20) == 11);
    assert(binSearch!(x => true)(0, 20) == 1);
    assert(binSearch!(x => false)(0, 20) == 20);
}

import std.range.primitives;

/// Find minimum
E minimum(alias pred = "a < b", Range, E = ElementType!Range)(Range range, E seed)
if (isInputRange!Range && !isInfinite!Range) {
    import std.algorithm, std.functional;
    return reduce!((a, b) => binaryFun!pred(a, b) ? a : b)(seed, range);
}

/// ditto
ElementType!Range minimum(alias pred = "a < b", Range)(Range range) {
    assert(!range.empty, "minimum: range must not empty");
    auto e = range.front; range.popFront;
    return minimum!pred(range, e);
}

///
unittest {
    assert(minimum([2, 1, 3]) == 1);
    assert(minimum!"a > b"([2, 1, 3]) == 3);
    assert(minimum([2, 1, 3], -1) == -1);
    assert(minimum!"a > b"([2, 1, 3], 100) == 100);
}

/// Find maximum
E maximum(alias pred = "a < b", Range, E = ElementType!Range)(Range range, E seed)
if (isInputRange!Range && !isInfinite!Range) {
    import std.algorithm, std.functional;
    return reduce!((a, b) => binaryFun!pred(a, b) ? b : a)(seed, range);
}

/// ditto
ElementType!Range maximum(alias pred = "a < b", Range)(Range range) {
    assert(!range.empty, "maximum: range must not empty");
    auto e = range.front; range.popFront;
    return maximum!pred(range, e);
}

///
unittest {
    assert(maximum([2, 1, 3]) == 3);
    assert(maximum!"a > b"([2, 1, 3]) == 1);
    assert(maximum([2, 1, 3], 100) == 100);
    assert(maximum!"a > b"([2, 1, 3], -1) == -1);
}

/**
Range that rotate elements.
 */
Rotator!Range rotator(Range)(Range r) {
    return Rotator!Range(r);
}

/// ditto
struct Rotator(Range)
if (isForwardRange!Range && hasLength!Range) {
    size_t cnt;
    Range start, now;
    this(Range r) {
        cnt = 0;
        start = r.save;
        now = r.save;
    }
    this(this) {
        start = start.save;
        now = now.save;
    }
    @property bool empty() const {
        return now.empty;
    }
    @property auto front() const {
        assert(!now.empty);
        import std.range : take, chain;
        return chain(now, start.take(cnt));
    }
    @property Rotator!Range save() {
        return this;
    }
    void popFront() {
        cnt++;
        now.popFront;
    }
}

///
unittest {
    import std.algorithm : equal, cmp;
    import std.array : array;
    int[] a = [1, 2, 3];
    assert(equal!equal(a.rotator, [
        [1, 2, 3],
        [2, 3, 1],
        [3, 1, 2],
    ]));
    int[] b = [3, 1, 4, 1, 5];
    assert(equal(b.rotator.maximum!"cmp(a, b) == -1", [5, 3, 1, 4, 1]));
}
