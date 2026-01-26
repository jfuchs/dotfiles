# Simple, reliable prompt similar to p10k lean style
# Shows: directory, git info, command execution time, exit status
# Git status is fetched asynchronously to avoid blocking

# Enable colors
autoload -U colors && colors

# ============================================================================
# Async git status
# ============================================================================

# State variables
_prompt_git_info=""
_prompt_exec_start=0
_prompt_exec_time=0
_prompt_exit_code=0
_prompt_async_fd=""
_prompt_async_pid=""

# Get git status synchronously (called in background)
_prompt_git_status() {
  cd -q "$1" 2>/dev/null || return

  # Check if we're in a git repo
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || \
  branch=$(git rev-parse --short HEAD 2>/dev/null) || return

  local result="%F{cyan}${branch}%f"

  # Check for staged changes
  if ! git diff --cached --quiet 2>/dev/null; then
    result+="%F{green}+%f"
  fi

  # Check for unstaged changes
  if ! git diff --quiet 2>/dev/null; then
    result+="%F{yellow}!%f"
  fi

  # Check for untracked files
  if [[ -n $(git ls-files --others --exclude-standard 2>/dev/null | head -1) ]]; then
    result+="%F{blue}?%f"
  fi

  echo " ${result}"
}

# Callback when async job completes
_prompt_async_callback() {
  local fd="$1"

  # Read result from file descriptor
  _prompt_git_info=""
  if [[ -n "$fd" ]] && read -r -u "$fd" _prompt_git_info 2>/dev/null; then
    : # Successfully read
  fi

  # Clean up file descriptor
  if [[ -n "$_prompt_async_fd" ]]; then
    zle -F "$_prompt_async_fd" 2>/dev/null
    exec {_prompt_async_fd}<&- 2>/dev/null
    _prompt_async_fd=""
  fi

  _prompt_async_pid=""

  # Redraw prompt with new git info
  zle && zle reset-prompt
}

# Start async git status fetch
_prompt_async_start() {
  # Kill any existing async job
  if [[ -n "$_prompt_async_pid" ]]; then
    kill "$_prompt_async_pid" 2>/dev/null
    _prompt_async_pid=""
  fi

  # Clean up old file descriptor
  if [[ -n "$_prompt_async_fd" ]]; then
    zle -F "$_prompt_async_fd" 2>/dev/null
    exec {_prompt_async_fd}<&- 2>/dev/null
    _prompt_async_fd=""
  fi

  # Clear git info while loading
  _prompt_git_info=""

  # Quick check: are we in a git repo at all?
  git rev-parse --is-inside-work-tree &>/dev/null || return

  # Start background job and capture output via fd
  exec {_prompt_async_fd}< <(_prompt_git_status "$PWD")
  _prompt_async_pid=$!

  # Register callback for when data is available
  zle -F "$_prompt_async_fd" _prompt_async_callback
}

# ============================================================================
# Prompt hooks
# ============================================================================

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

  # Start async git status fetch
  _prompt_async_start
}

# ============================================================================
# Prompt segments
# ============================================================================

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

# Right prompt with time
_prompt_time() {
  echo "%F{8}%T%f"
}

# ============================================================================
# Set prompts
# ============================================================================

setopt PROMPT_SUBST

PROMPT='%F{blue}%~%f${_prompt_git_info}
$(_prompt_char) '

RPROMPT='$(_prompt_format_time)$(_prompt_time)'
