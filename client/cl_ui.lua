local function KvpSet(key, value)
    SetResourceKvp(key, json.encode(value))
end

local function KvpGet(key)
    local str = GetResourceKvpString(key)
    if not str or str == "" then
        return {}
    end
    return json.decode(str)
end


RegisterCommand("synchronisedScenes", function(_, args)
    local favs = KvpGet("synchedScenesFav")
    SendNUIMessage({
        source = "synched_scenes_devtool",
        open = true,
        favs = favs,
        current = SynchedScenes.currentScene

    })
    SetNuiFocus(true, true)
end)

RegisterNuiCallback("sync_scenes:getSynchedScenes", function(_, cb)
    local scenes = SynchedScenes.scenes
    cb({ data = scenes })
end)

RegisterNUICallback("sync_scenes:startSynchedScene", function(data, cb)
    StopSynchronisedScene()
    local sceneId = tonumber(data.id) or 1
    local scenes = SynchedScenes.scenes
    if not scenes[sceneId] then
        cb({ ok = false, message = "Scene not found" })
        return
    end
    SynchedScenes.currentScene = scenes[sceneId].name
    StartSyncScene(scenes[sceneId], function(animDur)
        local scene = {
            name = scenes[sceneId].name,
            animDur = animDur,
            actors = #scenes[sceneId].actors,
            objects = #scenes[sceneId].objects
        }
        cb({ ok = true, scene = scene, currentScene = currentScene })
    end)
end)

RegisterNUICallback("sync_scenes:stopSynchedScene", function(data, cb)
    StopSynchronisedScene()
    cb({ ok = true })
end)

RegisterNUICallback("sync_scenes:SynchedScenes:toggleFav", function(data, cb)
    if not data.favs then
        cb({ ok = false, message = "Favs not passed" })
        return
    end
    KvpSet("synchedScenesFav", data.favs)
    cb({ ok = true })
end)

RegisterNUICallback("sync_scenes:closeMenu", function(data, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)
