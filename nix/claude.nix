{ lib, pkgs, ... }:
let
  statusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      gawk
      git
      jq
      util-linux
    ];
    bashOptions = [ "nounset" ];
    text = builtins.readFile ./claude-statusline.sh;
  };
in
{
  programs.claude-code = {
    enable = true;
    # claude comes from its own installer, not from nixpkgs.
    package = null;
    # settings.json holds keys this module does not declare.
    mutableSettings = true;
    settings.statusLine = {
      type = "command";
      command = lib.getExe statusline;
    };
  };
}
