#!/usr/bin/env zsh
# Prompt test scenarios
# Each function sets up a specific state and prints the prompt

set -e

SCRIPT_DIR="${0:A:h}"
TEST_REPO_DIR="${SCRIPT_DIR}/test-repo"

# Source the prompt
source "${SCRIPT_DIR}/../../dot_prompt.zsh"

# Helper to render the prompt for a given state
render_prompt() {
    local scenario_name="$1"
    local exit_code="${2:-0}"
    local exec_time="${3:-0}"

    # Set up prompt variables
    _prompt_exit_code=$exit_code
    _prompt_exec_time=$exec_time

    # Update vcs_info
    vcs_info

    # Expand the prompts
    local left_prompt="${(e)PROMPT}"
    local right_prompt="${(e)RPROMPT}"

    # Print scenario header
    print -P "%F{8}─── ${scenario_name} ───%f"

    # Print the prompt (simulating terminal width)
    local term_width=80
    local left_len=${#${(S%%)left_prompt//\%\{*\%\}/}}
    local right_len=${#${(S%%)right_prompt//\%\{*\%\}/}}
    local padding=$((term_width - left_len - right_len))

    if (( padding > 0 )); then
        print -P "${left_prompt}${(l:$padding:)}\n${right_prompt}"
    else
        print -P "${left_prompt}"
        print -P "${right_prompt}"
    fi
    print ""
}

# Setup test git repo
setup_test_repo() {
    rm -rf "$TEST_REPO_DIR"
    mkdir -p "$TEST_REPO_DIR"
    cd "$TEST_REPO_DIR"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test User"
    echo "initial" > file.txt
    git add file.txt
    git commit -q -m "Initial commit"
}

# Scenario: Clean git repo
scenario_git_clean() {
    setup_test_repo
    render_prompt "git-clean"
}

# Scenario: Git repo with staged changes
scenario_git_staged() {
    setup_test_repo
    echo "staged change" >> file.txt
    git add file.txt
    render_prompt "git-staged"
}

# Scenario: Git repo with unstaged changes
scenario_git_unstaged() {
    setup_test_repo
    echo "unstaged change" >> file.txt
    render_prompt "git-unstaged"
}

# Scenario: Git repo with untracked files
scenario_git_untracked() {
    setup_test_repo
    echo "new file" > newfile.txt
    render_prompt "git-untracked"
}

# Scenario: Git repo with all types of changes
scenario_git_mixed() {
    setup_test_repo
    echo "staged" >> file.txt
    git add file.txt
    echo "unstaged" >> file.txt
    echo "untracked" > untracked.txt
    render_prompt "git-mixed"
}

# Scenario: Non-git directory
scenario_no_git() {
    local tmpdir=$(mktemp -d)
    cd "$tmpdir"
    render_prompt "no-git"
    rm -rf "$tmpdir"
}

# Scenario: Command failed (exit code 1)
scenario_error() {
    setup_test_repo
    render_prompt "error-exit" 1
}

# Scenario: Long running command (5 seconds)
scenario_long_command() {
    setup_test_repo
    render_prompt "long-command-5s" 0 5
}

# Scenario: Very long running command (1 hour)
scenario_very_long_command() {
    setup_test_repo
    render_prompt "long-command-1h" 0 3600
}

# Scenario: Deep directory path
scenario_deep_path() {
    setup_test_repo
    mkdir -p very/deep/nested/directory/structure
    cd very/deep/nested/directory/structure
    render_prompt "deep-path"
}

# Cleanup
cleanup() {
    rm -rf "$TEST_REPO_DIR"
}

# Run all scenarios
run_all() {
    print -P "%F{cyan}%BPrompt Visual Test Scenarios%b%f\n"

    scenario_no_git
    scenario_git_clean
    scenario_git_staged
    scenario_git_unstaged
    scenario_git_untracked
    scenario_git_mixed
    scenario_error
    scenario_long_command
    scenario_very_long_command
    scenario_deep_path

    cleanup
    print -P "%F{green}All scenarios rendered%f"
}

# Run specific scenario or all
if [[ -n "$1" ]]; then
    "scenario_$1"
    cleanup
else
    run_all
fi
