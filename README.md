# Level Editor

## DualTileMapTool

here is how to use it:
it works IN THE EDITOR! nice
to create tiles, just select any tile except empty one (atlas_coords (0, 3) or `erase` terrain)
If you select a terrain set, for some reason godot will show nicer grid
every shortcut that godot supports works, right click to erase, rect, and stuff like that
To erase a tile without creating an empty transparent hole (so just empty tile),
select the empty tile atlas_coords (0, 3) or `erase` terrain, and draw with it (left click, not right click)
to see how it works (what tile map ACTUALLY stores) toggle `show_raw_tilemap` export boolean
if you want it to be more or less responsive (@tool only), change the `update_interval`
In game, it will update as soon as the player clicks, but in engine godot does not have `tile_added` signal or anything like that
So i just update every single tile every `update_interval` time
