--
-- Multiplayer event: remove a split shape (tree / stump) on the server.
--
TreeBrushDeleteEvent = {}
local TreeBrushDeleteEvent_mt = Class(TreeBrushDeleteEvent, Event)

InitEventClass(TreeBrushDeleteEvent, 'TreeBrushDeleteEvent')

function TreeBrushDeleteEvent.emptyNew()
    local self = Event.new(TreeBrushDeleteEvent_mt)
    return self
end

function TreeBrushDeleteEvent.new(splitShapeId)
    local self = TreeBrushDeleteEvent.emptyNew()
    self.splitShapeId = splitShapeId
    return self
end

function TreeBrushDeleteEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        local splitShapeId = readSplitShapeIdFromStream(streamId)
        if splitShapeId ~= 0 then
            TreeBrush.deleteSplitShape(splitShapeId, true)
        end
    end
end

function TreeBrushDeleteEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        writeSplitShapeIdToStream(streamId, self.splitShapeId)
    end
end

function TreeBrushDeleteEvent.sendEvent(splitShapeId)
    if g_server == nil then
        g_client:getServerConnection():sendEvent(TreeBrushDeleteEvent.new(splitShapeId))
    end
end
