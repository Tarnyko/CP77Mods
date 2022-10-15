import Edgerunning.System.EdgerunningSystem

// CET command to stop FX effects - Game.EdgerunnerClear()
public static exec func EdgerunnerClear(gi: GameInstance) -> Void {
  EdgerunningSystem.GetInstance(gi).StopFX();
}

// CET command to get current coords - Game.GetDistrict()
public static exec func GetDistrict(gi: GameInstance) -> Void {
  let player: ref<PlayerPuppet> = GetPlayer(gi);
  let district: gamedataDistrict = player.GetPreventionSystem().GetDistrictE();
  LogChannel(n"DEBUG", s"Position: \(player.GetWorldPosition()) , district: \(district)");
}
