FUNC void B_TransverInventory(var C_Npc victm, var C_Npc plunder)
{
    if (Npc_GetInvItemBySlot (victm, 0, 0) > 0)
    {
        var int itemid;
            
        itemid = Hlp_GetInstanceID (item);
        
        CreateInvItems (plunder, itemid, NPC_HasItems (victm, itemid));
        
        NPC_RemoveInvItems (victm, itemid, NPC_HasItems (victm, itemid));
        
        B_TransverInventory(victm,plunder);
    };
};