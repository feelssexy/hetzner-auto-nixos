#!/bin/env zsh
set -e

host="${1:-root@10.1.0.3}"
myip="10.1.0.2"
ssh() {
	command ssh -o StrictHostKeyChecking=no $host "$@"
}
echo $host

#sed -i '/^10\.1\.0\.3/d' ~/.ssh/known_hosts # dangerous command, doesn't change with $host
ssh-keygen -R 10.1.0.3
ssh-copy-id -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no $host
ssh umount -R /mnt || true # necessary for reruns
ssh fdisk /dev/sda <<EOF
g
n


+1G
t
1
n



w
EOF
ssh bash -c \''mkfs.fat -F 32 /dev/sda1
fatlabel /dev/sda1 NIXBOOT
mkfs.ext4 /dev/sda2 -L NIXROOT
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot'\'

rsync -vPr --mkpath . ${host}:/mnt/etc/nixos/

ssh ls .ssh/id_ed25519 || yes '' | ssh ssh-keygen -t ed25519
# host hardcoded here
ssh cat './.ssh/*.pub' | sed 's/root@nixos$/Hewwo/' >> ~/.ssh/authorized_keys

# add to known_hosts (i do NOT know how to get the correct format for the known_hosts file and it infuriates me)
#{ echo -n $myip\ ; < ~/.ssh/id_ed25519.pub | cut -d\  -f1-2 } | ssh tee .ssh/known_hosts
#ssh ssh user@$myip -o StrictHostKeyChecking=no
ssh tee -a .ssh/known_hosts <<< "10.1.0.2 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPXebM6I1rvCJvFpwO4nfNJGuduzP1ed5FWKKFKeFjr"
# is -- necessary? turns out no..?
ssh ssh user@$myip -fND 1080
sed -i '/ Hewwo$/d' ~/.ssh/authorized_keys # dangerous
ssh tee -a /etc/profile.local <<< $'export all_proxy=socks5h://localhost:1080\nexport ALL_PROXY="$all_proxy"'
# better way to set env please?
#ssh bash -c \''all_proxy=socks5h://localhost:1080 nixos-install'\'

ssh mkdir -m 700 /mnt/root/.ssh
ssh cp /mnt/etc/nixos/nixkey /etc/nixos
echo -n {/mnt,}/root/.ssh/config | ssh xargs -I{} -d'" "'  cp /mnt/etc/nixos/sshconfig {}
#ssh cp /mnt/etc/nixos/sshconfig /root/.ssh/config
#ssh cp /mnt/etc/nixos/sshconfig /mnt/root/.ssh/config

ssh rm -rf /mnt/etc/nixos
ssh git clone git@github.com:nixvps/nixos-configuration.git /mnt/etc/nixos 

ssh bash -lc nixos-install
ssh-keygen -R 10.1.0.3

#ssh reboot 0
