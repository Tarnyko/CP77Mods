import Edgerunning.System.EdgerunningSystem
import Edgerunning.Common.E

@addMethod(EquipmentSystemPlayerData)
private func AddNeuroblockersIfVik() -> Void {
  let journalManager: wref<JournalManager> = GameInstance.GetJournalManager(this.m_owner.GetGame());
  let trackedObjective: wref<JournalQuestObjective> = journalManager.GetTrackedEntry() as JournalQuestObjective;
  let questsSystem: ref<QuestsSystem> = GameInstance.GetQuestsSystem(this.m_owner.GetGame());
  let transactionSystem: ref<TransactionSystem>;
  let neuroblockersFact: Int32 = questsSystem.GetFact(n"neuroblockers_added");
  let id: String = trackedObjective.GetId();
  if Equals(id, "install_cyberware") && Equals(neuroblockersFact, 0) {
    transactionSystem = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
    transactionSystem.GiveItemByTDBID(this.m_owner, t"Items.ripperdoc_med_common", 1);
    questsSystem.SetFact(n"neuroblockers_added", 1);
  };
}

@wrapMethod(PlayerPuppet)
private final func ActivateIconicCyberware() -> Void {
  wrappedMethod();

  let item: ItemID;
  if GameInstance.GetStatsSystem(this.GetGame()).GetStatBoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatType.HasBerserk) {
    if !StatusEffectSystem.ObjectHasStatusEffect(this, t"BaseStatusEffect.BerserkPlayerBuff") {
      item = this.GetCurrentBerserk();
      if !ItemID.IsValid(item) {
        return ;
      };
      EdgerunningSystem.GetInstance(this.GetGame()).OnBerserkActivation(item);
    };
  } else {
    if GameInstance.GetStatsSystem(this.GetGame()).GetStatBoolValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatType.HasSandevistan) {
      if !StatusEffectSystem.ObjectHasStatusEffect(this, t"BaseStatusEffect.SandevistanPlayerBuff") {
        item = this.GetCurrentSandevistan();
        if !ItemID.IsValid(item) {
          return ;
        };
        EdgerunningSystem.GetInstance(this.GetGame()).OnSandevistanActivation(item);
      };
    };
  };
}

@wrapMethod(KerenzikovEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  EdgerunningSystem.GetInstance(scriptInterface.GetGame()).OnKerenzikovActivation();
}

@replaceMethod(InventoryDataManagerV2)
public final static func IsEquipmentAreaCyberware(areaType: gamedataEquipmentArea) -> Bool {
  switch areaType {
    case gamedataEquipmentArea.AbilityCW:
    case gamedataEquipmentArea.NervousSystemCW:
    case gamedataEquipmentArea.MusculoskeletalSystemCW:
    case gamedataEquipmentArea.IntegumentarySystemCW:
    case gamedataEquipmentArea.ImmuneSystemCW:
    case gamedataEquipmentArea.LegsCW:
    case gamedataEquipmentArea.EyesCW:
    case gamedataEquipmentArea.CardiovascularSystemCW:
    case gamedataEquipmentArea.HandsCW:
    case gamedataEquipmentArea.ArmsCW:
    case gamedataEquipmentArea.SystemReplacementCW:
    // added this one
    case gamedataEquipmentArea.FrontalCortexCW:
      return true;
  };
  return false;
}


// Get installed cyberware
@addMethod(EquipmentSystemPlayerData)
public final const func GetCyberwareFromSlots() -> array<ref<Item_Record>> {
  let result: array<ref<Item_Record>>;
  let record: ref<Item_Record>;
  let equipSlots: array<SEquipSlot>;
  let i: Int32;

  for slot in [
      gamedataEquipmentArea.FrontalCortexCW,
      gamedataEquipmentArea.SystemReplacementCW,
      gamedataEquipmentArea.EyesCW,
      gamedataEquipmentArea.MusculoskeletalSystemCW,
      gamedataEquipmentArea.NervousSystemCW,
      gamedataEquipmentArea.CardiovascularSystemCW,
      gamedataEquipmentArea.ImmuneSystemCW,
      gamedataEquipmentArea.IntegumentarySystemCW,
      gamedataEquipmentArea.HandsCW,
      gamedataEquipmentArea.ArmsCW,
      gamedataEquipmentArea.LegsCW
    ] {
      equipSlots = this.m_equipment.equipAreas[this.GetEquipAreaIndex(slot)].equipSlots;
      i = 0;
      while i < ArraySize(equipSlots) {
        if ItemID.IsValid(equipSlots[i].itemID) {
          record = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(equipSlots[i].itemID));
          ArrayPush(result, record);
        };
        i += 1;
      };
    };

  E(s"Detected cyberware: \(ArraySize(result))");
  return result;
}

// -- System-Ex compat

@if(ModuleExists("SystemEx"))
@addMethod(PlayerPuppet)
public func GetCurrentBerserk() -> ItemID {
  let cyberware: array<ref<Item_Record>> = EquipmentSystem.GetData(this).GetCyberwareFromSlots();
  let tags: array<CName> = [ n"Berserk" ];
  let result: ItemID;
  let id: ItemID;
  for record in cyberware {
    id = ItemID.FromTDBID(record.GetID());
    if EquipmentSystem.GetData(this).CheckTagsInItem(id, tags) {
      result = id;
    };
  };

  return result;
}

@if(ModuleExists("SystemEx"))
@addMethod(PlayerPuppet)
public func GetCurrentSandevistan() -> ItemID {
  let cyberware: array<ref<Item_Record>> = EquipmentSystem.GetData(this).GetCyberwareFromSlots();
  let tags: array<CName> = [ n"Sandevistan" ];
  let result: ItemID;
  let id: ItemID;
  for record in cyberware {
    id = ItemID.FromTDBID(record.GetID());
    if EquipmentSystem.GetData(this).CheckTagsInItem(id, tags) {
      result = id;
    };
  };

  return result;
}

@if(!ModuleExists("SystemEx"))
@addMethod(PlayerPuppet)
public func GetCurrentBerserk() -> ItemID {
  return EquipmentSystem.GetData(this).GetActiveItem(gamedataEquipmentArea.SystemReplacementCW);
}

@if(!ModuleExists("SystemEx"))
@addMethod(PlayerPuppet)
public func GetCurrentSandevistan() -> ItemID {
  return EquipmentSystem.GetData(this).GetActiveItem(gamedataEquipmentArea.SystemReplacementCW);
}

// -- Arms cyberware usage
@wrapMethod(RPGManager)
public final static func AwardExperienceFromDamage(hitEvent: ref<gameHitEvent>, damagePercentage: Float) -> Void {
  wrappedMethod(hitEvent, damagePercentage);

  let record: wref<Item_Record>;
  let data: ref<AttackData> = hitEvent.attackData;
  let type: gamedataItemType;
  if data.GetInstigator().IsPlayer() && !hitEvent.target.IsPlayer() {
    record = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(data.GetWeapon().GetItemID()));
    type = record.ItemType().Type();
    switch type {
      case gamedataItemType.Cyb_NanoWires:
      case gamedataItemType.Cyb_MantisBlades:
      // case gamedataItemType.Cyb_Launcher:
        EdgerunningSystem.GetInstance(data.GetInstigator().GetGame()).OnArmsCyberwareActivation(type);
        break;
    };
  };
}


// -- Projectile launcher usage
@wrapMethod(LeftHandCyberwareTransition)
public final func DetachProjectile(scriptInterface: ref<StateGameScriptInterface>, opt angleOffset: Float) -> Void {
  wrappedMethod(scriptInterface, angleOffset);
  EdgerunningSystem.GetInstance(scriptInterface.executionOwner.GetGame()).OnArmsCyberwareActivation(gamedataItemType.Cyb_Launcher);
}

@wrapMethod(UseAction)
public func StartAction(gameInstance: GameInstance) -> Void {
  wrappedMethod(gameInstance);
  let data: ref<gameItemData> = this.GetItemData();
  if !IsDefined(data) || !this.m_executor.IsPlayer() {
    return;
  };
  
  let id: TweakDBID = ItemID.GetTDBID(data.GetID());

  // Optical cammo
  if Equals(id, t"Items.OpticalCamoRare") || Equals(id, t"Items.OpticalCamoEpic") || Equals(id, t"Items.OpticalCamoLegendary") {
    EdgerunningSystem.GetInstance(gameInstance).OnOpticalCamoActivation();
  };
}
