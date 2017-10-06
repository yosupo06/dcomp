module dcomp.scanner;

import dcomp.array;

/**
Scanner 速くはないが遅くもない printf/scanfよりちょっと遅いくらい？
*/
class Scanner {
    import std.stdio : File;
    import std.conv : to;
    import std.range : front, popFront, array, ElementType;
    import std.array : split;
    import std.traits : isSomeChar, isStaticArray, isArray; 
    import std.algorithm : map;
    File f;
    this(File f) {
        this.f = f;
    }
    char[512] lineBuf;
    char[] line;
    private bool succW() {
        import std.range.primitives : empty, front, popFront;
        import std.ascii : isWhite;
        while (!line.empty && line.front.isWhite) {
            line.popFront;
        }
        return !line.empty;
    }
    private bool succ() {
        import std.range.primitives : empty, front, popFront;
        import std.ascii : isWhite;
        while (true) {
            while (!line.empty && line.front.isWhite) {
                line.popFront;
            }
            if (!line.empty) break;
            line = lineBuf[];
            f.readln(line);
            if (!line.length) return false;
        }
        return true;
    }

    private bool readSingle(T)(ref T x) {
        import std.algorithm : findSplitBefore;
        import std.string : strip;
        import std.conv : parse;
        if (!succ()) return false;
        static if (isArray!T) {
            alias E = ElementType!T;
            static if (isSomeChar!E) {
                //string or char[10] etc
                //todo optimize
                auto r = line.findSplitBefore(" ");
                x = r[0].strip.dup;
                line = r[1];
            } else static if (isStaticArray!T) {
                foreach (i; 0..T.length) {
                    bool f = succW();
                    assert(f);
                    x[i] = line.parse!E;
                }
            } else {
                FastAppender!(E[]) buf;
                while (succW()) {
                    buf ~= line.parse!E;
                }
                x = buf.data;
            }
        } else {
            x = line.parse!T;
        }
        return true;
    }
    int read(T, Args...)(ref T x, auto ref Args args) {
        if (!readSingle(x)) return 0;
        static if (args.length == 0) {
            return 1;
        } else {
            return 1 + read(args);
        }
    }
}


///
unittest {
    import std.path : buildPath;
    import std.file : tempDir;
    import std.algorithm : equal;
    import std.stdio : File;
    string fileName = buildPath(tempDir, "kyuridenanmaida.txt");
    auto fout = File(fileName, "w");
    fout.writeln("1 2 3");
    fout.writeln("ab cde");
    fout.writeln("1.0 1.0 2.0");
    fout.close;
    Scanner sc = new Scanner(File(fileName, "r"));
    int a;
    int[2] b;
    char[2] c;
    string d;
    double e;
    double[] f;
    sc.read(a, b, c, d, e, f);
    assert(a == 1);
    assert(equal(b[], [2, 3])); // 配列型は行末まで読み込む
    assert(equal(c[], "ab")); // char型配列はトークンをそのまま返す
    assert(equal(d, "cde")); // stringもchar型配列と同様
    assert(e == 1.0); // 小数も可
    assert(equal(f, [1.0, 2.0]));
    assert(sc.read(a) == 0); // EOF
}

unittest {
    import std.path : buildPath;
    import std.file : tempDir;
    import std.algorithm : equal;
    import std.stdio : File, writeln;
    import std.datetime;
    string fileName = buildPath(tempDir, "kyuridenanmaida.txt");
    auto fout = File(fileName, "w");
    foreach (i; 0..1_000_000) {
        fout.writeln(3*i, " ", 3*i+1, " ", 3*i+2);
    }
    fout.close;
    writeln("Scanner Speed Test(3*1,000,000 int)");
    StopWatch sw;
    sw.start;
    Scanner sc = new Scanner(File(fileName, "r"));
    foreach (i; 0..500_000) {
        int a, b, c;
        sc.read(a, b, c);
        assert(a == 3*i);
        assert(b == 3*i+1);
        assert(c == 3*i+2);
    }
    foreach (i; 500_000..700_000) {
        int[3] d;
        sc.read(d);
        int a = d[0], b = d[1], c = d[2];
        assert(a == 3*i);
        assert(b == 3*i+1);
        assert(c == 3*i+2);
    }
    foreach (i; 700_000..1_000_000) {
        int[] d;
        sc.read(d);
        assert(d.length == 3);
        int a = d[0], b = d[1], c = d[2];
        assert(a == 3*i);
        assert(b == 3*i+1);
        assert(c == 3*i+2);
    }
    writeln(sw.peek.msecs, "ms");
}
