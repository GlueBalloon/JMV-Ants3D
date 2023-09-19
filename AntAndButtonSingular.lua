Button = class()
-- copyright JMV38 2013 - all rights reserved

function Button:init(n,N,side,w0)
    local x0
    if side=="left" then x0 = w0+3 else x0 = WIDTH - (w0 +3) end
    self.x = x0
    self.y = HEIGHT/(N+1)*(N-n+1)
    self.w = w0
    self.h = HEIGHT/(N+1)/2.1
    self.fontSize = WIDTH/30*8/N
    self.gray = color(127, 127, 127, 255)
    self.red = color(255, 0, 0, 255)
    self.purple = color(197, 15, 204, 255)
    self.black = color(60, 60, 60, 255)
    self.white = color(255, 255, 255, 255)
    self.butColor = self.gray
    self.txtColor = self.black
    self.txt = "button "..tostring(n)
    self.enabled = false
    self.onclick = function()  end  -- do nothing by default
    self.onRclick = function()  end  -- do nothing by default
    self.onLclick = function()  end  -- do nothing by default
end

function Button:draw()
    if self.enabled then
        rectMode(RADIUS)
        fill(self.butColor)
        rect(self.x,self.y,self.w,self.h)
        fill(self.txtColor)
        textMode(CENTER)
        textWrapWidth(self.w*1.8)
        fontSize(self.fontSize)
        font("Baskerville-BoldItalic")
        text(self.txt,self.x,self.y)
        
    end
end

local abs = math.abs
function Button:touched(touch)
    if self.enabled then
        if touch.state == BEGAN then
            if (abs(touch.x- self.x)<self.w) and (abs(touch.y- self.y)<self.h) 
            then 
                self.onclick() 
                if (touch.x > self.x) then self.onRclick() else self.onLclick() end
            end
        end
    end
end

Ant = class()
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

function Ant:init(caller)
    self.caller = caller
    
    self.speed = 100 * caller.sizeFactor 
    self.changeDirPeriod = 0.5 
    
    self.body = physics.body(CIRCLE,3*caller.sizeFactor/0.7)
    local body = self.body
    body.info = self
    body.type = DYNAMIC
    body.fixedRotation = true    
    body.position = caller.v0
    local angle = rad(rnd(360))
    body.angle = angle
    self.linearVelocity = vec2(cos(angle),sin(angle))*self.speed
    body.linearVelocity = self.linearVelocity
    
    self.action = ANT_ACTION_RUN
    
    -- init mesh information
    local w,h = caller:getOneImageWH()
    self.w = w *caller.sizeFactor
    self.h = h *caller.sizeFactor
    self.imgState = 0
    self.imgStateDelta = 1
    self.imgState0 = ANT_TEXTURE_MOVE_MIN 
    self.imgStateMax = ANT_TEXTURE_MOVE_MAX - ANT_TEXTURE_MOVE_MIN 
    self.coords = caller.coords
    self.ms = caller.antsMesh
    local v = caller.v0
    self.rect = self.ms:addRect(v.x,v.y,self.w,self.h,body.angle)    
    self.ms:setRectColor(self.rect,caller.color)
    self.ms:setRectTex(self.rect,table.unpack(self.coords[self.imgState0]))
    
    -- ant brain data
    self.typ = ANT
    self.familly = familly
    self.goal = GOAL_LEAVE_HOME 
    self.decisionT0 = ElapsedTime + 1.5
    
    self.dead = false
    --    self.iAmCloseFromHome = 255
    --    self.iAmCloseFromFood = 0
    --    self.lastHomeSmell = 0
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

function Ant:touched(touch)
    
end





