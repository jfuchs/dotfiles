#!/usr/bin/env bash
# Visual regression test runner for zsh prompt
# Captures prompt screenshots and compares against baselines

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAPSHOTS_DIR="${SCRIPT_DIR}/snapshots"
ACTUAL_DIR="${SCRIPT_DIR}/actual"
DIFF_DIR="${SCRIPT_DIR}/diff"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detect available capture method
detect_capture_method() {
    if command -v termshot &> /dev/null; then
        echo "termshot"
    elif command -v aha &> /dev/null && command -v wkhtmltoimage &> /dev/null; then
        echo "aha"
    elif command -v ansihtml &> /dev/null; then
        echo "ansihtml"
    else
        echo "text"
    fi
}

# Detect available comparison method
detect_compare_method() {
    if command -v compare &> /dev/null; then
        echo "imagemagick"
    elif command -v pixelmatch &> /dev/null; then
        echo "pixelmatch"
    else
        echo "text"
    fi
}

CAPTURE_METHOD="${CAPTURE_METHOD:-$(detect_capture_method)}"
COMPARE_METHOD="${COMPARE_METHOD:-$(detect_compare_method)}"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Capture prompt output using termshot
capture_termshot() {
    local scenario="$1"
    local output_file="$2"

    termshot --show-cmd --filename "$output_file" -- \
        zsh -c "source ${SCRIPT_DIR}/scenarios.zsh && scenario_${scenario}"
}

# Capture prompt output using aha (ANSI to HTML) + wkhtmltoimage
capture_aha() {
    local scenario="$1"
    local output_file="$2"
    local html_file="${output_file%.png}.html"

    # Run scenario and convert ANSI to HTML
    zsh -c "source ${SCRIPT_DIR}/scenarios.zsh && scenario_${scenario}" 2>&1 | \
        aha --no-header > "$html_file"

    # Add styling for terminal look
    cat > "${html_file}.styled" <<EOF
<!DOCTYPE html>
<html>
<head>
<style>
body {
    background: #1e1e1e;
    padding: 20px;
    margin: 0;
    font-family: 'JetBrains Mono', 'Fira Code', 'Monaco', 'Menlo', monospace;
    font-size: 14px;
    line-height: 1.4;
}
pre {
    margin: 0;
    white-space: pre-wrap;
}
</style>
</head>
<body>
$(cat "$html_file")
</body>
</html>
EOF
    mv "${html_file}.styled" "$html_file"

    # Convert HTML to image
    wkhtmltoimage --quiet --quality 100 --width 800 "$html_file" "$output_file"
    rm -f "$html_file"
}

# Capture as text (fallback)
capture_text() {
    local scenario="$1"
    local output_file="$2"

    zsh -c "source ${SCRIPT_DIR}/scenarios.zsh && scenario_${scenario}" 2>&1 > "$output_file"
}

# Main capture function
capture_scenario() {
    local scenario="$1"
    local output_file="$2"

    case "$CAPTURE_METHOD" in
        termshot)
            capture_termshot "$scenario" "$output_file"
            ;;
        aha)
            capture_aha "$scenario" "$output_file"
            ;;
        *)
            capture_text "$scenario" "${output_file%.png}.txt"
            ;;
    esac
}

# Compare images using ImageMagick
compare_imagemagick() {
    local baseline="$1"
    local actual="$2"
    local diff_file="$3"

    # Get difference metric (0 = identical)
    local diff_metric
    diff_metric=$(compare -metric AE "$baseline" "$actual" "$diff_file" 2>&1) || true

    if [[ "$diff_metric" == "0" ]]; then
        return 0
    else
        return 1
    fi
}

# Compare text files
compare_text() {
    local baseline="$1"
    local actual="$2"
    local diff_file="$3"

    if diff -u "$baseline" "$actual" > "$diff_file" 2>&1; then
        return 0
    else
        return 1
    fi
}

# Main compare function
compare_files() {
    local baseline="$1"
    local actual="$2"
    local diff_file="$3"

    if [[ "$COMPARE_METHOD" == "imagemagick" && "$baseline" == *.png ]]; then
        compare_imagemagick "$baseline" "$actual" "$diff_file"
    else
        compare_text "$baseline" "$actual" "$diff_file"
    fi
}

# List of scenarios to test
SCENARIOS=(
    "no_git"
    "git_clean"
    "git_staged"
    "git_unstaged"
    "git_untracked"
    "git_mixed"
    "error"
    "long_command"
    "very_long_command"
    "deep_path"
)

# Generate baseline snapshots
generate_baselines() {
    log_info "Generating baseline snapshots..."
    log_info "Capture method: $CAPTURE_METHOD"

    mkdir -p "$SNAPSHOTS_DIR"

    local ext="png"
    [[ "$CAPTURE_METHOD" == "text" ]] && ext="txt"

    for scenario in "${SCENARIOS[@]}"; do
        local output_file="${SNAPSHOTS_DIR}/${scenario}.${ext}"
        log_info "  Capturing: $scenario"
        capture_scenario "$scenario" "$output_file"
    done

    log_info "Baselines generated in $SNAPSHOTS_DIR"
}

# Run visual regression tests
run_tests() {
    log_info "Running visual regression tests..."
    log_info "Capture method: $CAPTURE_METHOD"
    log_info "Compare method: $COMPARE_METHOD"

    mkdir -p "$ACTUAL_DIR" "$DIFF_DIR"

    local ext="png"
    [[ "$CAPTURE_METHOD" == "text" ]] && ext="txt"

    local passed=0
    local failed=0
    local missing=0

    for scenario in "${SCENARIOS[@]}"; do
        local baseline="${SNAPSHOTS_DIR}/${scenario}.${ext}"
        local actual="${ACTUAL_DIR}/${scenario}.${ext}"
        local diff_file="${DIFF_DIR}/${scenario}.${ext}"

        # Capture current state
        capture_scenario "$scenario" "$actual"

        if [[ ! -f "$baseline" ]]; then
            log_warn "  $scenario: MISSING BASELINE"
            ((missing++))
            continue
        fi

        # Compare
        if compare_files "$baseline" "$actual" "$diff_file"; then
            echo -e "  ${GREEN}PASS${NC}: $scenario"
            ((passed++))
            rm -f "$diff_file"  # Clean up diff for passing tests
        else
            echo -e "  ${RED}FAIL${NC}: $scenario (see ${diff_file})"
            ((failed++))
        fi
    done

    echo ""
    log_info "Results: $passed passed, $failed failed, $missing missing baselines"

    if [[ $failed -gt 0 ]]; then
        log_error "Visual regression tests failed!"
        log_info "Review diffs in $DIFF_DIR"
        log_info "To update baselines, run: $0 update"
        return 1
    fi

    if [[ $missing -gt 0 ]]; then
        log_warn "Some baselines are missing. Run '$0 generate' to create them."
    fi

    return 0
}

# Update baselines from actual (after reviewing diffs)
update_baselines() {
    if [[ ! -d "$ACTUAL_DIR" ]]; then
        log_error "No actual screenshots found. Run tests first."
        return 1
    fi

    log_info "Updating baselines from actual screenshots..."

    cp -r "$ACTUAL_DIR"/* "$SNAPSHOTS_DIR"/
    rm -rf "$ACTUAL_DIR" "$DIFF_DIR"

    log_info "Baselines updated."
}

# Clean up test artifacts
clean() {
    log_info "Cleaning test artifacts..."
    rm -rf "$ACTUAL_DIR" "$DIFF_DIR" "${SCRIPT_DIR}/test-repo"
    log_info "Done."
}

# Print usage
usage() {
    cat <<EOF
Usage: $0 <command>

Commands:
    test      Run visual regression tests
    generate  Generate baseline snapshots
    update    Update baselines from actual screenshots
    clean     Remove test artifacts
    help      Show this help message

Environment Variables:
    CAPTURE_METHOD  Override capture method (termshot, aha, text)
    COMPARE_METHOD  Override compare method (imagemagick, pixelmatch, text)

Current Configuration:
    Capture: $CAPTURE_METHOD
    Compare: $COMPARE_METHOD
EOF
}

# Main
case "${1:-test}" in
    test)
        run_tests
        ;;
    generate)
        generate_baselines
        ;;
    update)
        update_baselines
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        log_error "Unknown command: $1"
        usage
        exit 1
        ;;
esac
