-- Import CodeaCraft modules
currentAngle = 0

function setup()
    -- Setup the main viewer
    scene = craft.scene()
    
    -- Create the globe (sphere)
    local globe = scene:entity()
    globe.model = craft.model.icosphere(1)
    globe.material = craft.material("Materials:Specular")
    globe.material.map = readImage(asset.builtin.Blocks.Gravel_Dirt)
    globe.scale = vec3(5, 5, 5)
    
    -- Setup OrbitViewer for camera control
    viewer = scene.camera:add(OrbitViewer, globe.position, 23, 6, 800)
    
    smallSphere = scene:entity()
    smallSphere.model = craft.model.icosphere(0.2)
    smallSphere.material = craft.material("Materials:Specular")
    smallSphere.material.map = readImage(asset.builtin.Blocks.Gravel_Dirt)
    smallSphere.position = vec3(0, 5, 0)
end

local moving = false
local slerpT = 0
local startRotation
local targetRotation

function travelTo(direction)
    local rotationAxis = vec3(0, 1, 0):cross(smallSphere.position):normalize()
    startRotation = quat.lookRotation(smallSphere.position, vec3(0, 1, 0))
    targetRotation = quat.angleAxis(math.rad(direction), rotationAxis) * startRotation
    
    slerpT = 0
    moving = true
end

function draw()
    scene:update(DeltaTime)
    scene:draw()
    
    if moving and slerpT < 1 then
        local currentRotation = startRotation:slerp(targetRotation, slerpT)
        smallSphere.position = rotateVectorByQuat(vec3(0, 5, 0), currentRotation)
        
        slerpT = slerpT + 0.01
        if slerpT >= 1 then
            moving = false
        end
    end
end

-- Rotate a vector by a quaternion
function rotateVectorByQuat(v, q)
    local qv = quat(v.x, v.y, v.z, 0)
    local result = q * qv * q:conjugate()
    return vec3(result.x, result.y, result.z)
end




function rotateVectorByQuat(v, q)
    local angles = q:angles()
    local m = matrix()
    m = m:rotate(angles.x, 1, 0, 0)
    m = m:rotate(angles.y, 0, 1, 0)
    m = m:rotate(angles.z, 0, 0, 1)
    
    local x = m[1] * v.x + m[5] * v.y + m[9] * v.z
    local y = m[2] * v.x + m[6] * v.y + m[10] * v.z
    local z = m[3] * v.x + m[7] * v.y + m[11] * v.z
    
    return vec3(x, y, z)
end
