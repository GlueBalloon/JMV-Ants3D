viewer.mode = STANDARD

-- Define collision groups
GROUP_PLANET = 1<<0
GROUP_SMALL_SPHERE_A = 1<<1
GROUP_SMALL_SPHERE_B = 1<<2

smallSpheres = {} -- List to store all small spheres

function setup()
    -- Set up the 3D scene
    scene = craft.scene()
    
    -- Create the planet (large sphere)
    planet = scene:entity()
    planet.position = vec3(0, 0, 0)
    planet.model = craft.model.icosphere(4.25, 3)
    planet.material = craft.material(asset.builtin.Materials.Standard)
    planet.material.diffuse = color(100, 100, 100)
    
    scene.camera:add(OrbitViewer, planet.position, 23, 6, 800)
    
    -- Place smaller spheres on the planet's surface
    for i = 1, 3 do
        placeSmallSphere(GROUP_SMALL_SPHERE_A, color(255, 0, 0))
        placeSmallSphere(GROUP_SMALL_SPHERE_B, color(0, 0, 255))
    end
end

function placeSmallSphere(group, col)
    local placed = false
    while not placed do
        -- Generate a random unit vector for position
        local randomDirection = vec3(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5):normalize()
        local position = planet.position + randomDirection * 4
        
        -- Brute-force check for collisions with previously placed spheres
        local collisionDetected = false
        for _, s in ipairs(smallSpheres) do
            local dist = position:dist(s.position)
            if dist < 2 then -- 2 is the sum of the radii of the two spheres
                collisionDetected = true
                print("Collision detected!")
                break
            end
        end
        
        if not collisionDetected then
            local smallSphere = scene:entity()
            smallSphere.position = position
            smallSphere.model = craft.model.icosphere(2, 3)
            smallSphere.material = craft.material(asset.builtin.Materials.Standard)
            smallSphere.material.diffuse = col
            local rbSmall = smallSphere:add(craft.rigidbody, STATIC)
            smallSphere:add(craft.shape.sphere, 2)
            rbSmall.group = group
            table.insert(smallSpheres, smallSphere)
            placed = true
        end
    end
end

function draw()
    scene:update(DeltaTime)
    scene:draw()
end

function touched(t)
    touches.touched(t)
end

