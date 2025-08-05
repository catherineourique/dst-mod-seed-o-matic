
local function LaunchSeed(inst)
    if not (inst.components.machine and inst.components.machine.ison and inst.components.container and
       inst.components.seedomaticmanager and #inst.components.seedomaticmanager.valid > 0) then
        inst.Transform:SetNoFaced()
        inst.components.machine:TurnOff()
        return
    end
    
    inst.Transform:SetEightFaced()
    if not inst.AnimState:IsCurrentAnimation("firing") then
        inst.AnimState:PushAnimation("firing", true)
    end
    
    local x, z, slot, num, seeds, seed, seed_replica
    num = math.random(1,#inst.components.seedomaticmanager.valid)
    x = inst.components.seedomaticmanager.valid[num][1]
    z = inst.components.seedomaticmanager.valid[num][2]
    slot = inst.components.seedomaticmanager.valid[num][3]
    table.remove(inst.components.seedomaticmanager.valid, num)
    
    if inst.components.container.slots[slot] == nil or not inst.components.container.slots[slot].components.stackable then
        return LaunchSeed(inst)
    end
    
    seeds = inst.components.container:RemoveItemBySlot(slot)
    if seeds.components.stackable:IsStack() then
        seed = seeds.components.stackable:Get(1)
        inst.components.container:GiveItem(seeds, slot)
    else
        seed=seeds
    end        
    seed:AddComponent('seedomaticseed')
    seed.components.seedomaticseed:LaunchToPoint(inst, x, z)
    
    inst:FacePoint(Vector3(x,0,z))
    inst.SoundEmitter:PlaySound("dontstarve/common/together/infection_burst")
    inst.components.seedomaticmanager.seedomatic_task = inst:DoTaskInTime(
        inst.components.seedomaticmanager.interval, LaunchSeed
    )
end

local SeedOMaticManager = Class(function(self, inst)
    self.inst = inst
    self.interval = 0.35
    self.num_tiles = 1
    self.delta = 4/3.
    self.valid = {}
    self.grid = {}
    self.inst:DoTaskInTime(0, function(inst)
        self:GenGrid()
    end)
end)


function SeedOMaticManager:GenGrid()
    local xc, zc, num, i, j, k
    local pos = self.inst:GetPosition()
    xc = math.floor((pos.x+0.5)/4*3)*4/3+2/3.
    zc = math.floor((pos.z+0.5)/4*3)*4/3+2/3.
    num = self.num_tiles*3+1
    self.grid = {}
    k=0
    for i=-num, num do
        for j=-num, num do
            k=k+1
            self.grid[k] = {
                i*self.delta,
                j*self.delta,
                (i+1)%3+1,
                (j+1)%3+1
            }
        end
    end
end

function SeedOMaticManager:Start()
    local pos = self.inst:GetPosition()
    local l = 0
    local slot
    self.valid = {}
    for k, v in pairs(self.grid) do
        if TheWorld.Map:CanTillSoilAtPoint(pos.x+v[1], 0, pos.z+v[2], false) then
            slot = v[3]+(v[4]-1)*3
            if self.inst.components.container.slots[slot] then
                l = l+1
                self.valid[l] = {pos.x+v[1], pos.z+v[2], slot}
            end
        end
    end
    self.seedomatic_task = self.inst:DoTaskInTime(self.interval, LaunchSeed)
end

function SeedOMaticManager:Stop()
    self.valid = {}
    if self.seedomatic_task ~= nil then
        self.seedomatic_task:Cancel()
    end
end



return SeedOMaticManager

