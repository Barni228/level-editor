# Level Editor

## Known Issues

if you assign a TileSet resource to `DualTileMapTool`, when you open TileSet Editor on that resource
it might print a bunch of errors about some mesh:

```
ERROR: scene/main/canvas_item.cpp:1000 - Required object "rp_mesh" is null.
```

to fix it, you just need to save the `TileSet` resource as file (Save As...)  
but beware that when this happens, ur `TileSet` will actually break so you will need to create a new one,  
so just save it as `.tres` file immediately, and then use this node

## DualTileMapTool

here is how to use it:  
it works IN THE EDITOR! nice  
to create tiles, just select any tile except empty one (atlas_coords (0, 3))  
To erase a tile without creating an empty transparent hole (so just empty tile),  
select the empty tile atlas_coords (0, 3) (make sure it is not painted with terrain at all), and draw with it (left click, not right click)  
to see what you drew (what tile map ACTUALLY stores) toggle `show_raw_tilemap` export boolean  
if you want it to be more or less responsive (`@tool` only), change the `update_interval`  
In game, it will update as soon as the player clicks, but in engine godot does not have `tile_added` signal or anything like that  
So i just update tile map every `update_interval` seconds

## DualTileMapLayer

This is what `DualTileMapTool` uses  
If you don't care about tile map working in the editor (only in game), just use this node  
If you want tile map to work both in the editor AND in game, create `DualTileMapTool` and `DualTileMapLayer`  
and give both of them the same `DualTileMapData` `data`  
This way all updates created by `DualTileMapTool` will also happen in the `DualTileMapLayer`
