SynchedScenes = {
    scenes = {},
    currentScene = "",
}

local cache = {
    entities = {},
}

local randomPeds = {
    `a_m_y_genstreet_02`,
    `a_m_y_genstreet_02`,
    `a_m_y_genstreet_02`,
    `a_m_y_genstreet_02`
}

function GetScenesList()
    local loadFile = LoadResourceFile(GetCurrentResourceName(), "data/data.json")
    if not loadFile then
        print("Sync Scenes: data.json not found")
        return {}
    end
    local data = json.decode(loadFile)

    local _scenes = {}
    for k, scene in pairs(data) do
        local _scene = {
            id = k,
            name = scene.name,
            category = scene.category,
            deltaZ = scene.deltaZ,
            actors = scene.actors,
            objects = scene.objects
        }
        _scenes[k] = _scene
    end

    return _scenes
end

local function modelLoader(model)
    if not IsModelInCdimage(model) or not IsModelValid(model) then
        print("Sync Scenes: Model not found " .. model)
        return
    end
    if not HasModelLoaded(model) then
        RequestModel(model)
        Wait(100)
        while not HasModelLoaded(model) do
            Wait(10)
        end
    end
end

local function loadAnimDict(dict)
    if not DoesAnimDictExist(dict) then
        return
    end
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)

        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
    end
end

function StartSyncScene(data, cb)
    local ped = PlayerPedId()
    local px, py, pz = table.unpack(GetEntityCoords(ped))
    local rx, ry, rz = table.unpack(GetEntityRotation(ped))
    local fx, fy = px + GetEntityForwardX(ped), py + GetEntityForwardY(ped) * 3
    local _, z = GetGroundZFor_3dCoord(px, py + 0.2, pz, 0)

    for _, _actor in pairs(data.actors) do
        loadAnimDict(_actor.animDict)
    end

    for _, _object in pairs(data.objects) do
        modelLoader(GetHashKey(_object.model))
        loadAnimDict(_object.animDict)
    end


    local scene = NetworkCreateSynchronisedScene(fx, fy, pz + data.deltaZ, rx, ry, rz, 2, true, false, -1, 0, 1.0)

    for i = 1, (#data.actors) do
        local hash = randomPeds[i]
        if string.find(data.name, "with dog") then
            hash = `a_c_rottweiler`
        end
        modelLoader(hash)
        local actor = CreatePed(6, hash, px, py - 5, z, 0, true, true)
        cache.entities[#cache.entities + 1] = actor
        NetworkAddPedToSynchronisedScene(actor, scene, data.actors[i].animDict or "",
            data.actors[i].anim or "", 1.5,
            -4.0, 1, 16,
            1148846080, 0)
    end

    if #data.objects > 0 then
        local x = 0
        for _, _object in pairs(data.objects) do
            x += 0.3
            local object = nil
            if IsModelAVehicle(GetHashKey(_object.model)) then
                object = CreateVehicle(GetHashKey(_object.model), px + x, py, z, 0, true, true)
            else
                object = CreateObject(GetHashKey(_object.model), px + x, py, z, true, true, true)
            end
            cache.entities[#cache.entities + 1] = object
            NetworkAddEntityToSynchronisedScene(object, scene, _object.animDict or "", _object.anim or "", 1.0, 1.0, 1)
        end
    end

    NetworkStartSynchronisedScene(scene)
    local animDur = GetAnimDuration(data.actors[1].animDict, data.actors[1].anim) * 1000
    if cb and type(cb) == "function" then
        cb(animDur)
    end
    --- code bellow to wait for the scene to finish and then stop it, not recommended while testing scenes ---
    -- Wait(animDur)
    -- NetworkStopSynchronisedScene(scene)
    -- for _, _entity in ipairs(cache.entities) do
    --     DeleteEntity(_entity)
    -- end
end

function StopSynchronisedScene()
    NetworkStopSynchronisedScene(SynchedScenes.currentScene)
    for _, _entity in ipairs(cache.entities) do
        DeleteEntity(_entity)
    end
end

-- AddEventHandler("onResourceStart", function(resource)
--     if resource == GetCurrentResourceName() then
--         SynchedScenes.scenes = GetScenesList()
--         print("Sync Scenes: Loaded " .. #SynchedScenes.scenes .. " scenes")
--     end
-- end)

CreateThread(function()
    SynchedScenes.scenes = GetScenesList()
    print("Sync Scenes: Loaded " .. #SynchedScenes.scenes .. " scenes")
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for _, entity in ipairs(cache.entities) do
            DeleteEntity(entity)
        end
    end
end)
