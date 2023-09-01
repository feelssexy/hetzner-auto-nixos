{ lib, ... }: # This make sure that our interface is named `eth0`.
# This should be ok as long as you don't have multiple physical network cards
# For multiple cards one could add a netdev unit to rename the interface based on the mac address
let smth = netname: ip: gateway: {
     		${netname}.extraConfig = ''
                    [Match]
                    Name = ${netname}
                    [Network]
                    # Add your own assigned ipv6 subnet here here!
                    Address = ${ip}
                    Gateway = ${gateway}
		'';
	};
in {
#networking.usePredictableInterfaceNames = false;
#systemd.network = {enable = true; networks.xd.extraConfig = "lol"; };
# i wonder how this could be fixed (recursiveUpdate expects two sets and not a list of sets)
#systemd.network = lib.recursiveUpdate [ { enable = true; }
#	(smth "enp1s0" "2a01:4f8:c012:e22f::/64" "fe80::1")
#	(smth "enp7s0" "10.1.0.3/24" "172.31.1.1") ];

systemd.network.enable = true;
#systemd.network.networks =
#	(smth "enp1s0" "2a01:4f8:c012:e22f::/64" "fe80::1") //
#	(smth "enp7s0" "10.1.0.3/24" "172.31.1.1");
#
#}

systemd.network.networks = {
	enp1s0.extraConfig = ''
	    [Match]
	    Name = enp1s0
	    [Network]
	    # Add your own assigned ipv6 subnet here here!
	    Address = 2a01:4f8:c012:e22f::1/64
	    Peer = fe80::1
	    [Route]
	    Gateway = fe80::1
	    GatewayOnLink = yes
	'';

	enp7s0.extraConfig = ''
	    [Match]
	    Name = enp7s0
	    [Network]
	    # Add your own assigned ipv6 subnet here here!
	    Address = 10.1.0.3/24
	    Peer = 172.31.1.1
	    [Route]
	    Gateway = 172.31.1.1
	    GatewayOnLink = yes
	'';
};
}
