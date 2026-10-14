"""Run inside Unreal Editor's Python console before first Play or packaging.

exec(open(r'C:/path/to/Unreal/Tools/Bootstrap.py').read())
Creates editor assets; never runs as part of the packaged game.
"""
import unreal

MATERIAL = "/Game/Art/M_Prototype"
MAP = "/Game/Maps/FarmValley"
tools = unreal.AssetToolsHelpers.get_asset_tools()

if not unreal.EditorAssetLibrary.does_asset_exist(MATERIAL):
    material = tools.create_asset("M_Prototype", "/Game/Art", unreal.Material, unreal.MaterialFactoryNew())
    tint = unreal.MaterialEditingLibrary.create_material_expression(material, unreal.MaterialExpressionVectorParameter)
    tint.set_editor_property("parameter_name", "Tint")
    tint.set_editor_property("default_value", unreal.LinearColor(0.5, 0.5, 0.5, 1.0))
    unreal.MaterialEditingLibrary.connect_material_property(tint, "", unreal.MaterialProperty.MP_BASE_COLOR)
    roughness = unreal.MaterialEditingLibrary.create_material_expression(material, unreal.MaterialExpressionConstant)
    roughness.set_editor_property("r", 0.85)
    unreal.MaterialEditingLibrary.connect_material_property(roughness, "", unreal.MaterialProperty.MP_ROUGHNESS)
    unreal.MaterialEditingLibrary.recompile_material(material)
    unreal.EditorAssetLibrary.save_asset(MATERIAL)

level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
if not unreal.EditorAssetLibrary.does_asset_exist(MAP):
    if not level.new_level(MAP):
        raise RuntimeError("Could not create FarmValley level. Run this script in the editor, not in a packaged game.")
    level.save_current_level()
else:
    level.load_level(MAP)

unreal.log("Chicken Valley assets ready. Press Play: the C++ game mode builds both farms at runtime.")
