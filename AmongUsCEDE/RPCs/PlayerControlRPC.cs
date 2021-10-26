﻿using System;
using System.Collections.Generic;
using System.Text;
using AmongUsCEDE.Core.Extensions;
using BepInEx;
using HarmonyLib;
using InnerNet;
using Hazel;
using PowerTools;
using UnityEngine;
using AmongUsCEDE.Core;
using AmongUsCEDE.Lua;
using AmongUsCEDE.LuaData;

namespace AmongUsCEDE.RPCs
{
	[HarmonyPatch(typeof(PlayerControl))]
	[HarmonyPatch("HandleRpc")]
	class PlayerControlRPC
	{


		static bool Prefix(PlayerControl __instance, byte callId, ref MessageReader reader)
		{
			switch (callId)
			{
				case 2:
					PlayerControl.GameOptions = GameOptionsData.FromBytes(reader.ReadBytesAndSize());
					GameOptionsExtension.Deserialize(reader);
					return false;
				case 3: //overwrite set impostors cuz impostors no exist anymore
					bool dointro = reader.ReadBoolean();
					GameFunctions.SetRoles(__instance, reader.ReadBytesAndSize(), reader.ReadBytesAndSize(), dointro); //reads the two arrays for players and roles
					return false;
				case 12:
					if (GameData.Instance == null) return false;
					PlayerControl user = MessageExtensions.ReadNetObject<PlayerControl>(reader);
					PlayerControl target = MessageExtensions.ReadNetObject<PlayerControl>(reader);
					bool DoAnimation = reader.ReadBoolean();
					if (AmongUsClient.Instance.AmClient)
					{
						if (DoAnimation)
						{
							user.MurderPlayer(target);
						}
						else
						{
							GameFunctions.MurderPlayerNoAnimation(target,user);
						}
					}

					return false;
				case 34: //with every among us update check to make sure this isn't overwritten
					HostRequestType request = (HostRequestType)reader.ReadByte();
					switch(request)
					{
						case HostRequestType.UsePrimary:
							GameFunctions.SendRequestToHost(__instance,request,reader.ReadByte());
							break;
						case HostRequestType.Custom:
							GameFunctions.SendRequestToHost(__instance, request, (PlayerInfoLua)__instance, reader.ReadByte(), reader.ReadDynValueList().ToArray()); //this is complete
							return false;
						default:
							return false;
					}
					return false;
			}

			return true;
		}
	}
}
