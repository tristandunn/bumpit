# Bumpit

Automatically bump dependencies in multiple package managers, with current
support for:

- [Bundler][]
- [Yarn][]

## Usage

Running the command will detect package managers for the current directory and
bump the dependencies for them.

```sh
$ bumpit
```

### Options

```
$ bumpit --help

USAGE
  $ bumpit [options]

OPTIONS
  -c, --commit       Output a commit message.
  -h, --help         Prints this help message.
  -p, --pristine     Don't bump if not in a clean state.
  --verify [COMMAND} Run a command to verify changes.

EXAMPLES
  $ bumpit --commit --pristine --verify="bundle exec rake && yarn test"
```

## License

bumpit uses the MIT license. See LICENSE for more details.

[Bundler]: https://bundler.io
[Yarn]: https://yarnpkg.com
