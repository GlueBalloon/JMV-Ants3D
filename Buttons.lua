Buttons = class()
-- copyright JMV38 2013 - all rights reserved


function Buttons:init()
    -- all the buttons
    local side = "right"  -- "right" or "left"
    local w0 = 60
    local b = {}
    self.b = b
    local N = 11
    local but
    
    -- show pheromons
    but = Button(2,N,side,w0) 
    b[1] = but
    but.enabled = true
    but.onclick = function() pheromonVisible = not pheromonVisible end
    but.txt = "pheros"
    
    -- show ant design
    but = Button(3,N,side,w0) 
    b[2] = but
    but.enabled = false
    but.onclick = function() 
        antDesignMode = not antDesignMode
        antRunningMode = not antRunningMode
        if antDesignMode then 
            self.b["antDesignStep"].txt = tostring(antDesignStep) 
            self.b["antDesignStep"].enabled = true
            physics.pause()
        else
            self.b["antDesignStep"].enabled = false
            physics.resume()
        end
    end
    but.txt = "design"
    
    -- not a button, just to show the current design step
    but = Button(4,N,side,w0) 
    b[3] = but
    but.enabled = false
    local changeStep = function(d)  
        antDesignStep = antDesignStep + d
        if antDesignStep > #redAnts.coords then antDesignStep = 1 end
        if antDesignStep < 1 then antDesignStep = #redAnts.coords end
        self.b["antDesignStep"].txt = "-    "..tostring(antDesignStep).."   +"
    end
    but.onRclick = function() changeStep(1)  end
    but.onLclick = function() changeStep(-1)  end
    but.txt = "data"
    b["antDesignStep"] = but
    
    -- settings
    but = Button(1,N,side,w0) 
    b[4] = but
    but.enabled = true
    self.settings = false
    but.onclick = function() 
        self.settings = not self.settings 
        b[2].enabled = self.settings
        b[3].enabled = false
        antDesignMode = false
        antRunningMode = true
    end
    but.txt = "settings"
    
end

function Buttons:draw()
    pushStyle() pushMatrix()
    resetMatrix() resetStyle()
    for i,b in ipairs(self.b) do b:draw() end
    popStyle() popMatrix()
end

function Buttons:touched(touch)
    for i,b in ipairs(self.b) do b:touched(touch) end
end

