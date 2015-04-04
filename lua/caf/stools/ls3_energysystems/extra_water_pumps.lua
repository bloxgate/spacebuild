DEVICEGROUP.type = "generator_liquid_water"

--[[
	You can also use skin = number here to define a skin to make the Module spawn with
	You can also use material = "path/to/material" to set a material to make it spawn with
]]

DEVICEGROUP.devices = {
    add_one = {
        Name = "CE Medium Water Pump",
        model = "models/ce_ls3additional/water_pump/water_pump.mdl",
        skin = 0
    },
    add_2 = {
        Name = "CS Large Water Pump",
        model = "models/chipstiks_ls3_models/largeh2opump/largeh2opump.mdl",
    },
    motor = {
        Name = "N3X15 - 3-Phase Motor",
        model = "models/n3x15/motor/electric_motor.mdl",
        material = "models/n3x15/motor/electric_motor", -- NO I DON'T KNOW WHY THE MDL DOESN'T SPECIFY THE FUCKING TEXTURE, STOP ASKING
    },
}

