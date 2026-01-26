# Dockerfile for visual regression testing of zsh prompt
# Provides a consistent environment for capturing terminal screenshots

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install dependencies
RUN apt-get update && apt-get install -y \
    zsh \
    git \
    curl \
    aha \
    wkhtmltopdf \
    imagemagick \
    fonts-jetbrains-mono \
    && rm -rf /var/lib/apt/lists/*

# Install termshot (Go binary)
RUN curl -fsSL https://github.com/homeport/termshot/releases/latest/download/termshot_linux_amd64.tar.gz \
    | tar -xz -C /usr/local/bin termshot

# Set up work directory
WORKDIR /dotfiles

# Copy test files
COPY test/visual/ /dotfiles/test/visual/
COPY dot_prompt.zsh /dotfiles/

# Make scripts executable
RUN chmod +x /dotfiles/test/visual/*.sh /dotfiles/test/visual/*.zsh

# Default command runs tests
CMD ["/dotfiles/test/visual/run-tests.sh", "test"]
