# advmarkers

A marker/waypoint CSM for Minetest, designed for use with the [marker] mod.

To display markers, the server currently needs the [marker] mod installed,
otherwise "command not found" errors will be displayed, as CSMs cannot currently
create HUDs on their own.

## How to use

advmarkers introduces two chatcommands:

 - `.mrkr`: Opens a formspec allowing you to display or delete markers.
 - `.add_mrkr`: Adds markers. You can either use `.add_mrkr x,y,z Marker name` or `.add_mrkr here Marker name` to add markers. Markers are (currently) cross-server, and adding a marker with (exactly) the same name as another will overwrite the original marker.

If you die, a marker is automatically added at your death position.

[marker]: https://github.com/Billy-S/kingdoms_game/blob/master/mods/marker