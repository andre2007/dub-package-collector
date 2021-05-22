import std;

JSONValue getDubDescribeJSON(string root, string args)
{
    auto dubOutput = executeShell(`dub describe --vquiet ` ~ args, null, Config.none, size_t.max, root);
    enforce(dubOutput.status == 0, dubOutput.output);
    JSONValue jsResult;
    try
    {
        jsResult = parseJSON(dubOutput.output);
    }
    catch(Exception e)
    {
        writeln("Cannot parse json: ", dubOutput.output);
        throw e;
    }
    return jsResult;
}

struct DubProject
{
    PackageAndPath rootPackage;
    PackageAndPath[] linkedDependencies;
}

struct PackageAndPath
{
    string name;
    string version_;
    string path;
}

string mainPackageName(string packageName)
{
    return packageName.split(":")[0];
}

DubProject toDubProject(JSONValue dubDescribe)
{
    string rootPackage = dubDescribe["rootPackage"].str;
    string[] linkDependencies = dubDescribe["targets"].array.filter!(
            js => js["rootPackage"].str == rootPackage).array[0]
        .object["linkDependencies"].array.map!(js => js.str).array;

    JSONValue[string] packMap = () {
        JSONValue[string] result;
        dubDescribe["packages"].array.each!(js => result[js["name"].str] = js);
        return result;
    }();
    return DubProject(PackageAndPath(rootPackage, packMap[rootPackage].object["version"].str,
            packMap[rootPackage].object["path"].str), linkDependencies.map!(name => PackageAndPath(name,
            packMap[name].object["version"].str, packMap[name].object["path"].str)).array);
}
