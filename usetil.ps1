# A convenient bundle of scripted utilities - Created by Connor :)

$option = "none"
$makeChoice = $true
$validCmd = @('ping','p')

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$parts = $currentUser -split '\\'
$username = $parts[-1] # Gets the current users name and strips its domain name

$orig_fg_color = $host.UI.RawUI.ForegroundColor

while ($option -eq "none") {
    $correct = $false

    if ($makeChoice -eq $true) {
        Write-Host "`nType a command or 'help' for a list of commands"
        $choice = Read-Host ">"; $choice = $choice.Trim()
        [System.Console]::Clear()

        if ($choice -ieq "a command") { $correct = $true; ":D" }

        $tokens = $choice -split '\s+', 2
        $choice = $tokens[0]
        if ($validCmd -contains $choice -and $tokens[1]) { $pingIP = $tokens[1]; $prePing = $true }
    }

    if ($recentMode -eq $true) { $choice = "recent" } else { $makeChoice = $true }
    
    switch ($choice) {
        # THE HELP MENU - Uses $correct to skip the "Input an actual command" error
        {$_ -in "help", "h"} {
            Write-Host @"

The Help Menu:

help | h: List this menu

terminal |  term |  t: Start-Process cmd.exe or powershell.exe
search   |  ad   |  s: Search your PC's active directory computer descriptions and query for MAC addresses
wake     |  wol  |  w: Send a magic packet to a MAC Address, UDP via port 7
ping     |          p: Ping a selected host in 3 different modes
exprs    |         rs: Restart and open Windows Explorer
gpupdate |  gpu  | gp: Run a simple forced group policy update
              booyeah: -

Often times Y = "e" and N = "q"

- Connor's Scripted Toolkit (ISE Iteration 1)-
https://github.com/coredmo/Powershell-ISE---ScriptEnder`n
"@
            Write-Host "Press enter to return..."
            $noid = Read-Host -Debug; Clear-Host
            if ($noid -ieq "dingus") { Start-Process "https://cat-bounce.com/" } elseif ($noid -ieq " ") { Write-Host "dingus" }
            $correct = $true
        }

        # Start-Process cmd.exe or powershell.exe
        {$_ -in "terminal","term","t"} {
            $correct = $true
            $folderPath = "C:\users\$username"
            Write-Host "Do you want to start the instance in Administrator? Y or E - Yes"
            $tchoose1 = [System.Console]::ReadKey().Key
            [System.Console]::Clear()

            Write-Host "Press E for cmd.exe or press Q for powershell.exe"
            $tchoose2 = [System.Console]::ReadKey().Key
            [System.Console]::Clear()

            if ($tchoose2 -ieq "e") {
                if ($choose -ieq "y" -or $tchoose1 -ieq "e") { Start-Process cmd.exe -Verb RunAs -WorkingDirectory $folderPath }
                else { Start-Process cmd.exe -WorkingDirectory $folderPath }
            } 
            elseif ($tchoose2 -ieq "q") {
                if ($choose -ieq "y" -or $tchoose1 -ieq "e") { Start-Process powershell.exe -Verb RunAs -WorkingDirectory $folderPath }
                else { Start-Process powershell.exe -WorkingDirectory $folderPath }
            } 
            else { $host.UI.RawUI.ForegroundColor = "Red"
                Write-Host "Invalid"; $host.UI.RawUI.ForegroundColor = $orig_fg_color
            }
        }

        # Search the local active directory's computer descriptions
        {$_ -in "ad", "search", "s"} {
            $adMode = $true
            $preBreak = $false
            $pingConfig = $false
            $adLoop = $true
            while ($adLoop) {
                Write-Host "Do you want to enable host pinging? Y | Yes - N | No"
                $adInput = $Host.UI.RawUI.ReadKey("IncludeKeyDown,NoEcho").Character
                if ($adInput -ieq "y" -or $adInput -ieq "e") { 
                    $dcIP = (Resolve-DnsName -Name (Get-ADDomainController).HostName | Select-Object -ExpandProperty IPAddress).ToString()
                    $pingConfig = $true; $adLoop = $false; [System.Console]::Clear(); "Pinging each selected host"
                }
                if ($adInput -ieq "n" -or $adInput -ieq "q") { $pingConfig = $false; $adLoop = $false; [System.Console]::Clear(); "Skipping ping function"}
            }
            while ($adMode -eq $true) {
                if ($savedConfo -eq $true -and $recents.Count -gt 0) { 
                    $host.UI.RawUI.ForegroundColor = "Yellow"; Write-Host "Recent Results:`n $recents"; $host.UI.RawUI.ForegroundColor = $orig_fg_color }
                do {
                    Write-Host "- Enter any piece of the computer object's description or leave it blank to return to the console -"
                    $input = Read-Host "You can press 'c' while it's querying to abort the process`n>"
                    if (-not $input) {
                        [System.Console]::Clear();
                        $adMode = $false
                        $preBreak = $true; break
                    }
                } while (-not $input)
                [System.Console]::Clear();
                if ($preBreak -eq $true) { $correct = $true; continue }
            
                $host.UI.RawUI.ForegroundColor = "Yellow"
                Write-Host "Showing results for $input`n"
                $host.UI.RawUI.ForegroundColor = $orig_fg_color
            
                $result = Get-ADComputer -Filter "Description -like '*$input*'" -Properties Description
                $dcTarget = $false
            
                $unitList = @();
                if ($result) {
                    foreach ($computer in $result) {
                        $cancelResult = $false
                        if ([System.Console]::KeyAvailable -and [System.Console]::ReadKey().Key -eq "C") {
                            Write-Host " button pressed:`nAborting query..."
                            Start-Sleep -Milliseconds 60
                            $cancelResult = $true
                        }
                        if ($cancelResult) { break }
                        $unitlist += $computer.Name

                        Write-Host "$($computer.Name), $($computer.Description)"
                        $nsResult = nslookup $($computer.Name)
                        $nsRegex = "(?:\d{1,3}\.){3}\d{1,3}(?!.*(?:\d{1,3}\.){3}\d{1,3})"
                        $nsMatches = [regex]::Matches($nsResult, $nsRegex)
                        if ($pingConfig -eq $true) { 
                            if ($dcIP -notcontains $nsMatches) {
                                $pingResult = ping -n 1 $nsMatches
                                if (-not $?) { $host.UI.RawUI.ForegroundColor = "Red"; "$pingResult"; $host.UI.RawUI.ForegroundColor = $orig_fg_color }
                                else { $host.UI.RawUI.ForegroundColor = "Green"; "The host '$nsMatches' was pinged successfully"; $host.UI.RawUI.ForegroundColor = $orig_fg_color }
                            } else { 
                                $host.UI.RawUI.ForegroundColor = "Red"
                                "Ping skipped: Target is the domain controller"
                                $host.UI.RawUI.ForegroundColor = $orig_fg_color
                                $dcTarget = $true
                            }
                        }
                        $macResult = arp -a | findstr "$nsMatches"
                        if ($macResult -eq $null -or $macResult -eq '') {
                            if ($pingResult -like "*Request timed out.*" -or $pingResult -like "*could not find host*") { $diffLan = $false } else { $diffLan = $true }
                            if ($diffLan -eq $true) {
                            $host.UI.RawUI.ForegroundColor = "Yellow"
                            if ($dcTarget -eq $false) { Write-Host "  This host may be in a different LAN" }
                            $dcTarget = $false
                            $host.UI.RawUI.ForegroundColor = $orig_fg_color
                            $diffLan = $false
                            }
                        }
                        $host.UI.RawUI.ForegroundColor = "Yellow"; Write-Host "$macResult`n"; $host.UI.RawUI.ForegroundColor = $orig_fg_color
                        "----------------------------"
                    }
                } else {
                    Write-Host "No results found for $input`n"
                }
                Write-Host "`nPress any key to reset or press S to save this list to the recents list`nPress c to return to the command line..."
                $adOption = [System.Console]::ReadKey().Key; [System.Console]::Clear();
                if ($adOption -ieq "c") { $adMode = $false; $correct = $true}
                elseif ($adOption -ieq "s") { $recents = $unitList; $savedConfo = $true }
            }
        }

        # Select an address from the recents list and read details/run scripts on them
        {$_ -in "recents", "recent", "rec", "r"} {
            if ($recents -ne $null) {
                $recentMode = $true
                while ($recentMode) {
                    $host.UI.RawUI.ForegroundColor = "Yellow"; Write-Host "Recent Results:`n $recents"; $host.UI.RawUI.ForegroundColor = $orig_fg_color
                    $thiss = Read-Host; if ($thiss -ieq "c") { $rcSelect = $false; $correct = $true }
                }
            } else { Write-Host "There is no recents list, use the AD Query script to make one"; $correct = $true }
        }

        # Send a magic packet to a MAC Address, UDP via port 7
        {$_ -in "wake","wol","w"} {
            $wolMode = $true
            while ($wolMode -eq $true) {
	            if ($recentMode -eq $true) { $mac = $recentMAC }
                else { $mac = Read-Host "Input a MAC Address or leave it blank to return" }
                if ($mac -eq $null -or $mac -eq '') { $wolMode = $false; $correct = $true; Clear-Host } 
                else {
	                $macByteArray = $mac -split "[:-]" | ForEach-Object { [Byte] "0x$_"}
	                [Byte[]] $magicPacket = (,0xFF * 6) + ($macByteArray  * 16)
	                $udpClient = New-Object System.Net.Sockets.UdpClient
	                $udpClient.Connect(([System.Net.IPAddress]::Broadcast),7)
	                $udpClient.Send($MagicPacket,$MagicPacket.Length)
	                $udpClient.Close()
	                Write-Host "$mac --- $macByteArray"
                    Start-Sleep -Milliseconds 2800
                    if ($recentMode -eq $true) { $wolMode = $false; $correct = $true; Clear-Host }
                }
            }
        }

        # Ping a selected host in different modes
        {$_ -in "ping","p"} {
            $pingOption = $true
            while ($pingOption -eq $true) {
                if ($prePing -eq $null) { 
                    do {
                        $pingIP = Read-Host "- Easy ping utility - Enter an IP -`n>"
                        if (-not $pingIP) {
                            [System.Console]::Clear();
                            $host.UI.RawUI.ForegroundColor = "Red"
                            Write-Host "Error: Input cannot be blank. Please enter a valid string."
                            $host.UI.RawUI.ForegroundColor = $orig_fg_color
                        }
                    } while (-not $pingIP) 
                }

                do {
                    $eValues = @('a', 'b', 'c')
                    Write-Host "Pinging '$pingIP'`n`nWhat type of scan do you want?`nA - 5 attempts | B - 1 attempts | C - Indefinite"
                    $n = $Host.UI.RawUI.ReadKey("IncludeKeyDown,NoEcho").Character
                    if ($eValues -notcontains $n) {
                        [System.Console]::Clear();
                        $host.UI.RawUI.ForegroundColor = "Red"
                        Write-Host "Error: Input cannot be blank or incorrect. Please enter a valid option."
                        $host.UI.RawUI.ForegroundColor = $orig_fg_color
                    }
                } while ($eValues -notcontains $n)
                [System.Console]::Clear()
                $host.UI.RawUI.ForegroundColor = "Yellow"
                Write-Host "Processing Ping..."
                $host.UI.RawUI.ForegroundColor = $orig_fg_color

                if ($n -ieq "a") { $n = 5 } elseif ($n -ieq "b") { $n = 1 }
                if ($n -ieq "c") { $constPing = $true } else { $pingResult = ping -n $n $pingIP }

                if ($constPing -eq $true) { Write-Host "Press C at any point to cancel" }
                while ($constPing -eq $true) {
                    $pingResult = ping -n 1 $pingIP
                    "$pingResult`n"
                    Start-Sleep -Milliseconds 500
                    if ([System.Console]::KeyAvailable -and [System.Console]::ReadKey().Key -eq "C") {
                        Write-Host " > Abort button pressed:`nPress any key to continue"
                        [System.Console]::ReadKey().Key
                        $constPing = $false
                    }
                }

                [System.Console]::Clear()
                $pingResult

                $host.UI.RawUI.ForegroundColor = "Yellow"
                Write-Host "`nPress any key to restart or press C to return to the console"
                $host.UI.RawUI.ForegroundColor = $orig_fg_color

                $cancel = [System.Console]::ReadKey().Key
                [System.Console]::Clear()
                if ($cancel -ieq "c") { $pingOption = $null }
            }
            [System.Console]::Clear()
            $correct = $true
            $prePing = $null
        }

        # Run a simple forced group policy update
        {$_ -in "gpupdate","gp"} {
            Write-Host "Running Group Policy Update"
            gpupdate /Force
            Write-Host "Press any key to continue..."
            [System.Console]::ReadKey().Key
            $correct = $true
        }

        # Restart and open Windows Explorer
        {$_ -in "exprs","rs"} { Stop-Process -Name explorer -Force; Start-Process explorer; $correct = $true }

        # Debug
        "e" { $recents; $notused = $Host.UI.RawUI.ReadKey("IncludeKeyDown,NoEcho"); $correct = $true }

        "booyeah" {
            "Opening 300 instances of the calculator..."
            Start-Sleep -Milliseconds 1800
            "jk"; Start-Sleep -Milliseconds 650; "jk"
            Start-Sleep -Milliseconds 1000
            $correct = $true
            while ($true) { 
                Write-Host "Press A-debug or B-fibba"
                $choose = [System.Console]::ReadKey().Key
                [System.Console]::Clear()
                if ($choose -ieq "a") {
                    $option = "debug"
                    break
                } elseif ($choose -ieq "b") {
                    $option = "fibba" 
                    break
            } Clear-Host }
        }
    }

    if ($correct -eq $true) {
        continue
    }

    Clear-Host
    $host.UI.RawUI.ForegroundColor = "Red"
    Write-Host "Please input an actual command or follow the latter half of these here instructions"
    $host.UI.RawUI.ForegroundColor = $orig_fg_color
}

while ($option -eq "fibba") {
    Write-Host "`nDebug & test section 1"
    Write-Host "`nPress any key to start the Fibonacci Mode..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Clear-Host
    # Fib(b)onacci Mode
    $fib = 1
    $bon = 0
    while ($true) {
        "`nFibonacci Mode: Active`nPress C to cancel`n"
        $acci = $fib + $bon
        $fib = $bon
        $bon = $acci
        $host.UI.RawUI.ForegroundColor = "Green"
        "     $acci"
        $host.UI.RawUI.ForegroundColor = $orig_fg_color
        Start-Sleep -Milliseconds 500
        Clear-Host
        if ([System.Console]::KeyAvailable -and [System.Console]::ReadKey().Key -eq "C") { [System.Console]::Clear(); break }
    }
    Start-Sleep -Milliseconds 500
}

while ($option -eq "debug") {
    Write-Host "This is a debug section"
    Start-Sleep -Milliseconds 20
}