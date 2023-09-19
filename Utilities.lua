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
