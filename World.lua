World = class()
-- copyright JMV38 2013 - all rights reserved

--    object types
local OBJ_EDGE = 0
local OBJ_ANT = 1
local OBJ_HOME = 2
local OBJ_FOOD = 3
local OBJ_FINGER = 4
local OBJ_OBSTACLE = 5
local rnd = math.random
function World:init()
    -- visibility
    local ms = mesh()
    local img = image(200,200)
    setContext(img)
        pushStyle()
        background(0, 0, 0, 0)
        fill(255, 255, 255, 255)
        ellipse(100,100,200,200)
        popStyle()
    setContext()
    ms.texture = img
    local i = ms:addRect(75,HEIGHT-15,150,30)
    -- rect for fps
    local c = color(127, 127, 127, 255)
    ms:setRectColor(i,c)
    ms:setRectTex(i,0.5,0.5,0.1,0.1)
    self.ms = ms

    -- edges (not too close to real edges, due to image read)
    edge = {}
    local d = PHERO_SCALE
    edge[1] = physics.body(EDGE,vec2(d,d),vec2(WIDTH-d,d))
    edge[1].info = {typ=OBJ_EDGE, side="bottom"} 
    edge[2] = physics.body(EDGE,vec2(d,d),vec2(d,HEIGHT-d))
    edge[2].info = {typ=OBJ_EDGE, side="left"} 
    edge[3] = physics.body(EDGE,vec2(WIDTH-d,d),vec2(WIDTH-d,HEIGHT-d))
    edge[3].info = {typ=OBJ_EDGE, side="right"} 
    edge[4] = physics.body(EDGE,vec2(d,HEIGHT-d),vec2(WIDTH-d,HEIGHT-d))
    edge[4].info = {typ=OBJ_EDGE, side="top"} 
    local obstacle = {}
    local body,r
    r = 40
    self.d = r*2
    -- food
    for j=1,2 do
        body = physics.body(CIRCLE,r)
        body.type = DYNAMIC
        body.sensor = true
        body.friction = 0.01
        body.x = WIDTH/2   + (math.random()-0.5)*WIDTH/1.2
        body.y = HEIGHT/2  + (math.random()-0.5)*HEIGHT/1.2
        body.mass = 100
        obstacle[j] = body
        i = ms:addRect(body.x,body.y,2*r,2*r)
        body.info = {i=i,w=2*r,h=2*r,["typ"]=OBJ_FOOD,["r"]=r,body=body}
        local foodColor = color(58, 146, 55, 255)
        ms:setRectColor(i,foodColor)
        ms:setRectTex(i,0,0,1,1)
    end
    -- obstacles
    for j=1,4 do
--        body = physics.body(POLYGON,vec2(-10,-100),vec2(-10,100),vec2(10,100), vec2(10,-100))
        r = 100
        body = physics.body(CIRCLE,r)
        body.type = DYNAMIC
        body.friction = 0.01
        body.x = WIDTH/2   + (math.random()-0.5)*WIDTH/1.2
        body.y = HEIGHT/2  + (math.random()-0.5)*HEIGHT/1.2
        body.fixedRotation = true    
        obstacle[#obstacle+1] = body
        i = ms:addRect(body.x,body.y,20,200,0)
        body.info = {i=i,w=2*r,h=2*r,["typ"]=OBJ_OBSTACLE,["r"]=r,body=body}
        body.mass = 100
        local obstacleColor = color(70, 52, 30, 255)
        ms:setRectColor(i,obstacleColor)
    --    ms:setRectTex(i,0.5,0.5,0.1,0.1)
     --   ms:setRectTex(i,0.4,0.4,0.2,0.2)
    end
    self.obstacle = obstacle
end

function World:draw()
    local body,pos,i,d,v,_,w,h
    local ms = self.ms
    for _,body in pairs(self.obstacle) do
        pos = body.position
        --        print(table.unpack(body.info))
        v = body.info
        i,w,h = v.i, v.w, v.h
        ms:setRect(i,pos.x,pos.y,w,h)
        body.linearVelocity = body.linearVelocity * 0
    end
--    noSmooth()
    local w,h = pheromon.width, pheromon.height
    w , h = WIDTH*w/(w-2) , HEIGHT *h/(h-2)
    if pheromonVisible then sprite(pheromon,WIDTH/2,HEIGHT/2,w,h) end
--    smooth()
    ms:draw()
end

function World:touched(touch)
    local pos
    local t = vec2(touch.x,touch.y)
    if touch.state == BEGAN then
    for i,obj in pairs(self.obstacle) do
        pos = obj.position
        if pos:dist(t)<obj.info.r then touchedObject = obj end
    end
    elseif touch.state == MOVING then 
        if touchedObject then touchedObject.position = t end
    elseif touch.state == ENDED or touch.state == CANCELLED then 
        touchedObject = nil
    end
end




