

viewer.mode = STANDARD

-- Variables to store the model and its bounding box corners
local modelEntity
local testPointEntity

-- Sliders for scale, rotation, and point position
local scaleXSlider, scaleYSlider, scaleZSlider
local rotationSlider
local pointXSlider, pointYSlider, pointZSlider

viewer.mode = STANDARD

function setup()
    scene = craft.scene()
    scene.sky.material.sky = color(72, 235, 215)       
    scene.sky.material.horizon = color(34, 30, 66)       
    scene.sky.material.ground = color(60, 74, 200)   
    -- Monkey
    monkey = scene:entity()
    monkey.model = craft.model(asset.builtin.Primitives.Monkey)
    monkey.material = craft.material(asset.builtin.Materials.Specular)
    monkey.material.diffuse = color(183, 48, 224)
    monkey.position = vec3(0, 0, 0)
    monkey.scale = vec3(1, 1, 1)
    monkey.rotation = quat.eulerAngles(0, 0, 0)
    
    -- Box
    box = scene:entity()
    box.model = craft.model(asset.builtin.Primitives.RoundedCube)
    box.material = craft.material(asset.builtin.Materials.Specular)
    box.material.diffuse = color(0, 0, 255)
    box.position = vec3(0, 0, 0)
    box.scale = vec3(0.04, 0.8, 0.25)
    box.rotation = quat.eulerAngles(0, 0, 0)
    
    -- Camera
    orbitViewer = scene.camera:add(OrbitViewer, monkey.position, 6, 1, 10)
    
    setupParameters()
end

-- Parameters for controlling the monkey's transformation
function setupParameters()
    parameter.number("Monkey Scale X", 0.1, 3, 1)
    parameter.number("Monkey Scale Y", 0.1, 3, 1)
    parameter.number("Monkey Scale Z", 0.1, 3, 1)
    parameter.number("Monkey Rotate X", 0, 360, 12)
    parameter.number("Monkey Rotate Y", 0, 360, 212)
    parameter.number("Monkey Rotate Z", 0, 360, 0)
    
    -- Parameters for controlling the box's position
    parameter.number("Box Position X", -10, 10, 1.08)
    parameter.number("Box Position Y", -10, 10, 0.61)
    parameter.number("Box Position Z", -10, 10, -0.5)
end

function draw()
    scene:update(DeltaTime)
    scene:draw()
    monkey.scale = vec3(Monkey_Scale_X, Monkey_Scale_Y, Monkey_Scale_Z)
    monkey.rotation = quat.eulerAngles(Monkey_Rotate_X, Monkey_Rotate_Y, Monkey_Rotate_Z)
    box.position = vec3(Box_Position_X, Box_Position_Y, Box_Position_Z)
    -- Draw the absolute bounds of the monkey
    drawAbsoluteBounds(monkey)
    
    -- Draw the absolute bounds of the box
    drawAbsoluteBounds(box)
    
    -- Check if the test point is inside the bounding box
    if absoluteBoundsIntersect(monkey, box) then
        box.material.diffuse = color(0, 255, 0) -- Green if intersect
    else
        box.material.diffuse = color(255, 112, 0) -- Red if not
    end
end


function touched(t)
    touches.touched(t)
end



function getAbsoluteBounds(entity)
    local b = entity.model.bounds
    local corners = {
        b.min,
        vec3(b.min.x, b.min.y, b.max.z),
        vec3(b.min.x, b.max.y, b.min.z),
        vec3(b.min.x, b.max.y, b.max.z),
        vec3(b.max.x, b.min.y, b.min.z),
        vec3(b.max.x, b.min.y, b.max.z),
        vec3(b.max.x, b.max.y, b.min.z),
        b.max
    }
    
    local transformedCorners = {}
    for _, corner in ipairs(corners) do
        table.insert(transformedCorners, entity:transformPoint(corner))
    end
    
    return transformedCorners
end

function drawAbsoluteBounds(entity)
    local transformedCorners = getAbsoluteBounds(entity)
    
    -- Connect the transformed corners with lines
    local lines = {
        {1, 2}, {2, 4}, {4, 3}, {3, 1},
        {5, 6}, {6, 8}, {8, 7}, {7, 5},
        {1, 5}, {2, 6}, {3, 7}, {4, 8}
    }
    
    for _, line in ipairs(lines) do
        scene.debug:line(transformedCorners[line[1]], transformedCorners[line[2]], color(255, 0, 0))
    end
end

function pointIsInBounds(point, modelEntity)
    -- Transform the point to the model's local space
    local localPoint = modelEntity:inverseTransformPoint(point)
    
    -- Get the model's original bounds
    local bounds = modelEntity.model.bounds
    
    return localPoint.x >= bounds.min.x and localPoint.x <= bounds.max.x and
    localPoint.y >= bounds.min.y and localPoint.y <= bounds.max.y and
    localPoint.z >= bounds.min.z and localPoint.z <= bounds.max.z
end

function absoluteBoundsIntersect(entityA, entityB)
    local cornersA = getAbsoluteBounds(entityA)
    local cornersB = getAbsoluteBounds(entityB)
    
    -- Get normals for entityA
    local normalsA = getBoxNormals(cornersA)
    
    -- Get normals for entityB
    local normalsB = getBoxNormals(cornersB)
    
    -- Check for separation on each normal
    for _, normal in ipairs(normalsA) do
        if isSeparatedOnAxis(normal, cornersA, cornersB) then
            return false
        end
    end
    
    for _, normal in ipairs(normalsB) do
        if isSeparatedOnAxis(normal, cornersA, cornersB) then
            return false
        end
    end
    
    return true
end

function getBoxNormals(corners)
    return {
        (corners[2] - corners[1]):normalize(),
        (corners[4] - corners[1]):normalize(),
        (corners[5] - corners[1]):normalize()
    }
end

function isSeparatedOnAxis(axis, cornersA, cornersB)
    local minA, maxA = projectToAxis(axis, cornersA)
    local minB, maxB = projectToAxis(axis, cornersB)
    
    return maxA < minB or maxB < minA
end

function projectToAxis(axis, corners)
    local min = math.huge
    local max = -math.huge
    
    for _, corner in ipairs(corners) do
        local projection = corner:dot(axis)
        min = math.min(min, projection)
        max = math.max(max, projection)
    end
    
    return min, max
end
