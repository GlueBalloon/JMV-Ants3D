
Ant3D = class()
-- copyright JMV38 2013 - all rights reserved

-- an Ant is just a data structure with no method,
-- to avoid memory overload by duplication of methods

-- utilities
local rnd = math.random
local deg = math.deg
local rad = math.rad
local cos = math.cos
local sin = math.sin
local floor = math.floor
-- constants
--    object types
local TYP_EDGE = 0
local ANT = 1
local HOME = 2
local FOOD = 3
local FINGER = 4
--    index for ant texture parts
local ANT_TEXTURE_MOVE_MIN = 1
local ANT_TEXTURE_MOVE_MAX = 6
local ANT_TEXTURE_STOP = 7
local ANT_TEXTURE_DEAD = 8
--    physical action
local ANT_ACTION_DEAD = 1
local ANT_ACTION_STOP = 2
local ANT_ACTION_RUN = 3
--    main objective of the ant
local GOAL_FIND_FOOD = 1
local GOAL_FIND_HOME = 2
local GOAL_ATTACK = 3
local GOAL_LEAVE_HOME = 4
local GOAL_ENTER_HOME = 5
local GOAL_WAIT_IN_HOME = 6
local GOAL_DEAD = 7

function Ant3D:init(caller, antColor)
    self.caller = caller
    self.color = antColor

    self.changeDirPeriod = 6.0 --0.5
    self.speedRatioToGlobe = 0.00065 --0.00015

    self.body = self:createBodyEntity(self.color)
    self.body.d = {} --catch-all data table
    local body = self.body
    body.info = self
    body.type = DYNAMIC
    
    self.action = ANT_ACTION_RUN
    
    self.body.d.arcProgress = 0
    self.body.d.destination = nil
    self.body.d.arcStep = 0.02
    self.body.d.moving = false
    self.body.d.startPoint = vec3(0,0,0)
    self.body.d.endPoint = vec3(0,0,0)
    
    -- ant brain data
    self.typ = ANT
    self.familly = familly
    self.goal = GOAL_LEAVE_HOME 
    self.decisionT0 = ElapsedTime + 1.5
    
    self.dead = false
    self.lastPheroPos = {-1,-1}
    self.lastTouchT0 = 0
    self.closeFromHome0 = 254
    self.closeFromHome = self.closeFromHome0
    self.closeFromFood0 = 254
    self.closeFromFood = 0
    self.energy0 = 7000
    self.energy = self.energy0 
    
    self.collide = caller.collide
end

function Ant3D:createBodyEntity(antColor)
    local antEntity = scene:entity() -- Create a new entity for the ant
    -- Add a capsule model to the entity, rotated on its side
    antEntity.model = craft.model(asset.builtin.Primitives.Capsule) -- Adjust the dimensions as needed
    antEntity.material = craft.material("Materials:Standard") -- Use a standard material for now
    antEntity.material.diffuse = antColor -- Set the ant color for visibility
    antEntity.scale = vec3(0.08, 0.11, 0.08)
    
    -- Rotate the capsule on its side
    antEntity.rotation = quat.eulerAngles(90, 0, 0) -- Rotate 90 degrees around the x-axis
    antRB = antEntity:add(craft.rigidbody, DYNAMIC, 0)
    antRB.group = GROUP_ANT
    antRB.mask = MASK_ANT
    antEntity.rigidbody = antRB
    return antEntity
end
