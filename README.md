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

