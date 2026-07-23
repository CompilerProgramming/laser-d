/**
 * Build a platform distribution from an already-built Laser-D compiler.
 *
 * Run through Dub:
 *   dub run dmd:distribution
 */
module build_distribution;

import std.algorithm : endsWith, filter;
import std.file : SpanMode, copy, dirEntries, exists, getAttributes,
                  mkdirRecurse, read, readText, rmdirRecurse, write;
import std.path : buildPath, dirName, relativePath;
import std.stdio : writeln;
import std.string : indexOf, strip;
import std.zip : ArchiveMember, CompressionMethod, ZipArchive;

version (Windows)
{
    enum platformName = "windows";
    enum compilerSource = "generated/windows/release/64/laserd.exe";
    enum compilerName = "laserd.exe";
    enum configName = "sc.ini";
    enum configContents =
        "[Environment]\r\n" ~
        "DFLAGS=\"-I%@P%\\..\\import\"\r\n";
}
else version (OSX)
{
    enum platformName = "macos";
    enum compilerSource = "generated/osx/release/64/laserd";
    enum compilerName = "laserd";
    enum configName = "dmd.conf";
    enum configContents =
        "[Environment]\n" ~
        "DFLAGS=-I%@P%/../import\n";
}
else version (linux)
{
    enum platformName = "linux";
    enum compilerSource = "generated/linux/release/64/laserd";
    enum compilerName = "laserd";
    enum configName = "dmd.conf";
    enum configContents =
        "[Environment]\n" ~
        "DFLAGS=-I%@P%/../import\n";
}
else
{
    static assert(false, "Laser-D distributions support Windows, Linux, and macOS");
}

enum architectureName = "x86_64";

void main()
{
    const root = __FILE_FULL_PATH__.dirName.dirName;
    const compilerPath = root.buildPath(compilerSource);
    if (!compilerPath.exists)
        throw new Exception("Laser-D compiler not found: " ~ compilerPath);

    const versionName = root.buildPath("VERSION").readText.strip;
    const distributionName =
        "laser-d-" ~ versionName ~ "-" ~ platformName ~ "-" ~ architectureName;
    const outputDirectory = root.buildPath("dist");
    const stageDirectory = outputDirectory.buildPath(distributionName);
    const archivePath = outputDirectory.buildPath(distributionName ~ ".zip");

    if (stageDirectory.exists)
        stageDirectory.rmdirRecurse;
    outputDirectory.mkdirRecurse;

    const binaryDirectory = stageDirectory.buildPath("bin");
    const importDirectory = stageDirectory.buildPath("import");
    binaryDirectory.mkdirRecurse;
    importDirectory.mkdirRecurse;

    compilerPath.copy(binaryDirectory.buildPath(compilerName));
    binaryDirectory.buildPath(configName).write(configContents);

    const libraryDirectory = root.buildPath("library");
    foreach (entry; dirEntries(libraryDirectory, "*.d", SpanMode.depth)
             .filter!(entry => !isLibraryTest(entry.name)))
    {
        const relative = entry.name.relativePath(libraryDirectory);
        const destination = importDirectory.buildPath(relative);
        destination.dirName.mkdirRecurse;
        entry.name.copy(destination);
    }

    root.buildPath("README.md").copy(stageDirectory.buildPath("README.md"));
    root.buildPath("LICENSE.txt").copy(stageDirectory.buildPath("LICENSE.txt"));
    libraryDirectory.buildPath("README.md")
        .copy(stageDirectory.buildPath("STANDARD_LIBRARY.md"));

    ZipArchive archive = new ZipArchive();
    foreach (entry; dirEntries(stageDirectory, SpanMode.depth)
             .filter!(entry => entry.isFile))
    {
        ArchiveMember member = new ArchiveMember();
        const relative = entry.name.relativePath(outputDirectory)
            .replacePathSeparators;
        member.name = relative;
        member.expandedData = cast(ubyte[]) entry.name.read;
        member.compressionMethod = CompressionMethod.deflate;
        member.fileAttributes = entry.name.getAttributes;
        archive.addMember(member);
    }
    archivePath.write(archive.build);

    writeln("Staged distribution: ", stageDirectory);
    writeln("Distribution archive: ", archivePath);
}

private bool isLibraryTest(string path)
{
    const normalized = path.replacePathSeparators;
    return normalized.endsWith("/library/test") ||
           normalized.indexOf("/library/test/") != -1;
}

private string replacePathSeparators(string path)
{
    import std.string : replace;
    return path.replace('\\', '/');
}
