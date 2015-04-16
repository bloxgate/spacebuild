
TOOL.Category		= "Resource Distribution"
TOOL.Mode 			= "rd3_resdebug"
TOOL.Name			= "Resource Debugger"
TOOL.Command		= nil
TOOL.ConfigName		= nil
if (CLIENT and GetConVarNumber("CAF_UseTab") == 1) then TOOL.Tab = "Custom Addon Framework" end

if ( CLIENT ) then
	language.Add( "tool.rd3_resdebug.name",	"RD Resource Debugger" )
	language.Add( "tool.rd3_resdebug.desc",	"Spams the ent's resource table to the console, Left Click = serverside, Right click = Clientside" )
	language.Add( "tool.rd3_resdebugr.0", "Click an RD3 Ent" )
end

function dumpCAFOwnership(ent)
    CAFLog.Info('Ownership data:')
    CAFLog.Info('----------------')
    if ent.GetOwner then
        CAFLog.Info('GetOwner    : '..tostring(ent:GetOwner()))
    end
    if ent.GetPlayer then
        CAFLog.Info('GetPlayer   : '..tostring(ent:GetPlayer()))
    end
    if ent.GetCreator then
        CAFLog.Info('GetCreator  : '..tostring(ent:GetCreator()))
    end
    if ent.GetRD3Owner then
        CAFLog.Info('GetRD3Owner  : '..tostring(ent:GetRD3Owner()))
    end
    CAFLog.Info('CAF.GetOwner: '..tostring(CAF.GetOwner(ent)))
end

function TOOL:LeftClick( trace )
    if (CLIENT) then return true end
	if (not trace.Entity:IsValid() ) then
        MsgAll("Selected entity is invalid!")
        return false
    end
	CAF.GetAddon("Resource Distribution").PrintDebug(trace.Entity)
    dumpCAFOwnership(trace.Entity)
	return true
end

function TOOL:RightClick( trace )
	if (SERVER) then return true end
    if (not trace.Entity:IsValid() ) then
        MsgAll("Selected entity is invalid!")
        return false
    end
	CAF.GetAddon("Resource Distribution").PrintDebug(trace.Entity)
    dumpCAFOwnership(trace.Entity)
	return true
end

function TOOL:Reload( trace )
    if (CLIENT) then return true end
    if (not trace.Entity:IsValid() ) then
        MsgAll("Selected entity is invalid!")
        return false
    end
	--for something else
	return true
end
