# jfuchs/dotfiles

This project contains my personal dotfiles and Codespaces configuration, managed
by [chezmoi](https://chezmoi.io).

## Usage

### Install

```shell
> sh -c "$(curl -fsLS git.io/chezmoi)" -- init --apply jfuchs
```

or 

```shell
brew install chezmoi
chezmoi init --apply jfuchs
```

### Update

```shell
> chezmoi update
```

### Local amendments

To make machine-specific changes that aren't tracked in this repo, source a `.local` file from the relevant config. For example, `dot_zshrc` sources `~/.zshrc.local` if it exists:

```shell
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

Put any machine-specific shell configuration in `~/.zshrc.local`. Since chezmoi doesn't manage that file, it won't be overwritten by `chezmoi apply` or `chezmoi update`.
