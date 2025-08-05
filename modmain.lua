local _G = GLOBAL

Assets = {
    Asset("ATLAS", "images/inventoryimages/seedomatic_item.xml"),
    Asset("IMAGE", "images/inventoryimages/seedomatic_item.tex"),
}

PrefabFiles =
{
    "seedomatic",
}

------------------------------------------------------------------------------
local containers = require "containers"
local params = {}

local containers_widgetsetup_pf = containers.widgetsetup  
function containers.widgetsetup(container, prefab, data, ...)
    local t = params[prefab or container.inst.prefab]
    if t ~= nil then
        for k, v in pairs(t) do
            container[k] = v
        end
        container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
    else
        containers_widgetsetup_pf(container, prefab, data, ...)
    end
end

params.seedomatic =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_chest_3x3",
        animbuild = "ui_chest_3x3",
        pos = _G.Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
}

for y = 2, 0, -1 do
    for x = 0, 2 do
        table.insert(params.seedomatic.widget.slotpos, _G.Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
    end
end

function params.seedomatic.itemtestfn(container, item, slot)
    return (item.prefab == "seeds" or string.match(item.prefab, "_seeds")) and not item:HasTag("treeseed")
end

params.seedomatic.priorityfn = params.seedomatic.itemtestfn

------------------------------------------------------------------------------


AddRecipe("seedomatic_item",
	{
		_G.Ingredient("farm_plow_item", 1),
		_G.Ingredient("gears", 1),
		_G.Ingredient("slurtle_shellpieces",4)
	},
	_G.RECIPETABS.FARM,
	_G.TECH.SCIENCE_TWO,
	nil, -- placer
	nil, -- min_spacing
	nil, -- nounlock
	1, -- numtogive
	nil, -- builder_tag
	"images/inventoryimages/seedomatic_item.xml", -- atlas
	"seedomatic_item.tex" -- image
)

------------------------------------------------------------------------------


_G.STRINGS.NAMES.SEEDOMATIC_ITEM = "Seed-O-Matic"
_G.STRINGS.NAMES.SEEDOMATIC = "Seed-O-Matic"
_G.STRINGS.RECIPE_DESC.SEEDOMATIC_ITEM = "Also useful against zombies!"
_G.STRINGS.RECIPE_DESC.SEEDOMATIC = "Also useful against zombies!"
_G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.SEEDOMATIC_ITEM = "Also useful against zombies!"
_G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.SEEDOMATIC = "Also useful against zombies!"

