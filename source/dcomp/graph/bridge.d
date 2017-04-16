module dcomp.graph.bridge;

import dcomp.graph.dfstree;

struct BridgeInfo {
    bool[] isRoot;
    int count; // group count
    int[] id, root; // i to group, group root
    this(int n) {
        isRoot = new bool[n];
        id = new int[n];
    }
}

BridgeInfo bridge(T)(T g) {
    return bridge(g, dfsTree(g));
}

BridgeInfo bridge(T)(T g, DFSTreeInfo info) {
    import std.conv : to;
    int n = g.length.to!int;    
    auto br = BridgeInfo(n);
    
    with (br) with (info) {
        foreach (p; vlis) {
            isRoot[p] = (low[p] == ord[p]);
            if (isRoot[p]) {
                id[p] = count++;
                root ~= ((par[p] == -1) ? -1 : id[par[p]]);
            } else {
                id[p] = id[par[p]];
            }
        }
    }
    return br;
}

unittest {
    import std.algorithm, std.conv, std.stdio;
    import std.random;
    import std.typecons;
    import std.datetime;
    import dcomp.datastructure.unionfind;

    alias E = Tuple!(int, "to");

    writeln("Bridge Random1000");
    void f() {
        //make graph
        int n = uniform(1, 30);
        int m = uniform(1, 200);
        E[][] g = new E[][](n);
        int[2][] edges;
        auto qf = UnionFind(n);
        foreach (i; 0..m) {
            int x = uniform(0, n);
            int y = uniform(0, n);
            edges ~= [x, y];
            g[x] ~= E(y); g[y] ~= E(x);
            qf.merge(x, y);
        }

        //component count
        int connect = (){
            auto qf = UnionFind(n);
            edges.each!(v => qf.merge(v[0], v[1]));
            return qf.count;
        }();

        auto br = bridge(g);
        auto naive = UnionFind(n);
        //nonbridge union
        foreach (i; 0..m) {
            int c = (){
                auto qf = UnionFind(n);
                edges.each!((j, v){if (i != j) qf.merge(v[0], v[1]);});
                return qf.count;
            }();
            if (connect == c) {
                //not bridge
                naive.merge(edges[i][0], edges[i][1]);
            }
        }
        assert(br.count == naive.count);
        foreach (i; 0..n) {
            foreach (j; 0..n) {
                bool same1 = (br.id[i] == br.id[j]);
                bool same2 = naive.same(i, j);
                assert(same1 == same2);
            }
        }
    }
    auto ti = benchmark!f(1000);
    writeln(ti[0].msecs, "ms");
}
