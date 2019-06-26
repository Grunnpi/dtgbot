-----------------------------------------------------------------------------
-- MIME support for the Lua language.
-- Author: Diego Nehab
-- Conforming to RFCs 2045-2049
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module and import dependencies
-----------------------------------------------------------------------------
local base = _G

local _M = _G

-- high level stuffing filter
function _M.unb64(blob)
    return blob
end

return _M