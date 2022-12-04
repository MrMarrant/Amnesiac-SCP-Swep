hook.Add( "PostGamemodeLoaded", "AmnesiacSwepInitialize", function()

	if SERVER then
		AddCSLuaFile( "languages/language.lua" )
		include( "languages/language.lua" )
		AddCSLuaFile( "functions/amnesia_effect.lua" )
		include( "functions/amnesia_effect.lua" )
	end
end )