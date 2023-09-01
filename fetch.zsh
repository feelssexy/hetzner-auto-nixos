timeout 3 rsync -vPrc "$@" --exclude '*.zsh' alice@10.1.0.3:/etc/nixos/ . || rsync -vPrc "$@" --exclude '*.zsh' root@10.1.0.3:/mnt/etc/nixos/ .
