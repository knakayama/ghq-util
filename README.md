ghq-util
========

ghq utility

# Requirements

1. [ghq](https://github.com/motemen/ghq)
1. [peco](https://github.com/peco/peco)

# Install

## antigen

Add the following line to your `~/.zshrc`:

```zsh
antigen bundle knakayama/ghq-util
```

then, source `~/.zshrc`.

## manually

Follow the below commands:

```bash
$ git clone https://github.com/knakayama/ghq-util.git
$ cd ghq-util
$ source ghu.zsh
```

# Usage

```bash
Usage: ghu [-h] COMMAND [<args>]

ghq utility

Commands:

  rm    Remove ghq repo(s) with peco style selecting
  mk    Create ghq repo
  for   Execute commands in ghq repo(s)

Run 'ghu COMMAND -h' for more information on a command.
```

# Reference

* http://qiita.com/uasi/items/610ef5745fc35745fd54
* http://qiita.com/uasi/items/dae9b180680e90950cb1

# License

[MIT](https://github.com/knakayama/ghq-util/blob/master/LICENSE)

# Author

[knakayama](https://github.com/knakayama)
