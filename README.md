# AdminPanel
Once I opened my own server, I decided to get a decent admin panel for it. Although there were no admin panels for Sven Co-op written in AngelScript (Why?), that's why I decided to write my own.
The admin panel is mostly written in Hungarian Notation (read the first two comment blocks in the admin panel source file).
I still haven't finished it and mostly it was made specifically for the so-called Cancer (Half-Life C) server.
Logging was unfinished and I decided to cut it off from most of the code.
You have to modify the owner SteamID and add admins by editing the admin panel source file on your own, that is, the admin panel is fully standalone. It doesn't use any files, nor create any.
Add yourself to `g_a_lpszAllowedSteamIDs` in `PluginInit` (a comment block is left there to help you)
Set `g_lpszTheOwner` to your (the owner :D) SteamID.
The admin panel source file may contain some trash/unused code, don't mind that. I was writing the whole admin panel for more than four months and I might have already forgotten about some unused code.

# TODO list
- Add commands (.sethealth TheKirkaYT 12412412)
- Rewrite logging logic
- Make a real "minimal" version (no metamod)
- Finish second page of Player management menu

Feel free to report any bugs, don't forget to describe "how to reproduce"!
