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
* [Escape Sequences](#escape-sequences)
    * [Hiding and Showing the cursor](#hiding-and-showing-the-cursor)
    * [Line wrapping](#line-wrapping)
    * [Moving the cursor to specific coordinates](#moving-the-cursor-to-specific-coordinates)
    * [Moving the cursor to the bottom of the terminal.](#moving-the-cursor-to-the-bottom-of-the-terminal)
    * [Moving the cursor relatively](#moving-the-cursor-relatively)
        * [Cursor Up](#cursor-up)
        * [Cursor Down](#cursor-down)
        * [Cursor Left](#cursor-left)
        * [Cursor Right](#cursor-right)
    * [Clearing the screen](#clearing-the-screen)
    * [Setting the scroll area.](#setting-the-scroll-area)
    * [Saving and Restoring the user's terminal screen.](#saving-and-restoring-the-users-terminal-screen)
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
| Linux with glibc | `linux-gnu` |
| Linux with musl | `linux-musl` |
| Cygwin | `cygwin` |
| Bash on Windows 10 | `linux-gnu` |
| OpenBSD | `openbsd*` |
| FreeBSD | `freebsd*` |
| NetBSD | `netbsd` |
| macOS | `darwin*` |
| iOS | `darwin9` |
| Solaris | `solaris*` |
| Android (Termux) | `linux-android` |
| Android | `linux-gnu` |
| Haiku | `haiku` |


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

## Escape Sequences

For the purposes of this resource we won't be using `tput`. The `tput` command has a lot of overhead (`10-15 ms` per invocation) and won't make the program any more portable than sticking to standard **VT100** escape sequences. Using `tput` also adds a dependency on `ncurses` which defeats the whole purpose of doing this in `bash`.

### Hiding and Showing the cursor

See:

- https://vt100.net/docs/vt510-rm/DECTCEM.html

```sh
# Hiding the cursor.
printf '\e[?25l'

# Showing the cursor.
printf '\e[?25h'
```

### Line wrapping

See:

- https://vt100.net/docs/vt510-rm/DECAWM.html

```sh
# Disabling line wrapping.
printf '\e[?7l'

# Enabling line wrapping.
printf '\e[?7h'
```

### Moving the cursor to specific coordinates

See:

- https://vt100.net/docs/vt510-rm/CUP.html

```sh
# Move the cursor to 0,0.
printf '\e[H'

# Move the cursor to line 3, column 10.
printf '\e[3;10H'

# Move the cursor to line 5.
printf '\e[5H'
```

### Moving the cursor to the bottom of the terminal.

See:

- [getting-the-window-size](#getting-the-window-size)
- https://vt100.net/docs/vt510-rm/CUP.html

```sh
# Using terminal size, move cursor to bottom.
printf '\e[%sH' "$LINES"
```

### Moving the cursor relatively

When using these escape sequences and the cursor hits the edge of the window it stops.


#### Cursor Up

See:

- https://vt100.net/docs/vt510-rm/CUU.html

```sh
# Move the cursor up a line.
printf '\e[A'

# Move the cursor up 10 lines.
printf '\e[10A'
```

#### Cursor Down

See:

- https://vt100.net/docs/vt510-rm/CUD.html

```sh
# Move the cursor down a line.
printf '\e[B'

# Move the cursor down 10 lines.
printf '\e[10B'
```

#### Cursor Left

See:

- https://vt100.net/docs/vt510-rm/CUB.html

```sh
# Move the cursor back a column.
printf '\e[D'

# Move the cursor back 10 columns.
printf '\e[10D'
```

#### Cursor Right

See:

- https://vt100.net/docs/vt510-rm/CUF.html

```sh
# Move the cursor forward a column.
printf '\e[C'

# Move the cursor forward 10 columns.
printf '\e[10C'
```

### Clearing the screen

See:

- https://vt100.net/docs/vt510-rm/ED.html
- https://vt100.net/docs/vt510-rm/CUP.html

```sh
# Clear the screen.
printf '\e[2J'

# Clear the screen and move cursor to (0,0).
# This mimics the 'clear' command.
printf '\e[2J\e[H'
```

### Setting the scroll area.

This sequence allow you to limit the terminal's vertical scrolling area between two points. This comes in handy when you need to reserve portions of the screen for a top or bottom status-line (*you don't want them to scroll*).

This sequence also has the side-effect of moving the cursor to the top-left of the boundaries. This means you can use it directly after a screen clear instead of `\e[H` (`\e[2J\e[0;10r`).

See:

- https://vt100.net/docs/vt510-rm/DECSTBM.html

```sh
# Limit scrolling from line 0 to line 10.
printf '\e[0;10r'

# Set scrolling margins back to default.
printf '\e[;r'
```

### Saving and Restoring the user's terminal screen.

This is one of the only non **VT100** I'll be covering. This sequence allows you to save and restore the user's terminal screen when running your program. When the user exits the program, their command-line will be restored as it was before running the program.

While this sequence is XTerm specific, it is covered by almost all modern terminal emulators and simply ignored in older ones. There is also [DECCRA](https://vt100.net/docs/vt510-rm/DECCRA.html) which may or may not be more widely supported than the XTerm sequence but I haven't done much testing.

```sh
# Save the user's terminal screen.
printf '\e[?1049h'

# Restore the user's terminal screen.
printf '\e[?1049l'
```

## References

- \[1\]: https://github.com/dylanaraps/neofetch/blob/415ef5d4aeb1cced7afcf9fd1223dd09c3306b9c/neofetch#L814-L845
- \[2\]: https://en.wikipedia.org/wiki/Uname
