/+ dub.sdl:
    name "A"
    dependency "dcomp" version=">=0.2.2"
+/

import dcomp.scanner;

int main() {
    import std.stdio;
    auto sc = new Scanner();
    int a, b;
    int[] c;
    sc.read(a, b, c);
    writeln(a, b, c);
    return 0;
}