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
        # continuum adds its save call to status-right when it loads. On a
        # reload it can skip that step, so a reload must not reset status-right.
        extraConfig = ''
          set -g @bar-right " #{?session_many_attached,⚇ ,}#{?pane_synchronized,⚏ ,}| %Y %m%d %H%M | %U "
          %if "#{==:#{m:*continuum_save*,#{status-right}},0}"
          set -g status-right "#{T:@bar-right}"
          %endif
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

      set -g status-interval 15
      set -g status-style "fg=#8a8a8a,bg=#080808"
      set -g status-left "#[fg=#080808,bg=#8a8a8a,bold] #S #[default] "
      set -g status-left-length 100
      set -g status-right-length 100
      setw -g window-status-format "#{?window_last_flag, ,}#I #W#{?#{||:#{window_bell_flag},#{window_zoomed_flag}}, ,}#{?window_bell_flag,!,}#{?window_zoomed_flag,Z,}#{?window_last_flag, ,}"
      setw -g window-status-current-format " #I #W*#{?#{||:#{window_bell_flag},#{window_zoomed_flag}}, ,}#{?window_bell_flag,!,}#{?window_zoomed_flag,Z,} "
      setw -g window-status-style "fg=#8a8a8a,bg=#080808"
      setw -g window-status-current-style "fg=#080808,bg=#8a8a8a,bold"
      setw -g window-status-last-style "fg=#8a8a8a,bg=#303030"
      setw -g window-status-activity-style "underscore"
      setw -g window-status-bell-style "fg=#ffff00,blink,bold"
      set -g pane-border-style "fg=#303030"
      set -g pane-active-border-style "fg=#{?pane_in_mode,#ffb000,#{?synchronize-panes,#d70000,#00afff}}"
      set -g message-style "fg=#080808,bg=#8a8a8a,bold"
      set -g message-command-style "fg=#ffff00,bg=#080808,bold"
      set -g mode-style "fg=#080808,bg=#ffb000"
    '';
  };
}
