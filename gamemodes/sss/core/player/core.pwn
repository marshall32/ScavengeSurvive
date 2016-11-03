/*==============================================================================


	Southclaw's Scavenge and Survive

		Copyright (C) 2016 Barnaby "Southclaw" Keene

		This program is free software: you can redistribute it and/or modify it
		under the terms of the GNU General Public License as published by the
		Free Software Foundation, either version 3 of the License, or (at your
		option) any later version.

		This program is distributed in the hope that it will be useful, but
		WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
		See the GNU General Public License for more details.

		You should have received a copy of the GNU General Public License along
		with this program.  If not, see <http://www.gnu.org/licenses/>.


==============================================================================*/


#include <YSI\y_hooks>


#define DEFAULT_POS_X				(10000.0)
#define DEFAULT_POS_Y				(10000.0)
#define DEFAULT_POS_Z				(1.0)


enum E_PLAYER_DATA
{
			// Database Account Data
			ply_Password[MAX_PASSWORD_LEN],
			ply_IP,
			ply_RegisterTimestamp,
			ply_LastLogin,
			ply_TotalSpawns,
			ply_Warnings,

			// Character Data
bool:		ply_Alive,
Float:		ply_HitPoints,
Float:		ply_ArmourPoints,
Float:		ply_FoodPoints,
			ply_Clothes,
			ply_Gender,
Float:		ply_Velocity,
			ply_CreationTimestamp,

			// Internal Data
			ply_ShowHUD,
			ply_PingLimitStrikes,
			ply_stance,
			ply_JoinTick,
			ply_SpawnTick
}

static
			ply_Data[MAX_PLAYERS][E_PLAYER_DATA];


forward OnPlayerDisconnected(playerid);
forward OnDeath(playerid, killerid, reason);


public OnPlayerConnect(playerid)
{
	logf("[JOIN] %p joined", playerid);

	SetPlayerColor(playerid, 0xB8B8B800);

	if(IsPlayerNPC(playerid))
		return 1;

	ResetVariables(playerid);

	ply_Data[playerid][ply_JoinTick] = GetTickCount();

	new
		ipstring[16],
		ipbyte[4];

	GetPlayerIp(playerid, ipstring, 16);

	sscanf(ipstring, "p<.>a<d>[4]", ipbyte);
	ply_Data[playerid][ply_IP] = ((ipbyte[0] << 24) | (ipbyte[1] << 16) | (ipbyte[2] << 8) | ipbyte[3]);

	if(BanCheck(playerid))
		return 0;

	defer LoadAccountDelay(playerid);

	SetPlayerBrightness(playerid, 255);

	TogglePlayerControllable(playerid, false);
	Streamer_ToggleIdleUpdate(playerid, true);
	SetSpawnInfo(playerid, NO_TEAM, 0, DEFAULT_POS_X, DEFAULT_POS_Y, DEFAULT_POS_Z, 0.0, 0, 0, 0, 0, 0, 0);
	SpawnPlayer(playerid);

	/*
	If you have any respect for me or my work that I do completely free:
	DO NOT REMOVE THIS MESSAGE.
	It's just one line of text that appears when a player joins.
	Feel free to add your own message UNDER this one with information regarding
	your own modifications you've made to the code but DO NOT REMOVE THIS!

	Thank you :)
	*/
	ChatMsg(playerid, ORANGE, "Scavenge and Survive "C_BLUE"(Copyright (C) 2016 Barnaby \"Southclaw\" Keene)");
	ChatMsgAll(WHITE, " >  %P (%d)"C_WHITE" has joined", playerid, playerid);
	ChatMsg(playerid, YELLOW, " >  MoTD: "C_BLUE"%s", gMessageOfTheDay);

	ply_Data[playerid][ply_ShowHUD] = true;

	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(gServerRestarting)
		return 0;

	Logout(playerid);

	switch(reason)
	{
		case 0:
		{
			ChatMsgAll(GREY, " >  %p lost connection.", playerid);
			log(sprintf("[PART] %p (lost connection)", playerid), 0);
		}
		case 1:
		{
			ChatMsgAll(GREY, " >  %p left the server.", playerid);
			log(sprintf("[PART] %p (quit)", playerid), 0);
		}
	}

	SetTimerEx("OnPlayerDisconnected", 100, false, "dd", playerid, reason);

	return 1;
}

timer LoadAccountDelay[5000](playerid)
{
	if(!IsPlayerConnected(playerid))
	{
		print("[LoadAccountDelay] WARNING: Player not connected any more.");
		return;
	}

	if(gServerInitialising || GetTickCountDifference(GetTickCount(), gServerInitialiseTick) < 5000)
	{
		defer LoadAccountDelay(playerid);
		return;
	}

	new loadresult = LoadAccount(playerid);

	if(loadresult == -1) // LoadAccount aborted, kick player.
	{
		KickPlayer(playerid, "Account load failed");
		return;
	}

	if(loadresult == 0) // Account does not exist
	{
		DisplayRegisterPrompt(playerid);
	}

	if(loadresult == 1) // Account does exist, prompt login
	{
		DisplayLoginPrompt(playerid);
	}

	if(loadresult == 2) // Account does exist, auto login
	{
		Login(playerid);
	}

	if(loadresult == 3) // Account does exist, but not in whitelist
	{
		WhitelistKick(playerid);
	}

	if(loadresult == 4) // Account does exists, but is disabled
	{
		KickPlayer(playerid, "Account inactive");
	}

	CheckForExtraAccounts(playerid);

	return;
}

hook OnPlayerDisconnected(playerid)
{
	d:3:GLOBAL_DEBUG("[OnPlayerDisconnected] in /gamemodes/sss/core/player/core.pwn");

	ResetVariables(playerid);
}

ResetVariables(playerid)
{
	ply_Data[playerid][ply_Password][0]			= EOS;
	ply_Data[playerid][ply_IP]					= 0;
	ply_Data[playerid][ply_Warnings]			= 0;

	ply_Data[playerid][ply_Alive]				= false;
	ply_Data[playerid][ply_HitPoints]			= 100.0;
	ply_Data[playerid][ply_ArmourPoints]		= 0.0;
	ply_Data[playerid][ply_FoodPoints]			= 80.0;
	ply_Data[playerid][ply_Clothes]				= 0;
	ply_Data[playerid][ply_Gender]				= 0;
	ply_Data[playerid][ply_Velocity]			= 0.0;

	ply_Data[playerid][ply_PingLimitStrikes]	= 0;
	ply_Data[playerid][ply_stance]				= 0;
	ply_Data[playerid][ply_JoinTick]			= 0;
	ply_Data[playerid][ply_SpawnTick]			= 0;

	SetPlayerSkillLevel(playerid, WEAPONSKILL_PISTOL,			100);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN,	100);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_MICRO_UZI,		100);

	for(new i; i < 10; i++)
		RemovePlayerAttachedObject(playerid, i);
}

ptask PlayerUpdate[100](playerid)
{
	new pinglimit = (Iter_Count(Player) > 10) ? (gPingLimit) : (gPingLimit + 100);

	if(GetPlayerPing(playerid) > pinglimit)
	{
		if(GetTickCountDifference(GetTickCount(), ply_Data[playerid][ply_JoinTick]) > 10000)
		{
			ply_Data[playerid][ply_PingLimitStrikes]++;

			if(ply_Data[playerid][ply_PingLimitStrikes] == 30)
			{
				KickPlayer(playerid, sprintf("Having a ping of: %d limit: %d.", GetPlayerPing(playerid), pinglimit));

				ply_Data[playerid][ply_PingLimitStrikes] = 0;

				return;
			}
		}
	}
	else
	{
		ply_Data[playerid][ply_PingLimitStrikes] = 0;
	}

	if(NetStats_MessagesRecvPerSecond(playerid) > 200)
	{
		ChatMsgAdmins(3, YELLOW, " >  %p sending %d messages per second.", playerid, NetStats_MessagesRecvPerSecond(playerid));
		return;
	}

	if(!IsPlayerSpawned(playerid))
		return;

	if(IsPlayerInAnyVehicle(playerid))
	{
		PlayerVehicleUpdate(playerid);
	}
	else
	{
		if(!gVehicleSurfing)
			VehicleSurfingCheck(playerid);
	}

	PlayerBagUpdate(playerid);

	new
		hour,
		minute;

	// Get player's own time data
	GetTimeForPlayer(playerid, hour, minute);

	// If it's -1, just use the default instead.
	if(hour == -1 || minute == -1)
		gettime(hour, minute);

	SetPlayerTime(playerid, hour, minute);

	return;
}

public OnPlayerRequestClass(playerid, classid)
{
	if(IsPlayerNPC(playerid))return 1;

	SetSpawnInfo(playerid, NO_TEAM, 0, DEFAULT_POS_X, DEFAULT_POS_Y, DEFAULT_POS_Z, 0.0, 0, 0, 0, 0, 0, 0);

	return 0;
}

public OnPlayerRequestSpawn(playerid)
{
	if(IsPlayerNPC(playerid))return 1;

	SetSpawnInfo(playerid, NO_TEAM, 0, DEFAULT_POS_X, DEFAULT_POS_Y, DEFAULT_POS_Z, 0.0, 0, 0, 0, 0, 0, 0);

	return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
	if(clickedid == Text:65535)
	{
		if(IsPlayerDead(playerid))
		{
			SelectTextDraw(playerid, 0xFFFFFF88);
		}
		else
		{
			ShowWatch(playerid);
		}
	}

	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(IsPlayerNPC(playerid))
		return 1;

	if(IsPlayerOnAdminDuty(playerid))
	{
		SetPlayerPos(playerid, 0.0, 0.0, 3.0);
		return 1;
	}

	ply_Data[playerid][ply_SpawnTick] = GetTickCount();

	SetAllWeaponSkills(playerid, 500);
	SetPlayerTeam(playerid, 0);
	ResetPlayerMoney(playerid);

	PlayerPlaySound(playerid, 1186, 0.0, 0.0, 0.0);
	PreloadPlayerAnims(playerid);
	SetAllWeaponSkills(playerid, 500);
	Streamer_Update(playerid);

	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(IsPlayerInAnyVehicle(playerid))
	{
		static
			str[8],
			Float:vx,
			Float:vy,
			Float:vz;

		GetVehicleVelocity(GetPlayerLastVehicle(playerid), vx, vy, vz);
		ply_Data[playerid][ply_Velocity] = floatsqroot( (vx*vx)+(vy*vy)+(vz*vz) ) * 150.0;
		format(str, 32, "%.0fkm/h", ply_Data[playerid][ply_Velocity]);
		SetPlayerVehicleSpeedUI(playerid, str);
	}
	else
	{
		static
			Float:vx,
			Float:vy,
			Float:vz;

		GetPlayerVelocity(playerid, vx, vy, vz);
		ply_Data[playerid][ply_Velocity] = floatsqroot( (vx*vx)+(vy*vy)+(vz*vz) ) * 150.0;
	}

	if(ply_Data[playerid][ply_Alive])
	{
		if(IsPlayerOnAdminDuty(playerid))
			ply_Data[playerid][ply_HitPoints] = 250.0;

		SetPlayerHealth(playerid, ply_Data[playerid][ply_HitPoints]);
		SetPlayerArmour(playerid, ply_Data[playerid][ply_ArmourPoints]);
	}
	else
	{
		SetPlayerHealth(playerid, 100.0);		
	}

	return 1;
}

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
	d:3:GLOBAL_DEBUG("[OnPlayerStateChange] in /gamemodes/sss/core/player/core.pwn");

	if(newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER)
	{
		ShowPlayerDialog(playerid, -1, DIALOG_STYLE_MSGBOX, " ", " ", " ", " ");
		HidePlayerGear(playerid);
	}

	return 1;
}

hook OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	d:3:GLOBAL_DEBUG("[OnPlayerEnterVehicle] in /gamemodes/sss/core/player/core.pwn");

	if(IsPlayerKnockedOut(playerid))
		return 0;

	if(GetPlayerSurfingVehicleID(playerid) == vehicleid)
		CancelPlayerMovement(playerid);

	if(ispassenger)
	{
		new driverid = -1;

		foreach(new i : Player)
		{
			if(IsPlayerInVehicle(i, vehicleid))
			{
				if(GetPlayerState(i) == PLAYER_STATE_DRIVER)
				{
					driverid = i;
				}
			}
		}

		if(driverid == -1)
			CancelPlayerMovement(playerid);
	}

	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(IsPlayerKnockedOut(playerid))
		return 0;

	if(!IsPlayerInAnyVehicle(playerid))
	{
		new weaponid = GetItemTypeWeaponBaseWeapon(GetItemType(GetPlayerItem(playerid)));

		if(weaponid == 34 || weaponid == 35 || weaponid == 43)
		{
			if(newkeys & 128)
			{
				TogglePlayerHatItemVisibility(playerid, false);
				TogglePlayerMaskItemVisibility(playerid, false);
			}
			if(oldkeys & 128)
			{
				TogglePlayerHatItemVisibility(playerid, true);
				TogglePlayerMaskItemVisibility(playerid, true);
			}
		}
	}

	return 1;
}

KillPlayer(playerid, killerid, deathreason)
{
	CallLocalFunction("OnDeath", "ddd", playerid, killerid, deathreason);
}

// ply_Password
stock GetPlayerPassHash(playerid, string[MAX_PASSWORD_LEN])
{
	if(!IsValidPlayerID(playerid))
		return 0;

	string[0] = EOS;
	strcat(string, ply_Data[playerid][ply_Password]);

	return 1;
}

stock SetPlayerPassHash(playerid, string[MAX_PASSWORD_LEN])
{
	if(!IsPlayerConnected(playerid))
		return 0;

	ply_Data[playerid][ply_Password] = string;

	return 1;
}

// ply_IP
stock GetPlayerIpAsInt(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_IP];
}

// ply_RegisterTimestamp
stock GetPlayerRegTimestamp(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_RegisterTimestamp];
}

stock SetPlayerRegTimestamp(playerid, timestamp)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	ply_Data[playerid][ply_RegisterTimestamp] = timestamp;

	return 1;
}

// ply_LastLogin
stock GetPlayerLastLogin(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_LastLogin];
}

stock SetPlayerLastLogin(playerid, timestamp)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	ply_Data[playerid][ply_LastLogin] = timestamp;

	return 1;
}

// ply_TotalSpawns
stock GetPlayerTotalSpawns(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_TotalSpawns];
}

stock SetPlayerTotalSpawns(playerid, amount)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	ply_Data[playerid][ply_TotalSpawns] = amount;

	return 1;
}

// ply_Warnings
stock GetPlayerWarnings(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_Warnings];
}

stock SetPlayerWarnings(playerid, timestamp)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	ply_Data[playerid][ply_Warnings] = timestamp;

	return 1;
}

// ply_Alive
stock IsPlayerAlive(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_Alive];
}

stock SetPlayerAliveState(playerid, bool:st)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	ply_Data[playerid][ply_Alive] = st;

	return 1;
}

// ply_ShowHUD
stock IsPlayerHudOn(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_ShowHUD];
}

stock TogglePlayerHUD(playerid, bool:st)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	ply_Data[playerid][ply_ShowHUD] = st;

	return 1;
}

// ply_HitPoints
forward Float:GetPlayerHP(playerid);
stock Float:GetPlayerHP(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0.0;

	return ply_Data[playerid][ply_HitPoints];
}

stock SetPlayerHP(playerid, Float:hp)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	if(hp > 100.0)
		hp = 100.0;

	ply_Data[playerid][ply_HitPoints] = hp;

	return 1;
}

// ply_ArmourPoints
forward Float:GetPlayerAP(playerid);
stock Float:GetPlayerAP(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0.0;

	return ply_Data[playerid][ply_ArmourPoints];
}

stock SetPlayerAP(playerid, Float:amount)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	ply_Data[playerid][ply_ArmourPoints] = amount;

	return 1;
}

// ply_FoodPoints
forward Float:GetPlayerFP(playerid);
stock Float:GetPlayerFP(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0.0;

	return ply_Data[playerid][ply_FoodPoints];
}

stock SetPlayerFP(playerid, Float:food)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	ply_Data[playerid][ply_FoodPoints] = food;

	return 1;
}

// ply_Clothes
stock GetPlayerClothesID(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_Clothes];
}

stock SetPlayerClothesID(playerid, id)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	ply_Data[playerid][ply_Clothes] = id;

	return 1;
}

// ply_Gender
stock GetPlayerGender(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_Gender];
}

stock SetPlayerGender(playerid, gender)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	ply_Data[playerid][ply_Gender] = gender;

	return 1;
}

// ply_Velocity
forward Float:GetPlayerTotalVelocity(playerid);
Float:GetPlayerTotalVelocity(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0.0;

	return ply_Data[playerid][ply_Velocity];
}

// ply_CreationTimestamp
stock GetPlayerCreationTimestamp(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_CreationTimestamp];
}

stock SetPlayerCreationTimestamp(playerid, timestamp)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	ply_Data[playerid][ply_CreationTimestamp] = timestamp;

	return 1;
}

// ply_PingLimitStrikes
// ply_stance
stock GetPlayerStance(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_stance];
}

stock SetPlayerStance(playerid, stance)
{
	if(!IsPlayerConnected(playerid))
		return 0;

	ply_Data[playerid][ply_stance] = stance;

	return 1;
}

// ply_JoinTick
stock GetPlayerServerJoinTick(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_JoinTick];
}

// ply_SpawnTick
stock GetPlayerSpawnTick(playerid)
{
	if(!IsValidPlayerID(playerid))
		return 0;

	return ply_Data[playerid][ply_SpawnTick];
}
