@echo off
doskey ls = dir
doskey rm = del

doskey docs = cd c:\Users\clutch\Documents
doskey clutch = cd c:\Users\clutch\Documents\Clutch
doskey usfa = cd c:\Users\clutch\Documents\Clutch\USFA
doskey apps = cd c:\Users\clutch\Documents\Clutch\Apps
doskey legacy = cd c:\Users\clutch\Documents\Clutch\Apps\Legacy
doskey civ = cd c:\Users\clutch\Documents\Clutch\Apps\Civilian-Fatalities\Civilian-Fatalities
doskey contact = cd c:\Users\clutch\Documents\Clutch\Apps\Contact\Contact
doskey ff = cd c:\Users\clutch\Documents\Clutch\Apps\Firefighter-Fatalities\Firefighter-Fatalities
doskey hotel = cd c:\Users\clutch\Documents\Clutch\Apps\Hotel\Hotel
doskey nfa = cd c:\Users\clutch\Documents\Clutch\Apps\NFACourses\NFACourses
doskey pubs = cd c:\Users\clutch\Documents\Clutch\Apps\Publications\Publications
doskey registry = cd c:\Users\clutch\Documents\Clutch\Apps\Registry\Registry
doskey releases = cd c:\Users\clutch\Documents\Clutch\Apps\Releases
doskey thes = cd c:\Users\clutch\Documents\Clutch\Apps\Thesaurus\Thesaurus
doskey usfa-ui = cd c:\Users\clutch\Documents\Clutch\Apps\USFA-UI\USFA-UI
doskey usfa-common = cd c:\Users\clutch\Documents\Clutch\Apps\USFA-Common-React
doskey scripts = cd c:\Users\clutch\Documents\Clutch\ScriptCommands

doskey new-release= Powershell -ExecutionPolicy Bypass -Command "c:\Users\clutch\Documents\Clutch\ScriptCommands\new_release.ps1" $*
doskey update-apps = PowerShell -ExecutionPolicy Bypass -Command "c:\Users\clutch\Documents\Clutch\ScriptCommands\update_apps.ps1" $*
