{
  description = "Shared home-manager modules";

  outputs = _: {
    homeModules.core = ./nix/core.nix;
  };
}
