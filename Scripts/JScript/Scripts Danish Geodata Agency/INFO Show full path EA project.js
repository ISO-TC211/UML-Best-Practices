!INC Local Scripts.EAConstants-JScript

/**
* Shows the full path of the currently opened EA project.
*/
function main() {
	Repository.EnsureOutputVisible("Script");
	Session.Output("File name: " + Repository.ConnectionString);
}

main();