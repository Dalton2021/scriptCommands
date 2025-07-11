@echo off
doskey ls = dir
doskey rm = del

doskey dev-www = cd c:\Users\clutch\Documents\Clutch\Apps\Legacy\dev-www.usfa.fema.gov
doskey www = cd c:\Users\clutch\Documents\Clutch\Apps\Legacy\www.usfa.fema.gov
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
doskey usfa-ui-admin = cd c:\Users\clutch\Documents\Clutch\Admin\USFA-UI-Admin
doskey usfa-common = cd c:\Users\clutch\Documents\Clutch\Apps\USFA-Common-React
doskey scripts = cd c:\Users\clutch\Documents\Clutch\ScriptCommands
doskey sandbox-admin = cd c:\Users\clutch\Documents\Clutch\Admin\Sandbox-Admin
doskey sandbox = cd c:\Users\clutch\Documents\Clutch\Apps\Sandbox
doskey admin = cd c:\Users\clutch\Documents\Clutch\Admin
doskey thes-admin = cd c:\Users\clutch\Documents\Clutch\Admin\Thesaurus-Admin
doskey nfirs = cd c:\Users\clutch\Documents\Clutch\Admin\NFIRS-Admin
doskey civ-admin = cd c:\Users\clutch\Documents\Clutch\Admin\Civilian-Fatalities-Admin
doskey ff-admin = cd c:\Users\clutch\Documents\Clutch\Admin\Firefighter-Fatalities-Admin
doskey registry-admin = cd c:\Users\clutch\Documents\Clutch\Admin\Registry-Admin

doskey new-release= Powershell -ExecutionPolicy Bypass -Command "c:\Users\clutch\Documents\Clutch\ScriptCommands\new_release.ps1" $*
doskey update-apps = PowerShell -ExecutionPolicy Bypass -Command "c:\Users\clutch\Documents\Clutch\ScriptCommands\update_apps.ps1" $*
doskey checkout-new = PowerShell -ExecutionPolicy Bypass -Command "c:\Users\clutch\Documents\Clutch\ScriptCommands\checkout-newBranch.ps1" $*
doskey checkout-default = PowerShell -ExecutionPolicy Bypass -Command "c:\Users\clutch\Documents\Clutch\ScriptCommands\checkout-default.ps1" $*