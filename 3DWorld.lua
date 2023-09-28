
-- Collision Groups
GROUP_GLOBE = 1<<0       -- 0001
GROUP_ANT = 1<<1        -- 0010
GROUP_FOOD = 1<<2       -- 0100
GROUP_OBSTACLE = 1<<3   -- 1000
GROUP_HOME_BASE = 1<<4  -- 10000

-- Masks
MASK_GLOBE = ~(GROUP_GLOBE)  -- Globe should not collide with itself
MASK_ANT = ~(GROUP_ANT)      -- Ants should not collide with themselves
MASK_FOOD = ~(GROUP_FOOD)    -- Food should not collide with itself
MASK_OBSTACLE = ~(GROUP_OBSTACLE) -- Obstacles should not collide with themselves
MASK_HOME_BASE = ~(GROUP_HOME_BASE) -- Home bases should not collide with themselves
function createEnvironment(globeRadius)
    globe3D = createWorld(globeRadius)
    initializeViewer(globe3D)
    foodSources = makeFoodSources(globe3D)
    obstacles = makeObstacles(globe3D)


    --make an already plenty subdivided icosahedron
    icosahedron = createIcosahedron(globeRadius)
    
    --generate data to split the icosahedron into smaller triangles
    positions = icosahedron.model.positions
    indices = icosahedron.model.indices
    local newPos, newInd = subdivide(positions, indices, icosahedron)

    --use that data to make a new model
    newModel = craft.model()
    newModel.positions = newPos 
    newModel.indices = newInd
    newModel.uvs = generateUVs(newPos)
    newModel.normals = generateNormals(newPos)
    icosahedron.model = newModel
    
    --
    cubesAtVertices(icosahedron, color(236, 67, 202))
    
    return globe3D
end

function generateUVs(positions)
    local uvs = {}
    for _, pos in ipairs(positions) do
        -- Calculate the spherical coordinates
        local longitude = math.atan(pos.z, pos.x)
        local latitude = math.asin(pos.y)
        
        -- Map the longitude and latitude to U and V coordinates
        local u = 0.5 + longitude / (2 * math.pi)
        local v = 0.5 - latitude / math.pi
        
        table.insert(uvs, vec2(u, v))
    end
    return uvs
end

function generateUVs(positions)
    local uvs = {}
    for _, pos in ipairs(positions) do
        local normalizedPos = pos:normalize()
        
        -- Compute theta and phi
        local theta = math.atan(normalizedPos.z, normalizedPos.x)
        local phi = math.acos(normalizedPos.y)
        
        -- Convert to UV coordinates
        local u = (theta + math.pi) / (2 * math.pi)
        local v = phi / math.pi
        
        table.insert(uvs, vec2(u, v))
    end
    return uvs
end

function generateUVs(positions)
    local uvs = {}
    local seamThreshold = 0.9 -- Adjust this value if needed
    for _, pos in ipairs(positions) do
        local normalizedPos = pos:normalize()
        
        -- Compute theta and phi
        local theta = math.atan(normalizedPos.z, normalizedPos.x)
        local phi = math.acos(normalizedPos.y)
        
        -- Convert to UV coordinates
        local u = (theta + math.pi) / (2 * math.pi)
        local v = phi / math.pi
        
        -- Adjust the UV coordinates for vertices along the seam
        if u > seamThreshold then
            u = 0
        end
        
        table.insert(uvs, vec2(u, v))
    end
    return uvs
end

function generateUVs(positions)
    local uvs = {}
    for _, pos in ipairs(positions) do
        local normalizedPos = pos:normalize()
        
        -- Compute the cylindrical projection
        local u = 0.5 + (math.atan(normalizedPos.z, normalizedPos.x) / (2 * math.pi))
        local v = 0.5 - (math.asin(normalizedPos.y) / math.pi)
        
        table.insert(uvs, vec2(u, v))
    end
    return uvs
end



function generateNormals(positions)
    local normals = {}
    for _, pos in ipairs(positions) do
        local normal = pos:normalize()
        table.insert(normals, normal)
    end
    return normals
end


function cubesAtVertices(entity, aColor)
    -- Create a material for the cubes
    local mat = craft.material("Materials:Specular")
    mat.diffuse = aColor or color(64, 0, 255)
    
    local scale = entity.scale
    
    -- Iterate over the model's positions and place a cube at each position
    for _, pos in ipairs(entity.model.positions) do
        local worldPos = vec3(pos.x * scale.x, pos.y * scale.y, pos.z * scale.z)
        local e = scene:entity()
        e.position = worldPos
        e.model = craft.model.cube(vec3(0.025, 0.025, 0.025))
        e.rotation = quat.eulerAngles(45,0,0)
        e.material = mat
    end
end

function subdivide(positions, indices, entity)
    local newPositions = {}
    local newIndices = {}
    local midpointCache = {}
    
    local function getMidpoint(p1, p2)
        local key = math.min(p1, p2) .. "_" .. math.max(p1, p2)
        if midpointCache[key] then
            return midpointCache[key]
        end
        
        local midpoint = (positions[p1] + positions[p2]) * 0.5
        
        -- Calculate the distance of the original position from the center
        local originalDistance = positions[p1]:len()
        
        -- Normalize the midpoint and scale it to the original distance
        midpoint = midpoint:normalize() * originalDistance
        
        table.insert(newPositions, midpoint)
        local index = #newPositions + #positions -- Adjusted index to account for original positions
        
        midpointCache[key] = index
        return index
    end
    
    for i = 1, #indices, 3 do
        local a, b, c = indices[i], indices[i+1], indices[i+2]
        
        -- Subdivide the triangle
        local ab = getMidpoint(a, b)
        local bc = getMidpoint(b, c)
        local ca = getMidpoint(c, a)
        
        -- Triangle 1
        table.insert(newIndices, a)
        table.insert(newIndices, ca)
        table.insert(newIndices, ab)
        
        -- Triangle 2
        table.insert(newIndices, b)
        table.insert(newIndices, ab)
        table.insert(newIndices, bc)
        
        -- Triangle 3
        table.insert(newIndices, c)
        table.insert(newIndices, bc)
        table.insert(newIndices, ca)
        
        -- Triangle 4 (central triangle)
        table.insert(newIndices, ab)
        table.insert(newIndices, ca)
        table.insert(newIndices, bc)
        
    end
    
    for i, v in ipairs(positions) do
        table.insert(newPositions, v)
    end
    
    return newPositions, newIndices
end

function createIcosahedron(radius)
    local icosahedron = scene:entity()
    icosahedron.model = craft.model(asset.icosahedron)
    icosahedron.scale = vec3(1,1,1) * radius * 2 -- Adjust the size of the globe
    return icosahedron
end


function createWorld(radius)
    -- Set up the 3D world
    scene = craft.scene()
    scene.sky.material.sky = color(72, 235, 215)       
    scene.sky.material.horizon = color(34, 30, 66)       
    scene.sky.material.ground = color(33, 70, 120)
    -- Create the globe (sphere)
    local globe = scene:entity()
    scene.physics.gravity = vec3(0,0,0)
    --globe.model = craft.model(asset.builtin.Primitives.Sphere)
    globe.model = craft.model(asset.icosahedron)
    globe.material = craft.material(asset.builtin.Materials.Standard)
    globe.material.map = readImage(asset.builtin.Surfaces.Basic_Bricks_Color) -- You can replace this with any texture
    globe.material.diffuse = color(223, 196, 152)
    globe.material.opacity = 0.2
    globe.material.roughness = 0.7
    globe.material.roughnessMap = readImage(asset.builtin.Surfaces.Desert_Cliff_Roughness)
    globe.material.offsetRepeat = vec4(0,0,2,2)
    globe.scale = vec3(1,1,1) * radius -- Adjust the size of the globe
    globeRB = globe:add(craft.rigidbody, DYNAMIC, 0)
    globeRB.group = GROUP_GLOBE
    globeRB.mask = MASK_GLOBE
    
    globe:add(craft.shape.sphere, 1)
    --set up a fill light
    fillLight = scene:entity()
    fillLight.rotation = quat.eulerAngles(146, 100, 46)  -- Adjust the angles to point the light where the shadows are
    local fillLightComponent = fillLight:add(craft.light, DIRECTIONAL)
    fillLightComponent.distance = 100
    fillLightComponent.intensity = 0.7  -- Adjust the intensity as needed
    fillLightComponent.color = color(55, 150, 196)
    
    return globe
end

function makeSmallTestSphere(globe)
    smallSphere = scene:entity()
    smallSphere.d = {} --catch-all data table
    smallSphere.model = craft.model.icosphere(0.2) -- 0.2 is the radius, adjust as needed
    smallSphere.material = craft.material("Materials:Specular")
    smallSphere.material.map = readImage(asset.builtin.Blocks.Cotton_Red) -- You can replace this with any texture
    smallSphere.position = vec3(0, 0, -globe.scale.z)
    smallSphere.d.moving = false
    smallSphere.d.arcProgress = 0
    smallSphere.d.arcStep = 0.0125
    smallSphere.d.startPoint = vec3(0, 0, globe.scale.z)
    smallSphere.d.endPoint = vec3(0, globe.scale.y, 0)
end

function initializeViewer(globe)
    -- Initialize the OrbitViewer
    viewer = scene.camera:add(OrbitViewer, globe.position, 23, 6, 800)
end



function randomSurfacePointNear(locus, distance, globe)
    -- Generate a random direction vector
    local randomDirection = vec3(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5):normalize()
    
    -- Scale the direction vector by the desired distance
    local offset = randomDirection * distance
    
    -- Calculate the new point
    local newPoint = locus + offset
    
    -- Normalize the new point to the globe's surface
    local radius = globe.scale.x
    newPoint = newPoint:normalize() * radius
    
    return newPoint
end

function makeFoodSources(globe)
    -- Extract globe's properties
    local globeRadius = globe.scale.x -- Assuming the globe is uniformly scaled
    local globePosition = globe.position
    
    -- Define the number, size, and position of food sources
    local numFoodSources = 5
    local foodHeight = 0.1 -- height of the squashed sphere

    local foodSources = {}
    
    for i = 1, numFoodSources do
        local food = scene:entity()
        food.d = {} --catch-all data table
        food.model = craft.model(asset.builtin.Primitives.Sphere)
        food.material = craft.material(asset.builtin.Materials.Standard)
        food.material.map = readImage(asset.builtin.Blocks.Stone_Browniron_Alt) -- You can replace this with any texture
        food.material.diffuse = color(221, 0, 255)
        local foodRadius = globeRadius * (math.random(70, 150) * 0.001) -- size relative to the globe
        food.scale = vec3(foodRadius, foodHeight, foodRadius) -- squash the sphere

        
        -- Generate a random unit vector
        local randomDirection = vec3(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5):normalize()
        local foodPosition = globePosition + randomDirection * globeRadius
        
        food.position = foodPosition
        
        -- Calculate the orientation based on the direction vector
        local upVector = (foodPosition - globePosition):normalize()
        local defaultUp = vec3(0, 1, 0):normalize()
        upVector = upVector:normalize()
        
        local sinkAmount = food.scale.y -- Adjust as needed
        food.position = food.position - upVector * sinkAmount
        
        local dotProduct = defaultUp:dot(upVector)
        local angle = math.acos(dotProduct)
        
        local rotationAxis = defaultUp:cross(upVector):normalize()
        
        food.rotation = quat.angleAxis(math.deg(angle), rotationAxis)
        
        
        foodRB = food:add(craft.rigidbody, STATIC) -- static so it doesn't move
        foodRB.group = GROUP_FOOD
        foodRB.mask = MASK_FOOD
        foodRB.mass = 100
        food:add(craft.shape.sphere, foodRadius) -- collision shape
        food.d.info = {["typ"]=OBJ_FOOD, ["r"]=foodRadius, body=foodRB}

        table.insert(foodSources, food)
    end
    
    return foodSources
end

function makeObstacles(globe)
    -- Extract globe's properties
    local globeRadius = globe.scale.x -- Assuming the globe is uniformly scaled
    local globePosition = globe.position
    
    -- Define the number, size, and position of obstacles
    local numObstacles = 4
    local obstacleHeight = globeRadius * 0.2 -- height of the capsule
    local obstacleRadius = globeRadius * 0.38 -- size relative to the globe
    local obstacles = {}
    
    for i = 1, numObstacles do
        local obstacle = scene:entity()
        obstacle.d = {} --catch-all data table
        local obstacleHeight = globeRadius * (math.random(30, 90
        ) * 0.001) -- height of the capsule
        local obstacleRadius = globeRadius * (math.random(180, 310) * 0.001) -- size relative to the globe
        obstacle.model = craft.model(asset.builtin.Primitives.Capsule)
        obstacle.material = craft.material(asset.builtin.Materials.Standard)
        obstacle.material.map = readImage(asset.builtin.Blocks.Gravel_Dirt) -- You can replace this with any texture
        obstacle.material.offsetRepeat = vec4(0,0,1.5,2.5)
        obstacle.scale = vec3(obstacleRadius * 2, obstacleHeight, obstacleRadius * 2)
        --local uvs = generateNormalBasedUVs(obstacle.model.positions)
        --obstacle.model.uvs = uvs
        
        -- Generate a random unit vector
        local randomDirection = vec3(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5):normalize()
        local obstaclePosition = globePosition + randomDirection * globeRadius
        
        obstacle.position = obstaclePosition
        
        -- Calculate the orientation based on the direction vector
        local upVector = (obstaclePosition - globePosition):normalize()
        local defaultUp = vec3(0, 1, 0):normalize()
        upVector = upVector:normalize()
        
        local sinkAmount = obstacle.scale.y * 0.65 -- Adjust as needed
        obstacle.position = obstacle.position - upVector * sinkAmount
        
        local dotProduct = defaultUp:dot(upVector)
        local angle = math.acos(dotProduct)
        
        local rotationAxis = defaultUp:cross(upVector):normalize()
        
        obstacle.rotation = quat.angleAxis(math.deg(angle), rotationAxis)
        
        obstacleRB = obstacle:add(craft.rigidbody, STATIC) -- static so it doesn't move
        obstacleRB.friction = 0.01
        obstacleRB.mass = 100
        obstacleRB.group = GROUP_OBSTACLE
        obstacleRB.mask = MASK_OBSTACLE
        obstacle:add(craft.shape.capsule, obstacleRadius, obstacleHeight) -- collision shape
        obstacle.d.info = {["typ"]=OBJ_OBSTACLE, ["r"]=obstacleRadius, body=obstacleRB}
        --local obstacleColor = color(70, 52, 30, 255)
        --obstacle.material.diffuse = obstacleColor
        table.insert(obstacles, obstacle)
        --print(table.unpack(obstacle.model.normals))
    end
    
    return obstacles
end

function generateNormalBasedUVs(normals)
    local uvs = {}
    
    for i, normal in ipairs(normals) do
        local u = 0.5 + normal.x * 0.5
        local v = 0.5 + normal.z * 0.5
        
        table.insert(uvs, vec2(u, v))
    end
    
    return uvs
end

