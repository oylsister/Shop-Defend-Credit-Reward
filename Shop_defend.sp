/*	Copyright (C) 2021 Oylsister
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <shop>

#pragma semicolon 1
#pragma newdecls required

Handle g_hCvarRequireDamage;
Handle g_hCvarCreditReward;
Handle g_hCvarEnabled;
Handle g_hCvarPrefix;

int g_iRequireDamage;
int g_iCreditReward;
bool g_bEnablePlugin;
char g_sPrefix[32];

int g_iClientDamage[MAXPLAYERS+1] = 0;

public Plugin myinfo = 
{
	name = "[Shop] Defend Credits for Zombie:Reloaded", 
	author = "Oylsister", 
	description = "Give Credit to player after do damage to zombie for a while", 
	version = "1.0", 
	url = "https://github.com/oylsister"
}

public void OnPluginStart()
{
	g_hCvarEnabled = CreateConVar("sm_shop_defendcredit_enable", "1.0", "Enable Plugin or not?", _, true, 0.0, true, 1.0);
	g_hCvarRequireDamage = CreateConVar("sm_shop_defendcredit_damage", "5000", "How much damage that player need to get the credit", _, true, 0.0, false);
	g_hCvarCreditReward = CreateConVar("sm_shop_defendcredit_amount", "10", "How much credits player will received after reach specific damage", _, true, 0.0, false);
	g_hCvarPrefix = CreateConVar("sm_shop_defendcredit_prefix", "{green}[Defend]", "What prefix you would like to use?");
	
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_hurt", OnPlayerTakeDamage, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	HookConVarChange(g_hCvarCreditReward, OnConVarChange);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);
	HookConVarChange(g_hCvarRequireDamage, OnConVarChange);
	HookConVarChange(g_hCvarPrefix, OnConVarChange);
}

public void OnMapStart()
{
	g_iCreditReward = GetConVarInt(g_hCvarCreditReward);
	g_bEnablePlugin = view_as<bool>(GetConVarInt(g_hCvarEnabled));
	g_iRequireDamage = GetConVarInt(g_hCvarRequireDamage);
	GetConVarString(g_hCvarPrefix, g_sPrefix, sizeof(g_sPrefix));
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			g_iClientDamage[i] = 0;
		}
	}
}

public void OnMapEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			g_iClientDamage[i] = 0;
		}
	}
}

public void OnConVarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_hCvarCreditReward)
		g_iCreditReward = GetConVarInt(g_hCvarCreditReward);
		
	else if (cvar == g_hCvarEnabled)
		g_bEnablePlugin = view_as<bool>(GetConVarInt(g_hCvarEnabled));
		
	else if (cvar == g_hCvarRequireDamage)
		g_iRequireDamage = GetConVarInt(g_hCvarRequireDamage);
		
	else if (cvar == g_hCvarPrefix)
		GetConVarString(g_hCvarPrefix, g_sPrefix, sizeof(g_sPrefix));
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnablePlugin) 
		return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(g_iClientDamage[i] != 0)
				g_iClientDamage[i] = 0;
			
			CPrintToChat(i, "%s{default} The Current round is enabled Defending Credit Reward, Damaging zombie for a while will reward you with credit", g_sPrefix);
		}
	}
}

public void OnPlayerTakeDamage(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnablePlugin) 
		return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!client || !attacker) 
		return;
		
	int damage = GetEventInt(event, "dmg_health");
	
	if (GetClientTeam(attacker) == 3)
		g_iClientDamage[attacker] += damage;
		
	else
		return;
	
	if (g_iClientDamage[attacker] >= g_iRequireDamage)
	{
		int credits = Shop_GetClientCredits(attacker);
		int new_credits = credits + g_iCreditReward;
		
		Shop_SetClientCredits(attacker, new_credits);
		
		CPrintToChat(attacker, "%s{default} You have received {lightgreen}%d for damaging zombie!", g_sPrefix, g_iCreditReward);
		g_iClientDamage[attacker] = 0;
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnablePlugin) 
		return;
		
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iClientDamage[client] = 0;
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnablePlugin) 
		return;
		
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			g_iClientDamage[i] = 0;
		}
	}
}

public void OnClientConnected(int client)
{
	g_iClientDamage[client] = 0;
}

public void OnClientDisconnect(int client)
{
	g_iClientDamage[client] = 0;
}