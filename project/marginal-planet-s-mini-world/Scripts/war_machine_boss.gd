enum State {
	IDLE,            # 待机（未发现玩家）
	ENTERING_COMBAT, # 进入战斗动画
	COMBAT,          # 战斗状态（寻路、攻击）
	ATTACKING,       # 正在执行攻击动作（不可移动）
	STUNNED,         # 受击硬直
	DEFEATED,        # 被击败（非战斗状态，可互动）
	DEAD             # 完全死亡（消失）
}
