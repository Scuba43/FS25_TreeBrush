--
-- Tree Brush for Farming Simulator 25
-- Brush function to remove large numbers of trees and stumps,
-- designed for use in build mode (construction mode).
--
TreeBrush = {}
TreeBrush.name = g_currentModName
TreeBrush.path = g_currentModDirectory

TreeBrush.enabled = false
TreeBrush.applyState = 0
TreeBrush.applyCooldown = 0
TreeBrush.applyInterval = 200

TreeBrush.minRadius = 2
TreeBrush.maxRadius = 30
TreeBrush.radius = 8

TreeBrush.center = nil
TreeBrush.candidates = {}
TreeBrush.actionEventIds = {}
TreeBrush.registered = false
TreeBrush.registerTries = 0
TreeBrush.maxRegisterTries = 600

source(g_currentModDirectory .. 'events/TreeBrushDeleteEvent.lua')

addModEventListener(TreeBrush)

if PlayerInputComponent ~= nil and TreeBrush.hooksInstalled ~= true then
    TreeBrush.hooksInstalled = true

    PlayerInputComponent.registerActionEvents = Utils.appendedFunction(PlayerInputComponent.registerActionEvents,
        function(...)
            return TreeBrush.onRegisterActionEvents(...)
        end)

    PlayerInputComponent.unregisterActionEvents = Utils.appendedFunction(PlayerInputComponent.unregisterActionEvents,
        function(...)
            return TreeBrush.onUnregisterActionEvents(...)
        end)
end

function TreeBrush:loadMap(name)
    if g_server ~= nil then
        addConsoleCommand('treeBrushRadius', 'Set tree brush radius in meters (2-30)', 'consoleSetRadius', TreeBrush)
    end
end

function TreeBrush:deleteMap()
    TreeBrush:unregisterActionEvents()
    TreeBrush.enabled = false
    TreeBrush.applyState = 0
end

function TreeBrush.onRegisterActionEvents(inputComponent)
    if inputComponent.player ~= nil and inputComponent.player.isOwner then
        TreeBrush:registerActionEvents()
    end
end

function TreeBrush.onUnregisterActionEvents(inputComponent)
    if inputComponent.player ~= nil and inputComponent.player.isOwner then
        TreeBrush:unregisterActionEvents()
    end
end

function TreeBrush:unregisterActionEvents()
    if not TreeBrush.registered then
        return
    end
    g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)
    g_inputBinding:removeActionEventsByTarget(TreeBrush)
    g_inputBinding:endActionEventsModification()
    TreeBrush.actionEventIds = {}
    TreeBrush.registered = false
end

function TreeBrush:registerActionEvents()
    TreeBrush:unregisterActionEvents()

    local ids = {}

    g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)

    local successToggle, toggleId = g_inputBinding:registerActionEvent('TREEBRUSH_TOGGLE', TreeBrush, TreeBrush.actionToggle, false, true, false, true)
    ids.toggle = successToggle and toggleId or nil

    local successApply, applyId = g_inputBinding:registerActionEvent('TREEBRUSH_APPLY', TreeBrush, TreeBrush.actionApply, true, true, false, true)
    ids.apply = successApply and applyId or nil

    local successRadiusUp, radiusUpId = g_inputBinding:registerActionEvent('TREEBRUSH_RADIUS_UP', TreeBrush, TreeBrush.actionRadiusUp, false, true, false, true)
    ids.radiusUp = successRadiusUp and radiusUpId or nil

    local successRadiusDown, radiusDownId = g_inputBinding:registerActionEvent('TREEBRUSH_RADIUS_DOWN', TreeBrush, TreeBrush.actionRadiusDown, false, true, false, true)
    ids.radiusDown = successRadiusDown and radiusDownId or nil

    g_inputBinding:endActionEventsModification()

    local allRegistered = successToggle and successApply and successRadiusUp and successRadiusDown
    if not allRegistered then
        print(string.format('[TreeBrush] Action event registration incomplete (toggle=%s, apply=%s, radiusUp=%s, radiusDown=%s)', tostring(successToggle), tostring(successApply), tostring(successRadiusUp), tostring(successRadiusDown)))
        return false
    end

    TreeBrush.actionEventIds = ids

    g_inputBinding:setActionEventTextPriority(ids.toggle, GS_PRIO_NORMAL)
    g_inputBinding:setActionEventText(ids.toggle, g_i18n:getText('input_TREEBRUSH_TOGGLE'))
    g_inputBinding:setActionEventTextVisibility(ids.toggle, true)

    g_inputBinding:setActionEventTextPriority(ids.apply, GS_PRIO_HIGH)
    g_inputBinding:setActionEventText(ids.apply, g_i18n:getText('input_TREEBRUSH_APPLY'))
    g_inputBinding:setActionEventTextVisibility(ids.apply, true)

    g_inputBinding:setActionEventText(ids.radiusUp, g_i18n:getText('input_TREEBRUSH_RADIUS_UP'))
    g_inputBinding:setActionEventText(ids.radiusDown, g_i18n:getText('input_TREEBRUSH_RADIUS_DOWN'))

    TreeBrush.registered = true
    TreeBrush:updateActionEventStates()
    print('[TreeBrush] Action events registered')
    return true
end

function TreeBrush:updateActionEventStates()
    local ids = TreeBrush.actionEventIds
    if ids == nil then
        return
    end
    g_inputBinding:setActionEventActive(ids.apply, TreeBrush.enabled)
    g_inputBinding:setActionEventActive(ids.radiusUp, TreeBrush.enabled)
    g_inputBinding:setActionEventActive(ids.radiusDown, TreeBrush.enabled)
end

function TreeBrush:actionToggle(actionName, state)
    TreeBrush.enabled = not TreeBrush.enabled

    if not TreeBrush.enabled then
        TreeBrush.applyState = 0
    end

    TreeBrush:updateActionEventStates()
    g_currentMission:addExtraPrintText(string.format(g_i18n:getText(TreeBrush.enabled and 'treeBrush_enabled' or 'treeBrush_disabled'), TreeBrush.radius))
end

function TreeBrush:actionApply(actionName, state)
    if not TreeBrush.enabled then
        return
    end
    TreeBrush.applyState = (state == 1) and 1 or 0
end

function TreeBrush:actionRadiusUp(actionName, state)
    TreeBrush:setRadius(TreeBrush.radius + 1)
end

function TreeBrush:actionRadiusDown(actionName, state)
    TreeBrush:setRadius(TreeBrush.radius - 1)
end

function TreeBrush:setRadius(radius)
    TreeBrush.radius = math.max(TreeBrush.minRadius, math.min(TreeBrush.maxRadius, radius))
    if TreeBrush.enabled then
        g_currentMission:addExtraPrintText(string.format(g_i18n:getText('treeBrush_radiusSet'), TreeBrush.radius))
    end
end

function TreeBrush:consoleSetRadius(radius)
    radius = tonumber(radius)
    if radius == nil then
        return 'treeBrushRadius <' .. TreeBrush.minRadius .. '-' .. TreeBrush.maxRadius .. '>'
    end
    TreeBrush:setRadius(math.floor(radius))
    return 'treeBrushRadius = ' .. TreeBrush.radius
end

function TreeBrush.isInputAllowed()
    if g_gui ~= nil and g_gui:getIsGuiVisible() then
        local screen = g_gui.currentScreen
        local className = screen ~= nil and screen.className or nil
        return className ~= nil and string.find(className:lower(), 'construction') ~= nil
    end
    return true
end

function TreeBrush.getMousePosition()
    local mx, my = 0.5, 0.5
    local inputBinding = g_inputBinding
    if inputBinding ~= nil and inputBinding.mousePosXLast ~= nil and inputBinding.mousePosYLast ~= nil then
        mx, my = inputBinding.mousePosXLast, inputBinding.mousePosYLast
        if mx > 1 or my > 1 then
            mx = mx / math.max(g_screenWidth or 1, 1)
            my = my / math.max(g_screenHeight or 1, 1)
        end
    end
    return mx, my
end

function TreeBrush:update(dt)
    if not TreeBrush.registered then
        if g_currentMission ~= nil and g_localPlayer ~= nil and TreeBrush.registerTries < TreeBrush.maxRegisterTries then
            TreeBrush.registerTries = TreeBrush.registerTries + 1
            TreeBrush:registerActionEvents()
        end
        if not TreeBrush.registered then
            return
        end
    end

    if not TreeBrush.enabled then
        TreeBrush.center = nil
        return
    end

    local mission = g_currentMission
    if mission == nil or g_localPlayer == nil or mission.paused then
        return
    end

    if not TreeBrush.isInputAllowed() then
        TreeBrush.center = nil
        return
    end

    TreeBrush:updateBrushCenter()

    if TreeBrush.center ~= nil then
        TreeBrush:drawBrush()
    end

    if TreeBrush.applyState == 1 and TreeBrush.center ~= nil then
        TreeBrush.applyCooldown = TreeBrush.applyCooldown - dt
        if TreeBrush.applyCooldown <= 0 then
            TreeBrush.applyCooldown = TreeBrush.applyInterval
            TreeBrush:applyBrush(TreeBrush.center[1], TreeBrush.center[2], TreeBrush.center[3])
        end
    else
        TreeBrush.applyCooldown = 0
    end
end

function TreeBrush:updateBrushCenter()
    TreeBrush.center = nil

    local cameraNode = g_localPlayer:getCurrentCameraNode()
    if cameraNode == nil or cameraNode == 0 then
        return
    end

    local mx, my = TreeBrush.getMousePosition()
    local cx, cy, cz = getWorldTranslation(cameraNode)
    local px, py, pz = unProject(mx, my, 1)

    local dx, dy, dz = px - cx, py - cy, pz - cz
    dx, dy, dz = MathUtil.vector3Normalize(dx, dy, dz)
    if dx == nil then
        return
    end

    raycastClosest(cx, cy, cz, dx, dy, dz, 1500, 'brushRaycastCallback', TreeBrush, CollisionFlag.TERRAIN)
end

function TreeBrush:brushRaycastCallback(hitObjectId, x, y, z, distance)
    if hitObjectId ~= nil and hitObjectId ~= 0 then
        TreeBrush.center = {x, y, z}
    end
end

function TreeBrush:drawBrush()
    local c = TreeBrush.center
    if c == nil then
        return
    end

    local terrainRootNode = g_currentMission.terrainRootNode
    local segments = 32
    local prevX, prevY, prevZ = nil, nil, nil

    for i = 0, segments do
        local angle = (i % segments) / segments * 2 * math.pi
        local x = c[1] + math.sin(angle) * TreeBrush.radius
        local z = c[3] + math.cos(angle) * TreeBrush.radius
        local y = getTerrainHeightAtWorldPos(terrainRootNode, x, c[2], z) + 0.3

        if prevX ~= nil then
            drawDebugLine(prevX, prevY, prevZ, 1, 0.2, 0.2, x, y, z, 1, 0.2, 0.2)
        end

        prevX, prevY, prevZ = x, y, z
    end

    drawDebugLine(c[1], c[2], c[3], 1, 1, 1, c[1], c[2] + 5, c[3], 1, 1, 1)
end

function TreeBrush:applyBrush(x, y, z)
    if not g_currentMission:getHasPlayerPermission('cutTrees') then
        g_currentMission:addExtraPrintText(g_i18n:getText('treeBrush_noPermission'))
        return
    end

    TreeBrush.candidates = {}
    overlapBox(x, y + 10, z, 0, 0, 0, TreeBrush.radius * 2, 20, TreeBrush.radius * 2, 'brushOverlapCallback', TreeBrush, CollisionFlag.TREE)

    local removed = 0
    for shapeId in pairs(TreeBrush.candidates) do
        if TreeBrush.deleteSplitShape(shapeId) then
            removed = removed + 1
        end
    end

    if removed > 0 then
        g_currentMission:addExtraPrintText(string.format(g_i18n:getText('treeBrush_removed'), removed))
    end
end

function TreeBrush:brushOverlapCallback(hitObjectId, x, y, z, distance)
    if hitObjectId ~= nil and hitObjectId ~= 0 then
        TreeBrush.candidates[hitObjectId] = true
    end
end

function TreeBrush.deleteSplitShape(shapeId, noEventSend)
    if shapeId == nil or shapeId == 0 or not entityExists(shapeId) then
        return false
    end

    if not getHasClassId(shapeId, ClassIds.MESH_SPLIT_SHAPE) then
        return false
    end

    if getSplitType(shapeId) == 0 then
        return false
    end

    if getRigidBodyType(shapeId) ~= RigidBodyType.STATIC then
        return false
    end

    if not noEventSend and g_server == nil then
        TreeBrushDeleteEvent.sendEvent(shapeId)
        return true
    end

    local treePlantManager = nil
    if g_currentMission ~= nil then
        treePlantManager = g_currentMission.treePlantManager
    end
    if treePlantManager == nil and g_treePlantManager ~= nil then
        treePlantManager = g_treePlantManager
    end

    if treePlantManager ~= nil and treePlantManager.removingSplitShape ~= nil then
        pcall(function()
            treePlantManager:removingSplitShape(shapeId)
        end)
    end

    delete(shapeId)
    return true
end
