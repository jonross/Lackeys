# Lackeys

Don't struggle with unintuitive app shortcuts or tricky window layouts.  Get Lackeys to do it for
you.

Lackeys is a prototype keyboard accelerator for MacOS.  Like all recent accessibility apps, it is
inherently insecure (it must run un-sandboxed) and should be used with caution.  Key actions are
deliberately limited so that a compromised configuration file cannot invoke arbitrary commands.
More configuration security features are planned.

This is an alpha release for early adopters.

## Disclaimer

This is my first MacOS app.  I have no idea what I'm doing.

# Installing

Unzip Lackeys.zip in `/Applications`.  Launch the app, grant accessibility rights, then use the
status bar menu (the icon should say "L?") to enable the app.  The icon should change to "L+".
The next time it launches, granting rights should not be needed.

# Bugs

There is not a "reload config" yet.  Exit and restart.

Moving and resizing windows only works with one display.

The first time you use the `prompt` action, the cursor is not in the text box.  After typing a
response this works fine until the next time the app launches.

MacOS periodically disables the key event monitor and/or accessibility API without notice or error,
making Lackeys unable to move / resize windows, or to process any key bindings at all.  (If you are
able to reproduce this reliably please let me know!) To fix, exit and restart the app.  If that
doesn't help, exit the app, type

    tccutil reset Accessibility com.github.jonross.Lackeys

and follow the post-installation steps above.  Do not type this while Lackeys is still running or
you will temporarily disable your keyboard.

# Configuration

## Basics

Lackeys reads `~/.lackeys` on startup.  This is a text file that maps key chords to simple actions
like opening other apps or sending a different key sequence.  Key mappings can be global or
app-specific.  A pound-sign (#) begins a comment.  Example:

    # shortcuts to open apps
    bind Control Shift G to open Google Chrome
    bind Control Shift S to open Slack

    # bindings below this are for Slack
    in Slack

    # use other keys for Jump and Search
    bind Command G to send Command K
    bind Command S to send Command G

## Key names

The target of a `bind` command or `send` action is an unshifted letter, number or symbol combined
with one or more of `Shift` `Control` `Option` `Command`.  (Binding an unmodified key is insecure
and therefore disallowed.)  Examples:

    bind Control T ...
    bind Shift Option J ...
    bind Command Equals ...

All keys other than alphanumerics have one-word alphanumeric names.  On a Macbook Pro:

* Top row: `Grave Minus Equals`
* Second row: `LeftBracket RightBracket Backslash`
* Third row: `Semicolon Quote`
* Fourth row: `Comma Period Slash`
* Directional: `UpArrow DownArrow LeftArrow RightArrow`
* Other: `Escape Delete Tab Return Space`

Key names are not case sensitive.

Shifted key names are not required for bindings; use e.g. `Command Shift 5` not `Command Percent`.

## Actions

`open APP`

Launch the named application, or switch to it if already open.  Note: application names may differ
from what they display in the menu bar; the correct name is the entry in `/Applications`.  For
example, Google Chrome is called `Google Chrome` even though it displays `Chrome` in the menu bar.

`send CHORD`

Send a different key chord than what was typed.  The syntax for sending `KEYS` is the same as for
binding to that for binding.

`order TEXT ...`

Issue an external commmand, like a shell script.  Due to security constraints, Lackeys cannot
directly invoke shell scripts, as it could grant accessibility rights to arbitrary code.  Instead,
the text is appended to `~/.lackeydo`, which you can watch from a separately invoked script via `tail
-f` and interpret as you please.  You can use this script as the template for an interpreter:

    touch ~/.lackeydo
    tail -f -0 ~/.lackeydo | while read line; do
        # interpret as desired; run a google search, shortcut to web pages, etc
    done

`prompt`

The same as `order` but prompt interactively and then send the entered text as an order.

`resize X Y WIDTH HEIGHT`

Resize the current window.  The values are either absolute pixel coordinates or width/height
percentages of the nearest display, and can also be expressed as deltas from the current location,
indicated by a dot.  (A dot by itself means no change.)  Examples:

        # top half of screen
        resize 0% 0% 100% 50%

        # full screen
        resize 0% 0% 100% 100%

        # top right box of 4x4 grid
        resize 75% 0% 25% 25%

        # 500x400 window at 100,100
        resize 100 100 500 400

        # shift window to the right 50 pixels
        resize .+50 . . .

        # keep height but use full width
        resize 0% . 100% .

        # keep width but use full height
        resize . 0% . 100%

## Leader keys (advanced)

Vim and Emacs users are familiar with the notion of leader keys and prefix keys, which allow
keyboard shortcuts to use two keys instead of one.  This opens up a wider range of shortcuts
that are easier to remember, because fewer modifier keys are needed.

Lackeys has nine leader key slots labeled `L1` through `L9` that may be associated to any key chord
applicable to the `bind` command.  Leader bindings may use two key chords, and the second key does
not require modifiers.  You should select infrequently used chords as leaders since they will not be
available for single-key mappings.  For example, in place of the example app shortcuts above:

    bind Control Shift G to open Google Chrome
    bind Control Shift S to open Slack

we can write

    leader L1 Command Semicolon

    bind L1 G to open Google Chrome
    bind L1 S to open Slack

So, typing `Command Semicolon` then `G` would launch Chrome.

# What's next

Fix the bugs, obviously.

I'd like to teach Lackeys to automatically restore window layouts when changing displays.  For
example, if you have three monitors at work and prefer specific apps on each monitor, Lackeys should
recognize when you plug in at your desk, and reposition your apps .  Syntatically, there are many
ways to do that with a config file, and suggestions are welcome.  Example:

    when 3 displays

    put Xcode on 1
    put Slack on 2
    put iTerm on 2
    put * on 3

