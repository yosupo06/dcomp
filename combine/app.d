import std.stdio, std.process, std.exception, std.string, std.algorithm;
import std.array, std.conv;
import std.getopt;

import shrink;

string basePath = "";
bool removeComment, removeUnittest;

int main(string[] args) {
    //read opt
    string inputName, outputName;
    auto opt = getopt(args,
        config.required,
        "input|i", &inputName,
        config.required,
        "output|o", &outputName,
        "c", &removeComment,
        "u", &removeUnittest,
        );
    if (opt.helpWanted) {
        defaultGetoptPrinter("dlang source combiner.",
            opt.options);
    }

    //search dcomp home
    auto f = execute(["dub", "list"]);
    enforce(!f.status, "failed execute");
    basePath = f.output.splitLines
        .map!split
        .filter!`a.length && a[0] == "dcomp"`
        .front[2];
    enforce(basePath, "dcomp not found");
    writeln(basePath);


    string[] imported = enumImport(inputName);
    writeln(imported);

    bool[string] visited;
    auto ouf = File(outputName, "w");
    foreach (ph; imported) {
        auto inf = File(ph, "r");
        auto data = new ubyte[inf.size()];
        inf.rawRead(data);
        bool first = (ph == inputName);
        if (!first) {
            ouf.writeln("/* IMPORT " ~ ph ~ " */");
            data = someTrim(data);
        }
        foreach (line; data.map!(to!char).array.splitLines) {
            if (willCommentOut(line.idup, first)) {
                ouf.writeln("// " ~ line);
            } else {
                ouf.writeln(line);
            }
        }
    }
    return 0;
}

ubyte[] someTrim(ubyte[] fileBytes) {
    if (removeComment) {
        fileBytes = fileBytes.trimComment;
    }
    if (removeUnittest) {
        fileBytes = fileBytes.trimUnittest;
    }
    return fileBytes;
}
    
string[] findImport(string line) {
    import std.regex : regex, replaceAll;
    string[] res;
    auto l = line.split;
    if (l.length >= 2 && l[0] == "import") {
        if (l[1].split(".")[0] == "dcomp") {
            //dcomp import
            foreach (ph; l[1..$]) {
                ph = ph.replace(".", "/");
                ph = ph.replaceAll(regex("[;,]"), "");
                res ~= basePath ~ "source/" ~ ph ~ ".d";
            }
        }
    }
    return res;    
}

string[] findImport(string[] lines) {
    import std.regex : regex, replaceAll;
    return lines.map!findImport.join;
}

bool willCommentOut(string s, bool first) {
    auto l = s.split;
    if (l.length && l[0] == "module" && !first) return true;
    if (findImport(s).length) return true;
    return false;
}

string[] enumImport(string fn) {
    bool[string] visited;
    string[] stack;
    stack ~= fn;
    while (stack.length) {
        auto path = stack[$-1];
        stack = stack[0..$-1];
        if (path in visited) continue;
        visited[path] = true;
        auto f = File(path, "r");
        ubyte[] data = new ubyte[f.size()];
        f.rawRead(data);
        data = data.someTrim;
        stack ~= data.map!(to!char).array
            .splitLines.map!(to!string).array.findImport;
    }

    string[] res;
    res ~= fn;
    foreach (s, _; visited) {
        if (s == fn) continue;
        res ~= s;
    }
    return res;
}
