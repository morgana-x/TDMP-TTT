 maps = {}

 maps["lee_sandbox"] = {
    pickups = {
        {Vec(-2.67, 1.59, -55.45), "tdmp_gun"},
        {Vec(1.52, 2.624, -53.993), "tdmp_shotgun"},
        {Vec(20.345,5.3486, -54.074), "tdmp_shotgun"},
        {Vec(11.761, 1.04, 9,26), "tdmp_rifle"},
        {Vec(3.23, 2.88, -31.125), "tdmp_gun"},
        {Vec(35.372, 7.0949, -5.595), "tdmp_rocket"},
        {Vec(-30.856, 7.0925, -37.111), "tdmp_rifle"},
        {Vec(-37.115, 1.6965, -66.912), "tdmp_gun"}
    }
 }

maps["mansion_sandbox"] = {
    pickups = {
        {Vec(56.7, 9.09, -16.182), "tdmp_gun"},
        {Vec(64.979, 9.295, -24.188), "tdmp_gun"},
        {Vec(26.493, 8.3963, -39.648), "tdmp_shotgun"},
        {Vec(26.55, 9.7859, 26.232), "tdmp_rifle"},
        {Vec(53.9, 22.593, -26.829), "tdmp_rifle"},
        {Vec(-19.039, 8.797, -25.853), "tdmp_rocket"}
    }
}



moddedmaps = {}


moddedmaps["Minecraft Modern Town"] = { -- https://steamcommunity.com/sharedfiles/filedetails/?id=2691792518
    pickups = {
        {Vec(17.938, 13.799, -32.741), "tdmp_gun"},
        {Vec(25.852, 20.296, 6.38337), "tdmp_gun"},
        {Vec(30.751, 14.597, 14.189), "tdmp_shotgun"},
        {Vec(-35.685, 20.297, 0.07217), "tdmp_rifle"},
        {Vec(-35.313, 33.095, 20.893), "tdmp_rifle"},
        {Vec(0.29841, 14.59, -37.004), "tdmp_shotgun"},
        {Vec(0.05, 22.299, -23.39), "tdmp_shotgun"},
        {Vec(-5.89, 51.396, -29.45), "tdmp_rifle"}
    }
}

moddedmaps["Small Minecraft Castle"] = { -- https://steamcommunity.com/sharedfiles/filedetails/?id=2420362691
    pickups = {
        {Vec(-5.61, 9.6978, 1.1413), "tdmp_gun"},
        {Vec(-23.858, 14.4, 19.46), "tdmp_shotgun"},
        {Vec(-20.689, 20.795, 25.519), "tdmp_rifle"},
        {Vec(-4.5, 14.4, 10.212), "tdmp_rifle"},
        {Vec(-3.75, 15.299, 2.225), "tdmp_gun"},
        {Vec(16.083, 7.995, -13.482), "tdmp_shotgun"},
        {Vec(20.15, 7.995, -21.329), "tdmp_gun"},
        {Vec(-3.182, 14.398, -18.436), "tdmp_gun"},
        {Vec(-10.301, 7.995, 14.697), "tdmp_gun"},
        {Vec(-23.875, 7.9953, -14.691), "tdmp_gun"},
        {Vec(-38.036, 6.395, 38.098), "tdmp_rifle"},
        {Vec(18.498, 7.995, 8.9876), "tdmp_gun"},
        {Vec(15.527, 7.995, 25.396), "tdmp_shotgun"},
        {Vec(-13.821, 7.997, -1.0758), "tdmp_shotgun"}
    }
}
local pref = true
function GetLevelId()
   -- DebugPrint(GetString("game.mod.title"))
    return (pref and GetString("game.levelid")) or GetString("game.mod.title")
end

function MapGetPickups()
    local id = GetLevelId()

    if maps[id] then
        return maps[id].pickups
    elseif moddedmaps[GetString("game.mod.title")] then
        pref = false
        return moddedmaps[GetString("game.mod.title")].pickups
    end
    return {}
end