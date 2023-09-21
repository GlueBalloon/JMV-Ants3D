function randomPlus(min, max)
    if min % 1 == 0 and max % 1 == 0 then
        -- Both min and max are integers
        return math.random(min, max)
    else
        -- At least one of min or max is a decimal
        local offset = (max - min) * math.random()
        return min + offset
    end
end

-- Function to rotate a vector by a quaternion
function rotateVectorByQuat(vec, quat)
    local qvec = vec3(quat.x, quat.y, quat.z)
    local uv = qvec:cross(vec)
    local uuv = qvec:cross(uv)
    uv = uv * (2.0 * quat.w)
    uuv = uuv * 2.0
    return vec + uv + uuv
end


