module tools.paths;

import std.file : exists;
import std.path : buildNormalizedPath, buildPath, dirName, setExtension;
import std.process : environment;

version (Posix)
    enum exeExtension = "";
else version (Windows)
    enum exeExtension = ".exe";

version (Windows)
    enum os = "windows";
else version (OSX)
    enum os = "osx";
else version (linux)
    enum os = "linux";
else version (FreeBSD)
    enum os = "freebsd";
else version (OpenBSD)
    enum os = "openbsd";
else version (NetBSD)
    enum os = "netbsd";
else version (DragonFlyBSD)
    enum os = "dragonflybsd";
else version (Solaris)
    enum os = "solaris";
else version (SunOS)
    enum os = "solaris";
else
    static assert(0, "Unrecognized or unsupported OS.");

enum projectRootDir = __FILE_FULL_PATH__.dirName.buildNormalizedPath("..", "..", "..");
enum generatedDir = projectRootDir.buildPath("generated");

enum laserDFilename = "laserd".setExtension(exeExtension);

enum compilerRootDir = __FILE_FULL_PATH__.dirName.buildNormalizedPath("..", "..");
alias testPath = path => compilerRootDir.buildPath("test", path);

string build()
{
    static string build;
    return build = build ? build : environment.get("BUILD", "release");
}

string buildOutputPath()
{
    static string buildOutputPath;
    return buildOutputPath ? buildOutputPath : (buildOutputPath = generatedDir.buildPath(os, build, dmdModel));
}

// Laser-D currently supports x86-64 only. The compiler is built by Dub in the
// repository root, so there is no generated/32 or generated/64 path from which
// the test harness can infer its model.
string dmdModel()
{
    static string dmdModel;

    if (dmdModel)
        return dmdModel;

    return dmdModel = environment.get("DMD_MODEL", "64");
}

string model()
{
    static string model;
    return model ? model : (model = environment.get("MODEL", dmdModel));
}

string dmdPath()
{
    const configured = environment.get("LASERD_COMPILER", "");
    if (configured.length)
        return configured;

    const dubCompiler = projectRootDir.buildPath(laserDFilename);
    return dubCompiler.exists
        ? dubCompiler
        : buildOutputPath.buildPath(laserDFilename);
}

string resultsDir()
{
    static string resultsDir;
    enum def = testPath("test_results");
    return resultsDir ? resultsDir : (resultsDir = environment.get("RESULTS_DIR", def));
}

/// Returns: a path to 'target' relative to `base` using POSIX file separators
version (Windows)
string relativePosixPath(const string target, const string base) pure @safe
{
    import std.array : join;
    import std.path : relativePath, pathSplitter;

    return target.relativePath(base)
                .pathSplitter()
                .join('/');
}
