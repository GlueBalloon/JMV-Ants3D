-- Import CodeaCraft modules
currentAngle = 0

function setup()
    globe3D = createEnvironment(6)
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

function draw()
    scene:update(DeltaTime)
    scene:draw()
    ants3DTables[1]:antsUpdate()
    ants3DTables[2]:antsUpdate()
    
    -- If moving, compute the new position along the arc
    if smallSphere.moving then
        smallSphere.position = travelAlongArc(startPoint, endPoint, globe3D.scale.x, smallSphere.arcProgress)
        smallSphere.arcProgress = smallSphere.arcProgress + smallSphere.step
        
        if smallSphere.arcProgress >= 1 then
            smallSphere.arcProgress = 0
            smallSphere.moving = false  -- Stop moving
        end
    end
end

function touched(touch)
    if touch.state == BEGAN then
        if smallSphere then
            -- Set the start and end points for the movement
            startPoint = smallSphere.position
            local rad = globe3D.scale.x
            endPoint = vec3(randomPlus(-rad, rad), randomPlus(-rad, rad), randomPlus(-rad, rad)) -- Random end point for demonstration
            
            -- Reset arcProgress and set moving to true
            smallSphere.arcProgress = 0
            smallSphere.moving = true
        end
    end
    touches.touched(touch)
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

function travelToGivenDestination(entity)
    -- Check if the entity has the necessary properties
    if not (entity.startPoint and entity.endPoint and entity.arcProgress and entity.radius) then
        return
    end
    
    -- Compute the new position along the arc
    entity.position = travelAlongArc(entity.startPoint, entity.endPoint, entity.radius, entity.arcProgress)
    
    -- Update the progress along the arc
    entity.arcProgress = entity.arcProgress + entity.step
    
    -- Reset the progress if it reaches or exceeds 1
    if entity.arcProgress >= 1 then
        entity.arcProgress = 0
        -- Optionally, set a new destination here
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


