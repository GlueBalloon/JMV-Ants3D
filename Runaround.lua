-- Import CodeaCraft modules
currentAngle = 0
desiredAngle = 0

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
    smallSphere.position = vec3(0.0, 5.0, -0.0) -- Position at the equator of the larger globe
    -- Variable to store the current rotation of the small sphere
    currentRotation = quat.lookRotation(vec3(5, 0, 0), vec3(0,1,0))
end



-- Variables to control the movement
local moving = false
local startRotation
local targetRotation
local slerpT = 0

 -- Initial rotation

function quatTravelTo(dynamicPoleDirection, dynamicPoleDistance)
    -- Convert dynamic pole coordinates to Cartesian coordinates
    local targetPosition = polarToCartesian(dynamicPoleDirection, dynamicPoleDistance)
    
    -- Determine the rotation required to move from the current position to the target position
    startRotation = currentRotation
    targetRotation = quat.lookRotation(targetPosition, vec3(0,1,0))
    
    -- Reset slerpT and set moving to true
    slerpT = 0
    moving = true
end

function travelTo(angleFromNP, distanceFromNP, longitude)
    -- Convert dynamic pole coordinates to Cartesian coordinates
    endPosition = polarToCartesian(angleFromNP, distanceFromNP, 5)
    
    -- Set the start position to the current position of the small sphere
    startPosition = smallSphere.position
    
    -- Rotate the start position around the Y-axis by the longitude angle
    local rotationY = quat.angleAxis(longitude, vec3(0, 1, 0))
    startPosition = rotateVectorByQuat(startPosition, rotationY)
    
    print("NPdir: ", angleFromNP, ", NPdist: ", distanceFromNP)
    print("Start Position:", startPosition)
    print("End Position:", endPosition)
    print("---------")
    
    -- Reset slerpT and set moving to true
    slerpT = 0
    moving = true
end


function draw()
    scene:update(DeltaTime)
    scene:draw()
    
    -- If moving, compute the new position along the great circle path
    if moving and slerpT < 1 then
        -- Inside the draw function
        smallSphere.position = greatCirclePosition(startPosition, endPosition, slerpT, math.random(0,360))
        
        slerpT = slerpT + 0.01 -- Adjust this value to control the speed of the movement
        
        if slerpT >= 1 then
            moving = false
        end
    end
end


function greatCirclePosition(start, finish, t)
    -- If start or finish is the North Pole or South Pole, set a fixed axis
    if start == vec3(0.0, 5.0, 0.0) or start == vec3(0.0, -5.0, 0.0) then
        axis = vec3(0, 0, -1)
    elseif finish == vec3(0.0, 5.0, 0.0) or finish == vec3(0.0, -5.0, 0.0) then
        axis = vec3(0, 0, 1)
    else
        axis = start:cross(finish):normalize()
    end
    
    local angle = math.acos(start:dot(finish) / (start:len() * finish:len()))
    local rotation = quat.angleAxis(math.deg(angle * t), axis)
    local newPosition = rotateVectorByQuat(start, rotation)
    return newPosition
end




function dynamicTravel(entity, relativeDirection, relativeDistance)
    
    print("DPdir: ", relativeDirection, ", DPdist: ", relativeDistance)
    -- Calculate the arc length for the given degree of travel
    local r = 5  -- radius of the sphere
    local arcLength = (2 * math.pi * r / 360) * relativeDistance
    
    -- Convert the entity's current position to polar coordinates
    local currentPolar = cartesianToPolar(entity.position.x, entity.position.y, entity.position.z)
    
    -- Calculate the terminus of the journey
    local terminus = findTerminus(currentPolar, relativeDirection, arcLength)
    
    -- Use the travelTo function to move the entity to the calculated terminus
    travelTo(terminus.theta, terminus.phi)
end

-- Rotate a vector by a quaternion
function rotateVectorByQuat(v, q)
    local angles = q:angles()
    local m = matrix()
    m = m:rotate(angles.x, 1, 0, 0)
    m = m:rotate(angles.y, 0, 1, 0)
    m = m:rotate(angles.z, 0, 0, 1)
    
    -- Manually apply the rotation matrix to the vector
    local x = m[1] * v.x + m[5] * v.y + m[9] * v.z
    local y = m[2] * v.x + m[6] * v.y + m[10] * v.z
    local z = m[3] * v.x + m[7] * v.y + m[11] * v.z
    
    return vec3(x, y, z)
end

function findTerminus(currentPolar, relativeDirection, arcLength)
    local r = 5  -- radius of the sphere
    
    -- Calculate the change in phi (distance) based on the arc length
    local deltaPhi = math.deg(arcLength / r)
    
    -- Adjust the current phi and theta based on the relative direction and distance
    local newPhi = currentPolar.phi + deltaPhi
    local newTheta = currentPolar.theta + relativeDirection
    
    -- Ensure the angles wrap around correctly
    if newPhi > 180 then
        newPhi = 360 - newPhi
        newTheta = newTheta + 180
    end
    
    newTheta = newTheta % 360
    
    return {theta = newTheta, phi = newPhi}
end

function circumnavigate(direction)
    -- Convert the current position of the ball to polar coordinates
    local currentPolar = cartesianToPolar(smallSphere.position)
    
    -- Calculate the end position based on the given direction
    local endPolar = {
        theta = (currentPolar.theta + direction) % 360,
        phi = currentPolar.phi
    }
    
    -- Convert the end polar coordinates back to Cartesian coordinates
    local endPosition = polarToCartesian(endPolar.theta, endPolar.phi, 5)
    
    -- Set the start position to the current position of the small sphere
    startPosition = smallSphere.position
    
    -- Set the end position
    endPosition = endPosition
    
    -- Reset slerpT and set moving to true
    slerpT = 0
    moving = true
end

-- Convert Cartesian coordinates to spherical coordinates
function cartesianToPolar(x, y, z)
    local direction = math.deg(math.atan(z, x))
    local distance = math.deg(math.acos(y / 5))
    return vec2(direction, distance)
end

function cartesianToPolar(position)
    local r = position:len()
    local theta = math.deg(math.atan(position.z, position.x))
    local phi = math.deg(math.acos(position.y / r))
    return {theta = theta, phi = phi}
end

function polarToCartesian(theta, phi, r)
    local x = r * math.sin(math.rad(phi)) * math.cos(math.rad(theta))
    local z = r * math.sin(math.rad(phi)) * math.sin(math.rad(theta))
    local y = r * math.cos(math.rad(phi))
    return vec3(x, y, z)
end



function touched(touch)
    if touch.state == BEGAN then

        if loop ~= 0 then
            loop = 0
        else
            loop = 180
        end
        
        travelTo(math.random(0,360), loop, math.random(0,360))
        
        --circumnavigate(math.random(0,360))
    end
    touches.touched(touch)
end
