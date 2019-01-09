# Writing a TUI in BASH [WIP]

Through my travels I've discovered it's possible to write a fully functional Terminal User Interface in BASH. The object of this guide is to document and teach the concepts in a simple way. To my knowledge they aren't documented anywhere so this is essential.

The benefit of using BASH is the lack of needed dependencies. If the system has BASH available, the program will run. Now there are cases against using BASH and they're most of the time valid. However, there are cases where BASH is the only thing available and that's where this guide comes in.

This guide covers BASH `3.2+` which covers pretty much every OS you'll come across. One of the major reasons for covering this version is macOS which will be forever stuck on BASH `3`.

To date I have written 3 different programs using this method. The best example of a TUI that covers most vital features is [**fff**](https://github.com/dylanaraps/fff) which is a Terminal File manager. Another good example is [**pxltrm**](https://github.com/dylanaraps/pxltrm) which is a pixel art editor in the terminal.

## Table of Contents

<!-- vim-markdown-toc GFM -->

* [Getting Started - The main loop](#getting-started---the-main-loop)
* [Clearing the screen](#clearing-the-screen)
* [Handling terminal window size](#handling-terminal-window-size)
* [Handling key-presses](#handling-key-presses)
* [Start of our basic program.](#start-of-our-basic-program)
* [Adding a Status-bar](#adding-a-status-bar)

<!-- vim-markdown-toc -->

## Getting Started - The main loop

First off we need a main function and a main loop. The loop is infinite and in this example waits for the user to press a key before it loops. It's pretty useless at this stage as its the foundation for what's to come.

```sh
#!/usr/bin/env bash
#
# program

main() {
    # Main loop.
    for ((;;)); {
        # Wait for user to press a key.
        # Value is stored in '$REPLY'
        read -rsn 1
    }
}

main "$@"
```


## Clearing the screen

The next step is to clear the screen, hide the cursor and disable line-wrapping. There are cases where the cursor should be shown throughout or line-wrapping should be enabled but for the purposes of this tutorial we'll disable them.

Further reading: `man trap` and `trap -l`

```sh
#!/usr/bin/env bash
#
# program

clear_screen() {
    # Clear the screen.
    #
    # '\e[?7l':  Disable line wrapping.
    # '\e[?25l': Hide the cursor.
    # '\e[2J':   Clear the screen.
    # '\e[H':    Move the cursor to '0,0' (home).
    printf '\e[?7l\e[?25l\e[2J\e[H'
}

main() {
    clear_screen

    # Trap 'EXIT'.
    # This is required to reset the terminal to a useable
    # state on Ctrl+C, 'exit' etc.
    # '\e[?7h':  Re-enable line wrapping.
    # '\e[?25h': Re-enable the cursor.
    trap 'clear_screen; printf "\e[?7h\e[?25h"' EXIT

    # Main loop.
    for ((;;)); {
        # Wait for user to press a key.
        # Value is stored in '$REPLY'
        read -rsn 1
    }
}

main "$@"
```

## Handling terminal window size

Knowing the size of the terminal window is essential when implementing a status bar or any kind of scrolling. Handling window resize is even more essential.

```sh
#!/usr/bin/env bash
#
# program

clear_screen() {
    # Clear the screen.
    #
    # '\e[?7l':  Disable line wrapping.
    # '\e[?25l': Hide the cursor.
    # '\e[2J':   Clear the screen.
    # '\e[H':    Move the cursor to '0,0' (home).
    printf '\e[?7l\e[?25l\e[2J\e[H'
}

get_term_size() {
    # Get the terminal lines and columns.
    # This can't reliably be done in pure bash.
    # 'stty' is used as it's POSIX and always available.
    read -r LINES COLUMNS < <(stty size)
}

main() {
    get_term_size
    clear_screen

    # Trap 'EXIT'.
    # This is required to reset the terminal to a useable
    # state on Ctrl+C, 'exit' etc.
    # '\e[?7h':  Re-enable line wrapping.
    # '\e[?25h': Re-enable the cursor.
    trap 'clear_screen; printf "\e[?7h\e[?25h"' EXIT

    # Trap 'SIGWINCH'
    # This signal allows us to react to a window size change.
    # Whenever the window is resized, we re-fetch the terminal size.
    trap 'get_term_size; clear_screen' WINCH

    # Main loop.
    for ((;;)); {
        # Wait for user to press a key.
        # Value is stored in '$REPLY'
        read -rsn 1
    }
}

main "$@"
```

## Handling key-presses

Another building block until we start work on what the TUI will represent. This is really simple. The tricky part is figuring out what BASH sees when you type a special key (*Enter, Escape, Arrow Keys*).

```sh
#!/usr/bin/env bash
#
# program

clear_screen() {
    # Clear the screen.
    #
    # '\e[?7l':  Disable line wrapping.
    # '\e[?25l': Hide the cursor.
    # '\e[2J':   Clear the screen.
    # '\e[H':    Move the cursor to '0,0' (home).
    printf '\e[?7l\e[?25l\e[2J\e[H'
}

get_term_size() {
    # Get the terminal lines and columns.
    # This can't reliably be done in pure bash.
    # 'stty' is used as it's POSIX and always available.
    read -r LINES COLUMNS < <(stty size)
}

get_key() {
    # Handle user input.
    case "$1" in
        # 'B' is what bash sees when you press 'Down Arrow'.
        # It's a portion of the escape sequence '\e[B' (cursor down).
        B|j) ;;

        # 'A' is what bash sees when you press 'Up Arrow'.
        # It's a portion of the escape sequence '\e[A' (cursor up).
        A|k) ;;

        # Exit the program on press of 'q'.
        q) exit ;;
    esac
}

main() {
    get_term_size
    clear_screen

    # Trap 'EXIT'.
    # This is required to reset the terminal to a useable
    # state on Ctrl+C, 'exit' etc.
    # '\e[?7h':  Re-enable line wrapping.
    # '\e[?25h': Re-enable the cursor.
    trap 'clear_screen; printf "\e[?7h\e[?25h"' EXIT

    # Trap 'SIGWINCH'
    # This signal allows us to react to a window size change.
    # Whenever the window is resized, we re-fetch the terminal size.
    trap 'get_term_size; clear_screen' WINCH

    # Main loop.
    for ((;;)); {
        # Wait for user to press a key.
        # Value is stored in '$REPLY'
        read -rsn 1 && get_key "$REPLY"
    }
}

main "$@"
```

## Start of our basic program.

For the purposes of this guide we'll be recreating the program `less`. The idea is simple and conveys the concepts in this guide well. This step adds
basic argument parsing and the input of a file to an array.

The program now reads the entirety of the file and waits for user input. Nothing much is happening yet but the foundations are now in place for us to add scrolling, a status-bar and other features.

```sh
#!/usr/bin/env bash
#
# program

clear_screen() {
    # Clear the screen.
    #
    # '\e[?7l':  Disable line wrapping.
    # '\e[?25l': Hide the cursor.
    # '\e[2J':   Clear the screen.
    # '\e[H':    Move the cursor to '0,0' (home).
    printf '\e[?7l\e[?25l\e[2J\e[H'
}

get_term_size() {
    # Get the terminal lines and columns.
    # This can't reliably be done in pure bash.
    # 'stty' is used as it's POSIX and always available.
    read -r LINES COLUMNS < <(stty size)
}

read_file() {
    # Error handling for null file or non-existent file.
    if [[ ! -f "$1" ]]; then
        # '>&2':        Print the error string to 'stderr'.
        # '${1:-null}': If '$1' is empty, display 'null'.
        printf '%s\n' "${1:-null}: No such file." >&2
        exit 1
    fi

    # Read the file into an array line by line.
    # bash 4+: Use 'readarray'/'mapfile'.
    while IFS= read -r line; do
        file_contents+=("$line")
    done < "$1"
}

get_key() {
    # Handle user input.
    case "$1" in
        # 'B' is what bash sees when you press 'Down Arrow'.
        # It's a portion of the escape sequence '\e[B' (cursor down).
        B|j) ;;

        # 'A' is what bash sees when you press 'Up Arrow'.
        # It's a portion of the escape sequence '\e[A' (cursor up).
        A|k) ;;

        # Exit the program on press of 'q'.
        q) exit ;;
    esac
}

main() {
    # Read the file.
    # Error handling is done in the function.
    read_file "$1"

    get_term_size
    clear_screen

    # Trap 'EXIT'.
    # This is required to reset the terminal to a useable
    # state on Ctrl+C, 'exit' etc.
    # '\e[?7h':  Re-enable line wrapping.
    # '\e[?25h': Re-enable the cursor.
    trap 'clear_screen; printf "\e[?7h\e[?25h"' EXIT

    # Trap 'SIGWINCH'
    # This signal allows us to react to a window size change.
    # Whenever the window is resized, we re-fetch the terminal size.
    trap 'get_term_size; clear_screen' WINCH

    # Main loop.
    for ((;;)); {
        # Wait for user to press a key.
        # Value is stored in '$REPLY'
        read -rsn 1 && get_key "$REPLY"
    }
}

main "$@"
```

## Adding a Status-bar

This next part requires an abundance of escape sequences. The status-bar reacts to window size since we redraw it on window resize.

```sh
#!/usr/bin/env bash
#
# program

clear_screen() {
    # Clear the screen.
    #
    # '\e[?7l':  Disable line wrapping.
    # '\e[?25l': Hide the cursor.
    # '\e[2J':   Clear the screen.
    # '\e[H':    Move the cursor to '0,0' (home).
    printf '\e[?7l\e[?25l\e[2J\e[H'
}

get_term_size() {
    # Get the terminal lines and columns.
    # This can't reliably be done in pure bash.
    # 'stty' is used as it's POSIX and always available.
    read -r LINES COLUMNS < <(stty size)
}

status_bar() {
    # Print the status bar on the bottom of the window.
    # We do this by using the '$LINES' variable which stores
    # the total number of lines in the window. We substract
    # this number by '2' to leave room for the status-bar.
    #
    # '\e[%sB':  Move the cursor N lines down.
    #            This has the added side-effect of moving
    #            the cursor to the bottom.
    # '\e[30m:'  Set text color to color '0'.
    # '\e[41m:'  Set text background color to color '1'.
    # '\e[K':    Clear to end of line.
    #            This has the added side-effect of coloring
    #            the entire line.
    # '\e[m':    Reset text colors.
    # '\e[H':    Move the cursor back to '0,0' (home).
    printf '\e[%sB\e[30m\e[41m\e[K%s\e[m\e[H' "$((LINES-2))" "$file_name"
}

read_file() {
    # Error handling for null file or non-existent file.
    if [[ ! -f "$1" ]]; then
        # '>&2':        Print the error string to 'stderr'.
        # '${1:-null}': If '$1' is empty, display 'null'.
        printf '%s\n' "${1:-null}: No such file." >&2
        exit 1
    fi

    # Store the file name for use later.
    file_name="$1"

    # Read the file into an array line by line.
    # bash 4+: Use 'readarray'/'mapfile'.
    while IFS= read -r line; do
        file_contents+=("$line")
    done < "$1"
}

get_key() {
    # Handle user input.
    case "$1" in
        # 'B' is what bash sees when you press 'Down Arrow'.
        # It's a portion of the escape sequence '\e[B' (cursor down).
        B|j) ;;

        # 'A' is what bash sees when you press 'Up Arrow'.
        # It's a portion of the escape sequence '\e[A' (cursor up).
        A|k) ;;

        # Exit the program on press of 'q'.
        q) exit ;;
    esac
}

main() {
    # Read the file.
    # Error handling is done in the function.
    read_file "$1"

    get_term_size
    clear_screen
    status_bar

    # Trap 'EXIT'.
    # This is required to reset the terminal to a useable
    # state on Ctrl+C, 'exit' etc.
    # '\e[?7h':  Re-enable line wrapping.
    # '\e[?25h': Re-enable the cursor.
    trap 'clear_screen; printf "\e[?7h\e[?25h"' EXIT

    # Trap 'SIGWINCH'
    # This signal allows us to react to a window size change.
    # Whenever the window is resized, we re-fetch the terminal size.
    trap 'get_term_size; clear_screen; status_bar' WINCH

    # Main loop.
    for ((;;)); {
        # Wait for user to press a key.
        # Value is stored in '$REPLY'
        read -rsn 1 && get_key "$REPLY"
    }
}

main "$@"
```
