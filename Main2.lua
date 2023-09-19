-- Import CodeaCraft modules
slerpT = 0

function setup()
    -- Setup the main viewer
    scene = craft.scene()
    
    -- Create the globe (sphere)
    local globe = scene:entity()
    globe.model = craft.model.icosphere(1)
    globe.material = craft.material("Materials:Specular")
    globe.material.map = readImage(asset.builtin.Blocks.Gravel_Dirt) -- You can replace this with any texture
    globe.scale = vec3(5, 5, 5) -- Adjust the size of the globe
    globeRB = globe:add(craft.rigidbody, KINEMATIC)
    globe:add(craft.shape.sphere, 1)
    
    -- Setup OrbitViewer for camera control
    viewer = scene.camera:add(OrbitViewer, globe.position, 23, 6, 800)
    
    smallSphere = scene:entity()
    smallSphere.model = craft.model.icosphere(0.2) -- 0.2 is the radius, adjust as needed
    smallSphere.material = craft.material("Materials:Specular")
    smallSphere.material.map = readImage(asset.builtin.Blocks.Gravel_Dirt) -- You can replace this with any texture
    smallSphere.position = vec3(0, 5, 0) -- Position at the North Pole of the larger globe
    
    startRotation = quat.lookRotation(vec3(0, 5, 0), vec3(0, 1, 0))
end

function draw()
    scene:update(DeltaTime)
    scene:draw()
    -- Move the smaller sphere towards the target position
    if targetPosition and slerpT < 1 then
        local slerpedQuat = quat.slerp(startRotation, targetRotation, slerpT)
        local rotationMatrix = slerpedQuat:toMatrix()
        smallSphere.position = rotationMatrix * vec3(0, 5, 0) -- Apply rotation matrix to North Pole position
        slerpT = slerpT + 0.01 -- Adjust this value to control the speed of the movement
    end
end

function touched(touch)
    if touch.state == BEGAN then
        -- Change direction on touch
        direction = direction * -1
    end
    touches.touched(touch)
    if true then return end
    -- Handle touch to get the point on the globe
    if touch.state == BEGAN then
        local origin, direction = viewer.camera:screenToRay(vec2(touch.x, touch.y))
        local hitInfo = scene.physics:raycast(origin, direction, 100)
        
        if hitInfo and hitInfo.point then
            -- Absolute 3D Position
            print("Absolute 3D Position:", hitInfo.point)
            
            -- Vector from Center
            local centerToTouch = (hitInfo.point - vec3(0,0,0)):normalize()
            print("Vector from Center:", centerToTouch)
            
            -- Dynamic-Pole System
            local polar = cartesianToPolar(centerToTouch)
            print("Dynamic-Pole System: ", polar.direction, ", ", polar.distance,"from North")
            
            targetRotation = quat.lookRotation(hitInfo.point:normalize() * 5, vec3(0, 1, 0))
            print("Target Rotation:", targetRotation, "\n---") -- Print the target rotation for debugging
            slerpT = 0
        end
    end
end


function cartesianToPolar(v)
    local direction = math.deg(math.atan(v.x, v.z))
    if direction < 0 then direction = direction + 360 end
    local distance = math.deg(math.acos(v.y))
    return {direction = direction, distance = distance}
end
