# Keyboard shortcuts

## Quiz

On macOS use Command where this table says Ctrl. Saving a document opened
from a numbered revision writes the same path at `now`.

<!-- generated: app-chords -->

| Key | Action | Where |
|:----|:-------|:------|
| F1 | Help (displaces Ace’s Open command palette) | Everywhere |
| F2 | Settings (displaces Ace’s Toggle fold widget) | Everywhere |
| F5 | Run the selected property | Outside the editor |
| Ctrl-S | Save the document | Everywhere |
| Ctrl-Shift-S | Save as a new file | Everywhere |
| Alt-O | Open a saved document | Outside the editor |
| Alt-C | Copy the document | Outside the editor |

<!-- /generated -->

F1 and F2 override Ace's command palette and fold-widget bindings. The
palette's commands remain reachable through **Ctrl-,**, Ace's own settings
menu; folding keeps `Alt-F2`, `Alt-L`, `Alt-Shift-L`, `Alt-0` and
`Alt-Shift-0`.

Alt-O and Alt-C, rather than Ctrl-O and Ctrl-Shift-C: **Ctrl-O** is free in
Ace's own keymap but is a Vim binding in both insert and normal mode, and the
editor can be switched to Vim in Settings; **Ctrl-Shift-C** is Chromium's
element inspector. Those two, and F5, apply outside the editor only, so
Ctrl-C and its neighbours keep their ordinary meaning while editing.

**Rerun, replay and cancel have no chord.** They act on a selected run rather
than on the document, and are reached by their buttons in the result pane.

## File rows

In the explorer, with a file row focused:

| Key | Action |
|:----|:-------|
| Enter or Space | Open the file |
| Delete | Delete the file, after confirming |
| Alt-Enter, Shift-F10, or the context-menu key | Open the row's actions |

## Ace editor

The document pane uses the vendored Ace editor. Its full default keymap is in
**[Ace editor keys](ace-keys.md)**, generated from the same manifest the
cross-app conflict gate reads. **Settings → Keybindings** selects the default
or the Vim keymap.

## Dialogs

Help, Settings, Open, Save As and the confirmations navigate the same way in
every app on this shell, and each can be dragged by its header; see
**[Dialog keyboard contract](modal-keys.md)**.

## Policy

Why a chord is or is not available, and what it may displace:
**[Key policy](key-policy.md)**.
