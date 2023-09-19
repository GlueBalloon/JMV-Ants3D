-- 0  fourmi
-- copyright JMV38 2013 - all rights reserved


--saveImage("Project:Icon", readImage(asset.ants))

viewer.mode = STANDARD

function setup()
    -- codea settings
    physics.gravity(0,0)
    smooth()
    -- game menu
    buttons = Buttons()
    -- initial game settings
    pheromonVisible = false
    antRunningMode = true    -- those modes are linked:
    antDesignMode = false
    antDesignStep = 8
    -- world settings
    PHERO_SCALE = 10     -- constant: the size reduction factor for pheromon images
    world = World()
    -- finger is a global object of world
    
    -- create a 1rst ant family:
    local brown = color(120, 65, 30, 255)
    local v0 = vec2(WIDTH/20,HEIGHT/15)
    local size = 0.7
    local family = 1
    redAnts = Ants(100, brown ,size ,v0, family)

    -- create a 2nd ant family:
    local black = color(0, 0, 0, 255)
    v0 = vec2(WIDTH/15*4,HEIGHT/13*4)
    size = 1.1
--    blackAnts = Ants(100, black,size ,v0)
    if FPS then 
        local dummyFps = FPS() -- corrects for the drawing bug
        fps=FPS() 
    end


end

function draw()
    background(255, 255, 255, 255)
    -- normal mode
    if antRunningMode then
        if pheromonVisible then background(0, 0, 0, 255) end
        world:draw()
        if redAnts then redAnts:draw() end
        if blackAnts then blackAnts:draw() end
        if fps then fps:draw() end
    end
    -- alternative drawing for ant design
    if antDesignMode then redAnts:drawDesignBench() end
    -- in any case show buttons on top
    buttons:draw()
end

function touched(touch)
    buttons:touched(touch)
    world:touched(touch)
end
local pi = math.pi
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

function collide(contact)
    local objA,objB = contact.bodyA.info,contact.bodyB.info
    if objA then if objA.typ==ANT then objA:collide(objB,contact) end end
    if objB then if objB.typ==ANT then objB:collide(objA,contact) end end
end

-- this function can be wrapped into a coroutine that will
--    1/ apply a unismooth to img
--    2/ autoadjust itself to 40 FPS
imgSmooth2 = function(img)
    local budget = 0.001
    local targetDeltaTime = 1/40
    local r0,g0,b0,a0
    local r,g,b,a
    local att = 2
    local imgGet,imgSet = img.get,img.set
    local c,count =0,0
    local t0 = 0
    local clock = os.clock
    local buffer1, buffer2= {},{}
    while true do
     for y = 2, img.height-1 do buffer1[y] = color(imgGet(img,1,y)) end  -- init
     -- copy values to edges
     for y = 1, img.height do imgSet(img,1,y, color(imgGet(img,2,y)) ) end 
     for y = 1, img.height do imgSet(img,img.width,y, color(imgGet(img,img.width-1,y)) ) end 
     for x = 1, img.width do imgSet(img,x,1, color(imgGet(img,x,2)) ) end 
     for x = 1, img.width do imgSet(img,x,img.height, color(imgGet(img,x,img.height-2)) ) end 
     for x = 1, img.width do imgSet(img,x,img.height-1, color(imgGet(img,x,img.height-2)) ) end 
     -- average other values
     for x = 2, img.width-1 do -- for each column of the image,
        for y = 2, img.height-1 do -- compute the 3x3 average ...
            r0,g0,b0,a0 = 0,0,0,0
            for p=1,3 do for q=1,3 do
                r,g,b,a = imgGet(img,x+p-2,y+q-2)
                r0,g0,b0,a0 = r0+r ,g0+g ,b0+b ,a0+a
            end end
            r,g,b,a = imgGet(img,x,y)
            r0,g0,b0,a0 = r0/9, g0/9, b0/9, 255
            if r0<r then r0 = r else r0 = (r0-r) + r end
            if g0<g then g0 = g else g0 = (g0-g) + g end
            if b0<b then b0 = b else b0 = (b0-b) + b end
            buffer2[y] = color(r0,g0,b0,a0)     -- ... and save it in a buffer
            -- (if the results are directly written, then next column cannot be computed)
        end
        for y = 2, img.height-1 do          -- instead,
            imgSet(img,x-1,y,buffer1[y])    -- write the results of PREVIOUS column
            buffer1[y] = buffer2[y]         -- and save current results for next col
        end
        if t0 < clock() then -- this is to stop if there no time left
 --[[           if DeltaTime > targetDeltaTime -- autoadjustment to target FPS
            then budget = budget*0.99 
            else budget = budget*1.01 
            end
    --]]
            count = count + 1    -- just for debug: proof the coroutine in runnning
            coroutine.yield(false)        -- leave the coroutine ...
            t0 = clock()+1/60 * budget    -- ... and when back compute new time limit
        end
     end
    coroutine.yield(true)        -- leave the coroutine with info it is finished
    end
end

 -- CAUTION: create a new wrap for each new img!

imgDecrease = function(img)
    local budget = 0.001
    local targetDeltaTime = 1/40
    local r0,g0,b0,a0
    local r,g,b,a
    local db,bmax = 0,0
    local imgGet,imgSet = img.get,img.set
    local c,count =0,0
    local t0 = 0
    local dr = 1
    local clock = os.clock
    while true do
     for x = 1, img.width do -- for each column of the image,
        for y = 1, img.height do 
            r0,g0,b0,a0 = imgGet(img,x,y)
            r0,g0,b0,a0 = r0-dr,g0-1,b0-1,255
            if r0<0 then r0=0 end
            if g0<0 then g0=0 end
            if b0<0 then b0=0 end
--            if b0>250 then bmax = 250 end
--            if b0>0 then b0=b0-db end
            imgSet(img,x,y, color(r0,g0,b0,a0)    ) 
        end
        if t0 < clock() then -- this is to stop if there no time left
 --[[           if DeltaTime > targetDeltaTime -- autoadjustment to target FPS
            then budget = budget*0.99 
            else budget = budget*1.01 
            end
    --]]
            count = count + 1    -- just for debug: proof the coroutine in runnning
            coroutine.yield(false)        -- leave the coroutine ...
            t0 = clock()+1/60 * budget    -- ... and when back compute new time limit
        end
     end
--     if bmax ==250 then db=1 else db=0 end
--     bmax=0
     coroutine.yield(true) 
    end
end







