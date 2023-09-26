
--ant obj model from https://www.turbosquid.com/Search/Artists/stickboybob

function setup()    
    
    -- copy images from Documents/Dropbox folder to local folder                        
    --[[
    img=readText(asset.documents.ANT)
    saveText(asset.."ANT.obj",img)
    stop()
    ]]

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
        
        --body.position = vec3(x, y, z)
        body.position = ants3DTables[1].base.position
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
        
        --body.position = vec3(x, y, z)
        body.position = ants3DTables[2].base.position
        orientToSurface(body, globe3D)
    end
end

function draw()
    scene:update(DeltaTime)
    scene:draw()
    ants3DTables[1]:antsUpdate()
    ants3DTables[2]:antsUpdate()
    
    travelIfGivenDestination(smallSphere, globe3D)
end

function touched(touch)
    if touch.state == BEGAN then
        if smallSphere then
            -- Set the start and end points for the movement
            smallSphere.d.startPoint = smallSphere.position
            local rad = globe3D.scale.x
            smallSphere.d.endPoint = vec3(randomPlus(-rad, rad), randomPlus(-rad, rad), randomPlus(-rad, rad)) -- Random end point for demonstration
            --print(smallSphere.d.endPoint)
            -- set moving to true
            smallSphere.d.moving = true
        end
        
        --[[
        -- Do the same for all ants
        for _, ants in ipairs(ants3DTables) do
            for _, ant in pairs(ants.antList) do
                ant.body.d.startPoint = ant.body.position
                --local rad = 0.00001
                --ant.body.d.endPoint = vec3(randomPlus(-rad, rad), randomPlus(-rad, rad), randomPlus(-rad, rad))
                local distance = randomPlus(ant.body.scale.y * 4, ant.body.scale.y * 8)
                ant.body.d.endPoint = randomSurfacePointNear(ant.body.position, ant.body.scale.y * 5, globe3D)
                -- set moving to true
                ant.body.d.arcProgress = 0
                ant.body.d.moving = true
            end
        end
        ]]
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
--[[
    local initialRotation = quat.eulerAngles(90, 0, 0)
    newRotation = newRotation * initialRotation
    
    antEntity.rotation = newRotation
]]
end

function travelIfGivenDestination(entity, globe, speed)
    -- Check if the entity has the necessary properties
    if not (entity.d.startPoint and entity.d.endPoint and entity.d.arcProgress) then
        return
    end
    
    local speed = speed or 0.5
    
    -- Check if the entity is supposed to be moving
    if not entity.d.moving then
        return
    end
    
    -- Fetch the radius from the globe
    local radius = globe.scale.x
    
    -- Calculate the actual distance between startPoint and endPoint
    local actualDistance = (entity.d.endPoint - entity.d.startPoint):len()
    
    -- Calculate arcStep based on the actual distance and desired speed
    entity.d.arcStep = speed / actualDistance  -- Adjust arcStep based on distance

    -- Compute the new position along the arc
    entity.position = travelAlongArc(entity.d.startPoint, entity.d.endPoint, radius, entity.d.arcProgress)
    
    -- Update the progress along the arc
    entity.d.arcProgress = entity.d.arcProgress + entity.d.arcStep
    
    -- Reset the progress if it reaches or exceeds 1
    if entity.d.arcProgress >= 1 then
        entity.d.arcProgress = 0
        entity.d.moving = false  -- Stop moving when reaching the destination
        -- Optionally, set a new destination here
    end
    
    orientToMovement(entity, globe, entity.d.startPoint, entity.d.endPoint)
end

function orientToMovement(antEntity, globe, startPoint, endPoint)
    local globePosition = globe.position
    local antPosition = antEntity.position
    
    -- Calculate the orientation based on the direction vector
    local upVector = (antPosition - globePosition):normalize()
    local forwardDirection = (endPoint - startPoint):normalize()  -- Direction of movement
    
    -- Calculate the right vector based on the cross product of forward and up vectors
    local rightVector = forwardDirection:cross(upVector):normalize()
    
    -- Recalculate the forward vector to make it orthogonal to the up and right vectors
    forwardDirection = upVector:cross(rightVector):normalize()
    
    -- Create a quaternion from the up and forward vectors
    local newRotation = quat.lookRotation(forwardDirection, upVector)
    
    -- The extra rotation the model needs to face the right direction 
    local modelForwardAdjustment = quat.eulerAngles(180, 180, 0)
    
    
    newRotation = newRotation * modelForwardAdjustment
    antEntity.rotation = newRotation

end

function travelAlongArc(startPoint, endPoint, radius, progress)
    -- Normalize the points to the sphere's surface
    startPoint = startPoint:normalize() * radius
    endPoint = endPoint:normalize() * radius
    
    -- Compute the cosine of the angle between A and B using the dot product
    local cosTheta = startPoint:dot(endPoint) / (startPoint:len() * endPoint:len())
    local theta = math.acos(cosTheta)
    
    local scaleA = math.sin((1 - progress) * theta) / math.sin(theta)
    local scaleB = math.sin(progress * theta) / math.sin(theta)
    local position = startPoint * scaleA + endPoint * scaleB
    
    return position
end


