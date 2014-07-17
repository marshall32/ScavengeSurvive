#define CAN_DATA_TYPE(%0)		((%0 >> 8) & 0xFF)
#define CAN_DATA_AMOUNT(%0)		(%0 & 0xFF)
#define CAN_DATA_COMBINE(%0,%1)	(%0 << 8 | %1)

enum
{
	CAN_CONTENTS_WATER,		// 0
	CAN_CONTENTS_BEER		// 1
}



public OnItemCreate(itemid)
{
	if(IsItemLoot(itemid))
	{
		if(GetItemType(itemid) == item_CanDrink)
		{
			// First 8 bits represent the type last 8 bits represent the amount
			new
				type = random(2),
				amount = random(10);

			SetItemExtraData(itemid, CAN_DATA_COMBINE(type, amount));
		}
	}

	#if defined can_OnItemCreate
		return can_OnItemCreate(itemid);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnItemCreate
	#undef OnItemCreate
#else
	#define _ALS_OnItemCreate
#endif
 
#define OnItemCreate can_OnItemCreate
#if defined can_OnItemCreate
	forward can_OnItemCreate(itemid);
#endif


public OnItemNameRender(itemid)
{
	if(GetItemType(itemid) == item_CanDrink)
	{
		new
			data,
			type,
			amount;

		data = GetItemExtraData(itemid);
		type = CAN_DATA_TYPE(data);
		amount = CAN_DATA_AMOUNT(data);

		if(amount > 0)
		{
			new str[12];

			switch(type)
			{
				case CAN_CONTENTS_WATER:
					format(str, sizeof(str), "Water %d", amount);

				case CAN_CONTENTS_BEER:
					format(str, sizeof(str), "Beer %d", amount);

				default:
					format(str, sizeof(str), "Unknown %d", amount);
			}

			SetItemNameExtra(itemid, str);
		}
		else
		{
			SetItemNameExtra(itemid, "Empty");
		}
	}

	#if defined can_OnItemNameRender
		return can_OnItemNameRender(itemid);
	#else
		return 0;
	#endif
}
#if defined _ALS_OnItemNameRender
	#undef OnItemNameRender
#else
	#define _ALS_OnItemNameRender
#endif
#define OnItemNameRender can_OnItemNameRender
#if defined can_OnItemNameRender
	forward can_OnItemNameRender(itemid);
#endif

public OnPlayerEaten(playerid, itemid)
{
	if(GetItemType(itemid) == item_CanDrink)
	{
		new
			data,
			type,
			amount;

		data = GetItemExtraData(itemid);
		type = CAN_DATA_TYPE(data);
		amount = CAN_DATA_AMOUNT(data);

		if(amount > 0)
		{
			SetItemExtraData(itemid, CAN_DATA_COMBINE(type, amount - 1));

			if(type == CAN_CONTENTS_BEER)
				SetPlayerDrunkLevel(playerid, GetPlayerDrunkLevel(playerid) + 500);
		}
		else
		{
			ShowActionText(playerid, "Empty", 2000, 70);
			return 1;
		}
	}
	#if defined can_OnPlayerEaten
		return can_OnPlayerEaten(playerid, itemid);
	#else
		return 0;
	#endif
}
#if defined _ALS_OnPlayerEaten
	#undef OnPlayerEaten
#else
	#define _ALS_OnPlayerEaten
#endif
#define OnPlayerEaten can_OnPlayerEaten
#if defined can_OnPlayerEaten
	forward can_OnPlayerEaten(playerid, itemid);
#endif
