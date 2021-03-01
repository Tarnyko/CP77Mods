public static func IsTppHead(itemId: ItemID) -> Bool {
  return Equals(ItemID.GetTDBID(itemId), t"Items.PlayerMaTppHead") || Equals(ItemID.GetTDBID(itemId), t"Items.PlayerWaTppHead");
}

public static func IsHeadGear(itemId: ItemID) -> Bool {
  return Equals(EquipmentSystem.GetEquipAreaType(itemId), gamedataEquipmentArea.Head);
}

public static func ShouldBeDisplayed(itemId: ItemID) -> Bool {
  return !IsHeadGear(itemId) || IsTppHead(itemId);
}

public static func ShouldBeHidden(itemId: ItemID) -> Bool {
  return IsHeadGear(itemId) && !IsTppHead(itemId);
}

@replaceMethod(EquipmentSystemPlayerData)
public final func OnEquipProcessVisualTags(itemID: ItemID) -> Void {
  Log("--- OnEquipProcessVisualTags " + TDBID.ToStringDEBUG(ItemID.GetTDBID(itemID))
    + " -> IsHeadGear: " + BoolToString(IsHeadGear(itemID)) + ", IsTppHead: " + BoolToString(IsTppHead(itemID)) + ", should display: " + BoolToString(ShouldBeDisplayed(itemID)));
  let itemEntity: wref<GameObject>;
  let transactionSystem: ref<TransactionSystem>;
  let areaType: gamedataEquipmentArea;
  let i: Int32;
  let tag: CName;
  transactionSystem = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  itemEntity = transactionSystem.GetItemInSlotByItemID(this.m_owner, itemID);
  areaType = EquipmentSystem.GetEquipAreaType(itemID);

  tag = this.GetVisualTagByAreaType(areaType);
  if NotEquals(tag, n"") && this.IsVisualTagActive(tag) {
    this.ClearItemAppearanceEvent(areaType);
  } else {
    if NotEquals(itemEntity, null) {
      i = 0;
      while i < ArraySize(this.m_clothingSlotsInfo) {
        if transactionSystem.MatchVisualTag(itemEntity, this.m_clothingSlotsInfo[i].visualTag, true) && !transactionSystem.IsSlotEmpty(this.m_owner, this.m_clothingSlotsInfo[i].equipSlot) {
          this.ClearItemAppearanceEvent(this.m_clothingSlotsInfo[i].areaType);
        };
        i += 1;
      };
      if Equals(areaType, gamedataEquipmentArea.OuterChest) && this.IsPartialVisualTagActive(itemID, transactionSystem) {
        this.m_isPartialVisualTagActive = true;
        this.UpdateInnerChest(transactionSystem);
      };
      if !this.IsUnderwearHidden() || Equals(areaType, gamedataEquipmentArea.UnderwearBottom) && ItemID.IsValid(this.GetActiveItem(gamedataEquipmentArea.Legs)) || this.IsVisualTagActive(n"hide_L1") {
        this.ClearItemAppearanceEvent(gamedataEquipmentArea.UnderwearBottom);
      };
      if this.IsBuildCensored() && !this.IsUnderwearTopHidden() || Equals(areaType, gamedataEquipmentArea.UnderwearTop) && ItemID.IsValid(this.GetActiveItem(gamedataEquipmentArea.InnerChest)) || this.IsVisualTagActive(n"hide_T1") {
        this.ClearItemAppearanceEvent(gamedataEquipmentArea.UnderwearTop);
      };
    };
  };

  if ShouldBeHidden(itemID) {
    this.ClearItemAppearanceEvent(gamedataEquipmentArea.Head);
  };
}

@replaceMethod(EquipmentSystemPlayerData)
private final func EquipItem(itemID: ItemID, slotIndex: Int32, opt addToInventory: Bool, opt blockActiveSlotsUpdate: Bool, opt forceEquipWeapon: Bool) -> Void {
  Log("--- EquipItem " + TDBID.ToStringDEBUG(ItemID.GetTDBID(itemID)));
  let i: Int32;
  let equipAreaIndex: Int32;
  let equipArea: SEquipArea;
  let transactionSystem: ref<TransactionSystem>;
  let placementSlot: TweakDBID;
  let packages: array<wref<GameplayLogicPackage_Record>>;
  let holsterItemID: ItemID;
  let weaponRecord: ref<WeaponItem_Record>;
  let itemEntity: wref<ItemObject>;
  let paperdollEquipData: SPaperdollEquipData;
  let audioEventFootwear: ref<AudioEvent>;
  let audioEventFoley: ref<AudioEvent>;
  let itemData: wref<gameItemData>;
  let cyberwareType: CName;
  let currentItem: ItemID;
  let currentItemData: wref<gameItemData>;
  itemData = RPGManager.GetItemData(this.m_owner.GetGame(), this.m_owner, itemID);
  if !this.IsEquippable(itemData) {
    return ;
  };
  if Equals(RPGManager.GetItemRecord(itemID).ItemType().Type(), gamedataItemType.Cyb_StrongArms) {
    this.HandleStrongArmsEquip(itemID);
  };
  equipAreaIndex = this.GetEquipAreaIndex(EquipmentSystem.GetEquipAreaType(itemID));
  equipArea = this.m_equipment.equipAreas[equipAreaIndex];
  currentItem = this.m_equipment.equipAreas[equipAreaIndex].equipSlots[slotIndex].itemID;
  currentItemData = RPGManager.GetItemData(this.m_owner.GetGame(), this.m_owner, currentItem);
  if NotEquals(currentItemData, null) && currentItemData.HasTag(n"UnequipBlocked") {
    return ;
  };
  if this.IsItemOfCategory(itemID, gamedataItemCategory.Weapon) && equipArea.activeIndex == slotIndex && this.CheckWeaponAgainstGameplayRestrictions(itemID) && !blockActiveSlotsUpdate {
    this.SetSlotActiveItem(EquipmentManipulationRequestSlot.Right, itemID);
    this.SetLastUsedItem(itemID);
  } else {
    if this.IsItemOfCategory(itemID, gamedataItemCategory.Weapon) && forceEquipWeapon && this.CheckWeaponAgainstGameplayRestrictions(itemID) {
      this.SetSlotActiveItem(EquipmentManipulationRequestSlot.Right, itemID);
      this.UpdateEquipAreaActiveIndex(itemID);
      this.SetLastUsedItem(itemID);
    } else {
      this.UnequipItem(equipAreaIndex, slotIndex);
      cyberwareType = TweakDBInterface.GetCName(ItemID.GetTDBID(itemID) + t".cyberwareType", n"");
      i = 0;
      while i < ArraySize(this.m_equipment.equipAreas[equipAreaIndex].equipSlots) {
        if Equals(cyberwareType, TweakDBInterface.GetCName(ItemID.GetTDBID(this.m_equipment.equipAreas[equipAreaIndex].equipSlots[i].itemID) + t".cyberwareType", n"type")) {
          this.UnequipItem(equipAreaIndex, i);
        };
        i += 1;
      };
    };
  };
  if Equals(equipArea.areaType, gamedataEquipmentArea.ArmsCW) {
    this.UnequipItem(equipAreaIndex, slotIndex);
  };
  this.m_equipment.equipAreas[equipAreaIndex].equipSlots[slotIndex].itemID = itemID;
  transactionSystem = GameInstance.GetTransactionSystem(this.m_owner.GetGame());
  placementSlot = this.GetPlacementSlot(equipAreaIndex, slotIndex);
  if placementSlot == t"AttachmentSlots.WeaponRight" || placementSlot == t"AttachmentSlots.WeaponLeft" {
    weaponRecord = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(itemID));
    if NotEquals(weaponRecord, null) && NotEquals(weaponRecord.HolsteredItem(), null) {
      EquipmentSystemPlayerData.UpdateArmSlot((this.m_owner as PlayerPuppet), itemID, true);
    };
  };
  if placementSlot != t"AttachmentSlots.WeaponRight" && placementSlot != t"AttachmentSlots.WeaponLeft" && placementSlot != t"AttachmentSlots.Consumable" {
    if !transactionSystem.HasItemInSlot(this.m_owner, placementSlot, itemID) {
      transactionSystem.RemoveItemFromSlot(this.m_owner, placementSlot);
      transactionSystem.AddItemToSlot(this.m_owner, placementSlot, itemID);
    };
  };
  if Equals(RPGManager.GetItemRecord(itemID).ItemType().Type(), gamedataItemType.Clo_Feet) {
    audioEventFootwear = new AudioEvent();
    audioEventFootwear.eventName = n"equipFootwear";
    audioEventFootwear.nameData = RPGManager.GetItemRecord(itemID).MovementSound().AudioMovementName();
    this.m_owner.QueueEvent(audioEventFootwear);
  };
  audioEventFoley = new AudioEvent();
  audioEventFoley.eventName = n"equipItem";
  audioEventFoley.nameData = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID)).AppearanceName();
  this.m_owner.QueueEvent(audioEventFoley);
  paperdollEquipData.equipArea = this.m_equipment.equipAreas[equipAreaIndex];
  paperdollEquipData.equipped = ShouldBeDisplayed(itemID); // tweak visibility
  paperdollEquipData.placementSlot = placementSlot;
  paperdollEquipData.slotIndex = slotIndex;
  this.ApplyEquipGLPs(itemID);
  this.UpdateWeaponWheel();
  this.UpdateQuickWheel();
  this.UpdateEquipmentUIBB(paperdollEquipData);
  i = 0;
  while i < ArraySize(this.m_hotkeys) {
    if this.m_hotkeys[i].IsCompatible(itemData.GetItemType()) {
      this.AssignItemToHotkey(itemData.GetID(), this.m_hotkeys[i].GetHotkey());
    };
    i += 1;
  };
  EquipmentSystem.GetInstance(this.m_owner).Debug_FillESSlotData(slotIndex, this.m_equipment.equipAreas[equipAreaIndex].areaType, itemID, this.m_owner);
  transactionSystem.OnItemAddedToEquipmentSlot(this.m_owner, itemID);
  if this.IsItemOfCategory(itemID, gamedataItemCategory.Cyberware) {
    this.CheckCyberjunkieAchievement();
  };
}

@addField(GameObject)
let m_trackedHeadItemId: ItemID;

@addField(GameObject)
let m_shouldTrackHeadItem: Bool;

@addMethod(GameObject)
public func HideHeadGear() -> Void {
  let transactionSystem: ref<TransactionSystem>;
  let equipmentData: ref<EquipmentSystemPlayerData>;
  transactionSystem = GameInstance.GetTransactionSystem(this.GetGame());
  transactionSystem.RemoveItemFromSlot(this, t"AttachmentSlots.Head");
}

@addMethod(GameObject)
public func UnequipHeadGear() -> Void {
  let equipmentSystem: ref<EquipmentSystemPlayerData>;
  let activeItemId: ItemID;
  if EquipmentSystem.HasItemInArea(this, gamedataEquipmentArea.Head) {
    equipmentSystem = EquipmentSystem.GetData(GetPlayer(this.GetGame()));
    activeItemId = EquipmentSystem.GetData(this).GetActiveItem(gamedataEquipmentArea.Head);
    equipmentSystem.UnequipItem(activeItemId);
    this.m_trackedHeadItemId = activeItemId;
    this.m_shouldTrackHeadItem = true;
  };
}

@addMethod(GameObject)
public func EquipHeadGear() -> Void {
  let equipmentSystem: ref<EquipmentSystemPlayerData>;
  let itemId: ItemID;
  if NotEquals(this.m_trackedHeadItemId, null) && this.m_shouldTrackHeadItem {
    equipmentSystem = EquipmentSystem.GetData(GetPlayer(this.GetGame()));
    itemId =  GameInstance.GetTransactionSystem(this.GetGame()).GetItemData(this, this.m_trackedHeadItemId).GetID();
    equipmentSystem.EquipItem(itemId, false, false, false);
    this.m_shouldTrackHeadItem = false;
  };
}

@addMethod(GameObject)
public func ReEquipItem() -> Void {
  this.UnequipHeadGear();
  this.EquipHeadGear();
}

@replaceMethod(PlayerPuppet)
protected cb func OnItemAddedToSlot(evt: ref<ItemAddedToSlot>) -> Bool {
  let newApp: CName;
  let itemTDBID: TweakDBID;
  let paperdollEquipData: SPaperdollEquipData;
  let equipmentData: ref<EquipmentSystemPlayerData>;
  let equipmentBB: ref<IBlackboard>;
  let equipSlot: SEquipSlot;
  let itemType: gamedataItemCategory;
  let itemRecord: ref<Item_Record>;
  let itemID: ItemID;
  let slotID: TweakDBID;
  itemID = evt.GetItemID();
  itemTDBID = ItemID.GetTDBID(itemID);
  Log("--- PlayerPuppet::OnItemAddedToSlot " + TDBID.ToStringDEBUG(itemTDBID)
    + " -> IsHeadGear: " + BoolToString(IsHeadGear(itemID)) + ", IsTppHead: " + BoolToString(IsTppHead(itemID)) + ", should display: " + BoolToString(ShouldBeDisplayed(itemID)));
  itemRecord = TweakDBInterface.GetItemRecord(itemTDBID);
  slotID = evt.GetSlotID();
  if NotEquals(itemRecord, null) && NotEquals(itemRecord.ItemCategory(), null) {
    itemType = itemRecord.ItemCategory().Type();
  };
  if Equals(itemType, gamedataItemCategory.Weapon) {
    newApp = TweakDBInterface.GetCName(itemTDBID + t".specific_player_appearance", n"");
    if NotEquals(newApp, n"") {
      GameInstance.GetTransactionSystem(this.GetGame()).ChangeItemAppearance(this, itemID, newApp);
    };
    if slotID == t"AttachmentSlots.WeaponRight" {
      paperdollEquipData.equipArea.areaType = TweakDBInterface.GetItemRecord(itemTDBID).EquipArea().Type();
      paperdollEquipData.equipArea.activeIndex = 0;
      equipSlot.itemID = itemID;
      ArrayPush(paperdollEquipData.equipArea.equipSlots, equipSlot);
      paperdollEquipData.equipped = ShouldBeDisplayed(itemID); // tweak visibility
      paperdollEquipData.placementSlot = EquipmentSystem.GetPlacementSlot(itemID);
      equipmentBB = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_Equipment);
      if NotEquals(equipmentBB, null) {
        equipmentBB.SetVariant(GetAllBlackboardDefs().UI_Equipment.lastModifiedArea, ToVariant(paperdollEquipData));
      };
    };
  } else {
    if Equals(itemType, gamedataItemCategory.Clothing) {
      equipmentData = EquipmentSystem.GetData(GetPlayer(this.GetGame()));
      if NotEquals(equipmentData, null) {
        equipmentData.OnEquipProcessVisualTags(itemID);
      };
    };
  };
  if slotID == t"AttachmentSlots.WeaponRight" || slotID == t"AttachmentSlots.WeaponLeft" {
    EquipmentSystemPlayerData.UpdateArmSlot(this, evt.GetItemID(), false);
  };
    // Track head item
  if IsHeadGear(itemID) && !IsTppHead(itemID) {
    Log("!!! Tracked item added: " + TDBID.ToStringDEBUG(ItemID.GetTDBID(itemID)));
    this.m_trackedHeadItemId = itemID;
    this.m_shouldTrackHeadItem = true;
  };
  super.OnItemAddedToSlot(evt);
}

@replaceMethod(PlayerPuppet)
protected cb func OnItemRemovedFromSlot(evt: ref<ItemRemovedFromSlot>) -> Bool {
  let newApp: CName;
  let itemTDBID: TweakDBID;
  let paperdollEquipData: SPaperdollEquipData;
  let equipmentBB: ref<IBlackboard>;
  let equipmentData: ref<EquipmentSystemPlayerData>;
  let itemType: gamedataItemCategory;
  let itemRecord: ref<Item_Record>;
  itemRecord = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(evt.GetItemID()));
  if NotEquals(itemRecord, null) && NotEquals(itemRecord.ItemCategory(), null) {
    itemType = itemRecord.ItemCategory().Type();
  };
  if Equals(itemType, gamedataItemCategory.Weapon) {
    if evt.GetSlotID() == t"AttachmentSlots.WeaponRight" {
      itemTDBID = ItemID.GetTDBID(evt.GetItemID());
      paperdollEquipData.equipArea.areaType = TweakDBInterface.GetItemRecord(itemTDBID).EquipArea().Type();
      paperdollEquipData.equipped = false;
      paperdollEquipData.placementSlot = EquipmentSystem.GetPlacementSlot(evt.GetItemID());
      equipmentBB = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_Equipment);
      if NotEquals(equipmentBB, null) {
        equipmentBB.SetVariant(GetAllBlackboardDefs().UI_Equipment.lastModifiedArea, ToVariant(paperdollEquipData));
      };
    };
  };
  if evt.GetSlotID() == t"AttachmentSlots.WeaponRight" || evt.GetSlotID() == t"AttachmentSlots.WeaponLeft" {
    EquipmentSystemPlayerData.UpdateArmSlot(this, evt.GetItemID(), true);
  };
  if Equals(evt.GetSlotID(), t"AttachmentSlots.Head") && !IsTppHead(evt.GetItemID()) {
      Log("!!! Tracked item removed: " + TDBID.ToStringDEBUG(ItemID.GetTDBID(evt.GetItemID())));
      this.m_shouldTrackHeadItem = false;
  };
  super.OnItemRemovedFromSlot(evt);

  Log("--- PlayerPuppet::OnItemRemovedFromSlot " + TDBID.ToStringDEBUG(itemTDBID)
    + " -> IsHeadGear: " + BoolToString(IsHeadGear(evt.GetItemID())) 
    + ", IsTppHead: " + BoolToString(IsTppHead(evt.GetItemID())) + ", should display: " 
    + BoolToString(ShouldBeDisplayed(evt.GetItemID()))
  );
}

@replaceMethod(EquipmentSystem)
private final const func GetHairSuffix(itemId: ItemID, owner: wref<GameObject>, suffixRecord: ref<ItemsFactoryAppearanceSuffixBase_Record>) -> String {
  let customizationState: ref<gameuiICharacterCustomizationState>;
  let characterCustomizationSystem: ref<gameuiICharacterCustomizationSystem>;
  let isMountedToVehicle: Bool;
  characterCustomizationSystem = GameInstance.GetCharacterCustomizationSystem(owner.GetGame());
  isMountedToVehicle = VehicleComponent.IsMountedToVehicle(owner.GetGame(), owner.GetEntityID());
  
  // Dirty hack: break hair suffux for vehicle TPP view to fix hair displaying, armor stats not working if mounted
  if isMountedToVehicle {
    return "";
  };

  if (owner as PlayerPuppet) == null && !characterCustomizationSystem.HasCharacterCustomizationComponent(owner) {
    return "Bald";
  };
  customizationState = characterCustomizationSystem.GetState();
  if customizationState != null {
    if customizationState.HasTag(n"Short") {
      return "Short";
    };
    if customizationState.HasTag(n"Long") {
      return "Long";
    };
    if customizationState.HasTag(n"Dreads") {
      return "Dreads";
    };
    if customizationState.HasTag(n"Buzz") {
      return "Buzz";
    };
    return "Bald";
  };
  return "Error";
}

@replaceMethod(inkMotorcycleHUDGameController)
protected cb func OnVehicleMounted() -> Bool {
  let playerPuppet: wref<GameObject>;
  let vehicle: wref<VehicleObject>;
  let shouldConnect: Bool;
  let bbSys: ref<BlackboardSystem>;
  this.m_fluffBlinking = new inkAnimController();
  this.m_fluffBlinking.Select(this.m_lowerfluff_L).Select(this.m_lowerfluff_R).Interpolate(n"transparency", ToVariant(0.25), ToVariant(1.00)).Duration(0.50).Interpolate(n"transparency", ToVariant(1.00), ToVariant(0.25)).Delay(0.55).Duration(0.50).Type(inkanimInterpolationType.Linear).Mode(inkanimInterpolationMode.EasyIn);
  playerPuppet = this.GetOwnerEntity() as GameObject;
  vehicle = GetMountedVehicle(playerPuppet);
  bbSys = GameInstance.GetBlackboardSystem(playerPuppet.GetGame());
  if shouldConnect {
    this.m_vehicleBlackboard = vehicle.GetBlackboard();
    this.m_activeVehicleUIBlackboard = bbSys.Get(GetAllBlackboardDefs().UI_ActiveVehicleData);
  };
  if NotEquals(this.m_vehicleBlackboard, null) {
    this.m_vehicleBBStateConectionId = this.m_vehicleBlackboard.RegisterListenerInt(GetAllBlackboardDefs().Vehicle.VehicleState, this, n"OnVehicleStateChanged");
    this.m_speedBBConnectionId = this.m_vehicleBlackboard.RegisterListenerFloat(GetAllBlackboardDefs().Vehicle.SpeedValue, this, n"OnSpeedValueChanged");
    this.m_gearBBConnectionId = this.m_vehicleBlackboard.RegisterListenerInt(GetAllBlackboardDefs().Vehicle.GearValue, this, n"OnGearValueChanged");
    this.m_rpmValueBBConnectionId = this.m_vehicleBlackboard.RegisterListenerFloat(GetAllBlackboardDefs().Vehicle.RPMValue, this, n"OnRpmValueChanged");
    this.m_leanAngleBBConnectionId = this.m_vehicleBlackboard.RegisterListenerFloat(GetAllBlackboardDefs().Vehicle.BikeTilt, this, n"OnLeanAngleChanged");
    this.m_tppBBConnectionId = this.m_activeVehicleUIBlackboard.RegisterListenerBool(GetAllBlackboardDefs().UI_ActiveVehicleData.IsTPPCameraOn, this, n"OnCameraModeChanged");
    this.m_playerStateBBConnectionId = this.m_activeVehicleUIBlackboard.RegisterListenerVariant(GetAllBlackboardDefs().UI_ActiveVehicleData.VehPlayerStateData, this, n"OnPlayerStateChanged");
  };

  playerPuppet.HideHeadGear();
}

@replaceMethod(inkMotorcycleHUDGameController)
protected cb func OnVehicleUnmounted() -> Bool {
  let playerPuppet: wref<GameObject>;
  playerPuppet = this.GetOwnerEntity() as GameObject;
  if NotEquals(this.m_vehicleBlackboard, null) {
    this.m_vehicleBlackboard.UnregisterListenerInt(GetAllBlackboardDefs().Vehicle.VehicleState, this.m_vehicleBBStateConectionId);
    this.m_vehicleBlackboard.UnregisterListenerFloat(GetAllBlackboardDefs().Vehicle.SpeedValue, this.m_speedBBConnectionId);
    this.m_vehicleBlackboard.UnregisterListenerInt(GetAllBlackboardDefs().Vehicle.GearValue, this.m_gearBBConnectionId);
    this.m_vehicleBlackboard.UnregisterListenerFloat(GetAllBlackboardDefs().Vehicle.RPMValue, this.m_rpmValueBBConnectionId);
    this.m_vehicleBlackboard.UnregisterListenerFloat(GetAllBlackboardDefs().Vehicle.BikeTilt, this.m_leanAngleBBConnectionId);
    this.m_activeVehicleUIBlackboard.UnregisterListenerBool(GetAllBlackboardDefs().UI_ActiveVehicleData.IsTPPCameraOn, this.m_tppBBConnectionId);
    this.m_activeVehicleUIBlackboard.UnregisterListenerVariant(GetAllBlackboardDefs().UI_ActiveVehicleData.VehPlayerStateData, this.m_playerStateBBConnectionId);
  };

  playerPuppet.EquipHeadGear();
}

// --- RE-EQUIP HEAD HEAR ON INVENTORY OPENING ---

@addField(gameuiInGameMenuGameController)
let m_playerPuppet: ref<GameObject>;

@replaceMethod(gameuiInGameMenuGameController)
private final func RegisterInputListenersForPlayer(playerPuppet: ref<GameObject>) -> Void {
  if playerPuppet.IsControlledByLocalPeer() {
    playerPuppet.RegisterInputListener(this, n"OpenPauseMenu");
    playerPuppet.RegisterInputListener(this, n"OpenMapMenu");
    playerPuppet.RegisterInputListener(this, n"OpenCraftingMenu");
    playerPuppet.RegisterInputListener(this, n"OpenJournalMenu");
    playerPuppet.RegisterInputListener(this, n"OpenPerksMenu");
    playerPuppet.RegisterInputListener(this, n"OpenInventoryMenu");
    playerPuppet.RegisterInputListener(this, n"OpenHubMenu");
    playerPuppet.RegisterInputListener(this, n"QuickSave");
    playerPuppet.RegisterInputListener(this, n"FastForward_Hold");
  };
  this.m_playerPuppet = playerPuppet;
}

@replaceMethod(gameuiInGameMenuGameController)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
  let isPlayerLastUsedKBM: Bool;
  if Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_PRESSED) {
    if Equals(ListenerAction.GetName(action), n"QuickSave") {
      this.HandleQuickSave();
    };
  };
  if Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_RELEASED) {
    if Equals(ListenerAction.GetName(action), n"OpenPauseMenu") {
      this.SpawnMenuInstanceEvent(n"OnOpenPauseMenu");
    } else {
      if Equals(ListenerAction.GetName(action), n"OpenHubMenu") {
        this.SpawnMenuInstanceEvent(n"OnOpenHubMenu");
      };
    };
  };
  if Equals(ListenerAction.GetName(action), n"OpenMapMenu") || Equals(ListenerAction.GetName(action), n"OpenCraftingMenu") || Equals(ListenerAction.GetName(action), n"OpenJournalMenu") || Equals(ListenerAction.GetName(action), n"OpenPerksMenu") || Equals(ListenerAction.GetName(action), n"OpenInventoryMenu") {
    isPlayerLastUsedKBM = this.GetPlayerControlledObject().PlayerLastUsedKBM();
    if Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_HOLD_COMPLETE) && !isPlayerLastUsedKBM || Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_RELEASED) && isPlayerLastUsedKBM {
      this.OpenShortcutMenu(ListenerAction.GetName(action));
    };
  };
  if (Equals(ListenerAction.GetName(action), n"OpenInventoryMenu") || Equals(ListenerAction.GetName(action), n"OpenHubMenu")) && NotEquals(this.m_playerPuppet, null) {
    this.m_playerPuppet.ReEquipItem();
  };
}