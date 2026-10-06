{ lib, pkgs, ... }:
let
  bat = "${lib.getExe pkgs.bat} -l diff --paging=never --style=changes --color=always";
  logArgs = "--date=format:'%Y-%m-%d %H:%M' --color --abbrev-commit --decorate --pretty=format:'%C(dim white)%h%Creset %C(white dim)%C(white bold)%G?%Creset %C(brightblack)%ad %C(brightblack)%an%C(auto)%d%Creset %s'";
in
{
  programs.git = {
    enable = true;

    settings = {
      alias = {
        ls = "log --graph ${logArgs}";
        l = "log --graph --branches --tags --remotes --full-history --date-order --exclude=refs/stash ${logArgs}";
        lo = ''
          !f() { b=''${1:-HEAD}; base=$2; if [ -z "$base" ]; then for c in $(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null) main master; do if git rev-parse --verify -q "$c" >/dev/null; then base=$c; break; fi; done; fi; git ls "$base..$b"; }; f'';
        s = "status -uno -s";
        db = "-c pager.diff='${bat}' diff";
        sb = "-c pager.show='${bat}' show";
        lb = "-c pager.log='${bat}' log";
      };

      init.defaultBranch = "main";
      commit.verbose = true;
      push = {
        default = "simple";
        autoSetupRemote = true;
        followTags = true;
      };
      diff.tool = "vimdiff";
      difftool.prompt = false;
      advice.skippedCherryPicks = false;

      color = {
        ui = true;
        decorate = {
          branch = "red";
          localBranchCurrent = "brightred";
          remoteBranch = "yellow";
          tag = "brightyellow";
          head = "brightblack";
        };
        status = {
          added = "yellow";
          changed = "red";
          untracked = 240;
          branch = 245;
        };
        diff = {
          new = "yellow";
          old = 240;
        };
        interactive.prompt = "yellow";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      syntax-theme = "ansi";
      line-numbers = true;
      side-by-side = false;
      minus-style = "syntax #3a2a10";
      minus-emph-style = "syntax #5a4020";
      plus-style = "syntax #1a2a3a";
      plus-emph-style = "syntax #2a3a5a";
      line-numbers-minus-style = "#a8842a";
      line-numbers-plus-style = "#5a7a9a";
    };
  };
}
