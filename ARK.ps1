# NOTES/TO DO'S
<#  1.) Make a little database of mod numbers to translate to mod name
    2.) Finish each function described 
    3.)
#>

# Store variables in file and bring them in







# Load in and declare necessary variables
[string]$defaultDrive = "C:"
[string]$userInput = $null
[bool[]]$foldersExist = $false,$false,$false,$false
[string[]]$homeMenu = "Server status","Launch a server","Shutdown a server","Update a server","Backup a server","Manage server mods","Create a new server","Delete a server"
[string[]]$modMenu = "Archive the mod", "Delete the mod"
[string[]]$serverCreationMenu = "Copy an existing server", "Download a clean install"
[string]$lastAction = $null
[string[]]$activeServers = $null


# !!!!!!!!!!!!!!!!!!!Need to error check this. 
#[string]$publicIP = (Invoke-WebRequest ifconfig.me/ip).Content.Trim()
[string]$publicIP = "Unavailable"






# Declare necessary functions

# Quick functions to notate the importance or quality of feedback
function MsgHi([string]$tempInput){
    if ($tempInput -ne $null){
        Write-Host -ForegroundColor Red $tempInput
    }
}
function MsgMed ([string]$tempInput)
{
    if ($tempInput -ne $null){
        Write-Host -ForegroundColor Yellow $tempInput
    }
}
function MsgLo([string]$tempInput){
    if ($tempInput -ne $null){
        Write-Host -ForegroundColor Green $tempInput
    }
}




# Quick function to allow me to ask the user for input and compare their input to a Regex, returns response for use only when passing the Regex rules
function askUser([string]$userQuestion,[string]$regexToMatch){
    #Write-Host -ForegroundColor Cyan $regexToMatch
    $userResponse = $null
    while (($userResponse -eq $null) -or ($userResponse -inotmatch $regexToMatch)){
        Write-Host -NoNewLine -ForegroundColor Yellow $userQuestion ": "
        $userResponse = Read-Host
    }
    return $userResponse
}

# Time formatting for file naming
function getMyTime(){return $currentDateTime = Get-Date -Format "MM-dd-yyyy hh.mm tt"}
    
# Header for synopsis of script purpose as well as credit/GitHub plug
function displayHomeHeader(){
    Write-Host -ForegroundColor Green "******************** ARK PARASERVER MANAGER *********************
This script is written by Dustin (www.github.com/kirigaine). It is a small 
PowerShell script intended to help manage my servers (ARK: Survival Evolved, Conan Exiles,
Teamspeak 3, Minecraft). This script will allow backups to be made, mods to be deleted, 
and more when necessary. To report any bugs, contact me on GitHub!
************************************************************`n"
}

# Display an array in usable format for user
function displayArrayAsIndexedList($givenArray){
    # Increment through each item in array while keeping an index for user input use. Format for visibilty
    $i=0
    foreach ($item in $givenArray){
        if (($i++%2) -eq 0){Write-Host -ForegroundColor White ($i)".)" $item}
        else{Write-Host -ForegroundColor Gray ($i)".)" $item}
    }
    if (($i%2)-eq 0) {Write-Host -ForegroundColor White "0 .) Exit" }
    else {Write-Host -ForegroundColor Gray "0 .) Exit" }
}

function getBaseFiles(){
    
    MsgMed "`nTesting if the following files exist:"

    Write-Host -NoNewLine "'$defaultDrive\Servers'... "
    if (Test-Path "$defaultDrive\Servers") {$foldersExist[0] = $true; MsgLo "Exists."}
    else {MsgHi "Does not exist."}

    Write-Host -NoNewLine "'$defaultDrive\Servers\ARK Survival Evolved'... "
    if (Test-Path "$defaultDrive\Servers\ARK Survival Evolved") {$foldersExist[1] = $true; MsgLo "Exists."}
    else {MsgHi "Does not exist."}

    Write-Host -NoNewLine "'$defaultDrive\Servers\ARK Survival Evolved\ARK Saves'... "
    if (Test-Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Saves") {$foldersExist[2] = $true; MsgLo "Exists."}
    else {MsgHi "Does not exist."}

    Write-Host -NoNewLine "'$defaultDrive\Servers\ARK Survival Evolved\ARK Maps'... "
    if (Test-Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Maps") {$foldersExist[3] = $true; MsgLo "Exists."}
    else {MsgHi "Does not exist."}
    MsgMed "Testing complete."

    # Decide what to do based on results of test. If they exist, continue into script. Else create or exit.
    if ($foldersExist[0] -and $foldersExist[1] -and $foldersExist[2] -and $foldersExist[3]){MsgLo "*****All necessary files exist.*****`n"}
    # Notify user that folders needed to function are not present    
    else{ 
        MsgHi "*****Not all necessary files exist.*****`n";
        $userInput = askUser "Would you like to create these files now?" "^[yn]{1}$";
            if ($userInput -imatch 'y') {createBaseFiles}
            else {myExit}
        }
}

function getServers(){
    $serversArray = Get-ChildItem -Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Maps\"
    displayArrayAsIndexedList($serversArray)
    #testMenuDisplay("Servers","$serversArray")
    return $serversArray
}

function getMods($userServer){
    $modsArray = Get-ChildItem -Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Maps\$userServer\ark survival evolved server\ShooterGame\Content\Mods\"
    displayArrayAsIndexedList $modsArray
    return $modsArray
}

function getActiveServers(){
    try{
        # !!! Need to still work on duplicates of processes and being able to handle them
        [string[]]$thecurrentProcesses
        Get-Process ShooterGameServer -ErrorAction Stop | ForEach-Object {if ($thecurrentProcesses -notcontains $_.Path){$thecurrentProcesses += $_.Path}}
        displayArrayAsIndexedList $thecurrentProcesses
        $lastAction = "We found all X servers"
    }
    catch [System.Management.Automation.ActionPreferenceStopException]{$lastAction = "ERROR: Could not find any 'ARK: Survival Evolved' servers currently running."}
}

function createBaseFiles(){
        if (-Not $foldersExist[0]) {New-Item -Path "$defaultDrive\" -Name "Servers" -ItemType "directory"}
        if (-Not $foldersExist[1]) {New-Item -Path "$defaultDrive\Servers" -Name "ARK Survival Evolved" -ItemType "directory"}
        if (-Not $foldersExist[2]) {New-Item -Path "$defaultDrive\Servers\ARK Survival Evolved" -Name "ARK Saves" -ItemType "directory"}
        if (-Not $foldersExist[3]) {New-Item -Path "$defaultDrive\Servers\ARK Survival Evolved" -Name "ARK Maps" -ItemType "directory"}
}

# Draw the persisent menu for throughout the script
function drawMenu([string]$title, [string[]]$tempArray){
    
    
    # Clear screen for a fresh draw (need delay in order for -ForegroundColor of Write-Host to perform correctly)
    cls;
    Start-Sleep -Milliseconds 250
    displayHomeHeader;
    # Check for TeamSpeak 3 Server process
    try{
        $teamspeakStatus = Get-Process ts3server -ErrorAction Stop
    }
    catch [System.Management.Automation.ActionPreferenceStopException]{$teamspeakStatus = $false}


    # Display server statuses/relevant host info to user
    Write-Host -NoNewline "Public IPv4 Address: "; MsgLo "$publicIP"
    Write-Host -NoNewline "TS3 Server Status: "; if ($teamspeakStatus) {MsgLo "Active`n"} else {MsgHi "Inactive"}
    Write-Host -NoNewLine "Active Game Servers: "; MsgHi "None`n"

    # Display last action (if it exists) to give feedback on actions taken by user
    if (($lastAction -ne $null) -and ($lastAction -ne "")) { 
        MsgMed "$lastAction`n";
        $lastAction = $null
    }

    # Display title as well as indexed array of possible actions
    if (($tempArray -ne $null) -And ($tempArray.Length -ne 0)){
        # Temporary length test for not displaying list
        #Write-Host $tempArray.Length
        Write-Host -NoNewLine -ForegroundColor White "=============="
        Write-Host -NoNewLine -ForegroundColor Yellow "{$title}"
        Write-Host -ForegroundColor White "==============`n"
        displayArrayAsIndexedList $tempArray
        Write-Host -ForegroundColor White "`n=====================================`n"
    }

}

function myExit(){
    MsgLo "Exiting the script. Goodbye.";
    Exit
}






#***SCRIPT STARTS HERE***




# Welcome user to the script
MsgLo "           ***Welcome to ARK Paraserver Manager***`n";

# Display header to user
displayHomeHeader;

#***************LAUNCH FILES EXIST TESTING***************
getBaseFiles;


<# Delete variables used for testing paths as they are no longer needed and script is intended to be left running.
Trying to use least memory as possible!#>
Remove-Variable foldersExist


# Reset user input variable from file testing
$userInput = $null










#***************USER HOMEPAGE***************
#displayHomeHeader;
while(1 -eq 1){
    cd $defaultDrive
    #drawMenu("Actions");
    drawMenu "Actions" $homeMenu

    $lastAction = $null
    $userInput = askUser "Which action would you like to perform?" '^[0-8]{1}$'
    # Handle user input
    switch($userInput){

        # GET SERVER STATUS
        1{
            try{
                # !!! Need to still work on duplicates of processes and being able to handle them
                [string[]]$thecurrentProcesses
                Get-Process ShooterGameServer -ErrorAction Stop | ForEach-Object {if ($thecurrentProcesses -notcontains $_.Path){$thecurrentProcesses += $_.Path}}
                displayArrayAsIndexedList($thecurrentProcesses);
                $lastAction = "We found all X servers"
            }
            catch [System.Management.Automation.ActionPreferenceStopException]{$lastAction = "ERROR: Could not find any 'ARK: Survival Evolved' servers currently running."}}
        
        # LAUNCH A SERVER
        2{while (1 -eq 1){
                $serverList = getServers;
                $userInput = askUser "Which server would you like to launch?" "[0-$($serverList.Length+1)]"
                if ($userInput -eq 0){Break;}
                if (-Not (Test-Path "D:\Servers\ARK\$($serverList[($userInput-1)])\ark survival evolved server\ShooterGame\Binaries\Win64\LaunchServer.bat")){$lastAction = "$($serverList[($userInput-1)])'s LaunchServer.bat could not be found. The server wasn't launched."; Break;}
                cd "D:\Servers\ARK\$($serverList[($userInput-1)])\ark survival evolved server\ShooterGame\Binaries\Win64\"
                & ".\LaunchServer.bat"
                $lastAction = "$($serverList[($userInput-1)]) has been launched. Look for the terminal opening up!"

            }
            #could be as simple as '& batfilelocation' but we need to test it to make sure it doesn't perform differently than expected
        }

        # SHUTDOWN A SERVER
        3{while (1 -eq 1){
            #this piggybacks off of #1, figure out that then we can shutdown servers easy
            try{
                # !!! Need to still work on duplicates of processes and being able to handle them
                [string[]]$thecurrentProcesses
                Get-Process ShooterGameServer -ErrorAction Stop | ForEach-Object {if ($thecurrentProcesses -notcontains $_.Path){$thecurrentProcesses += $_.Path}}
                displayArrayAsIndexedList $thecurrentProcesses
                $lastAction = "We found all X servers"
            }
            catch [System.Management.Automation.ActionPreferenceStopException]{$lastAction = "ERROR: Could not find any 'ARK: Survival Evolved' servers currently running."}
        }
        }


        # UPDATE A SERVER
        4{
            #need to create a lock so that this server cannot be launched while updating or already running
            $serverList = getServers;
            drawMenu "Servers" $serverList
            $userInput = askUser "Which server would you like to update" "^[0-$($serverList.Length+1)]$"
            if (userInput -eq 0){Break;}
            if (-Not (Test-Path "D:\Servers\ARK\Genesis\arkserver.bat")){$lastAction = "$($serverList[($userInput-1)])'s arkserver.bat could not be found. The updater wasn't launched."; Break;}
            cd "D:\Servers\ARK\$($serverList[($userInput-1)])"
            & ".\arkserver.bat"
            $lastAction = "$($serverList[($userInput-1)]) updater has been launched. Do not try to launch the server until this is completed. Look for the terminal opening up!"
        }

        # BACKUP A SERVER
        5{ 
            while (1 -eq 1){
                #Write-Host "**Your Servers**"
                $serverList = getServers;
                $userInput = askUser "Which server would you like to make a backup for?" "[0-$($serverList.Length+1)]"
                if ($userInput -eq 0){Break;}
                else {
                    $currentDate = getMyTime;
                    if (Test-Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Saves\$($serverList[($userInput-1)])\$($serverList[($userInput-1)]) $currentDate"){$lastAction = "File already exists (cannot save a duplicate date and time). No additional backup created."; Break}
                    Copy-Item -Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Maps\$($serverList[($userInput-1)])\ark survival evolved server\ShooterGame\Saved" -Recurse -Destination "$defaultDrive\Servers\ARK Survival Evolved\ARK Saves\$($serverList[($userInput-1)])\$($serverList[($userInput-1)]) $currentDate"
                    $lastAction = "$($serverList[($userInput-1)]) backup complete. '$($serverList[($userInput-1)]) $currentDate' has been created in '$defaultDrive\Servers\ARK Survival Evolved\ARK Saves\$($serverList[($userInput-1)])\'."
                    Break;
                }
            }
          }

        # MANAGE SERVER MODS
        6{ 
            $serverList = getServers;
            $userInput = askUser "Which server would you like to manage mods for?" "[0-$($serverList.Length+1)]"
            if ($userInput -eq 0){Break;}
            else{
                $modsList = getMods($serverList[($userInput-1)])
                $userInput2 = askUser "Which mod would you like to manage?" "[0-$($modsList.Length+1)]"
                if ($userInput2 -eq 0){Break;}
                else{
                    displayArrayAsIndexedList($modMenu)
                    $userInput3 = askUser "Would you like to archive or delete the mod?"
                    switch($userInput3){
                        0{Break;}
                        1{
                            Write-Host "input1: $userInput - $($serverList[($userInput-1)]) | input2: $userInput2 - $($modsList[($userInput2-1)]) | input3: $userInput3 - 1 archive 2 delete "
                            $currentDate = Get-Date -Format "MM-dd-yyyy HH.mm"
                            Write-Host "PATH: $defaultDrive\Servers\ARK Survival Evolved\ARK Maps\$($serverList[($userInput-1)])\ark survival evolved server\ShooterGame\Content\Mods\$($modsList[($userInput2-1)])"
                            Write-Host "DESTINATION: $defaultDrive\Servers\ARK Survival Evolved\ARK Saves\$($serverList[($userInput-1)])\Mod Archives\$($modsList[($userInput2-1)]) $currentDate"
                            
                            if (-Not (Test-Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Saves\$($serverList[($userInput-1)])\")){New-Item -Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Saves\" -Name "$($serverList[($userInput-1)])" -ItemType "directory"}
                            if (-Not (Test-Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Saves\$($serverList[($userInput-1)])\Mod Archives\")){New-Item -Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Saves\$($serverList[($userInput-1)])\" -Name "Mod Archives" -ItemType "directory"}
                            
                            $tempGet = Get-ItemPropertyValue -Name "LastWriteTime" -Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Maps\$($serverList[($userInput-1)])\ark survival evolved server\ShooterGame\Content\Mods\$($modsList[($userInput2-1)])"
                            Write-Host "this is the thing $tempGet"
                            $tempGet = $tempGet -replace "/", "-"
                            $tempGet = $tempGet -replace ":", "."
                            Write-Host "this is the thing $tempGet"
                            Pause
                            Move-Item -Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Maps\$($serverList[($userInput-1)])\ark survival evolved server\ShooterGame\Content\Mods\$($modsList[($userInput2-1)])" -Destination "$defaultDrive\Servers\ARK Survival Evolved\ARK Saves\$($serverList[($userInput-1)])\Mod Archives\$($modsList[($userInput2-1)]) $currentDate"
                            $lastAction = "$($modsList[($userInput2-1)]) archive complete. '$($modsList[($userInput2-1)]) $currentDate' has been created in '$defaultDrive\Servers\ARK Survival Evolved\ARK Saves\$($serverList[($userInput-1)])\Mod Archives\'."
                        }
                        2{
                            Remove-Item -Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Maps\$($serverList[($userInput-1)])\ark survival evolved server\ShooterGame\Content\Mods\$($modsList[($userInput2-1)])" -Recurse
                            $lastAction = "$($modsList[($userInput2-1)]) deletion complete. '$($modsList[($userInput2-1)])' has been deleted from '$defaultDrive\Servers\ARK Survival Evolved\wherever mods are'."
                            
                        }
                    }
                }
            }
         }
        # @echo off
        # start "" steamcmd.exe +login anonymous +force_install_dir "D:\Servers\ARK\Genesis\ARK Survival Evolved Server" +app_update 376030 validate

        # CREATE A NEW SERVER
        7{
            drawMenu "Actions" $serverCreationMenu
            $creationChoices = askUser "Would you like to copy an existing server or download a clean install?" "^[0-2]{1}$"
            switch($creationChoices){
                0{Break;}
                1{$serverList = getServers;
                  drawMenu "Servers" $serverList
                  $userInput = askUser "Which server would you like to copy?" "[0-$($serverList.Length+1)]"}

                2{
                    drawMenu $null $null
                    MsgMed "Server Name Requirements:"
                    MsgLo "> 2-20 Characters"
                    MsgLo "> Contains only letters and numbers"
                    $userInput = askUser "`nWhat would you like the name of your server to be?" "^[a-zA-Z0-9]{2,20}$"
                    
                    # Likely error checking needed trying to make/download a file
                    try{
                        $null = New-Item -Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Maps\" -Name $userInput -ItemType "directory"
                        $newServerPath = "$defaultDrive\Servers\ARK Survival Evolved\ARK Maps\$userInput"
                        $lastAction = "'$defaultDrive\Servers\ARK Survival Evolved\ARK Maps\$userInput' folder has been created"
                        
                        # Why is the pause not working?

                        # Turn these off until real testing
                        #"@echo off" > "$newServerPath\arkserver.bat"
                        #"start '' steamcmd.exe +login anonymous +force_install_dir '$defaultDrive\Servers\ARK Survival Evolved\Genesis\ARK Survival Evolved Server' +app_update 376030 validate" >> "$newServerPath\arkserver.bat"
                        "echo this is the bonus window" > "$newServerPath\arkserver.bat"
                        "pause" >> "$newServerPath\arkserver.bat"
                        $userInput = askUser "Would you like to launch the download terminal (Y\N)?" "^[yn]{1}$"
                        if ($userInput -imatch "n"){Break;}
                        & "$newServerPath\arkserver.bat"

                    }
                    catch [Error]{}
                }
            }
         }

        # Need to manage error, besides that it's okay
        # DELETE A SERVER
        8{
            while(1 -eq 1){
                $serverList = getServers;
                drawMenu "Servers" $serverList
                #cls
                #displayArrayAsIndexedList($serverList)
                $userInput = askUser "Which server would you like to delete?" "[0-$($serverList.Length+1)]"
                if ($userInput -eq 0){Break;}
                else { 
                    $safetyCheck = askUser "Are you sure you want to delete $($serverList[($userInput-1)]) (Y\N)?" "^[yn]{1}$"
                    if ($safetyCheck -imatch 'n') {Break;}
                    try{
                        Remove-Item -Path "$defaultDrive\Servers\ARK Survival Evolved\ARK Maps\$($serverList[($userInput-1)])" -Recurse;
                    }
                    catch [Error]{$lastAction = "Encountered an unknown error. Unable to delete '$defaultDrive\Servers\ARK Survival Evolved\ARK Maps\$($serverList[($userInput-1)])'."}
                    MsgLo "$($serverList[($userInput-1)]) has been deleted."
                    Break;}
                }
        }

        # EXIT
        0{MyExit;}
    }
}











