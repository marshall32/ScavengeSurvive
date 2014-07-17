#include <YSI\y_hooks>


static scr_TargetItem[MAX_PLAYERS];


hook OnPlayerConnect(playerid)
{
	scr_TargetItem[playerid] = INVALID_ITEM_ID;
}


public OnPlayerUseItemWithItem(playerid, itemid, withitemid)
{
	if(GetItemType(itemid) == item_Screwdriver)
	{
		new ItemType:itemtype = GetItemType(withitemid);

		if(
			itemtype == item_TntPhoneBomb ||
			itemtype == item_TntTripMine ||
			itemtype == item_IedPhoneBomb ||
			itemtype == item_IedTripMine ||
			itemtype == item_EmpPhoneBomb ||
			itemtype == item_EmpTripMine)
		{
			if(GetItemExtraData(withitemid) == 1)
			{
				StartHoldAction(playerid, 2000);
				ApplyAnimation(playerid, "BOMBER", "BOM_Plant_Loop", 4.0, 1, 0, 0, 0, 0);
				scr_TargetItem[playerid] = withitemid;
			}
		}
	}
	#if defined scr_OnPlayerUseItemWithItem
		return scr_OnPlayerUseItemWithItem(playerid, itemid, withitemid);
	#else
		return 0;
	#endif
}
#if defined _ALS_OnPlayerUseItemWithItem
	#undef OnPlayerUseItemWithItem
#else
	#define _ALS_OnPlayerUseItemWithItem
#endif
#define OnPlayerUseItemWithItem scr_OnPlayerUseItemWithItem
#if defined scr_OnPlayerUseItemWithItem
	forward scr_OnPlayerUseItemWithItem(playerid, itemid, withitemid);
#endif


hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(oldkeys & 16)
	{
		if(IsValidItem(scr_TargetItem[playerid]))
			StopHoldAction(playerid);
	}

	return 1;
}

public OnHoldActionFinish(playerid)
{
	if(IsValidItem(scr_TargetItem[playerid]))
	{
		ClearAnimations(playerid);
		SetItemExtraData(scr_TargetItem[playerid], 0);
		scr_TargetItem[playerid] = INVALID_ITEM_ID;

		return 1;
	}

	#if defined scr_OnHoldActionFinish
		return scr_OnHoldActionFinish(playerid);
	#else
		return 0;
	#endif
}


// Hooks


#if defined _ALS_OnHoldActionFinish
	#undef OnHoldActionFinish
#else
	#define _ALS_OnHoldActionFinish
#endif
#define OnHoldActionFinish scr_OnHoldActionFinish
#if defined scr_OnHoldActionFinish
	forward scr_OnHoldActionFinish(playerid);
#endif
