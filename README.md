# One Tap Macro

Hover a spell, press Ctrl+Alt, and it's a macro.

I made this because spells in WoW Forever don't start auto attack, so my shaman would shock a mob and then just stand there. The fix is putting `/startattack` in a macro for every spell you open with, and making those by hand gets old fast.

Made for WoW Forever since it's the version I play, feel free to fork my repo and change it to your version if you'd like.

## What it does

Hover a spell on your action bars or in your spellbook and press Ctrl and Alt together. You get a character macro named after the spell, made from your template. By default that's:

```
#showtooltip
/startattack
/cast [@mouseover,harm,nodead][] {spell}
```

`{spell}` becomes the spell's name, and leaving out the rank means you always cast the highest one you know.

Hovering an enemy? Then the spell goes to them, great for interrupting something you're not targeting. Your auto attack stays on whatever you were hitting. Not hovering anything, it just goes to your target like normal.

On an action bar the macro takes the spell's spot right away. From the spellbook it ends up on your cursor, so you can drop it wherever you want.

Do it again on the same spell and it updates the macro you already have, instead of making a second one. This is in case you've changed the template and need to edit a macro.

## Settings

`/otm` opens the settings. They're also under Options → AddOns → One Tap Macro.

There's just the template. Write whatever you want in there, `{spell}` gets swapped for the spell's name. Macros can be 255 characters at most. Reset template puts the default back.

## Btw

The macros go in your character macros, so they don't take up your account-wide slots.
