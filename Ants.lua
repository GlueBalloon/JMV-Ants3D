Ants = class()
-- copyright JMV38 2013 - all rights reserved

-- shortcuts to functions (accelerate)
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
local TYP_ANT = 1
local TYP_HOME = 2
local TYP_FOOD = 3
local TYP_FINGER = 4
local OBJ_OBSTACLE = 5
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

function Ants:init(n,c,size,v0,family)
    self.antsMesh = mesh()        -- the mesh to draw this family
    self.miscMesh = mesh()       -- another mesh for home base, etc...
    self.color = c          -- color of these ants
    self.sizeFactor = size  -- small size adjustment
    self.count = 0          -- internal clock
    self.v0 = v0            -- vec2 starting position
    self.body = {["position"]=v0} -- a non-clean trick to use ant function
    self.family = family

    self:antMeshInit()
    self:miscMeshInit()
    
    self.antList = {}
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
--        fill(0,0,120,255)
--        rect(1,1,w-3,h-3)
    setContext()
    pheromon = self.pheromon
    self.doPheroSmooth = true
    self.pheroSmooth = coroutine.wrap( imgSmooth2 )
    self.pheroDecreaseT0 = 10
    self.pheroDecrease = coroutine.wrap( imgDecrease )
end

function Ants:draw()
    self.count = self.count + 1
    self:antsMeshUpdate()
    self.miscMesh:draw()
    self.antsMesh:draw()
    self:antCreate()
    self:antsUpdate()
    self:pheroForce()
end

function Ants:pheroXY(ant)
    local pos = ant.body.position
    local x,y
    x = floor(pos.x/PHERO_SCALE)+2
    y = floor(pos.y/PHERO_SCALE)+2
    return x,y
end

function Ants:pheroAdd(ant)
    local x0,y0 = table.unpack(ant.lastPheroPos)
    local x,y = self:pheroXY(ant)
    if x~=x0 or y~=y0 then
        local r,g,b,a = self.pheromon:get(x,y)
        if ant.closeFromHome > 0 then
            ant.closeFromHome = ant.closeFromHome - 2
        end
            if b<ant.closeFromHome  
            then b = ant.closeFromHome 
            else ant.closeFromHome = b
            end
--            local db = 10 + ant.closeFromHome/25
--            if b<ant.closeFromHome  then b = b + db end
--            if b>255 then b=255 end
 --       end
        if ant.closeFromFood > 0 then
 --           local dr =  ant.closeFromFood/5*2
            ant.closeFromFood = ant.closeFromFood - 2
        end
            if r<ant.closeFromFood 
            then r = ant.closeFromFood 
            else ant.closeFromFood = r
            end
--            if r<ant.closeFromFood then r = r + dr end
--            if r>255 then r=255 end
--        end
        self.pheromon:set(x,y,r,g,b,255)
        ant.lastPheroPos = {x,y}
    end
end

function Ants:pheroForce()
    local x,y = self:pheroXY(self)
    local r,g,b,a = self.pheromon:get(x,y)
    self.pheromon:set(x,y,r,g,255,255)
end

function Ants:antCreate()
    if self.antCreateTime < ElapsedTime then
        self.antCreateTime = ElapsedTime + self.antCreateDelta
        if self.antEggs > 0 then 
            self.antEggs = self.antEggs -1 
            table.insert(self.antList,Ant(self))
            Ant(self)
        end
    end
end

function Ants:antsMeshUpdate()
    -- actions to do every frame for all ants
    local ms = self.antsMesh
    local coords = self.coords
    local body
    for _,ant in pairs(self.antList) do 
        body = ant.body
        body.linearVelocity = ant.linearVelocity --(avoids sliding)
        -- upddate visual
        ant.imgState = (ant.imgState + ant.imgStateDelta) % ant.imgStateMax  
        ms:setRect(ant.rect,body.position.x,body.position.y,ant.w,ant.h,body.angle)
        ms:setRectTex(ant.rect,table.unpack(coords[ant.imgState + ant.imgState0]))
        if ant.energy < 1000 then ms:setRectColor(ant.rect,color(255,0,0,255)) end
    end
end

function Ants:antsUpdate()
    local nextDecision = self.makeDecision
    for _,ant in pairs(self.antList) do 
        -- decrease energy
        ant.energy = ant.energy - 1
        -- if time's up, make new decision
        if ant.decisionT0 < ElapsedTime then nextDecision(self,ant) end
        -- put pheromon
--        if ant.lastTouchT0 < ElapsedTime then self:pheroAdd(ant) end
        self:pheroAdd(ant) 
    end
    if self.pheroDecreaseT0< ElapsedTime and not self.doPheroDecrease
    then self.doPheroSmooth = true end
    local stepFinished = false
--    if self.doPheroSmooth then stepFinished = self.pheroSmooth(self.pheromon) end
    if self.doPheroSmooth then stepFinished = true end
    if stepFinished then 
        self.doPheroSmooth = false 
        self.doPheroDecrease = true
    end
    stepFinished = false
    if self.doPheroDecrease then stepFinished = self.pheroDecrease(self.pheromon) end
    if stepFinished then 
        self.doPheroDecrease = false
        self.pheroDecreaseT0 = ElapsedTime + 1
    end
end

function Ants:makeDecision(ant)
    local goal = ant.goal
    local t0

    if     goal == GOAL_FIND_FOOD  then self:walkAround(ant)
    elseif goal == GOAL_LEAVE_HOME then ant.goal = GOAL_FIND_FOOD
    elseif goal == GOAL_FIND_HOME then self:walkAround(ant)
    elseif goal == GOAL_DEAD then self:kill(ant)
    elseif goal == GOAL_LEAVE_HOME then
    elseif goal == GOAL_LEAVE_HOME then
    elseif goal == GOAL_LEAVE_HOME then
    end
    if ant.energy <= 5000 then ant.goal = GOAL_FIND_HOME end
    if ant.energy <= 0 then ant.goal = GOAL_DEAD end
end

-- GOAL_DEAD = 0
-- GOAL_FIND_FOOD = 1
-- GOAL_FIND_HOME = 2
-- GOAL_ATTACK = 3
-- GOAL_LEAVE_HOME = 4
-- GOAL_ENTER_HOME = 5
-- GOAL_WAIT_IN_HOME = 6

function Ants:walkAround(ant)
    local n = 5
    if rnd(n) == 1 then self:shortPause(ant) else 
        if ant.goal == GOAL_FIND_HOME then self:toHome(ant) end
        if ant.goal == GOAL_FIND_FOOD then self:toFood(ant) end
    end
end

function Ants:changeDir(ant,duration)
    ant.action = ANT_ACTION_RUN
    self:setActionTexture(ant)
    local speed,angle
    local body = ant.body
    speed = ant.speed *(0.8+rnd()*0.4)
    angle = self:toHomeAngle(ant) 
    if angle then angle = angle + rad(rnd()*180 + 90)
    else angle = body.angle + rad(rnd()*180 - 90) end
    body.angle = angle
    ant.linearVelocity = vec2(cos(angle),sin(angle)) * speed
    body.linearVelocity = ant.linearVelocity
    local waitingTime = duration or 1
    ant.decisionT0 = ElapsedTime + waitingTime*(1+rnd())
end

function Ants:toHome(ant,duration)
    ant.action = ANT_ACTION_RUN
    self:setActionTexture(ant)
    local speed,angle
    local body = ant.body
    speed = ant.speed *(0.8+rnd()*0.4)
    angle = self:toHomeAngle(ant) 
    if angle then angle = angle + rad(rnd()*60 - 40)
--    if angle then 
    else angle = body.angle + rad(rnd()*180 - 100) end
    body.angle = angle
    ant.linearVelocity = vec2(cos(angle),sin(angle)) * speed
    body.linearVelocity = ant.linearVelocity
    local waitingTime = duration or 1
    ant.decisionT0 = ElapsedTime + waitingTime*(0.5+rnd())
end

function Ants:toFood(ant,duration)
    ant.action = ANT_ACTION_RUN
    self:setActionTexture(ant)
    local speed,angle
    local body = ant.body
    speed = ant.speed *(0.8+rnd()*0.4)
    angle = self:toFoodAngle(ant) 
--    if angle then 
    if angle then angle = angle + rad(rnd()*60 - 40)
    else
        angle = self:toHomeAngle(ant) 
        if angle then angle = angle + rad(rnd()*60 - 40 +180)
        else angle = body.angle + rad(rnd()*180 - 100) end
    end

    body.angle = angle
    ant.linearVelocity = vec2(cos(angle),sin(angle)) * speed
    body.linearVelocity = ant.linearVelocity
    local waitingTime = duration or 1
    ant.decisionT0 = ElapsedTime + waitingTime*(0.5+rnd())
end
function Ants:pause(ant,duration)
    ant.action = ANT_ACTION_STOP 
    self:setActionTexture(ant)
    ant.linearVelocity = vec2(0,0) 
    ant.body.linearVelocity = ant.linearVelocity
    local waitingTime = duration or 0.5
    ant.decisionT0 = ElapsedTime + waitingTime*(1+rnd())
end

function Ants:kill(ant,duration)
    ant.action = ANT_ACTION_DEAD 
    self:setActionTexture(ant)
    ant.linearVelocity = vec2(0,0) 
    ant.body.linearVelocity = ant.linearVelocity
    local waitingTime = duration or 60
    ant.decisionT0 = ElapsedTime + waitingTime*(1+rnd())
end

function Ants:shortPause(ant)
    self:pause(ant,0.2)
end

local xdir = vec2(1,0)
local srqt2 = math.sqrt(2)
local dir000 = xdir
local dir045 = xdir:rotate(45)/srqt2
local dir090 = xdir:rotate(90)
local dir135 = xdir:rotate(135)/srqt2
local dir180 = xdir:rotate(180)
local dir225 = xdir:rotate(225)/srqt2
local dir270 = xdir:rotate(270)
local dir315 = xdir:rotate(315)/srqt2

function Ants:toFoodAngle(ant)
    local map = self.pheromon
    local x,y = self:pheroXY(ant)
    local ref,c,_,angle,v
    ref,_,_ = map:get(x,y)
    c,_,_ = map:get(x+1,y)    v = dir000*(c-ref)
    c,_,_ = map:get(x+1,y+1)  v = dir045*(c-ref) + v
    c,_,_ = map:get(x,y+1)    v = dir090*(c-ref) + v
    c,_,_ = map:get(x-1,y+1)  v = dir135*(c-ref) + v
    c,_,_ = map:get(x-1,y)    v = dir180*(c-ref) + v
    c,_,_ = map:get(x-1,y-1)  v = dir225*(c-ref) + v
    c,_,_ = map:get(x,y-1)    v = dir270*(c-ref) + v
    c,_,_ = map:get(x+1,y-1)  v = dir315*(c-ref) + v
    if v:lenSqr()>0 then angle = xdir:angleBetween(v) end
    return angle
end

function Ants:toHomeAngle(ant)
    local map = self.pheromon
    local x,y = self:pheroXY(ant)
    local ref,c,_,angle,v
    _,_,ref = map:get(x,y)
    _,_,c = map:get(x+1,y)    v = dir000*(c-ref)
    _,_,c = map:get(x+1,y+1)  v = dir045*(c-ref) + v
    _,_,c = map:get(x,y+1)    v = dir090*(c-ref) + v
    _,_,c = map:get(x-1,y+1)  v = dir135*(c-ref) + v
    _,_,c = map:get(x-1,y)    v = dir180*(c-ref) + v
    _,_,c = map:get(x-1,y-1)  v = dir225*(c-ref) + v
    _,_,c = map:get(x,y-1)    v = dir270*(c-ref) + v
    _,_,c = map:get(x+1,y-1)  v = dir315*(c-ref) + v
    if v:lenSqr()>0 then angle = xdir:angleBetween(v) end
    return angle
end

function Ants:forceVelocity(ant,v)
    local body = ant.body
    angle = xdir:angleBetween(v)
    body.angle = angle
    ant.linearVelocity = v
    body.linearVelocity = v
end

function Ants.collide(ant,obj,contact)
    local state = contact.state
    local typ = obj.typ
    if not typ then return end
    if typ == TYP_HOME and (state==BEGAN or state==ENDED) then
        ant.goal = GOAL_FIND_FOOD
        ant.closeFromHome = ant.closeFromHome0
        ant.closeFromFood = 0
        ant.energy = ant.energy0
    end
    if typ == TYP_FOOD and (state==BEGAN or state==ENDED) then
        ant.goal = GOAL_FIND_HOME
        ant.closeFromHome = 0
        ant.closeFromFood = ant.closeFromFood0
        ant.energy = ant.energy0
    end
    if (typ == TYP_EDGE )and (state==BEGAN) then
        local v = ant.linearVelocity
        if obj.side=="left" or obj.side=="right" then v.x = -v.x end
        if obj.side=="bottom" or obj.side=="top" then v.y = -v.y end
        local body = ant.body
        local angle = xdir:angleBetween(v)
        body.angle = angle
        ant.linearVelocity = v
        body.linearVelocity = v
    end
    if ( typ == OBJ_OBSTACLE )and (state==BEGAN) then
        local v = ant.linearVelocity
        local pos0 = obj.body.position
        local body = ant.body
        local pos1 = body.position
        local normal = (pos1-pos0):normalize()
        local a = normal:dot(v)
        v = v - 2*a*normal
        body.angle = xdir:angleBetween(v)
        ant.linearVelocity = v
        body.linearVelocity = v
    end
end

function Ants:setActionTexture(ant)
    local function setAction(ant,delta,state0,state1)
        local stateMax
        if state1 then stateMax = state1 - state0 + 1 else stateMax = 1 end
        if ant.imgState0 ~= state0 then
        ant.imgState  = 0
        ant.imgState0 = state0
        ant.imgStateMax = stateMax
        ant.imgStateDelta = delta
        end
    end
    local action = ant.action
    if action == ANT_ACTION_DEAD then setAction(ant,0,ANT_TEXTURE_DEAD)
    elseif action == ANT_ACTION_STOP then setAction(ant,0,ANT_TEXTURE_STOP)
    elseif action == ANT_ACTION_RUN then 
        setAction(ant,1,ANT_TEXTURE_MOVE_MIN,ANT_TEXTURE_MOVE_MAX)
    elseif action == ANT_ACTION_BACKRUN then 
        setAction(ant,-1,ANT_TEXTURE_MOVE_MIN,ANT_TEXTURE_MOVE_MAX)
    end
end

function Ants:homeBaseInit()
    -- the home base
    self.baseRadius = 35
    self.base = physics.body(CIRCLE,self.baseRadius)
    self.base.position = self.v0
    self.base.sensor = true
    self.base.info = {["typ"]=HOME,["family"]= self.family }
end

-- ######### functions for initial drawings of misc  #######################
function Ants:miscMeshInit()
    local function setRectZlevel(ms,i,z)
        local v
        local k0 = (i-1)*6
        for k = k0+1,k0+6 do
        v = ms:vertex(k)
        v.z = z
        ms:vertex(k,v)
    end
    end
    img = image(100,100)
    setContext(img)
        pushStyle()
        fill(255, 255, 255, 255)
        ellipseMode(CORNER)
        ellipse(0,0,100,100)
        popStyle()
    setContext()
    local ms = self.miscMesh
    local p = self.v0
    ms.texture = img
    local i = ms:addRect(p.x,p.y,70,70)
    ms:setRectColor(i, color(178, 150, 116, 255))
    setRectZlevel(ms,i,-5)

    i = ms:addRect(p.x,p.y,40,40)
    ms:setRectColor(i, color(0, 0, 0, 200))
    setRectZlevel(ms,i,-4)
--[[        
    i = ms:addRect(p.x,p.y,50,50)
    ms:setRectColor(i, color(0, 0, 0, 128))
    setRectZlevel(ms,i,5)
--]]    
    i = ms:addRect(p.x,p.y,30,30)
    ms:setRectColor(i, color(0, 0, 0, 255))
    setRectZlevel(ms,i,5)

end
-- ######### functions for initial drawings of ants  #######################

function Ants:drawDesignBench()
    -- special to built images
        local ant = self.antList[1]
        local s = 10
        self.antsMesh:setRect(ant.rect, WIDTH/2, HEIGHT/2, ant.w*s, ant.h*s, 0) 
        ant.body.linearVelocity = vec2(0)
    self.antsMesh:setRectTex(ant.rect, table.unpack(self.coords[antDesignStep]))
        noSmooth()
        self.antsMesh:draw()
        smooth()
end

function Ants:antMeshInit()
    local img = {}
    local coords = {}
    -- get the images of various ant positions
    for i=ANT_TEXTURE_MOVE_MIN,ANT_TEXTURE_MOVE_MAX 
    do img[i] = self:loadImg(i) end
    img[ANT_TEXTURE_STOP] = self:stopImg()
    img[ANT_TEXTURE_DEAD] = self:deadImg()
    -- definition of 1 image
    local w0 = img[1].width 
    local h0 = img[1].height
    -- stick then im a single texture image
    local w = w0 * #img
    local h = h0
    local tex = image(w,h)
    setContext(tex)
        background(255, 255, 255, 0)
    setContext()
    for i =1,#img do
        local im = img[i]
        local x1 =  (w0)*(i-1)
        coords[i] = {(x1)/w, 0,w0/w, 1}
        for x=1,im.width do for y=1,im.height do
            tex:set(x+x1,y,color(im:get(x,y)))
        end end
    end

    self.coords = coords
    self.antsMesh.texture = tex
end

function Ants:getOneImageWH()
    return 31,31
end
function Ants:loadImg(phase)
    local w,h = self:getOneImageWH()
    self.img = image(w,h)
    local img = self.img
    setContext(img)
        pushMatrix() pushStyle()
        background(0, 0, 0, 0)
        fill(255, 255, 255, 255)
        stroke(255, 255, 255, 255)
        self:bodyImg()
        self:frontLeg(phase,"left")
        self:frontLeg(phase+3,"right")
        self:midLeg(phase+1,"left")
        self:midLeg(phase+4,"right")
        self:backLeg(phase+2,"left")
        self:backLeg(phase+5,"right")
        popMatrix() popStyle()
    setContext()
    return img
end

function Ants:stopImg()
    local w,h = self:getOneImageWH()
    self.img = image(w,h)
    local img = self.img
    setContext(img)
        pushMatrix() pushStyle()
        background(0, 0, 0, 0)
        fill(255, 255, 255, 255)
        stroke(255, 255, 255, 255)
        self:bodyImg()
        self:frontLeg(1,"left")
        self:frontLeg(1,"right")
        self:midLeg(3,"left")
        self:midLeg(3,"right")
        self:backLeg(5.99,"left")
        self:backLeg(5.99,"right")
        popMatrix() popStyle()
    setContext()
    return img
end

function Ants:deadImg()
    local w,h = self:getOneImageWH()
    self.img = image(w,h)
    local img = self.img
    setContext(img)
        pushMatrix() pushStyle()
        background(0, 0, 0, 0)
        fill(255, 255, 255, 255)
        stroke(255, 255, 255, 255)
        self:bodyImg("dead")
        self:deadLegs()

        popMatrix() popStyle()
    setContext()
    return img
end

function Ants:moveLeg(phase,side,ref,front,back)
    -- phase: 0 to 5.99, 0 = front and 5.99 = back
    local q = (phase - math.floor(phase/6)*6)/6
    local p = 1-q
    local sgn
    if side =="left" then sgn=1 else sgn=-1 end
    local x0,y0 = table.unpack(ref)
    local x1a,y1a,x2a,y2a = table.unpack(front)   -- front position
    local x1b,y1b,x2b,y2b = table.unpack(back )   -- back position
    local x1,y1 = x1a*p + x1b*q , y1a*p + y1b*q
    local x2,y2 = x2a*p + x2b*q , y2a*p + y2b*q
    self:leg(x0,y0,x1,y1*sgn,x2,y2*sgn)
end

function Ants:frontLeg(phase,side)
    local x0,y0 = 17,(self.img.height + 0)/2
    self:moveLeg(phase,side,{x0,y0},{0,0,5,7},{0,0,3,7})
    self:moveLeg(phase,side,{x0,y0},{4,6,11,12},{3,6,0,12})
end

function Ants:midLeg(phase,side)
    local x0,y0 = 14,(self.img.height + 0)/2
    self:moveLeg(phase,side,{x0,y0},{0,0,3,6},{0,0,1,6})
    self:moveLeg(phase,side,{x0,y0},{3,5,3,9},{1,5,-1,9})
    self:moveLeg(phase,side,{x0,y0},{3,8,3,14},{-1,8,-3,12}) 
end

function Ants:backLeg(phase,side)
    local x0,y0 = 13,(self.img.height + 0)/2
    self:moveLeg(phase,side,{x0,y0},{0,0,0,6},{0,0,-3,6})
    self:moveLeg(phase,side,{x0,y0},{1,6,-4,6},{-2,6,-9,6})
    self:moveLeg(phase,side,{x0,y0},{-3,6,-4,13},{-7,6,-13,9})
end

function Ants:deadLegs()
    local x0,y0 = self.img.width/2,(self.img.height + 0)/2
    translate(x0,y0)
    self:leg(0,0,0,0,2,5)
    self:leg(0,0,2,5,4,-4)
    self:leg(0,0,4,-3,-2,-7)

    self:leg(0,0,0,0,0,4)
    self:leg(0,0,0,4,2,-4)
    self:leg(0,0,2,-4,-1,-10)
    
    translate(2,-1)
    rotate(10)
    self:leg(0,0,0,0,2,5)
    self:leg(0,0,2,5,4,-4)
    self:leg(0,0,4,-3,-2,-7)

    self:leg(0,0,0,0,0,4)
    self:leg(0,0,0,4,2,-4)
    self:leg(0,0,2,-4,-1,-10)
    translate(-3,0)
    rotate(-10)
    self:leg(0,0,0,0,-2,5)
    self:leg(0,0,-2,5,-4,-4)
    self:leg(0,0,-4,-3,2,-7)

    self:leg(0,0,0,0,0,4)
    self:leg(0,0,0,4,-2,-4)
    self:leg(0,0,-2,-4,1,-10)
end

function Ants:bodyImg(spec)
    local y0 = (self.img.height + 1)/2
    local x0 = (self.img.width + 1)/2
    if spec==nil then
        strokeWidth(0)
        ellipse(6,y0,10,8)    -- abdomen
        ellipse(14,y0,12,4)    -- centre
        ellipse(21,y0,6,6)    -- tete
        self:legs(22,y0,0,0,3,5)    -- antenne
        self:legs(22,y0,3,5,7,3)
    elseif spec == "dead" then
        pushMatrix()
        translate(x0,y0)
        strokeWidth(0)
        ellipse(0,0,12,4)    -- centre
        rotate(20)
        ellipse(-8,0,10,8)    -- abdomen
        rotate(-40)
        ellipse(6,0,6,6)    -- tete
        self:legs(7,0,0,0,3,5)    -- antenne
        self:legs(7,0,3,5,9,4)
        popMatrix()
    end
end
function Ants:leg(x0,y0,x1,y1,x2,y2)
        strokeWidth(1.5)    
        lineCapMode(SQUARE)
        line(x0+x1,y0+y1,x0+x2,y0+y2)
end
function Ants:legs(x0,y0,x1,y1,x2,y2)
    self:leg(x0,y0,x1,y1,x2,y2)
    self:leg(x0,y0,x1,-y1,x2,-y2)
end

function Ants:touched(touch)
    -- Codea does not automatically call this method
end




