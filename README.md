# Basic Setup

Run `bundle install` to get the required gems.

The script will load the compiled beams into `~/.mix/beam`, so we need to get an `iex` that will load them.

Hopefully, `iex` is just a shell script. If you happen to have a custom `$PATH` variable that points to `~/.local/bin`, then copy `iex` to this directory and rename it to something like `deviex`.
Then in your custom `deviex`, move to the last line and change it to…

`exec elixir --no-halt --erl "-user Elixir.IEx.CLI" -pa "$HOME/.mix/beam" +iex "$@"`

And now it will load the `.beam` files located at `~/.mix/beam` at startup.

The reason why we use a different script for IEx is to avoid name conflicts with installed libs in the projects you'll work on with regular `iex`.
