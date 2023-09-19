viewer.mode = OVERLAY

local placedSpheres = {} -- List to store placed spheres

function setup()
    -- Set up the 3D scene
    scene = craft.scene()
    
    -- Create the planet (large sphere)
    planet = scene:entity()
    planet.position = vec3(0, 0, 0)
    planet.model = craft.model.icosphere(4.25, 3)
    planet.material = craft.material(asset.builtin.Materials.Standard)
    planet.material.diffuse = color(100, 100, 100)
    planet.scale = vec3(1, 1, 1)
    
    scene.camera:add(OrbitViewer, planet.position, 23, 6, 800)
    
    -- Place smaller spheres on the planet's surface
    for i = 1, 7 do
        placeSmallSphere()
    end
end

function placeSmallSphere()
    local placed = false
    local attempts = 0
    while not placed and attempts < 100 do
        attempts = attempts + 1
        -- Generate a random unit vector for position
        local randomDirection = vec3(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5):normalize()
        local position = planet.position + randomDirection * 4
        
        local smallSphere = scene:entity()
        smallSphere.position = position
        smallSphere.model = craft.model(asset.builtin.Primitives.Sphere)
        smallSphere.material = craft.material(asset.builtin.Materials.Standard)
        smallSphere.material.diffuse = color(math.random(255), math.random(255), math.random(255))
        smallSphere.scale = vec3(1, 1, 1) * 1.5
        
        local intersects = false
        for _, existingSphere in ipairs(placedSpheres) do
            if absoluteBoundsIntersect(smallSphere, existingSphere) then
                intersects = true
                break
            end
        end
        
        if not intersects then
            table.insert(placedSpheres, smallSphere)
            placed = true
        else
            print("could not place spehere after 100 tries, deleting "..tostring(smallSphere))
            smallSphere:destroy()
        end
    end
end

function draw()
    scene:update(DeltaTime)
    scene:draw()
    drawAbsoluteBounds(planet)
    drawAbsoluteBounds(placedSpheres[1])
end
