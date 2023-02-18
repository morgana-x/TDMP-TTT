 maps = {}

 maps["lee_sandbox"] = {
    pickups = {
        {Vec(-2.67, 1.59, -55.45), "tdmp_gun"},
        {Vec(1.52, 2.624, -53.993), "tdmp_shotgun"},
        {Vec(20.345,5.3486, -54.074), "tdmp_shotgun"},
        {Vec(11.761, 1.04, 9,26), "tdmp_rifle"}
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


function GetLevelId()
    return GetString("game.levelid")
end

function MapGetPickups()
    local id = GetLevelId()
    if maps[id] then
        return maps[id].pickups
    end
    return {}
end