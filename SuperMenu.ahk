#SingleInstance force

linksdir = %A_ScriptDir%\shortcuts
snippetsdir = %A_ScriptDir%\snippets
toolsdir = %A_ScriptDir%\tools

FormatTime, YearWeek, , YWeek
StringRight, weeknum, YearWeek, 2
weeknum := weeknum + 1

;Display a folder with its immediate files that match the filemask
;if no files are found, no menu is created. If you have something else in the menu, then you don't need to test it before you show it.
Capslock & RButton::
    menu, thismenu, add, SCRIPT FOLDER WK%weeknum%, WHATSUP
	menu, thismenu, add
    menu_fromfiles("linklist", "File / Folders", "OpenFileFolder", linksdir, "*.lnk", "thismenu", 0)
	menu_fromfiles("Weblinks", "Web Links", "OpenLink", linksdir, "*.url", "thismenu", 0)
    menu_fromfiles("snippetlist", "Snippets", "COPY2CLIP", snippetsdir, "*.txt", "thismenu", 0)
	menu_fromfiles("toolslist", "Tools", "OpenLink", toolsdir, "*.url", "thismenu", 0)
	menu, thismenu, add, ReadMe, RME
    menu, thismenu, show
	Reload
Return

Capslock & lButton::
	sel := Explorer_GetSelected()
	if ErrorLevel
    return
	SplitPath, sel ,,,,Filename
	StringRight, FnOut, Filename, 4
	if(FnOut == ".exe")
	{
		FileCreateShortcut, %sel%, %toolsdir%\%Filename%.lnk
	} 
	Else
	{
		FileCreateShortcut, %sel%, %linksdir%\%Filename%.lnk
	}
	reload
return

;  *** win+t 置顶窗口，win+b取消置顶
#t::
	WinSet AlwaysOnTop,On,A
return
#b::
	WinSet AlwaysOnTop,Off,A
return

!t::send %A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min%:%A_Sec%

F1::
If GetKeyState("CapsLock","T")
{
	send,^c
	clipwait,2
	InputBox, CodeName , please asign a name to the snippet
	if ErrorLevel
    return
	Fileappend,%clipboard%,%snippetsdir%\%CodeName%.txt
	reload
}
else
return

OpenFileFolder:
    curpath := menu_itempath("linklist", linksdir)".lnk"
    Run, %curpath%
RETURN

OpenLink:
    curpath := menu_itempath("Weblinks", linksdir)".url"
	IniRead, OutputVar, %curpath%, InternetShortcut, URL

	Run %OutputVar%
RETURN

COPY2CLIP:
    curpath := menu_itempath("snippetlist", snippetsdir)".txt"
	Clipboard := ""
    FileRead, Clipboard, %curpath%
; uncomment below for mouse tip display
;    Run %A_ScriptDir%\tooltip.exe
RETURN

WHATSUP:
    Run, %a_scriptdir%
RETURN

RME:
 Run, %a_scriptdir%\readme.txt
Return

;create menu from structure of folder
menu_fromfiles(submenuname, menutitle, whatsub, whatdir, filemask="*", parentmenu="", folders=1){
        menucount := 0
        loop, %whatdir%\*, 1, 0
        {
            if(file_isfolder(A_LoopFileFullPath)){
                if(folders){
                      menucount := menu_fromfiles(A_LoopFileFullPath, a_loopfilename, whatsub, A_LoopFileFullPath, filemask, submenuname, folders)                                   
                }
            }else{
                 loop, %A_LoopFileDir%\%filemask%, 0, 0
                {
					SplitPath, A_LoopFileFullPath,,,,filename
                    menu, %submenuname%, add, %filename%, %whatsub%
                    menucount++                
                }                
            }
        }
        if(parentmenu && menucount){
            menu, %parentmenu%, add, %menutitle%, :%submenuname%
            return menucount
        }       
}


;fetches the correct path from the menu
menu_itempath(whatmenu, whatdir){
    if(a_thismenu = whatmenu){
    endpath = %whatdir%\%a_thismenuitem%
        return endpath
    }else{
        endpath = %a_thismenu%\%a_thismenuitem%
        return endpath
    }
}


;returns true if the item is a folder, false if is a file
file_isfolder(whatfile){
    lastchar := substr(whatfile, 0, 1) ;fetch the last character from the string
    if(lastchar != "\")
        whatfile := whatfile . "\"
    if(fileexist(whatfile))
        return true
}


;get seleced file or folder's address in explorer
Explorer_GetSelected(hwnd="")
{
	return Explorer_Get(hwnd,true)
}
Explorer_Get(hwnd="",selection=false)
{
	if !(window := Explorer_GetWindow(hwnd))
		return ErrorLevel := "ERROR"
	if (window="desktop")
	{
		ControlGet, hwWindow, HWND,, SysListView321, ahk_class Progman
		if !hwWindow ; #D mode
			ControlGet, hwWindow, HWND,, SysListView321, A
		ControlGet, files, List, % ( selection ? "Selected":"") "Col1",,ahk_id %hwWindow%
		base := SubStr(A_Desktop,0,1)=="\" ? SubStr(A_Desktop,1,-1) : A_Desktop
		Loop, Parse, files, `n, `r
		{
			path := base "\" A_LoopField
			IfExist %path% ; ignore special icons like Computer (at least for now)
				ret .= path "`n"
		}
	}
	else
	{
		if selection
			collection := window.document.SelectedItems
		else
			collection := window.document.Folder.Items
		for item in collection
			ret .= item.path "`n"
	}
	return Trim(ret,"`n")
}
Explorer_GetWindow(hwnd="")
{
	; thanks to jethrow for some pointers here
    WinGet, process, processName, % "ahk_id" hwnd := hwnd? hwnd:WinExist("A")
    WinGetClass class, ahk_id %hwnd%
	
	if (process!="explorer.exe")
		return
	if (class ~= "(Cabinet|Explore)WClass")
	{
		for window in ComObjCreate("Shell.Application").Windows
			if (window.hwnd==hwnd)
				return window
	}
	else if (class ~= "Progman|WorkerW") 
		return "desktop" ; desktop found
}

#IfWinActive ahk_class Chrome_WidgetWin_1
{
	F9::
	send ^l
	sleep,500
	Send ^c
	ClipWait,1
	Clipboard := "read://" Clipboard
	ClipWait,1
	send ^l
	sleep,500
	send ^v{enter}
	return
}