{ config, ... }:
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    history = {
      size = 0;
      save = 0;
      share = false;
    };
    initContent = "unset HISTFILE";

    shellAliases = {
      l = "ls -lah";
      ll = "ls -lh";
      g = "git";
      gs = "git status";
      gd = "git diff";
      gdc = "git diff --cached";
      gc = "git commit";
      gl = "git l";
      gls = "git ls";
      up = "git add -up";
    };
  };
}
