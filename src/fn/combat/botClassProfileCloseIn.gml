// botClassProfileCloseIn(class): BotClassProfile.CloseIn - how near this class
// wants to be before it stops walking at a target; 0 is "no opinion". Only the
// pyro.
if (argument0 == CLASS_PYRO)
    return BOT_FLAME_REACH;
return 0;
