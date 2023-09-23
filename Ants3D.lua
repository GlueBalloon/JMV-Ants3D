
function createAntFamilies(globe)
    local antCount = 60
    -- Create the first ant family
    local brown = color(178, 62, 50)
    local startPosition1 = vec3(WIDTH/20, HEIGHT/15, 0) -- Adjust this to a suitable 3D position
    local size1 = 0.7
    local family1_3D = 1
    redAnts = Ants3D(antCount, brown, size1, startPosition1, family1_3D, globe)
    ants3DTables = {redAnts}
    
    -- Create the second ant family (if needed)
    local black3D = color(60, 40, 40)
    local startPosition2 = vec3(WIDTH/15*4, HEIGHT/13*4, 0) -- Adjust this to a suitable 3D position
    local size2 = 1.1
    local family2_3D = 1
    blackAnts = Ants3D(antCount, black3D, size2, startPosition2, family1_3D, globe)
    ants3DTables = {redAnts, blackAnts}
    
    return ants3DTables
end

Ants3D = class()
-- copyright JMV38 2013 - all rights reserved

-- shortcuts to functions (accelerate)
local rnd = math.random
local deg = math.deg
local rad = math.rad
local cos = math.cos
local sin = math.sin
local floor = math.floor
-- constants
PHERO_SCALE = 10
--    object types
local ANT = 1
local HOME = 2
local FOOD = 3
local FINGER = 4
local TYP_ANT = 1
local TYP_HOME = 2
local TYP_FOOD = 3
local TYP_FINGER = 4
local OBJ_OBSTACLE = 5
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

function Ants3D:init(n,c,size,startPos,family, globe)
    self.color = c          -- color of these ants
    self.size = size  -- small size adjustment
    self.count = 0          -- internal clock
    self.startPos = startPos            -- vec2 starting position
    self.body = {["position"]=startPos} -- a non-clean trick to use ant function
    self.family = family
    self.globe = globe
    self.antList = {}
    
    self:antEntitiesInit(n, c)
    

    self:homeBaseInit()
    
    -- the ant house data
    self.foodStock = 100
    self.antEggs = n
    self.antCreateTime = 0
    self.antCreateDelta = 0.5
    
    -- pheromons
    local w = floor(WIDTH/PHERO_SCALE)+3
    local h = floor(HEIGHT/PHERO_SCALE) +3
    self.pheromon = image(w,h)
    setContext(self.pheromon)
    background(0, 0, 0, 255)
    setContext()
    pheromon = self.pheromon
    self.doPheroSmooth = true
    self.pheroSmooth = coroutine.wrap( imgSmooth2 )
    self.pheroDecreaseT0 = 10
    self.pheroDecrease = coroutine.wrap( imgDecrease )
end

function Ants3D:antsUpdate()
    for _,ant in pairs(self.antList) do 
        -- decrease energy
        ant.energy = ant.energy - 1
        -- if time's up, make new decision
        if ant.decisionT0 < ElapsedTime then self:makeDecision(ant) end
        -- put pheromon
        --        if ant.lastTouchT0 < ElapsedTime then self:pheroAdd(ant) end
        self:pheroAdd(ant) 
    end
end

function Ants3D:makeDecision(ant)
    local goal = ant.goal
    local t0
    
    if     goal == GOAL_FIND_FOOD  then self:walkAround(ant)
    elseif goal == GOAL_LEAVE_HOME then ant.goal = GOAL_FIND_FOOD
    elseif goal == GOAL_FIND_HOME then self:walkAround(ant)
    elseif goal == GOAL_DEAD then self:kill(ant)
    end 

    if ant.energy <= 5000 then ant.goal = GOAL_FIND_HOME end
    if ant.energy <= 0 then ant.goal = GOAL_DEAD end
end

function Ants3D:pheroAdd(ant)
    
end

function Ants3D:walkAround(ant)
    local n = 5
    if rnd(n) == 1 then 
        self:shortPause(ant) 
    else 
        self:moveRandomly(ant)
    end
end

function Ants3D:kill(ant, duration)
    ant.action = ANT_ACTION_DEAD
    
    -- Stop the ant's movement in 3D space
    ant.velocity = vec3(0, 0, 0)
    ant.body.velocity = ant.velocity
    
    -- Set the time for the next decision
    local waitingTime = duration or 60
    ant.decisionT0 = ElapsedTime + waitingTime * (1 + rnd())
end


function Ants3D:pause(ant, duration)
    -- Stop the ant's movement
    ant.body.velocity = vec3(0, 0, 0)
    
    -- Set the time for the next decision
    local waitingTime = duration or 0.5
    ant.decisionT0 = ElapsedTime + waitingTime * (1 + rnd())
end

function Ants3D:shortPause(ant)
    self:pause(ant, 0.2)
end

function Ants3D:moveRandomly(ant)
    local scale = self.globe.scale
    local speed = scale.x * ant.speedRatioToGlobe
    ant.body.position = travelAlongArc(ant.body.position, vec3(randomPlus(-scale.x, scale.x), randomPlus(-scale.y, scale.y), randomPlus(-scale.z, scale.z)), scale.x, speed)

    -- Orient the ant to the surface
    orientToSurface(ant.body, self.globe)
end

function Ants3D:moveRandomly(ant)
    local scale = self.globe.scale
    local speed = scale.x * ant.speedRatioToGlobe
    
    -- Store the last position
    local lastPosition = ant.body.position
    
    -- Calculate the new position
    ant.body.position = travelAlongArc(ant.body.position, vec3(randomPlus(-scale.x, scale.x), randomPlus(-scale.y, scale.y), randomPlus(-scale.z, scale.z)), scale.x, speed)
    
    -- Calculate the direction vector
    local direction = (ant.body.position - lastPosition):normalize()
    
    -- Calculate the rotation quaternion based on the direction
    local targetRotation = quat.lookRotation(direction, vec3(0, 1, 0))
    
    -- Combine this with the initial 90-degree rotation
    local finalRotation = quat.eulerAngles(90, 0, 0) * targetRotation
    
    -- Set the ant's rotation
    ant.body.rotation = finalRotation
    
    -- Orient the ant to the surface
    orientToSurface(ant.body, self.globe)
end




function Ants3D:antEntitiesInit(numAnts, antColor)
    for i = 1, numAnts do
        table.insert(self.antList, Ant3D(self, antColor))
    end
end

function Ants3D:homeBaseInit()
    -- Extract globe's properties
    local globeRadius = self.globe.scale.x -- Assuming the globe is uniformly scaled
    local globePosition = self.globe.position
    local baseRadius = globeRadius * 0.03
    
    -- Create the squashed sphere for the home base
    self.base = scene:entity()
    self.base.d = {} --catch-all data table
    self.base.model = craft.model(asset.builtin.Primitives.Sphere)
    self.base.material = craft.material(asset.builtin.Materials.Standard)
    self.base.material.map = readImage(asset.builtin.Blocks.Glass_Frame) -- You can replace this with any texture
    self.base.scale = vec3(baseRadius, baseRadius * 0.2, baseRadius) -- squash the sphere
    
    local basePlanted = false
    while not basePlanted do
        -- Generate a random unit vector for position
        local randomDirection = vec3(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5):normalize()
        local homeBasePosition = globePosition + randomDirection * globeRadius
        self.base.position = homeBasePosition
        -- Calculate the orientation based on the direction vector
        local upVector = (homeBasePosition - globePosition):normalize()
        local downVector = (homeBasePosition + globePosition):normalize()
        local defaultUp = vec3(0, 1, 0):normalize()
        upVector = upVector:normalize()
        
        local dotProduct = defaultUp:dot(upVector)
        local angle = math.acos(dotProduct)
        
        local rotationAxis = defaultUp:cross(upVector):normalize()
        
        self.base.rotation = quat.angleAxis(math.deg(angle), rotationAxis)
        
        -- Check for intersections using the bounding box system
        local intersects = false
        for _, food in ipairs(foodSources) do
            if absoluteBoundsIntersect(self.base, food) then
                intersects = true
                break
            end
        end
        
        for _, obstacle in ipairs(obstacles) do
            if absoluteBoundsIntersect(self.base, obstacle) then
                intersects = true
                break
            end
        end
        
        if ants3DTables then
            for _, ants in ipairs(ants3DTables) do
                if self.base and ants.base and self.base ~= ants.base and absoluteBoundsIntersect(self.base, ants.base) then
                    intersects = true
                    break
                end
            end 
        end
        
        if not intersects then
            basePlanted = true
        end
        
        -- Adjust the position to sink the sphere into the globe
        local sinkAmount = self.base.scale.y * 0.6-- Adjust as needed
        self.base.position = self.base.position - upVector * sinkAmount
        self.base.d.info = {["typ"]=HOME,["family"]= self.family }
    end
end

