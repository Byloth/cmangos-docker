$WSL_IP = (wsl -- ip address show eth0 | Select-String -Pattern "inet ([\d.]+)").Matches.Groups[1].Value;

netsh interface portproxy add v4tov4 listenport=3724 listenaddress=0.0.0.0 connectport=3724 connectaddress=$WSL_IP
netsh interface portproxy add v4tov4 listenport=8085 listenaddress=0.0.0.0 connectport=8085 connectaddress=$WSL_IP
