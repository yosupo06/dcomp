module dcomp.scanner;

class Scanner {
    import std.stdio : File, stdin;
    import std.conv : to;
    import std.range : front, popFront, array, ElementType;
    import std.array : split;
    import std.traits : isSomeChar, isStaticArray, isArray; 
    import std.algorithm : map;
    File f;
    this(File f = stdin) {
        this.f = f;
    }
    string[] buf;
    private bool succ() {
        while (!buf.length) {
            if (f.eof) return false;
            buf = f.readln.split;
        }
        return true;
    }
    private bool readSingle(T)(ref T x) {
        if (!succ()) return false;
        static if (isArray!T) {
            alias E = ElementType!T;
            static if (isSomeChar!E) {
                //string or char[10] etc
                x = buf.front;
                buf.popFront;
            } else {
                static if (isStaticArray!T) {
                    //static
                    assert(buf.length == T.length);
                }
                x = buf.map!(to!E).array;
                buf.length = 0;                
            }
        } else {
            x = buf.front.to!T;
            buf.popFront;            
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
    assert(equal(b[], [2, 3]));
    assert(equal(c[], "ab"));
    assert(equal(d, "cde"));
    assert(e == 1.0);
    assert(equal(f, [1.0, 2.0]));
}
