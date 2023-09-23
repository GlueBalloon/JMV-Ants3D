-- Import CodeaCraft modules
currentAngle = 0

function setup()
    local globe3D = createEnvironment()
    makeSmallTestSphere(globe3D)
    ants3DTables = createAntFamilies(globe3D)
    
    for _, ant in ipairs(ants3DTables[1].antList) do
        local body = ant.body
        globeRadius = globe3D.scale.x
        -- Calculate the position on the globe's surface using spherical coordinates
        local theta = math.random() * 2 * math.pi -- Random azimuthal angle [0, 2π]
        local phi = math.acos(2 * math.random() - 1) -- Random polar angle [0, π]
        
        local x = globeRadius * math.sin(phi) * math.cos(theta)
        local y = globeRadius * math.sin(phi) * math.sin(theta)
        local z = globeRadius * math.cos(phi)
        
        body.position = vec3(x, y, z)
        orientToSurface(body, globe3D)
    end
    for _, ant in ipairs(ants3DTables[2].antList) do
        local body = ant.body
        globeRadius = globe3D.scale.x
        -- Calculate the position on the globe's surface using spherical coordinates
        local theta = math.random() * 2 * math.pi -- Random azimuthal angle [0, 2π]
        local phi = math.acos(2 * math.random() - 1) -- Random polar angle [0, π]
        
        local x = globeRadius * math.sin(phi) * math.cos(theta)
        local y = globeRadius * math.sin(phi) * math.sin(theta)
        local z = globeRadius * math.cos(phi)
        
        body.position = vec3(x, y, z)
        orientToSurface(body, globe3D)
    end
end

function orientToSurface(antEntity, globe)
    local globePosition = globe.position
    local antPosition = antEntity.position
    
    -- Calculate the orientation based on the direction vector
    local upVector = (antPosition - globePosition):normalize()
    local defaultUp = vec3(1, 0, 0):normalize()
    upVector = upVector:normalize()

    local dotProduct = defaultUp:dot(upVector)
    local angle = math.acos(dotProduct)
    
    local rotationAxis = defaultUp:cross(upVector):normalize()
    
    antEntity.rotation = quat.angleAxis(math.deg(angle), rotationAxis)
end
function orientToSurface(antEntity, globe)
    local globePosition = globe.position
    local antPosition = antEntity.position
    
    -- Calculate the orientation based on the direction vector
    local upVector = (antPosition - globePosition):normalize()
    local defaultUp = vec3(1, 0, 0):normalize()
    upVector = upVector:normalize()
    
    local dotProduct = defaultUp:dot(upVector)
    local angle = math.acos(dotProduct)
    
    local rotationAxis = defaultUp:cross(upVector):normalize()
    
    local surfaceAlignment = quat.angleAxis(math.deg(angle), rotationAxis)
    
    -- Get the ant's forward direction in world space
    local forwardDirection = rotateVectorByQuat(vec3(1, 0, 0), antEntity.rotation)
    
    -- Calculate the rotation needed to face the direction of movement
    local facingDirection = quat.lookRotation(forwardDirection, upVector)
    
    -- Combine the two rotations
    local finalRotation = surfaceAlignment * facingDirection
    
    antEntity.rotation = finalRotation
end

function orientToSurface(antEntity, globe)
    local globePosition = globe.position
    local antPosition = antEntity.position
    
    -- Calculate the orientation based on the direction vector
    local upVector = (antPosition - globePosition):normalize()
    local forwardDirection = rotateVectorByQuat(vec3(1, 0, 0), antEntity.rotation) -- Assuming the ant's forward direction is along the x-axis
    
    -- Calculate the right vector based on the cross product of forward and up vectors
    local rightVector = forwardDirection:cross(upVector):normalize()
    
    -- Recalculate the forward vector to make it orthogonal to the up and right vectors
    forwardDirection = upVector:cross(rightVector):normalize()
    
    -- Create a quaternion from the up and forward vectors
    local newRotation = quat.lookRotation(forwardDirection, upVector)
    
    -- Apply the initial rotation of 90 degrees around the x-axis
    local initialRotation = quat.eulerAngles(90, 0, 0)
    newRotation = newRotation * initialRotation
    
    antEntity.rotation = newRotation
end

function draw()
    scene:update(DeltaTime)
    scene:draw()
    ants3DTables[1]:antsUpdate()
    ants3DTables[2]:antsUpdate()
    
    -- If moving, compute the new position along the arc
    if moving then
        smallSphere.position = travelAlongArc(startPoint, endPoint, 5, arcProgress)
        arcProgress = arcProgress + step
        
        if arcProgress >= 1 then

            arcProgress = 0
        end
    end
end

function travelAlongArc(startPoint, endPoint, radius, t)
    -- Normalize the points to the sphere's surface
    startPoint = startPoint:normalize() * radius
    endPoint = endPoint:normalize() * radius
    
    -- Compute the cosine of the angle between A and B using the dot product
    local cosTheta = startPoint:dot(endPoint) / (startPoint:len() * endPoint:len())
    local theta = math.acos(cosTheta)
    
    local scaleA = math.sin((1 - t) * theta) / math.sin(theta)
    local scaleB = math.sin(t * theta) / math.sin(theta)
    local position = startPoint * scaleA + endPoint * scaleB
    
    return position
end

function touched(touch)
    if touch.state == BEGAN then
        if smallSphere then
            -- Set the start and end points for the movement
            startPoint = smallSphere.position
            endPoint = vec3(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5)) -- Random end point for demonstration
            
            -- Reset arcProgress and set moving to true
            arcProgress = 0
            moving = true
        end
    end
    touches.touched(touch)
end
