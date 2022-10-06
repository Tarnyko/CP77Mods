import Edgerunning.System.EdgerunningSystem

// Refresh on player visible
@wrapMethod(PlayerPuppet)
protected cb func OnMakePlayerVisibleAfterSpawn(evt: ref<EndGracePeriodAfterSpawn>) -> Bool {
  wrappedMethod(evt);
  EdgerunningSystem.GetInstance(this.GetGame()).RefreshConfig();
}

// Refresh on pause menu exit
@wrapMethod(PauseMenuBackgroundGameController)
protected cb func OnUninitialize() -> Bool {
  EdgerunningSystem.GetInstance(this.GetPlayerControlledObject().GetGame()).RefreshConfig();
  wrappedMethod();
}
