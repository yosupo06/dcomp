import std.stdio, std.process, std.exception, std.string, std.algorithm;
import std.array, std.conv;
import std.getopt;

import shrink;

string copyLight = r"
/*
This source code generated by dunkelheit and include dunkelheit's source code.
dunkelheit's Copyright: Copyright (c) 2016- Kohei Morita. (https://github.com/yosupo06/dunkelheit)
dunkelheit's License: MIT License(https://github.com/yosupo06/dunkelheit/blob/master/LICENSE.txt)
*/
";

string basePath = "";
bool removeComment, removeUnittest;

int main(string[] args) {
    //read opt
    string inputName, outputName;
    auto opt = getopt(args,
        config.required, "input|i", "input file name", &inputName,
        config.required, "output|o", "output file name", &outputName,
        "c", "remove comment", &removeComment,
        "u", "remove unittest", &removeUnittest,
        );
    if (opt.helpWanted) {
        defaultGetoptPrinter("dlang source combiner.",
            opt.options);
        return 0;
    }

    //search dunkelheit home
    auto f = execute(["dub", "list"]);
    enforce(!f.status, "failed execute");
    basePath = f.output.splitLines
        .map!split
        .filter!`a.length && a[0] == "dunkelheit"`
        .front[2];
    enforce(basePath, "dunkelheit not found");
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
    ouf.write(copyLight);
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
    auto l = line.replaceAll(regex("[;,]"), " ").split;
    bool find = false;
    if (l.length >= 1 && l[0] == "import") {
        l = l[1..$];
        find = true;
    } else if (l.length >= 2 && l[0] == "public" && l[1] == "import") {
        l = l[2..$];
        find = true;
    }
    if (!find) return [];
    string[] res;
    foreach (ph; l) {
        if (ph.count(":")) break;
        string f = ph.split(".")[0];
        if (f == "dkh") {
            ph = ph.replace(".", "/");
            res ~= basePath ~ "source/" ~ ph ~ ".d";
        } else if (f != "std" && f != "core") {
            res ~= ph ~ ".d";            
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
