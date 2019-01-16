# Writing a TUI in BASH [WIP]

Through my travels I've discovered it's possible to write a fully functional Terminal User Interface in BASH. The object of this guide is to document and teach the concepts in a simple way. To my knowledge they aren't documented anywhere so this is essential.

The benefit of using BASH is the lack of needed dependencies. If the system has BASH available, the program will run. Now there are cases against using BASH and they're most of the time valid. However, there are cases where BASH is the only thing available and that's where this guide comes in.

This guide covers BASH `3.2+` which covers pretty much every OS you'll come across. One of the major reasons for covering this version is macOS which will be forever stuck on BASH `3`.

To date I have written 3 different programs using this method. The best example of a TUI that covers most vital features is [**fff**](https://github.com/dylanaraps/fff) which is a Terminal File manager. Another good example is [**pxltrm**](https://github.com/dylanaraps/pxltrm) which is a pixel art editor in the terminal.

## Table of Contents

<!-- vim-markdown-toc GFM -->

* [Operating Systems](#operating-systems)
    * [Identify the Operating System.](#identify-the-operating-system)
    * [Documented `$OSTYPE` values.](#documented-ostype-values)
* [Terminal Window Size.](#terminal-window-size)
    * [Getting the window size.](#getting-the-window-size)
    * [Reacting to window size changes.](#reacting-to-window-size-changes)
* [References](#references)

<!-- vim-markdown-toc -->


## Operating Systems

### Identify the Operating System.

The quickest way to determine the current Operating System is the `$OSTYPE` variable. This variable is set at compile time in `bash` and typically stores the name of the running kernel or the name of the OS itself.

You can also use the command `uname` to identify which OS is running. The `uname` command is POSIX and should be available everywhere. The output from `uname` does differ from `$OSTYPE` but there's a vast amount of documented information about it. [\[1\]](https://github.com/dylanaraps/neofetch/blob/415ef5d4aeb1cced7afcf9fd1223dd09c3306b9c/neofetch#L814-L845) [\[2\]](https://en.wikipedia.org/wiki/Uname)

```sh
get_os() {
    # Figure out the current operating system to handle some
    # OS specific behavior.
    # '$OSTYPE' typically stores the name of the OS kernel.
    case "$OSTYPE" in
        linux*)
            # ...
        ;;

        # Mac OS X / macOS.
        darwin*)
            # ...
        ;;

        openbsd*)
            # ...
        ;;

        # Everything else.
        *)
            #...
        ;;
    esac
}
```

### Documented `$OSTYPE` values.

The table below was populated by users submitting the value of the `$OSTYPE` variable using the following command. If you're running an OS not mentioned below or the output differs, please open an issue with the correct value.

```sh
bash -c "echo $OSTYPE"
```

| OS     | `$OSTYPE` |
| ----- | ---------- |
| Linux | `linux-gnu` |
| CYGWIN | `cygwin` |
| Bash on Windows 10 | `linux-gnu` |
| OpenBSD | `openbsd*` |
| FreeBSD | `freebsd*` |
| NetBSD | `netbsd` |
| Mac OS | `darwin*` |
| iOS | `darwin9` |
| Solaris | `solaris*` |
| Android (termux) | `linux-android` |
| Android | `linux-gnu` |
| Haiku OS | `haiku` |


## Terminal Window Size.


### Getting the window size.

This function calls `stty size` to query the terminal for its size. This can be done in pure bash by setting `shopt -s checkwinsize` and using some trickery to capture the `$LINES` and `$COLUMNS` variables but this method is unreliable and only works in some versions of `bash`.

The `stty` command is POSIX and should be available everywhere which makes it a reliable and viable alternative.

```sh
get_term_size() {
    # Get terminal size ('stty' is POSIX and always available).
    # This can't be done reliably across all bash versions in pure bash.
    read -r LINES COLUMNS < <(stty size)
}
```

### Reacting to window size changes.

Using `trap` allows us to capture and react to specific signals sent to the running program. In this case we're trapping the `SIGWINCH` signal which is sent to the terminal and the running shell on window resize.

We're reacting to the signal by running the above `get_term_size()` function. The variables `$LINES` and `$COLUMNS` will be updated with the new terminal size ready to use elsewhere in the program.

```sh
# Trap the window resize signal (handle window resize events).
# See: 'man trap' and 'trap -l'
trap 'get_term_size' WINCH
```

## References

- \[1\]: https://github.com/dylanaraps/neofetch/blob/415ef5d4aeb1cced7afcf9fd1223dd09c3306b9c/neofetch#L814-L845
- \[2\]: https://en.wikipedia.org/wiki/Uname
