
local SeedOMaticSeed = Class(function(self, inst)
    self.inst = inst
    self.speed = 25
    self.base_y = 2
    self.threshold = 1
    self.gravity = -15
    self.noblock_time = 16
    
    self.inst:AddTag("NOBLOCK")
end)

function SeedOMaticSeed:LaunchToPoint(doer, x, z)
    local pos = doer:GetPosition()
    self.inst.Transform:SetPosition(pos.x, self.base_y, pos.z)
    self.inst.collision_mask = self.inst.Physics:GetCollisionMask()
    self.inst.Physics:ClearCollisionMask()
    self.inst:DoTaskInTime(4*FRAMES, function(inst)
        inst.Physics:SetCollisionMask(self.inst.collision_mask)
    end)
    self.inst.AnimState:SetScale(0.01,0.01)
    for i=1,3 do
        self.inst:DoTaskInTime((i+3)*FRAMES, function(inst)
            inst.AnimState:SetScale(i/3., i/3.)
        end)
    end
    self.pt = Vector3(x,0,z)
    
    local dx, dz, dysq, drsq, dsq
    dx = self.pt.x-pos.x
    dz = self.pt.z-pos.z
    drsq = dx*dx+dz*dz
    dysq = self.base_y*self.base_y
    dsq = drsq + dysq
    self.distsq = dsq
    
    self.vr=self.speed * math.sqrt(drsq/dsq)
    self.vy=self.speed * math.sqrt(dysq/dsq)
    
    self.inst:FacePoint(self.pt)
    
    self.inst:StartUpdatingComponent(self)
end

function SeedOMaticSeed:OnHit()
    if TheWorld.Map:CanTillSoilAtPoint(self.pt.x, 0, self.pt.z, false) then
        local farm_soil
        farm_soil = self:TillAtPoint(self.pt.x, self.pt.z)
        self.inst:Hide()
        self.inst:DoTaskInTime(0.35, function(inst, farm_soil)
            inst.components.farmplantable:Plant(farm_soil, inst)
        end, farm_soil)
    end
end

function SeedOMaticSeed:TillAtPoint(x,z)
	TheWorld.Map:CollapseSoilAtPoint(x, 0, z)
	local farm_soil = SpawnPrefab("farm_soil")
    farm_soil.Transform:SetPosition(x,0,z)
    return farm_soil
end

function SeedOMaticSeed:OnUpdate(dt)

    local dx, dy, dz, distsq, pos
    pos=self.inst:GetPosition()
    dx = self.pt.x-pos.x
    dy = self.pt.y-pos.y
    dz = self.pt.z-pos.z
    distsq = dx*dx+dy*dy+dz*dz
    if distsq < self.threshold*self.threshold or distsq > self.distsq or pos.y < 0.05 then
        self.inst:StopUpdatingComponent(self)
        self.inst.Physics:Stop()
        if distsq < self.threshold*self.threshold then
            self:OnHit()
        end
        self.inst:DoTaskInTime(self.noblock_time, function(inst)
            inst:RemoveTag("NOBLOCK")
        end)
        return
    end
    
    self.distsq = distsq
    
    self.inst.Physics:SetMotorVel(self.vr,-self.vy-(self.gravity*FRAMES),0)
    
end

return SeedOMaticSeed

