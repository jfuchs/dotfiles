# Visual Regression Tests for Zsh Prompt

This directory contains visual regression tests for the custom zsh prompt.
The tests capture screenshots of the prompt in various states and compare
them against baseline images to detect unintended visual changes.

## Test Scenarios

The following prompt states are tested:

| Scenario | Description |
|----------|-------------|
| `no_git` | Directory without git repository |
| `git_clean` | Clean git repository |
| `git_staged` | Repository with staged changes |
| `git_unstaged` | Repository with unstaged changes |
| `git_untracked` | Repository with untracked files |
| `git_mixed` | Repository with staged, unstaged, and untracked changes |
| `error` | After a command exits with error |
| `long_command` | After a command taking 5 seconds |
| `very_long_command` | After a command taking 1 hour |
| `deep_path` | Deeply nested directory path |

## Requirements

### For full image-based testing:
- `termshot` - Terminal screenshot tool ([homeport/termshot](https://github.com/homeport/termshot))
- `imagemagick` - For image comparison (`compare` command)

### Alternative (HTML-based):
- `aha` - ANSI to HTML converter
- `wkhtmltopdf` - HTML to image converter

### Fallback (text-based):
- No additional dependencies (uses plain diff)

## Usage

```bash
# Run tests (compares against baselines)
./run-tests.sh test

# Generate baseline snapshots
./run-tests.sh generate

# Update baselines after reviewing changes
./run-tests.sh update

# Clean up test artifacts
./run-tests.sh clean
```

## How It Works

1. **Scenario Setup**: `scenarios.zsh` creates temporary git repos in various
   states (clean, dirty, staged changes, etc.)

2. **Capture**: The prompt is rendered and captured as either:
   - PNG images (via `termshot` or `aha` + `wkhtmltoimage`)
   - Plain text with ANSI codes (fallback)

3. **Compare**: Current screenshots are compared against baselines:
   - Image diff via ImageMagick (shows pixel differences)
   - Text diff (shows line-by-line changes)

4. **Report**: Failed tests generate diff files showing what changed.

## CI Integration

The GitHub Actions workflow (`.github/workflows/visual-tests.yml`):
- Runs on every push/PR that modifies prompt files
- Uses a consistent Ubuntu environment for reproducible screenshots
- Uploads diff artifacts on failure for easy debugging

## Directory Structure

```
test/visual/
├── README.md           # This file
├── Dockerfile          # Consistent test environment
├── run-tests.sh        # Main test runner
├── scenarios.zsh       # Test scenario definitions
├── snapshots/          # Baseline images (committed)
├── actual/             # Current screenshots (gitignored)
└── diff/               # Visual diffs (gitignored)
```

## Updating Baselines

When you intentionally change the prompt appearance:

1. Run tests to generate new screenshots: `./run-tests.sh test`
2. Review the diffs in `diff/` directory
3. If changes are expected, update baselines: `./run-tests.sh update`
4. Commit the new baselines in `snapshots/`

## Troubleshooting

**Tests fail with "MISSING BASELINE"**
Run `./run-tests.sh generate` to create initial baselines.

**Different results on different machines**
Visual tests can be sensitive to font rendering differences. For consistent
results, run tests in Docker or CI. The text-based fallback is more portable.

**termshot not found**
Install from https://github.com/homeport/termshot or use `aha` fallback:
```bash
CAPTURE_METHOD=aha ./run-tests.sh test
```
