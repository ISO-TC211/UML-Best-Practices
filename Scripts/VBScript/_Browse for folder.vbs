Function BrowseForFolder()
	Dim shell : Set shell = CreateObject("Shell.Application")
	Dim folder : Set folder = shell.BrowseForFolder(0, "Choose a file:", &H4000)
	
	if (not folder is nothing) then
		BrowseForFolder = folder.self.Path
	else
		BrowseForFolder = "No folder selected"
	end if
End Function

BrowseForFile
