#!/usr/bin/env python3
"""Generate PNG snapshots for visual regression testing of zsh prompt."""

from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

# Colors (terminal-like dark theme)
BG_COLOR = (30, 30, 30)
DIR_COLOR = (95, 135, 255)      # Blue - directory
BRANCH_COLOR = (0, 215, 215)    # Cyan - git branch
STAGED_COLOR = (95, 215, 0)     # Green - staged changes
UNSTAGED_COLOR = (215, 175, 0)  # Yellow - unstaged changes
UNTRACKED_COLOR = (95, 135, 255) # Blue - untracked files
PROMPT_OK_COLOR = (95, 215, 0)  # Green - success prompt
PROMPT_ERR_COLOR = (215, 0, 0)  # Red - error prompt
TIME_COLOR = (108, 108, 108)    # Gray - time/labels
EXEC_TIME_COLOR = (215, 175, 0) # Yellow - execution time

# Image dimensions
WIDTH = 600
HEIGHT = 100
PADDING = 20
LINE_HEIGHT = 25

def get_font(size=14):
    """Get a monospace font, falling back to default if needed."""
    font_paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/TTF/DejaVuSansMono.ttf",
        "/System/Library/Fonts/Monaco.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
    ]
    for path in font_paths:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()

def create_snapshot(filename, elements, label):
    """
    Create a snapshot image.

    elements is a list of tuples: [(text, color), ...]
    for each line of the prompt.
    """
    img = Image.new('RGB', (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)
    font = get_font(14)
    small_font = get_font(12)

    # Draw label
    draw.text((PADDING, 8), label, fill=TIME_COLOR, font=small_font)

    y = 35
    for line in elements:
        x = PADDING
        for item in line:
            if len(item) == 2:
                text, color = item
                draw.text((x, y), text, fill=color, font=font)
                bbox = draw.textbbox((x, y), text, font=font)
                x = bbox[2]
            elif len(item) == 3:
                text, color, position = item
                if position == 'right':
                    bbox = draw.textbbox((0, 0), text, font=font)
                    text_width = bbox[2] - bbox[0]
                    draw.text((WIDTH - PADDING - text_width, y), text, fill=color, font=font)
        y += LINE_HEIGHT

    output_dir = Path(__file__).parent / "snapshots"
    output_dir.mkdir(exist_ok=True)
    img.save(output_dir / filename)
    print(f"  Generated: {filename}")

def main():
    print("Generating PNG snapshots...")

    # no_git: Just directory, no git info
    create_snapshot("no_git.png", [
        [("~/some/directory", DIR_COLOR)],
        [("❯", PROMPT_OK_COLOR), ("", TIME_COLOR), ("12:34:56", TIME_COLOR, 'right')],
    ], "no-git")

    # git_clean: Directory + clean branch
    create_snapshot("git_clean.png", [
        [("~/project", DIR_COLOR), (" main", BRANCH_COLOR)],
        [("❯", PROMPT_OK_COLOR), ("", TIME_COLOR), ("12:34:56", TIME_COLOR, 'right')],
    ], "git-clean")

    # git_staged: Directory + branch + staged indicator
    create_snapshot("git_staged.png", [
        [("~/project", DIR_COLOR), (" main", BRANCH_COLOR), ("+", STAGED_COLOR)],
        [("❯", PROMPT_OK_COLOR), ("", TIME_COLOR), ("12:34:56", TIME_COLOR, 'right')],
    ], "git-staged")

    # git_unstaged: Directory + branch + unstaged indicator
    create_snapshot("git_unstaged.png", [
        [("~/project", DIR_COLOR), (" main", BRANCH_COLOR), ("!", UNSTAGED_COLOR)],
        [("❯", PROMPT_OK_COLOR), ("", TIME_COLOR), ("12:34:56", TIME_COLOR, 'right')],
    ], "git-unstaged")

    # git_untracked: Directory + branch + untracked indicator
    create_snapshot("git_untracked.png", [
        [("~/project", DIR_COLOR), (" main", BRANCH_COLOR), ("?", UNTRACKED_COLOR)],
        [("❯", PROMPT_OK_COLOR), ("", TIME_COLOR), ("12:34:56", TIME_COLOR, 'right')],
    ], "git-untracked")

    # git_mixed: Directory + branch + all indicators
    create_snapshot("git_mixed.png", [
        [("~/project", DIR_COLOR), (" main", BRANCH_COLOR), ("+", STAGED_COLOR), ("!", UNSTAGED_COLOR), ("?", UNTRACKED_COLOR)],
        [("❯", PROMPT_OK_COLOR), ("", TIME_COLOR), ("12:34:56", TIME_COLOR, 'right')],
    ], "git-mixed")

    # error: Red prompt character
    create_snapshot("error.png", [
        [("~/project", DIR_COLOR), (" main", BRANCH_COLOR)],
        [("❯", PROMPT_ERR_COLOR), ("", TIME_COLOR), ("12:34:56", TIME_COLOR, 'right')],
    ], "error-exit")

    # long_command: Shows execution time
    create_snapshot("long_command.png", [
        [("~/project", DIR_COLOR), (" main", BRANCH_COLOR)],
        [("❯", PROMPT_OK_COLOR), ("", TIME_COLOR), ("took 5s  12:34:56", EXEC_TIME_COLOR, 'right')],
    ], "long-command-5s")

    # very_long_command: Shows longer execution time
    create_snapshot("very_long_command.png", [
        [("~/project", DIR_COLOR), (" main", BRANCH_COLOR)],
        [("❯", PROMPT_OK_COLOR), ("", TIME_COLOR), ("took 1h 0m 0s  12:34:56", EXEC_TIME_COLOR, 'right')],
    ], "long-command-1h")

    # deep_path: Long directory path
    create_snapshot("deep_path.png", [
        [("~/project/very/deep/nested/directory/structure", DIR_COLOR), (" main", BRANCH_COLOR)],
        [("❯", PROMPT_OK_COLOR), ("", TIME_COLOR), ("12:34:56", TIME_COLOR, 'right')],
    ], "deep-path")

    print("Done!")

if __name__ == "__main__":
    main()
