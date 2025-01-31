import Edgerunning.Common.E

/**
  public func Init(player: ref<PlayerPuppet>) -> Void
  public func OnPossessionChanged(playerPossesion: gamedataPlayerPossesion) -> Void
  public func IsGlitchesActive() -> Bool
  public func IsPrePsychosisActive() -> Bool
  public func IsPsychosisActive() -> Bool
  public func IsRipperdocBuffActive() -> Bool
  public func IsPossessed() -> Bool
*/
public class PsychosisEffectsChecker {
  private let player: wref<PlayerPuppet>;
  private let playerSystem: ref<PlayerSystem>;
  private let questsSystem: ref<QuestsSystem>;
  private let possessed: Bool;

  public func Init(player: ref<PlayerPuppet>) -> Void {
    this.player = player;
    this.playerSystem = GameInstance.GetPlayerSystem(this.player.GetGame());
    this.questsSystem = GameInstance.GetQuestsSystem(this.player.GetGame());
  }

  public func OnPossessionChanged(playerPossesion: gamedataPlayerPossesion) -> Void {
    this.possessed = Equals(playerPossesion, gamedataPlayerPossesion.Johnny);
  }

  public func IsGlitchesActive() -> Bool {
    return this.HasStatusEffect(t"BaseStatusEffect.ActiveLowHumanityGlitch");
  }

  public func IsPrePsychosisActive() -> Bool {
    return this.HasStatusEffect(t"BaseStatusEffect.ActivePrePsychosisGlitch");
  }

  public func IsPsychosisActive() -> Bool {
    return this.HasStatusEffect(t"BaseStatusEffect.ActivePsychosisBuff");
  }

  public func IsRipperdocBuffActive() -> Bool {
    let checked: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.player, n"Neuroblockers");
    E(s"? Check for neuroblockers tag: \(checked)");
    return checked;
  }

  public func IsPossessed() -> Bool {
    return this.possessed || this.IsJohnny();
  }

  private func HasStatusEffect(id: TweakDBID) -> Bool {
    return Equals(StatusEffectSystem.ObjectHasStatusEffect(this.player, id), true);
  }

  private func IsJohnny() -> Bool {
    let localPuppet: ref<PlayerPuppet> = this.playerSystem.GetLocalPlayerControlledGameObject() as PlayerPuppet;
    let factName: String = this.playerSystem.GetPossessedByJohnnyFactName();
    return localPuppet.IsJohnnyReplacer() || this.questsSystem.GetFactStr(factName) == 1;
  }
}
