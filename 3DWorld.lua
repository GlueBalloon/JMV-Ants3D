
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
    local globe3D = createWorld(globeRadius)
    initializeViewer(globe3D)
    foodSources = makeFoodSources(globe3D)
    obstacles = makeObstacles(globe3D)
    return globe3D
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
    smallSphere.d.arcStep = 0.01
    smallSphere.d.startPoint = vec3(0, 0, globe.scale.z)
    smallSphere.d.endPoint = vec3(0, globe.scale.y, 0)
end

function initializeViewer(globe)
    -- Initialize the OrbitViewer
    viewer = scene.camera:add(OrbitViewer, globe.position, 23, 6, 800)
end

function createWorld(radius)
    --[[
    parameter.integer("fillX",-180,180,45)
    parameter.integer("fillY",-180,180,45)
    parameter.integer("fillZ",-180,180,45)
    ]]
    -- Set up the 3D world
    scene = craft.scene()
    scene.sky.material.sky = color(72, 235, 215)       
    scene.sky.material.horizon = color(34, 30, 66)       
    scene.sky.material.ground = color(33, 70, 120)
    -- Create the globe (sphere)
    local globe = scene:entity()
    scene.physics.gravity = vec3(0,0,0)
    globe.model = craft.model(asset.builtin.Primitives.Sphere)
    globe.material = craft.material(asset.builtin.Materials.Standard)
    globe.material.map = readImage(asset.builtin.Blocks.Stone_Browniron_Alt) -- You can replace this with any texture
    globe.material.diffuse = color(0, 255, 117)
    globe.material.offsetRepeat = vec4(0,0,1.5,2.5)
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
        local uvs = generateNormalBasedUVs(obstacle.model.positions)
        obstacle.model.uvs = uvs
        
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

