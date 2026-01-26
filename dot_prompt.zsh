# Simple, reliable prompt similar to p10k lean style
# Shows: directory, git info, command execution time, exit status

# Enable colors
autoload -U colors && colors

# Enable vcs_info for git status
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '%F{green}+'
zstyle ':vcs_info:*' unstagedstr '%F{yellow}!'
zstyle ':vcs_info:git:*' formats '%F{cyan}%b%f%c%u'
zstyle ':vcs_info:git:*' actionformats '%F{cyan}%b%f|%F{red}%a%f%c%u'

# Track command execution time
_prompt_exec_start=0
_prompt_exec_time=0

preexec() {
  _prompt_exec_start=$EPOCHREALTIME
}

precmd() {
  local exit_code=$?

  # Calculate execution time
  if (( _prompt_exec_start > 0 )); then
    _prompt_exec_time=$(( EPOCHREALTIME - _prompt_exec_start ))
    _prompt_exec_start=0
  else
    _prompt_exec_time=0
  fi

  # Store exit code for prompt
  _prompt_exit_code=$exit_code

  # Update vcs_info
  vcs_info
}

# Format execution time (only show if > 3 seconds)
_prompt_format_time() {
  (( _prompt_exec_time < 3 )) && return

  local t=${_prompt_exec_time%.*}
  local d=$((t / 86400))
  local h=$(((t % 86400) / 3600))
  local m=$(((t % 3600) / 60))
  local s=$((t % 60))

  local result=""
  (( d > 0 )) && result+="${d}d "
  (( h > 0 )) && result+="${h}h "
  (( m > 0 )) && result+="${m}m "
  result+="${s}s"

  echo "%F{yellow}took ${result}%f "
}

# Prompt character: green for success, red for error
_prompt_char() {
  if (( _prompt_exit_code == 0 )); then
    echo '%F{green}❯%f'
  else
    echo '%F{red}❯%f'
  fi
}

# Git info with untracked files indicator
_prompt_git() {
  [[ -z "${vcs_info_msg_0_}" ]] && return

  local git_info="${vcs_info_msg_0_}"

  # Check for untracked files
  if command git status --porcelain 2>/dev/null | grep -q '^??'; then
    git_info+='%F{blue}?%f'
  fi

  echo " ${git_info}"
}

# Right prompt with time
_prompt_time() {
  echo "%F{8}%T%f"
}

# Set prompts
setopt PROMPT_SUBST

PROMPT='%F{blue}%~%f$(_prompt_git)
$(_prompt_char) '

RPROMPT='$(_prompt_format_time)$(_prompt_time)'
