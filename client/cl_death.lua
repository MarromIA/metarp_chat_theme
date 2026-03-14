-- ============================================================================
-- METARP CHAT - DEATH STATE CALLBACK (CLIENT)
-- ============================================================================
-- Version: 1.0.0
-- Description: Reports player death state to the server via ox_lib callback
-- Features:
--   - Checks osp_ambulance export if available (preferred)
--   - Falls back to native ped death checks
-- ============================================================================

-- ============================================================================
-- MARK: CALLBACK: IS DEAD
-- ============================================================================

--- Return whether the local player is currently dead or in last-stand.
--- Called by sv_utils.lua IsPlayerDead when framework metadata is inconclusive.
lib.callback.register('metarp_chat:client:isDead', function()
    -- Prefer osp_ambulance if running — it tracks last-stand state accurately
    if GetResourceState('osp_ambulance') == 'started' then
        local ok, isDead = pcall(function()
            return exports['osp_ambulance']:isDead()
        end)

        if ok and isDead ~= nil then return isDead end
    end

    -- Fallback: native ped death checks
    local ped = PlayerPedId()

    if not ped or ped == 0 then return false end
    if IsEntityDead(ped) then return true end
    if IsPedDeadOrDying    and IsPedDeadOrDying(ped, true)  then return true end
    if IsPedFatallyInjured and IsPedFatallyInjured(ped)     then return true end

    return false
end)