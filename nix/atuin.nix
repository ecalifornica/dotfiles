{ config, lib, ... }:
{
  programs.atuin = {
    enable = true;
    # zsh-vi-mode binds its keys at init. atuin must bind after that.
    enableZshIntegration = false;
  };

  programs.zsh.initContent = ''
    zvm_after_init_commands+=('eval "$(${lib.getExe config.programs.atuin.package} init zsh)"')
  '';
}
