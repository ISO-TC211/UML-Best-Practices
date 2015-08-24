/**
* See https://msdn.microsoft.com/en-us/library/6fw3zxcx%28v=vs.84%29.aspx for information about the functions used here.
*/
function getScriptEngineInfo() {
	return ScriptEngine() + " Version " + ScriptEngineMajorVersion() + "." + ScriptEngineMinorVersion() + "." + ScriptEngineBuildVersion();
}
 
function main() {
	Repository.EnsureOutputVisible("Script");
	var info = getScriptEngineInfo();
	Session.Output("Script engine information: " + info);
	Session.Output("Note: for JScript 5.8 and earlier, see https://msdn.microsoft.com/en-us/library/hbxc2t98%28v=vs.84%29.aspx");
}

main();