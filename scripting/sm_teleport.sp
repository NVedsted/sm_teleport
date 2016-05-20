#include <sourcemod>
#include <adminmenu>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = {
	name 			= "Teleport Commands",
	description 	= "Allows admins to teleport players.",
	author 		= "zaCade & N1ckles",
	version 		= "1.1"
};

Handle g_hAdminMenu;
ConVar g_cvNoBlock;

int g_aiSendTargets[MAXPLAYERS+1];

public void OnPluginStart() {
	LoadTranslations("common.phrases");
	
	g_cvNoBlock = CreateConVar("sm_teleport_noblock", "0", "Does the server have noblock? [1 = Yes, 0 = No]", FCVAR_PROTECTED, true, 0.0, true, 1.0);

	RegAdminCmd("sm_bring", Command_Bring, ADMFLAG_SLAY, "Brings target to you");
	RegAdminCmd("sm_goto", Command_Goto, ADMFLAG_SLAY, "Teleports you to a target");
	RegAdminCmd("sm_send", Command_Send, ADMFLAG_SLAY, "Teleports one target to another");
	RegAdminCmd("sm_place", Command_Place, ADMFLAG_SLAY, "Teleports target at aim");
	
	if (LibraryExists("adminmenu")) {
		Handle topMenu = GetAdminTopMenu();
		
		if (topMenu != null) {
			OnAdminMenuReady(topMenu);
		}
	}
}

public void OnAdminMenuReady(Handle topMenu) {
	if (g_hAdminMenu != topMenu) {
		g_hAdminMenu = topMenu;
		
		TopMenuObject hPlayerCommandsCategory = FindTopMenuCategory(g_hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
		
		if (hPlayerCommandsCategory != INVALID_TOPMENUOBJECT) {
			AddToTopMenu(g_hAdminMenu, "sm_bring", TopMenuObject_Item, AdminMenu_Bring, hPlayerCommandsCategory, "sm_bring", ADMFLAG_SLAY);
			AddToTopMenu(g_hAdminMenu, "sm_goto", TopMenuObject_Item, AdminMenu_GoTo, hPlayerCommandsCategory, "sm_goto", ADMFLAG_SLAY);
			AddToTopMenu(g_hAdminMenu, "sm_send", TopMenuObject_Item, AdminMenu_Send, hPlayerCommandsCategory, "sm_send", ADMFLAG_SLAY);
			AddToTopMenu(g_hAdminMenu, "sm_place", TopMenuObject_Item, AdminMenu_Place, hPlayerCommandsCategory, "sm_place", ADMFLAG_SLAY);
		}
	}
}

public void AdminMenu_Bring(Handle topMenu, TopMenuAction action, TopMenuObject obj, int client, char[] buffer, int maxlength) {
	switch(action) {
		case(TopMenuAction_DisplayOption): {
			Format(buffer, maxlength, "Bring player");
		}
		case(TopMenuAction_SelectOption): {
			Displaymenu_Bring(client);
		}
	}
}

public void AdminMenu_GoTo(Handle topMenu, TopMenuAction action, TopMenuObject obj, int client, char[] buffer, int maxlength) {
	switch(action) {
		case(TopMenuAction_DisplayOption): {
			Format(buffer, maxlength, "Go to player");
		}
		case(TopMenuAction_SelectOption): {
			Displaymenu_Goto(client);
		}
	}
}

public void AdminMenu_Send(Handle topMenu, TopMenuAction action, TopMenuObject obj, int client, char[] buffer, int maxlength) {
	switch(action) {
		case(TopMenuAction_DisplayOption): {
			Format(buffer, maxlength, "Send player");
		}
		case(TopMenuAction_SelectOption): {
			Displaymenu_Send(client);
		}
	}
}

public void AdminMenu_Place(Handle topMenu, TopMenuAction action, TopMenuObject obj, int client, char[] buffer, int maxlength) {
	switch(action) {
		case(TopMenuAction_DisplayOption): {
			Format(buffer, maxlength, "Place player");
		}
		case(TopMenuAction_SelectOption): {
			Displaymenu_Place(client);
		}
	}
}

public void Displaymenu_Bring(int client) {
	Handle hMenu = CreateMenu(Commandmenu_Bring);
	SetMenuTitle(hMenu, "Bring player");
	SetMenuExitBackButton(hMenu, true);
	
	for (int player = 1; player <= MaxClients; ++player) {
		if (client != player && IsClientInGame(player) && IsClientConnected(player) && IsPlayerAlive(player)) {
			char buffer[128], name[128], userID[16];
			IntToString(GetClientUserId(player), userID, sizeof(userID));
			GetClientName(player, name, sizeof(name));
			Format(buffer, sizeof(buffer), "%s (%s)", name, userID);
			AddMenuItem(hMenu, userID, buffer);
		}
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public void Displaymenu_Goto(int client) {
	Handle hMenu = CreateMenu(Commandmenu_Goto);	
	SetMenuTitle(hMenu, "Goto player:");
	SetMenuExitBackButton(hMenu, true);
	
	for (int player = 1; player <= MaxClients; ++player) {
		if (client != player && IsClientInGame(player) && IsClientConnected(player) && IsPlayerAlive(player)) {
			char buffer[128], name[128], userID[16];
			IntToString(GetClientUserId(player), userID, sizeof(userID));
			GetClientName(player, name, sizeof(name));
			Format(buffer, sizeof(buffer), "%s (%s)", name, userID);
			AddMenuItem(hMenu, userID, buffer);
		}
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public void Displaymenu_Send(int client) {
	Handle hMenu = CreateMenu(Commandmenu_Send);
	SetMenuTitle(hMenu, "Send player:");
	SetMenuExitBackButton(hMenu, true);
	
	for (int Player = 1; Player <= MaxClients; Player++) {
		if (client != Player && IsClientInGame(Player) && IsClientConnected(Player) && IsPlayerAlive(Player)) {
			char Buffer[128], Name[128], UserID[16];
			IntToString(GetClientUserId(Player), UserID, sizeof(UserID));
			GetClientName(Player, Name, sizeof(Name));
			Format(Buffer, sizeof(Buffer), "%s (%s)", Name, UserID);
			AddMenuItem(hMenu, UserID, Buffer);
		}
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public void Displaymenu_SendTo(int Client) {
	Handle hMenu = CreateMenu(Commandmenu_SendTo);	
	SetMenuTitle(hMenu, "Send %N to:", g_aiSendTargets[Client]);
	SetMenuExitBackButton(hMenu, true);

	for (int Player = 1; Player <= MaxClients; Player++) {
		if (Client != Player && g_aiSendTargets[Client] != Player && IsClientInGame(Player) && IsClientConnected(Player) && IsPlayerAlive(Player)) {
			char Buffer[128], Name[128], UserID[16];
			IntToString(GetClientUserId(Player), UserID, sizeof(UserID));
			GetClientName(Player, Name, sizeof(Name));
			Format(Buffer, sizeof(Buffer), "%s (%s)", Name, UserID);
			AddMenuItem(hMenu, UserID, Buffer);
		}
	}
	
	DisplayMenu(hMenu, Client, MENU_TIME_FOREVER);
}

public void Displaymenu_Place(int client) {
	Handle hMenu = CreateMenu(Commandmenu_Place);
	SetMenuTitle(hMenu, "Place a player at your aim:");
	SetMenuExitBackButton(hMenu, true);
	
	for (int player = 1; player <= MaxClients; ++player) {
		if (client != player && IsClientInGame(player) && IsClientConnected(player) && IsPlayerAlive(player)) {
			char buffer[128], name[128], userID[16];
			IntToString(GetClientUserId(player), userID, sizeof(userID));
			GetClientName(player, name, sizeof(name));
			Format(buffer, sizeof(buffer), "%s (%s)", name, userID);
			AddMenuItem(hMenu, userID, buffer);
		}
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public int Commandmenu_Bring(Menu hMenu, MenuAction Selection, int Parameter1, int Parameter2) {
	switch(Selection) {
		case(MenuAction_End): {
			CloseHandle(hMenu);
		}
		case(MenuAction_Cancel): {
			DisplayTopMenu(g_hAdminMenu, Parameter1, TopMenuPosition_LastCategory);
		}
		case(MenuAction_Select): {
			char Info[64];
			GetMenuItem(hMenu, Parameter2, Info, sizeof(Info));
			int Target = GetClientOfUserId(StringToInt(Info));
			
			if (Target <= 0) {
				ReplyToCommand(Parameter1, "[SM] Unable to find target.");
			} else if (!CanUserTarget(Parameter1, Target)) {
				ReplyToCommand(Parameter1, "[SM] Unable to target.");
			} else if (!IsPlayerAlive(Target)) {
				ReplyToCommand(Parameter1, "[SM] Player no longer alive.");
			} else {
				PerformTeleport(Target, Parameter1);
				LogAction(Parameter1, -1, "\"%L\" teleported \"%L\" to himself.", Parameter1, Target);
				ShowActivity(Parameter1, "teleported %N to himself.", Target);
			}
		}
	}
}

public int Commandmenu_Goto(Menu hMenu, MenuAction Selection, int Parameter1, int Parameter2) {
	switch(Selection) {
		case(MenuAction_End): {
			CloseHandle(hMenu);
		}
		case(MenuAction_Cancel): {
			DisplayTopMenu(g_hAdminMenu, Parameter1, TopMenuPosition_LastCategory);
		}
		case(MenuAction_Select): {
			char Info[64];
			GetMenuItem(hMenu, Parameter2, Info, sizeof(Info));
			int Target = GetClientOfUserId(StringToInt(Info));
			
			if (Target <= 0) {
				ReplyToCommand(Parameter1, "[SM] Unable to find target.");
			} else if (!CanUserTarget(Parameter1, Target)) {
				ReplyToCommand(Parameter1, "[SM] Unable to target.");
			} else if (!IsPlayerAlive(Target)) {
				ReplyToCommand(Parameter1, "[SM] Player no longer alive.");
			} else {
				PerformTeleport(Parameter1, Target);
				LogAction(Parameter1, -1, "\"%L\" teleported to \"%L\".", Parameter1, Target);
				ShowActivity(Parameter1, "teleported to %N.", Target);
			}
		}
	}
}

public int Commandmenu_Send(Menu hMenu, MenuAction Selection, int Parameter1, int Parameter2) {
	switch(Selection) {
		case(MenuAction_End): {
			CloseHandle(hMenu);
		}
		case(MenuAction_Cancel): {
			DisplayTopMenu(g_hAdminMenu, Parameter1, TopMenuPosition_LastCategory);
		}
		case(MenuAction_Select): {
			char Info[64];
			GetMenuItem(hMenu, Parameter2, Info, sizeof(Info));
			int Target = GetClientOfUserId(StringToInt(Info));
			
			if (Target <= 0) {
				ReplyToCommand(Parameter1, "[SM] Unable to find target.");
			} else if (!CanUserTarget(Parameter1, Target)) {
				ReplyToCommand(Parameter1, "[SM] Unable to target.");
			} else if (!IsPlayerAlive(Target)) {
				ReplyToCommand(Parameter1, "[SM] Player no longer alive.");
			} else {
				g_aiSendTargets[Parameter1] = Target;
				Displaymenu_SendTo(Parameter1);
			}
		}
	}
}

public int Commandmenu_SendTo(Menu hMenu, MenuAction Selection, int Parameter1, int Parameter2) {
	switch(Selection) {
		case(MenuAction_End): {
			CloseHandle(hMenu);
		}
		case(MenuAction_Cancel): {
			DisplayTopMenu(g_hAdminMenu, Parameter1, TopMenuPosition_LastCategory);
		}
		case(MenuAction_Select): {
			char Info[64];
			GetMenuItem(hMenu, Parameter2, Info, sizeof(Info));
			int Target1 = g_aiSendTargets[Parameter1];
			int Target2 = GetClientOfUserId(StringToInt(Info));
			
			if (Target1 <= 0) {
				ReplyToCommand(Parameter1, "[SM] Unable to find target.");
			} else if (Target2 <= 0) {
				ReplyToCommand(Parameter1, "[SM] Unable to find target to teleport to.");
			} else if (!CanUserTarget(Parameter1, Target1)) {
				ReplyToCommand(Parameter1, "[SM] Unable to target.");
			} else if (!IsPlayerAlive(Target1)) {
				ReplyToCommand(Parameter1, "[SM] Player to teleport no longer alive.");
			} else if (!IsPlayerAlive(Target2)) {
				ReplyToCommand(Parameter1, "[SM] Player no longer alive.");
			} else {
				PerformTeleport(Target1, Target2);
				LogAction(Parameter1, -1, "\"%L\" teleported \"%L\"to \"%L\".", Parameter1, Target1, Target2);
				ShowActivity(Parameter1, "teleported %N to %N.", Target1, Target2);
			}
		}
	}
}

public Action Command_Bring(int Client, int ArgC) {
	if (ArgC <= 0) {
		ReplyToCommand(Client, "[SM] Usage: sm_bring <name>");
		return Plugin_Handled;
	}

	char Argument[64];
	GetCmdArg(1, Argument, sizeof(Argument));
	
	int targets[MAXPLAYERS];
	char targetName[MAX_NAME_LENGTH];
	bool targetNameML;
	int targetCount = ProcessTargetString(Argument, Client, targets, MAXPLAYERS, COMMAND_FILTER_ALIVE, targetName, MAX_NAME_LENGTH, targetNameML);
	if(targetCount < 1){
		ReplyToTargetError(Client, targetCount);
		return Plugin_Handled;
	}
	
	for(int i = 0; i < targetCount; ++i){
		PerformTeleport(targets[i], Client);
	}
	
	if(targetCount == 1){
		LogAction(Client, -1, "\"%L\" teleported \"%L\" to himself.", Client, targets[0]);
		ShowActivity(Client, "teleported %s to himself.", targetName);
	} else {
		if(targetNameML){
			LogAction(Client, -1, "\"%L\" teleported \"%t\" to himself.", Client, targetName);
			ShowActivity(Client, "teleported %t to himself.", targetName);
		}else{
			LogAction(Client, -1, "\"%L\" teleported \"%s\" to himself.", Client, targetName);
			ShowActivity(Client, "teleported %s to himself.", targetName);
		}
	}
	
	return Plugin_Handled;
}

public int Commandmenu_Place(Menu hMenu, MenuAction Selection, int Parameter1, int Parameter2) {
	switch(Selection) {
		case(MenuAction_End): {
			CloseHandle(hMenu);
		}
		case(MenuAction_Cancel): {
			DisplayTopMenu(g_hAdminMenu, Parameter1, TopMenuPosition_LastCategory);
		}
		case(MenuAction_Select): {
			char Info[64];
			GetMenuItem(hMenu, Parameter2, Info, sizeof(Info));
			int Target = GetClientOfUserId(StringToInt(Info));
			
			if (Target <= 0) {
				ReplyToCommand(Parameter1, "[SM] Unable to find target.");
			} else if (!CanUserTarget(Parameter1, Target)) {
				ReplyToCommand(Parameter1, "[SM] Unable to target.");
			} else if (!IsPlayerAlive(Target)) {
				ReplyToCommand(Parameter1, "[SM] Player no longer alive.");
			} else {
				PerformTeleportToAim(Parameter1, Target);
				LogAction(Parameter1, -1, "\"%L\" teleported \"%L\" to his aim.", Parameter1, Target);
				ShowActivity(Parameter1, "teleported %N to his aim.", Target);
			}
		}
	}
}

public Action Command_Place(int Client, int ArgC) {
	if (ArgC <= 0) {
		ReplyToCommand(Client, "[SM] Usage: sm_place <name>");
		return Plugin_Handled;
	}

	char Argument[64];
	GetCmdArg(1, Argument, sizeof(Argument));
	
	int targets[MAXPLAYERS];
	char targetName[MAX_NAME_LENGTH];
	bool targetNameML;
	int targetCount = ProcessTargetString(Argument, Client, targets, MAXPLAYERS, COMMAND_FILTER_ALIVE, targetName, MAX_NAME_LENGTH, targetNameML);
	if(targetCount < 1){
		ReplyToTargetError(Client, targetCount);
		return Plugin_Handled;
	}
	
	float dst[3];
	if(!GetAimDestination(Client, dst)){
		ReplyToCommand(Client, "[SM] Failed to get destination.");
		return Plugin_Handled;
	}
	
	for(int i = 0; i < targetCount; ++i){
		TeleportEntity(targets[i], dst, NULL_VECTOR, NULL_VECTOR);
		
		if (!GetConVarBool(g_cvNoBlock)) {
			Handle Datapack;
			CreateDataTimer(1.0, ResetSinglePlayerCollision, Datapack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(Datapack, targets[i]);
			WritePackCell(Datapack, GetEntProp(targets[i], Prop_Data, "m_CollisionGroup"));		
			SetEntProp(targets[i], Prop_Data, "m_CollisionGroup", 17);
		}
	}
	
	if(targetCount == 1){
		LogAction(Client, -1, "\"%L\" teleported \"%L\" to his aim.", Client, targets[0]);
		ShowActivity(Client, "teleported %s to his aim.", targetName);
	} else {
		if(targetNameML){
			LogAction(Client, -1, "\"%L\" teleported \"%t\" to his aim.", Client, targetName);
			ShowActivity(Client, "teleported %t to his aim.", targetName);
		}else{
			LogAction(Client, -1, "\"%L\" teleported \"%s\" to his aim.", Client, targetName);
			ShowActivity(Client, "teleported %s to his aim.", targetName);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Goto(int Client, int ArgC) {
	if (ArgC <= 0) {
		ReplyToCommand(Client, "[SM] Usage: sm_goto <target>");
		return Plugin_Handled;
	}
	
	char Argument[64];
	GetCmdArg(1, Argument, sizeof(Argument));
	
	int targets[1];
	char name[MAX_NAME_LENGTH];
	bool ml;
	int error = ProcessTargetString(Argument, Client, targets, 1, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_MULTI, name, MAX_NAME_LENGTH, ml);
	PrintToServer(name);
	if(error < 1){
		ReplyToTargetError(Client, error);
	}else{
		PerformTeleport(Client, targets[0]);
		LogAction(Client, -1, "\"%L\" teleported to \"%L\".", Client, targets[0]);
		ShowActivity(Client, "teleported to %N.", targets[0]);
	}
	
	return Plugin_Handled;
}

public Action Command_Send(int Client, int ArgC) {
	if (ArgC <= 0) {
		ReplyToCommand(Client, "[SM] Usage: sm_send <name of targets> <name of destination>");
		return Plugin_Handled;
	}
	char Argument1[64], Argument2[64];
	GetCmdArg(1, Argument1, sizeof(Argument1));
	GetCmdArg(2, Argument2, sizeof(Argument2));
	
	// Get victims
	int targets[MAXPLAYERS];
	char targetName[MAX_NAME_LENGTH];
	bool targetNameML;
	int targetCount = ProcessTargetString(Argument1, Client, targets, MAXPLAYERS, COMMAND_FILTER_ALIVE, targetName, MAX_NAME_LENGTH, targetNameML);
	if(targetCount < 1){
		ReplyToTargetError(Client, targetCount);
		return Plugin_Handled;
	}
	
	// Get destination
	int destinations[1];
	char destinationName[MAX_NAME_LENGTH];
	bool destinationNameML;
	int error = ProcessTargetString(Argument2, Client, destinations, 1, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_MULTI, destinationName, MAX_NAME_LENGTH, destinationNameML);
	if(error < 1){
		ReplyToTargetError(Client, error);
		return Plugin_Handled;
	}
	int destination = destinations[0];
	
	// Teleport'em
	for(int i = 0; i < targetCount; ++i){
		PerformTeleport(targets[i], destination);	
	}
	
	
	if(targetNameML){
		LogAction(Client, -1, "\"%L\" teleported \"%t\"to \"%L\".", Client, targetName, destination);
		ShowActivity(Client, "teleported %t to %N.", targetName, destination);
	}else{
		LogAction(Client, -1, "\"%L\" teleported \"%s\"to \"%L\".", Client, targetName, destination);
		ShowActivity(Client, "teleported %s to %N.", targetName, destination);
	}
	
	return Plugin_Handled;
}

public void PerformTeleport(int target, int destination) {
	float teleportDestination[3];	
	GetClientAbsOrigin(destination, teleportDestination);	
	
	teleportDestination[2] = teleportDestination[2] + 16;
	TeleportEntity(target, teleportDestination, NULL_VECTOR, NULL_VECTOR);
	
	if (!GetConVarBool(g_cvNoBlock)) {
		Handle Datapack;
		CreateDataTimer(1.0, ResetPlayerCollision, Datapack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(Datapack, destination);
		WritePackCell(Datapack, target);
		WritePackCell(Datapack, GetEntProp(destination, Prop_Data, "m_CollisionGroup"));
		WritePackCell(Datapack, GetEntProp(target, Prop_Data, "m_CollisionGroup"));
		
		SetEntProp(destination, Prop_Data, "m_CollisionGroup", 17);
		SetEntProp(target, Prop_Data, "m_CollisionGroup", 17);
	}
}

public Action ResetPlayerCollision(Handle timer, Handle Datapack) {
	ResetPack(Datapack);
	int Parameter1 = ReadPackCell(Datapack);
	int Parameter2 = ReadPackCell(Datapack);
	int Group1 = ReadPackCell(Datapack);
	int Group2 = ReadPackCell(Datapack);
	
	if (IsClientInGame(Parameter1) && IsClientConnected(Parameter1) && IsPlayerAlive(Parameter1)) {
		SetEntProp(Parameter1, Prop_Data, "m_CollisionGroup", Group1);
	}
	if (IsClientInGame(Parameter2) && IsClientConnected(Parameter2) && IsPlayerAlive(Parameter2)) {
		SetEntProp(Parameter2, Prop_Data, "m_CollisionGroup", Group2);
	}
}

public Action ResetSinglePlayerCollision(Handle timer, Handle Datapack) {
	ResetPack(Datapack);
	int Parameter1 = ReadPackCell(Datapack);
	int Group1 = ReadPackCell(Datapack);
	
	if (IsClientInGame(Parameter1) && IsClientConnected(Parameter1) && IsPlayerAlive(Parameter1)) {
		SetEntProp(Parameter1, Prop_Data, "m_CollisionGroup", Group1);
	}
}

public bool GetAimDestination(int client, float destination[3]){
	float vOrigin[3], vAngles[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	
	Handle TraceRay = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceRayFilter);
	
	if (TR_DidHit(TraceRay)) {
		TR_GetEndPosition(destination, TraceRay);
		
		destination[2] += 16;
		return true;
	}
	
	CloseHandle(TraceRay);
	return false;
}

public void TeleportClientToAim(int client) {
	PerformTeleportToAim(client, client);
}

public void PerformTeleportToAim(int aimer, int target) {
	float dst[3];
	if(GetAimDestination(aimer, dst)){
		TeleportEntity(target, dst, NULL_VECTOR, NULL_VECTOR);
	}
	
}

public bool TraceRayFilter(int Entity, int Content) {
	return Entity > MaxClients;
}