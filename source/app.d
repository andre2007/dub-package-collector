import std;
import dub;

void main(string[] args)
{
	string root = getcwd;
	string archive;
	string folder;
	string build;
	string config;

	auto helpInformation = getopt(args, "root", &root, "archive", &archive,
			"folder", &folder, "build|b", &build, "config|c", &config);

	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("Dub Package Collector.", helpInformation.options);
	}

	string dubArgs = ["--build", build, "--config", config].chunks(2)
		.filter!(t => t[1] != "").join(" ").join(" ");

	JSONValue dubDescribe = getDubDescribeJSON(root, dubArgs);
	DubProject dubProject = toDubProject(dubDescribe);

	if (archive != "")
	{
		string archiveFilePath = (archive.isAbsolute) ? archive : buildPath(root, archive);
		createZipArchive(dubProject, archiveFilePath);
	}
	else
	{
		if (folder == "")
		{
			folder = "whitesource";
		}

		string folderPath = (folder.isAbsolute) ? folder : buildPath(root, folder);
		createFolder(dubProject, folderPath);
	}
}

private void createFolder(DubProject dubProject, string folderPath)
{
	foreach (entry; dirEntries(dubProject.rootPackage.path,
			"*.{d,di,dpp,json,sdl}", SpanMode.breadth))
	{
		string newFilePath = buildPath(folderPath, entry.name[dubProject.rootPackage.path.length .. $]);
		if (!exists(newFilePath.dirName))
		{
			mkdirRecurse(newFilePath.dirName);
		}
		entry.name.copy(newFilePath);
	}

	auto externalLinkDeps = dubProject.linkedDependencies
		.filter!(d => !d.path.startsWith(dubProject.rootPackage.path));
	
	foreach (linkedDependency; externalLinkDeps)
	{
		foreach (entry; dirEntries(linkedDependency.path, "*.{d,di,dpp,json,sdl}", SpanMode.breadth))
		{
			string newFilePath = buildPath(folderPath, ".dub", "packages", 
				linkedDependency.name.mainPackageName ~ "-" ~ linkedDependency.version_,
				linkedDependency.name.mainPackageName, entry.name[linkedDependency.path.length .. $]);
			if (!exists(newFilePath.dirName))
			{
				mkdirRecurse(newFilePath.dirName);
			}
			entry.name.copy(newFilePath);
		}
	}
}

private void createZipArchive(DubProject dubProject, string archiveFile)
{
	ZipArchive zipArchive = new ZipArchive();
	foreach (entry; dirEntries(dubProject.rootPackage.path,
			"*.{d,di,dpp,json,sdl}", SpanMode.breadth))
	{
		string archivedFilePath = entry.name[dubProject.rootPackage.path.length .. $];
		version (Windows)
			archivedFilePath = archivedFilePath.replace("\\", "/");
		ArchiveMember am = new ArchiveMember();
		am.name = archivedFilePath;
		am.expandedData = cast(ubyte[]) std.file.read(entry.name);
		zipArchive.addMember(am);
	}

	auto externalLinkDeps = dubProject.linkedDependencies
		.filter!(d => !d.path.startsWith(dubProject.rootPackage.path));

	foreach (linkedDependency; externalLinkDeps)
	{
		foreach (entry; dirEntries(linkedDependency.path, "*.{d,di,dpp,json,sdl}", SpanMode.breadth))
		{
			string archivedFilePath = ".dub/packages/" ~ linkedDependency.name.mainPackageName ~ "-" ~ linkedDependency.version_ ~ "/"
				~ linkedDependency.name.mainPackageName ~ "/" ~ entry.name[linkedDependency.path.length .. $];
			version (Windows)
				archivedFilePath = archivedFilePath.replace("\\", "/");
			ArchiveMember am = new ArchiveMember();
			am.name = archivedFilePath;
			am.expandedData = cast(ubyte[]) std.file.read(entry.name);
			zipArchive.addMember(am);
		}
	}

	void[] compressed_data = zipArchive.build();
	std.file.write(archiveFile, compressed_data);
}
