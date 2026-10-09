// botBrainInit(): server start; shared bot-layer state.
global.botNextStagger = 0;
global.botBrainNavGeneration = -1;
global.botBrainSignature = "";
global.botBrainClassSignature = "";
global.botBrainEarlier = ds_list_create();
botPolicyNetLoad();
