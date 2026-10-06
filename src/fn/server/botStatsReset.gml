// botStatsReset(): zero the cost counters the GameServer End Step hook keeps
// (global.botCostSum / botCostTicks in ms and frames, global.botCostMax).
global.botCostSum = 0;
global.botCostTicks = 0;
global.botCostMax = 0;
global.botCostOver = 0;
