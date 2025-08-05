require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/seedomatic.zip"),
}
local assets_item =
{
    Asset("ANIM", "anim/seedomatic_item.zip"),
}

local prefabs =
{
    "collapse_small",
	"seedomatic_item",
	"seedomatic_item_placer",
	"tile_outline",

}

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    if inst.components.container then
        inst.components.container:DropEverything()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function OnHit(inst)
    if not inst:HasTag("burnt") then
        if inst.AnimState:IsCurrentAnimation('firing') or inst.AnimState:IsCurrentAnimation('turn_on') then
            inst.AnimState:PlayAnimation("hit_on")
        else
            inst.AnimState:PlayAnimation("hit")
        end
    end
    if inst.components.container then
        inst.components.container:DropEverything()
    end
end


local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function OnBurnt(inst)
    if inst.components.container then
        inst.components.container:DropEverything()
        inst:RemoveComponent('container')
    end
    if inst.components.seedomaticmanager then
        inst.components.seedomaticmanager:Stop()
        inst:RemoveComponent('seedomaticmanager')
    end
    if inst.components.machine then
        inst:RemoveComponent('machine')
    end
    inst.AnimState:PlayAnimation('burnt',false)
    inst.AnimState:PushAnimation('burnt',false)
end

local function OnBuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/winter_meter_craft")
end

local function TurnOff(inst, instant)
    if inst.components.machine:IsOn() then
        if not inst.AnimState:IsCurrentAnimation("turn_off") then
            inst.AnimState:PlayAnimation("turn_off")
        end
        inst.AnimState:PushAnimation("idle", false)
    end
    if inst.components.seedomaticmanager ~= nil then
        inst.components.seedomaticmanager:Stop()
    end
end

local function StartSeedOMaticManager(inst)
    if inst.AnimState:IsCurrentAnimation('turn_on') then
        inst.components.seedomaticmanager:Start()
    end
end

local function TurnOn(inst, instant)
    if not inst.components.machine:IsOn() then
        inst.AnimState:PlayAnimation("turn_on")
    end
    if inst.components.container:IsOpen() then
        inst.components.container:Close()
    end
    
end

local function OnContainer(inst)
    inst.components.machine:TurnOff()
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .1)

    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("cartographydesk.png")

    inst.AnimState:SetBank("seedomatic")
    inst.AnimState:SetBuild("seedomatic")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:Hide('click_overlay')

    inst:AddTag("structure")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
    inst.OnBuilt = OnBuilt
    
    inst:SetDeployExtraSpacing(0.4)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("seedomatic")
    inst.components.container.onopenfn = OnContainer
    inst.components.container.onclosefn = OnContainer

    inst:AddComponent("machine")
    inst.components.machine.turnonfn = TurnOn
    inst.components.machine.turnofffn = TurnOff
    inst.components.machine.cooldowntime = 0.5
    
    TurnOff(inst)
    
    inst:AddComponent("seedomaticmanager")


    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"seedomatic_item"})
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(OnHit)
    MakeSnowCovered(inst)

    MakeMediumBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)
    inst.components.burnable:SetOnBurntFn(OnBurnt)

    inst.OnSave = onsave
    inst.OnLoad = onload

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
    
    inst:ListenForEvent('animover', StartSeedOMaticManager)

    return inst
end

--------------------------------------------------------------------

local function can_plow_tile(inst, pt, mouseover, deployer)
	local x, z = pt.x, pt.z

	local ents = TheWorld.Map:GetEntitiesOnTileAtPoint(x, 0, z)
	for _, ent in ipairs(ents) do
		if ent ~= inst and ent ~= deployer and ent.prefab ~= 'farm_soil' and not (ent:HasTag("NOBLOCK") or ent:HasTag("locomotor") or ent:HasTag("NOCLICK") or ent:HasTag("FX") or ent:HasTag("DECOR")) then
			return false
		end
	end

	return true
end

local function item_ondeploy(inst, pt, deployer)
    local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(pt:Get())

    local obj = SpawnPrefab("seedomatic")
	obj.Transform:SetPosition(cx, cy, cz)
	obj.OnBuilt(obj)

	if inst:IsValid() then
		obj.deploy_item_save_record = inst:GetSaveRecord()
		inst:Remove()
	end
end


local function item_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("seedomatic_item")
    inst.AnimState:SetBuild("seedomatic_item")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("usedeploystring")
    inst:AddTag("tile_deploy")

	MakeInventoryFloatable(inst, "small", 0.1, 0.8)

	inst._custom_candeploy_fn = can_plow_tile -- for DEPLOYMODE.CUSTOM

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/seedomatic_item.xml"
    inst.components.inventoryitem.imagename = "seedomatic_item"


    inst:AddComponent("deployable")
	inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
    inst.components.deployable.ondeploy = item_ondeploy

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end

local function placer_invalid_fn(player, placer)
    if player and player.components.talker then
        player.components.talker:Say(GetString(player, "ANNOUNCE_CANTBUILDHERE_THRONE"))
    end
end

local function placer_fn()
    local inst = CreateEntity()
    print('tomate')
    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("seedomatic")
    inst.AnimState:SetBuild("seedomatic")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:Hide('click_overlay')
    inst.AnimState:SetLightOverride(1)

    inst:AddComponent("placer")
    inst.components.placer.snap_to_tile = true

	inst.outline = SpawnPrefab("tile_outline")
	inst.outline.entity:SetParent(inst.entity)

	inst.components.placer:LinkEntity(inst.outline)

    return inst
end

----------------------------------------------------------------------

return Prefab("seedomatic", fn, assets, prefabs),
    Prefab("seedomatic_item", item_fn, assets_item, prefabs),
    Prefab("seedomatic_item_placer", placer_fn)
