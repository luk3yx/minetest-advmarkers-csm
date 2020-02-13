# advmarkers

## Warning

This is mostly useless if you use Minetest 0.4, as without the CSM HUD API this
CSM requires a `/mrkr` command to exist on the server. You probably want the
(nicer) [non-CSM](https://git.minetest.land/luk3yx/advmarkers) mod instead.

*This CSM does not co-operate with the server-side mod except for the fact that
it provides a `/mrkr` command, if you play on a server with the server-side mod
you don't need this.*

## Original README

A marker/waypoint CSM for Minetest, designed for use with the (now-defunct) marker mod.

This CSM works by itself on Minetest 5.0.0+, and with the server-side mod
installed on Minetest 0.4.

## How to use

`advmarkers` introduces the following chatcommands:

 - `.mrkr`: Opens a formspec allowing you to display or delete markers.
 - `.add_mrkr`: Adds markers. You can use `.add_mrkr x,y,z Marker name` to add markers. Markers are (currently) cross-server, and adding a marker with (exactly) the same name as another will overwrite the original marker. If you replace `x,y,z` with `here`, the marker will be set to your current position, and replacing it with `there` will set the marker to the last `.coords` position.
 - `.mrkr_export`: Exports your markers to an advmarkers string. Remember to not modify the text before copying it. You can use `.mrkr_export old` if you want an export string compatible with older versions of advmarkers (it should start with `M` instead of `J`). The old format will probably not work nicely with the planned server-side mod, however.
 - `.mrkr_import`: Imports your markers from an advmarkers string (`.mrkr_import <advmarkers string>`). Any markers with the same name will not be overwritten, and if they do not have the same co-ordinates, `_` will be appended to the imported one.
 - `.mrkr_upload`: Uploads your markers to your current server's advmarkers
    [server-side mod].
 - `.mrkrthere`: Sets a marker at the last `.coords` position.
 - `.clrmrkr`: Hides the currently displayed waypoint.

If you die, a marker is automatically added at your death position, and will
update the last `.coords` position.

## Chat channels integration

advmarkers works with the `.coords` command from chat_channels ([GitHub],
[GitLab]), even without chat channels installed. When someone does `.coords`,
advmarkers temporarily stores this position, and you can set a temporary marker
at the `.coords` position with `.mrkrthere`, or add a permanent marker with
`.add_mrkr there Marker name`.

[GitHub]: https://github.com/luk3yx/minetest-chat_channels
[GitLab]: https://gitlab.com/luk3yx/minetest-chat_channels
[server-side mod]: https://git.minetest.land/luk3yx/advmarkers
