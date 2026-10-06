{ config, pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    keyMode = "vi";
    baseIndex = 1;
    mouse = true;
    focusEvents = true;
    escapeTime = 10;
    historyLimit = 10000;
    terminal = "screen-256color";
    clock24 = true;
    secureSocket = false;

    plugins = [
      {
        plugin = pkgs.tmuxPlugins.resurrect;
        # The nixpkgs release of resurrect does not use XDG_DATA_HOME by default.
        extraConfig = ''
          set -g @resurrect-dir '${config.xdg.dataHome}/tmux/resurrect'
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = pkgs.tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
        '';
      }
    ];

    extraConfig = ''
      set -sa terminal-features ',alacritty:RGB'
      set -sa terminal-features ',xterm-256color:RGB'
      set -g display-time 4000

      # copy mode hands the selection to the terminal over OSC 52
      set -g set-clipboard external
      set -g allow-passthrough on
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-selection
      bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel

      bind c new-window -c '#{pane_current_path}'
      bind i command-prompt -p "insert window at:" "new-window -b -t :'%1' -c '#{pane_current_path}'"
      bind -r p previous-window
      bind -r n next-window
      bind -r o last-window

      bind '"' split-window -v -c '#{pane_current_path}'
      bind % split-window -h -c '#{pane_current_path}'

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
    '';
  };
}
