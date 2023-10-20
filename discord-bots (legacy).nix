{ config, pkgs, drugs, ... }: {
  mclaive = pkgs.buildPythonPackage {
    pname = "mclaive";

    src = pkgs.fetchtgit {
      
    };

  };
}
