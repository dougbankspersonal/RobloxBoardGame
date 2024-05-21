-- Common types

-- Everything you need to know about a table.
export type TableDescription = {
    TableId: number,
	HostPlayerId: number,
	MemberPlayerIds: {number},
    Public: boolean,
    InvitedPlayerIds: {number},
    GameConfigId: number,
}

export type GameConfig ={
    
}

return nil