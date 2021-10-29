import LimitedHudConfig.MinimapModuleConfig
import LimitedHudCommon.LHUDEvent

@addMethod(MinimapContainerController)
protected cb func OnLHUDEvent(evt: ref<LHUDEvent>) -> Void {
  this.ConsumeEvent(evt);
  this.DetermineCurrentVisibility();
}

@addMethod(MinimapContainerController)
public func DetermineCurrentVisibility() -> Void {
  if !MinimapModuleConfig.IsEnabled() {
    return ;
  };

  if this.lhud_isBraindanceActive {
    this.lhud_isVisibleNow = false;
    this.GetRootWidget().SetVisible(false);
    return ;
  };

  let showForGlobalHotkey: Bool = this.lhud_isGlobalFlagToggled && MinimapModuleConfig.BindToGlobalHotkey();
  let showForMinimapHotkey: Bool = this.lhud_isMinimapFlagToggled;
  let showForCombat: Bool = this.lhud_isCombatActive && MinimapModuleConfig.ShowInCombat();
  let showForOutOfCombat: Bool = this.lhud_isOutOfCombatActive && MinimapModuleConfig.ShowOutOfCombat();
  let showForStealth: Bool =  this.lhud_isStealthActive && MinimapModuleConfig.ShowInStealth();
  let showForVehicle: Bool =  this.lhud_isInVehicle && MinimapModuleConfig.ShowInVehicle();
  let showForScanner: Bool =  this.lhud_isScannerActive && MinimapModuleConfig.ShowWithScanner();
  let showForWeapon: Bool = this.lhud_isWeaponUnsheathed && MinimapModuleConfig.ShowWithWeapon();
  let showForZoom: Bool =  this.lhud_isZoomActive && MinimapModuleConfig.ShowWithZoom();

  let isVisible: Bool = showForGlobalHotkey || showForMinimapHotkey || showForCombat || showForOutOfCombat || showForStealth || showForVehicle || showForScanner || showForWeapon || showForZoom;
  if NotEquals(this.lhud_isVisibleNow, isVisible) {
    this.lhud_isVisibleNow = isVisible;
    if isVisible {
      this.AnimateAlpha(this.GetRootWidget(), MinimapModuleConfig.Opacity(), 0.3);
    } else {
      this.AnimateAlpha(this.GetRootWidget(), 0.0, 0.3);
    };
  };
}

@addMethod(MinimapContainerController)
protected cb func OnInitialize() -> Bool {
  if MinimapModuleConfig.IsEnabled() {
    this.lhud_isVisibleNow = false;
    this.GetRootWidget().SetOpacity(0.0);
    this.OnInitializeFinished();
  };
}
