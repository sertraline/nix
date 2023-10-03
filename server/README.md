# NixOS-anywhere conf
From machine: `nixos-rebuild switch --flake <url>`  
From remote: `NIX_SSHOPTS="-p 2216" nixos-rebuild switch --flake .#ovh --target-host "root@10.2.0.1"`

